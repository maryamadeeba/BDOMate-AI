import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../models/event_model.dart';
import 'api_constants.dart';

// ─── Scheduling Recommendation Model ────────────────────────────────────────

class ScheduleRecommendation {
  final DateTime date;
  final String reason;
  final int score;

  const ScheduleRecommendation({
    required this.date,
    required this.reason,
    required this.score,
  });

  factory ScheduleRecommendation.fromJson(Map<String, dynamic> json) {
    return ScheduleRecommendation(
      date: DateTime.parse(json['date'] as String),
      reason: json['reason'] as String? ?? '',
      score: (json['score'] as num?)?.toInt() ?? 0,
    );
  }
}

// ─── Event Service ────────────────────────────────────────────────────────────

class EventService extends ChangeNotifier {
  final List<EventModel> _events = [];
  bool _isLoading = false;
  bool _isPredicting = false;
  String? _error;

  List<EventModel> get events => _events;
  List<EventModel> get upcoming =>
      _events.where((e) => e.status == EventStatus.upcoming).toList();
  List<EventModel> get ongoing =>
      _events.where((e) => e.status == EventStatus.ongoing).toList();
  bool get isLoading => _isLoading;
  bool get isPredicting => _isPredicting;
  String? get error => _error;

  EventService() {
    loadEvents();
  }

  // ── Load events from backend ─────────────────────────────────────────────────

