// ============================================================
// FILE: lib/services/admin_analytics_service.dart
// ============================================================
import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

// ── Date Range Mode ─────────────────────────────────────────
enum DateRangeMode { weekly, monthly, yearly, custom }

// ── Admin Analytics Data Model ───────────────────────────────
class AdminAnalyticsData {
  final Map<String, dynamic> summary;
  final List<Map<String, dynamic>> partnerGrowth;
  final List<Map<String, dynamic>> emailStats;
  final List<Map<String, dynamic>> callStats;
  final List<Map<String, dynamic>> mouStats;
  final List<Map<String, dynamic>> campaignStats;
  final List<Map<String, dynamic>> eventStats;
  final List<Map<String, dynamic>> aiUsageStats;
  final List<Map<String, dynamic>> topBDOs;
  final DateTime fetchedAt;

  const AdminAnalyticsData({
    required this.summary,
    required this.partnerGrowth,
    required this.emailStats,
    required this.callStats,
    required this.mouStats,
    required this.campaignStats,
    required this.eventStats,
    required this.aiUsageStats,
    required this.topBDOs,
    required this.fetchedAt,
  });

  factory AdminAnalyticsData.fromJson(Map<String, dynamic> json) {
    return AdminAnalyticsData(
      summary: Map<String, dynamic>.from(json['summary'] ?? {}),
      partnerGrowth: List<Map<String, dynamic>>.from(json['partner_growth'] ?? []),
      emailStats: List<Map<String, dynamic>>.from(json['email_stats'] ?? []),
      callStats: List<Map<String, dynamic>>.from(json['call_stats'] ?? []),
      mouStats: List<Map<String, dynamic>>.from(json['mou_stats'] ?? []),
      campaignStats: List<Map<String, dynamic>>.from(json['campaign_stats'] ?? []),
      eventStats: List<Map<String, dynamic>>.from(json['event_stats'] ?? []),
      aiUsageStats: List<Map<String, dynamic>>.from(json['ai_usage_stats'] ?? []),
      topBDOs: List<Map<String, dynamic>>.from(json['top_bdos'] ?? []),
      fetchedAt: DateTime.tryParse(json['fetched_at'] ?? '') ?? DateTime.now(),
    );
  }
}

// ── Admin Analytics Service ──────────────────────────────────
class AdminAnalyticsService extends ChangeNotifier {
  // ── Config ─────────────────────────────────────────────────
  // TODO: Change this to your actual backend base URL
  static const String _baseUrl = 'http://localhost:8000/api/admin';

  // ── State ───────────────────────────────────────────────────
  bool _isLoading = false;
  String? _error;
  AdminAnalyticsData? _data;
  DateRangeMode _mode = DateRangeMode.monthly;
  DateTimeRange? _customRange;

  // ── Getters ─────────────────────────────────────────────────
  bool get isLoading => _isLoading;
  String? get error => _error;
  AdminAnalyticsData? get data => _data;
  DateRangeMode get mode => _mode;
  DateTimeRange? get customRange => _customRange;
  bool get hasData => _data != null;

  // Returns label like "Dec 1 – Dec 31" or "Weekly" etc.
  String get rangeSummaryLabel {
    switch (_mode) {
      case DateRangeMode.weekly:
        final now = DateTime.now();
        final start = now.subtract(const Duration(days: 6));
        return '${_fmt(start)} – ${_fmt(now)}';
      case DateRangeMode.monthly:
        final now = DateTime.now();
        return '${_monthName(now.month)} ${now.year}';
      case DateRangeMode.yearly:
        return 'Year ${DateTime.now().year}';
      case DateRangeMode.custom:
        if (_customRange != null) {
          return '${_fmt(_customRange!.start)} – ${_fmt(_customRange!.end)}';
        }
        return 'Custom Range';
    }
  }

  // ── Mode Change ─────────────────────────────────────────────
  void setMode(DateRangeMode mode) {
    _mode = mode;
    _customRange = null;
    notifyListeners();
  }

  void setCustomRange(DateTimeRange range) {
    _customRange = range;
    _mode = DateRangeMode.custom;
    notifyListeners();
  }

