import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../models/call_model.dart';
import 'api_constants.dart';

class CallService extends ChangeNotifier {
  List<CallModel> _calls = [];
  bool _isLoading = false;
  bool _isOnCall = false;
  bool _isTranscribing = false;
  CallModel? _activeCall;

  List<CallModel> get calls => _calls;
  bool get isLoading => _isLoading;
  bool get isOnCall => _isOnCall;
  bool get isTranscribing => _isTranscribing;
  CallModel? get activeCall => _activeCall;
  int get totalCalls => _calls.length;
  int get missedCalls =>
      _calls.where((c) => c.status == CallStatus.missed).length;
  int get totalDuration => _calls.fold(0, (s, c) => s + c.durationSeconds);

  CallService() {
    loadCallHistory();
  }

  // ── Load call history ────────────────────────────────────────
  // FIXED: Merges backend calls instead of replacing local ones
  Future<void> loadCallHistory() async {
    _isLoading = true;
    notifyListeners();
    try {
      final res = await http
          .get(Uri.parse(ApiConstants.callHistory))
          .timeout(const Duration(seconds: 15));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        final list = data['calls'] as List;

        // Keep locally added calls (ones that start with DEMO- or were just made)
        final localCalls = _calls
            .where(
              (c) => c.id.startsWith('DEMO-') || c.status == CallStatus.ongoing,
            )
            .toList();

        // Backend calls
        final backendCalls = list
            .map(
              (c) => CallModel(
                id: c['call_sid'] ?? c['id'] ?? '',
                contactName: c['contact'] ?? c['to'] ?? 'Unknown',
                contactPhone: c['to'] ?? '',
                type: CallType.outgoing,
                status: _parseStatus(c['status']),
                durationSeconds:
                    int.tryParse(c['duration']?.toString() ?? '0') ?? 0,
                callTime:
                    DateTime.tryParse(c['start_time'] ?? '') ?? DateTime.now(),
                isAiSummarized: false,
              ),
            )
            .toList();

        // Merge: local calls first, then backend calls (no duplicates)
        final backendIds = backendCalls.map((c) => c.id).toSet();
        final merged = [
          ...localCalls.where((c) => !backendIds.contains(c.id)),
          ...backendCalls,
        ];

        _calls = merged;
      }
    } catch (_) {}
    _isLoading = false;
    notifyListeners();
  }

  // ── Make IVR call ────────────────────────────────────────────
  Future<Map<String, dynamic>> startCall(
    String contactName,
    String contactPhone, {
    String? contactId,
    String purpose = 'general',
    String organization = '',
  }) async {
    _isOnCall = true;
    notifyListeners();

    try {
      final res = await http
          .post(
            Uri.parse(ApiConstants.callsSingle),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'phone_number': contactPhone,
              'contact_name': contactName,
              'call_purpose': purpose,
              'organization': organization,
            }),
          )
          .timeout(const Duration(seconds: 30));

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);

        // Build call model from response
        final newCall = CallModel(
          id:
              data['call_sid'] ??
              'DEMO-${DateTime.now().millisecondsSinceEpoch}',
          contactName: contactName,
          contactPhone: contactPhone,
          type: CallType.outgoing,
          status: CallStatus.completed,
          callTime: DateTime.now(),
          durationSeconds: _parseDuration(data['duration']),
          isAiSummarized: data['transcript'] != null,
          summary: data['recipient_action'] ?? data['message'],
          transcription: data['transcript'],
        );

        // Insert at top of list so it shows first
        _calls.insert(0, newCall);
        _activeCall = newCall;
        _isOnCall = false;
        notifyListeners();
        return data;
      } else {
        throw Exception(
          'Call failed (${res.statusCode}). '
          'Make sure backend is running and DEMO_MODE=true in .env',
        );
      }
    } catch (e) {
      _isOnCall = false;
      _activeCall = null;
      notifyListeners();
      rethrow;
    }
  }

  Future<void> endCall() async {
    _isOnCall = false;
    _activeCall = null;
    notifyListeners();
  }

  Future<String> transcribeCall(String callId) async {
    _isTranscribing = true;
    notifyListeners();
    try {
      final res = await http
          .get(Uri.parse('${ApiConstants.base}/calls/$callId'))
          .timeout(const Duration(seconds: 15));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        final idx = _calls.indexWhere((c) => c.id == callId);
        if (idx != -1) _calls[idx].isAiSummarized = true;
        _isTranscribing = false;
        notifyListeners();
        return 'Status: ${data['status']} | Duration: ${data['duration']}s';
      }
    } catch (_) {}
    _isTranscribing = false;
    notifyListeners();
    return 'Could not fetch transcript.';
  }

  Future<List<Map<String, dynamic>>> getIvrResponses() async {
    try {
      final res = await http
          .get(Uri.parse('${ApiConstants.base}/calls/ivr-responses'))
          .timeout(const Duration(seconds: 10));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        return List<Map<String, dynamic>>.from(data['responses'] ?? []);
      }
    } catch (_) {}
    return [];
  }

  CallModel? getById(String id) {
    try {
      return _calls.firstWhere((c) => c.id == id);
    } catch (_) {
      return null;
    }
  }

  int _parseDuration(dynamic val) {
    if (val == null) return 0;
    if (val is int) return val;
    final s = val.toString();
    final m = RegExp(r'(\d+)m').firstMatch(s);
    final sec = RegExp(r'(\d+)s').firstMatch(s);
    return (int.tryParse(m?.group(1) ?? '0') ?? 0) * 60 +
        (int.tryParse(sec?.group(1) ?? '0') ?? 0);
  }

  CallStatus _parseStatus(String? s) {
    switch (s) {
      case 'completed':
        return CallStatus.completed;
      case 'no-answer':
        return CallStatus.missed;
      case 'busy':
        return CallStatus.missed;
      case 'failed':
        return CallStatus.missed;
      default:
        return CallStatus.completed;
    }
  }
}