  Future<void> loadEvents() async {
    _isLoading = true;
    notifyListeners();
    try {
      final res = await http
          .get(Uri.parse(ApiConstants.eventsAll))
          .timeout(const Duration(seconds: 15));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        final list = data['events'] as List<dynamic>;
        final backendIds = list.map((e) => e['id'].toString()).toSet();

        // Remove stale backend copies; keep local-only events (no backend id)
        _events.removeWhere((e) => backendIds.contains(e.id));

        for (final e in list) {
          // start_date / end_date are the migrated columns; fall back to
          // created_at only when those columns are genuinely absent.
          final startDate = DateTime.tryParse(e['start_date'] as String? ?? '') ??
              DateTime.tryParse(e['created_at'] as String? ?? '') ??
              DateTime.now();
          final endDate = DateTime.tryParse(e['end_date'] as String? ?? '') ??
              startDate.add(const Duration(hours: 2));

          _events.insert(
            0,
            EventModel(
              id: e['id'].toString(),
              title: e['title'] as String? ?? '',
              description: e['description'] as String? ?? '',
              type: _parseEventType(e['type'] as String?),
              status: _parseEventStatus(e['status'] as String?),
              startDate: startDate,
              endDate: endDate,
              venue: e['venue'] as String? ?? 'TBD',
              expectedAttendees: (e['expected_attendees'] as num?)?.toInt() ?? 100,
              predictedAttendees: _parsePrediction(e['prediction']),
              organizer: e['organizer'] as String? ?? 'BDO',
              isVirtual: (e['is_virtual'] as bool?) ?? false,
              meetingLink: e['meeting_link'] as String?,
            ),
          );
        }
      }
    } catch (_) {
      _error = 'Could not load events.';
    }
    _isLoading = false;
    notifyListeners();
  }

  // ── Parse helpers for enum fields from backend ───────────────────────────────

  EventType _parseEventType(String? raw) {
    switch (raw?.toLowerCase()) {
      case 'conference': return EventType.conference;
      case 'webinar':    return EventType.webinar;
      case 'alumni_meet': return EventType.alumni_meet;
      case 'sponsor_meet': return EventType.sponsor_meet;
      case 'mou_signing': return EventType.mou_signing;
      case 'workshop':   return EventType.workshop;
      case 'networking': return EventType.networking;
      default:           return EventType.seminar;
    }
  }

  EventStatus _parseEventStatus(String? raw) {
    switch (raw?.toLowerCase()) {
      case 'ongoing':   return EventStatus.ongoing;
      case 'completed': return EventStatus.completed;
      default:          return EventStatus.upcoming;
    }
  }

  int? _parsePrediction(dynamic val) {
    if (val == null) return null;
    if (val is int) return val;
    final s = val.toString().toLowerCase();
    if (s.contains('high')) return 300;
    if (s.contains('medium')) return 150;
    if (s.contains('low')) return 50;
    return int.tryParse(s);
  }

  // ── Predict attendance via ML backend ────────────────────────────────────────

  Future<int> predictAttendance(String eventId) async {
    _isPredicting = true;
    notifyListeners();
    final event = getById(eventId);
    if (event == null) {
      _isPredicting = false;
      notifyListeners();
      return 0;
    }

    try {
      final res = await http
          .post(
            Uri.parse(ApiConstants.eventsPredict),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'title': event.title,
              'event_type': _mapEventType(event.type),
              'department': 'General',
              'day_of_week': _dayName(event.startDate.weekday),
              'time_slot': _timeSlot(event.startDate.hour),
              'season': _season(event.startDate.month),
              'capacity': event.expectedAttendees,
              'is_free': event.isVirtual,
              'has_food': !event.isVirtual,
              'industry_guests': event.invitedPartnerIds.isNotEmpty,
              'weeks_promoted': 2,
              'past_avg_attendance': (event.expectedAttendees * 0.6).round(),
            }),
          )
          .timeout(const Duration(seconds: 30));

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        final predicted = _parsePrediction(data['prediction']) ?? 0;
        final idx = _events.indexWhere((e) => e.id == eventId);
        if (idx != -1) _events[idx].predictedAttendees = predicted;
        _isPredicting = false;
        notifyListeners();
        return predicted;
      } else {
        throw Exception('Server error ${res.statusCode}');
      }
    } catch (_) {
      final fallback = ((event.expectedAttendees) * 0.78).round();
      final idx = _events.indexWhere((ev) => ev.id == eventId);
      if (idx != -1) _events[idx].predictedAttendees = fallback;
      _isPredicting = false;
      notifyListeners();
      return fallback;
    }
  }

  // ── AI Scheduling Recommendations ────────────────────────────────────────────
  // Calls /events/recommend endpoint. Falls back to local heuristics on failure.

  Future<List<ScheduleRecommendation>> getSchedulingRecommendations({
    required EventType eventType,
    required int expectedAttendees,
    required bool isVirtual,
    required DateTime referenceDate,
  }) async {
    try {
      final res = await http
          .post(
            Uri.parse(ApiConstants.eventsRecommend),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'event_type': _mapEventType(eventType),
              'expected_attendees': expectedAttendees,
              'is_virtual': isVirtual,
              'reference_date': referenceDate.toIso8601String(),
              'has_food': !isVirtual,
            }),
          )
          .timeout(const Duration(seconds: 20));

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        final list = data['recommendations'] as List<dynamic>;
        return list
            .map((e) =>
                ScheduleRecommendation.fromJson(e as Map<String, dynamic>))
            .toList();
      }
    } catch (_) {
      // fall through to local
    }
    return _localRecommendations(referenceDate);
  }

  List<ScheduleRecommendation> _localRecommendations(DateTime ref) {
    final now = ref.isAfter(DateTime.now()) ? ref : DateTime.now();
    final results = <ScheduleRecommendation>[];
    int added = 0;

    final reasons = [
      'Mid-week mornings have historically higher attendance rates.',
      'Tuesday–Thursday slots avoid weekend conflicts.',
      '10 AM slots see the highest engagement in past data.',
    ];

    for (int i = 1; i <= 30 && added < 3; i++) {
      final d = now.add(Duration(days: i));
      if (d.weekday >= DateTime.tuesday && d.weekday <= DateTime.thursday) {
        results.add(ScheduleRecommendation(
          date: DateTime(d.year, d.month, d.day, 10, 0),
          reason: reasons[added],
          score: 92 - (added * 8),
        ));
        added++;
      }
    }
    return results;
  }

  // ── Record actual attendance ──────────────────────────────────────────────────

  Future<void> recordActualAttendance(String eventId, int actual) async {
    final event = getById(eventId);
    if (event == null) return;
    try {
      await http
          .post(
            Uri.parse(ApiConstants.retrainRecord),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'event_type': _mapEventType(event.type),
              'department': 'General',
              'day_of_week': _dayName(event.startDate.weekday),
              'time_slot': _timeSlot(event.startDate.hour),
              'season': _season(event.startDate.month),
              'capacity': event.expectedAttendees,
              'is_free': event.isVirtual,
              'has_food': !event.isVirtual,
              'industry_guests': event.invitedPartnerIds.isNotEmpty,
              'weeks_promoted': 2,
              'past_avg_attendance': (event.expectedAttendees * 0.6).round(),
              'actual_attendance': actual,
            }),
          )
          .timeout(const Duration(seconds: 15));
    } catch (_) {}
    final idx = _events.indexWhere((e) => e.id == eventId);
    if (idx != -1) {
      _events[idx].actualAttendees = actual;
      notifyListeners();
    }
  }

  // ── CRUD ─────────────────────────────────────────────────────────────────────

  EventModel? getById(String id) {
    try {
      return _events.firstWhere((e) => e.id == id);
    } catch (_) {
      return null;
    }
  }

  // ── Clash detection ───────────────────────────────────────────────────────────
  // Returns the first existing event that overlaps [start, end), or null.
  // Two events clash when their time ranges overlap on the same calendar day:
  //   existing.start < newEnd  AND  existing.end > newStart
  EventModel? findClash(DateTime start, DateTime end, {String? excludeId}) {
    for (final e in _events) {
      if (e.id == excludeId) continue;
      // Only compare events on the same calendar day
      if (e.startDate.year != start.year ||
          e.startDate.month != start.month ||
          e.startDate.day != start.day) continue;
      // Overlap check: they clash unless one ends before the other starts
      final noOverlap = !e.endDate.isAfter(start) || !end.isAfter(e.startDate);
      if (!noOverlap) return e;
    }
    return null;
  }

  Future<void> addEvent(EventModel event) async {
    _isLoading = true;
    notifyListeners();
    await Future.delayed(const Duration(milliseconds: 300));
    _events.insert(0, event);
    _isLoading = false;
    notifyListeners();
    predictAttendance(event.id);
  }

  Future<void> updateEvent(EventModel updated) async {
    final idx = _events.indexWhere((e) => e.id == updated.id);
    if (idx != -1) {
      _events[idx] = updated;
      notifyListeners();
    }
  }

  /// Persists a newly created event to the backend so it survives restart.
  /// Called after addEvent inserts locally.
  Future<void> persistEventToBackend(EventModel event) async {
    try {
      await http
          .post(
            Uri.parse(ApiConstants.eventsAll),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'title': event.title,
              'description': event.description,
              'type': event.type.name,
              'status': event.status.name,
              'start_date': event.startDate.toIso8601String(),
              'end_date': event.endDate.toIso8601String(),
              'venue': event.venue,
              'expected_attendees': event.expectedAttendees,
              'organizer': event.organizer,
              'is_virtual': event.isVirtual,
              'meeting_link': event.meetingLink,
            }),
          )
          .timeout(const Duration(seconds: 15));
    } catch (_) {
      // Silent — event lives locally; syncs on next full load.
    }
  }

  Future<void> deleteEvent(String id) async {
    _events.removeWhere((e) => e.id == id);
    notifyListeners();
  }

  // ── Derivation helpers ────────────────────────────────────────────────────────

  String _mapEventType(EventType t) {
    switch (t) {
      case EventType.conference:
        return 'seminar';
      case EventType.seminar:
        return 'seminar';
      case EventType.webinar:
        return 'webinar';
      case EventType.alumni_meet:
        return 'social';
      case EventType.sponsor_meet:
        return 'seminar';
      case EventType.mou_signing:
        return 'ceremony';
      case EventType.workshop:
        return 'workshop';
      default:
        return 'seminar';
    }
  }

  String _dayName(int weekday) {
    const days = [
      'Monday', 'Tuesday', 'Wednesday', 'Thursday',
      'Friday', 'Saturday', 'Sunday',
    ];
    return days[(weekday - 1).clamp(0, 6)];
  }

  String _timeSlot(int hour) {
    if (hour < 12) return 'morning';
    if (hour < 17) return 'afternoon';
    return 'evening';
  }

  String _season(int month) {
    if (month >= 3 && month <= 5) return 'spring';
    if (month >= 6 && month <= 8) return 'summer';
    if (month >= 9 && month <= 11) return 'fall';
    return 'winter';
  }
}