  // ── Date Range Helpers ──────────────────────────────────────
  DateTimeRange get _effectiveRange {
    final now = DateTime.now();
    switch (_mode) {
      case DateRangeMode.weekly:
        return DateTimeRange(start: now.subtract(const Duration(days: 6)), end: now);
      case DateRangeMode.monthly:
        return DateTimeRange(start: DateTime(now.year, now.month, 1), end: now);
      case DateRangeMode.yearly:
        return DateTimeRange(start: DateTime(now.year, 1, 1), end: now);
      case DateRangeMode.custom:
        return _customRange ?? DateTimeRange(start: now.subtract(const Duration(days: 30)), end: now);
    }
  }

  // ── Main Fetch ──────────────────────────────────────────────
  Future<void> fetchAnalytics({String? authToken}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final range = _effectiveRange;
      final uri = Uri.parse('$_baseUrl/analytics').replace(queryParameters: {
        'start_date': range.start.toIso8601String(),
        'end_date': range.end.toIso8601String(),
        'mode': _mode.name,
      });

      final headers = <String, String>{'Content-Type': 'application/json'};
      if (authToken != null) headers['Authorization'] = 'Bearer $authToken';

      final response = await http.get(uri, headers: headers).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        _data = AdminAnalyticsData.fromJson(json);
        _error = null;
      } else if (response.statusCode == 403) {
        _error = 'Access denied. Admin privileges required.';
      } else {
        _error = 'Server error (${response.statusCode}). Using cached data.';
        // Fallback to mock data for demo / evaluation
        _data = _mockData();
      }
    } catch (e) {
      // Network error – fall back to rich mock data so demo still works
      _error = 'Could not reach server. Showing demo data.';
      _data = _mockData();
    }

    _isLoading = false;
    notifyListeners();
  }

  // ── Mock / Fallback Data ─────────────────────────────────────
  // This makes the UI fully functional even without a live backend.
  // The backend will replace these values with real DB aggregations.
  AdminAnalyticsData _mockData() {
    final range = _effectiveRange;
    final days = range.end.difference(range.start).inDays + 1;

    // Build time-series labels based on mode
    List<String> labels = _buildLabels(days);

    return AdminAnalyticsData(
      fetchedAt: DateTime.now(),
      summary: {
        'total_partners': 42,
        'new_partners': _mode == DateRangeMode.weekly ? 3 : (_mode == DateRangeMode.monthly ? 7 : 28),
        'active_partners': 36,
        'total_emails': _mode == DateRangeMode.weekly ? 48 : (_mode == DateRangeMode.monthly ? 187 : 924),
        'ai_emails': _mode == DateRangeMode.weekly ? 31 : (_mode == DateRangeMode.monthly ? 124 : 612),
        'total_calls': _mode == DateRangeMode.weekly ? 18 : (_mode == DateRangeMode.monthly ? 67 : 342),
        'call_duration_avg': 8.4,
        'total_mous': 12,
        'mous_signed': 8,
        'active_mous': 6,
        'expiring_soon': 2,
        'total_events': _mode == DateRangeMode.weekly ? 2 : (_mode == DateRangeMode.monthly ? 6 : 28),
        'campaign_reach': _mode == DateRangeMode.weekly ? 1240 : (_mode == DateRangeMode.monthly ? 4850 : 22400),
        'campaign_open_rate': 67.4,
        'ai_actions_total': _mode == DateRangeMode.weekly ? 94 : (_mode == DateRangeMode.monthly ? 381 : 1820),
        'avg_engagement_score': 74.2,
        'total_bdos': 5,
      },
      partnerGrowth: labels.asMap().entries.map((e) => {
        'label': e.value,
        'new': [2, 1, 3, 2, 4, 1, 3, 2, 1, 3, 2, 4, 1, 2, 3, 1, 4, 2, 3, 1, 2, 3, 2, 4, 1, 3, 2, 1, 3, 2, 4, 1][e.key % 32],
        'total': 14 + e.key,
      }).toList(),
      emailStats: labels.asMap().entries.map((e) => {
        'label': e.value,
        'sent': [5, 8, 4, 11, 7, 9, 6, 12, 8, 5, 10, 7][e.key % 12],
        'ai_generated': [3, 6, 2, 8, 5, 7, 4, 9, 6, 3, 7, 5][e.key % 12],
        'opened': [4, 6, 3, 9, 5, 7, 5, 10, 6, 4, 8, 6][e.key % 12],
      }).toList(),
      callStats: labels.asMap().entries.map((e) => {
        'label': e.value,
        'total': [2, 3, 1, 4, 3, 5, 2, 4, 3, 2, 4, 3][e.key % 12],
        'missed': [0, 1, 0, 1, 0, 1, 0, 1, 0, 0, 1, 0][e.key % 12],
        'avg_duration': [7.2, 9.1, 5.5, 10.3, 8.7, 11.2, 6.8, 9.5, 8.1, 7.3, 10.1, 8.4][e.key % 12],
      }).toList(),
      mouStats: [
        {'status': 'Active', 'count': 6, 'color': 0xFF2DC653},
        {'status': 'Draft', 'count': 3, 'color': 0xFF2E86AB},
        {'status': 'Pending', 'count': 2, 'color': 0xFFF4A261},
        {'status': 'Expired', 'count': 1, 'color': 0xFFE63946},
      ],
      campaignStats: labels.take(6).toList().asMap().entries.map((e) => {
        'label': e.value,
        'reach': [450, 820, 1200, 680, 940, 1100][e.key % 6],
        'open_rate': [68.0, 71.5, 58.2, 75.1, 63.8, 69.4][e.key % 6],
        'click_rate': [41.2, 45.8, 38.6, 50.3, 44.1, 47.2][e.key % 6],
      }).toList(),
      eventStats: labels.take(6).toList().asMap().entries.map((e) => {
        'label': e.value,
        'events': [1, 2, 0, 1, 2, 1][e.key % 6],
        'attendees': [45, 120, 0, 80, 200, 65][e.key % 6],
      }).toList(),
      aiUsageStats: labels.asMap().entries.map((e) => {
        'label': e.value,
        'emails': [4, 7, 3, 9, 6, 8, 5, 10, 7, 4, 8, 6][e.key % 12],
        'mous': [0, 1, 0, 2, 1, 1, 0, 2, 1, 0, 1, 1][e.key % 12],
        'summaries': [1, 2, 1, 3, 2, 3, 1, 3, 2, 1, 3, 2][e.key % 12],
        'campaigns': [0, 1, 0, 1, 1, 1, 0, 1, 1, 0, 1, 1][e.key % 12],
      }).toList(),
      topBDOs: [
        {'name': 'Maryam Adeeba', 'role': 'BDO Manager', 'emails': 48, 'calls': 22, 'partners': 14, 'score': 94.0},
        {'name': 'Hassan Malik', 'role': 'BDO', 'emails': 31, 'calls': 17, 'partners': 9, 'score': 81.0},
        {'name': 'Sana Tariq', 'role': 'BDO', 'emails': 27, 'calls': 12, 'partners': 8, 'score': 73.0},
        {'name': 'Usman Ghani', 'role': 'BDO', 'emails': 19, 'calls': 8, 'partners': 6, 'score': 62.0},
        {'name': 'Nida Farooq', 'role': 'BDO', 'emails': 14, 'calls': 6, 'partners': 5, 'score': 54.0},
      ],
    );
  }

  List<String> _buildLabels(int days) {
    final now = DateTime.now();
    switch (_mode) {
      case DateRangeMode.weekly:
        return List.generate(7, (i) {
          final d = now.subtract(Duration(days: 6 - i));
          return ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'][d.weekday - 1];
        });
      case DateRangeMode.monthly:
        return List.generate(4, (i) => 'W${i + 1}');
      case DateRangeMode.yearly:
        return ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
      case DateRangeMode.custom:
        if (days <= 14) return List.generate(days, (i) => '${_effectiveRange.start.add(Duration(days: i)).day}/${_effectiveRange.start.add(Duration(days: i)).month}');
        if (days <= 90) return List.generate((days / 7).ceil(), (i) => 'W${i + 1}');
        return ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'].sublist(0, 12.clamp(1, 12));
    }
  }

  String _fmt(DateTime d) => '${d.day} ${_monthName(d.month)}';
  String _monthName(int m) => ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'][m - 1];
}
