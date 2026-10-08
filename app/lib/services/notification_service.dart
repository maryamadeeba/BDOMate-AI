// lib/services/notification_service.dart
// ─────────────────────────────────────────────────────────────────────────────
// Web-safe version — no flutter_local_notifications (doesn't work on web).
// Uses backend polling + ChangeNotifier for badge counts and screen updates.

import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'api_constants.dart';

// ─── Model ────────────────────────────────────────────────────────────────────

class AppNotificationModel {
  final String id;
  final String title;
  final String body;
  final String type;
  final String? referenceId;
  bool isRead;
  final DateTime createdAt;

  AppNotificationModel({
    required this.id,
    required this.title,
    required this.body,
    required this.type,
    this.referenceId,
    required this.isRead,
    required this.createdAt,
  });

  factory AppNotificationModel.fromJson(Map<String, dynamic> j) {
    final rawDate = j['created_at'] as String? ?? '';
    final normalized = rawDate.replaceFirst(' ', 'T');
    return AppNotificationModel(
      id: j['id'].toString(),
      title: j['title'] as String? ?? '',
      body: j['body'] as String? ?? '',
      type: j['type'] as String? ?? 'general',
      referenceId: j['reference_id'] as String?,
      isRead: j['is_read'] as bool? ?? false,
      createdAt: DateTime.tryParse(normalized) ?? DateTime.now(),
    );
  }

  IconData get icon {
    switch (type) {
      case 'email_reply':
        return Icons.mark_email_unread_rounded;
      case 'event':
        return Icons.event_rounded;
      case 'call':
        return Icons.call_rounded;
      default:
        return Icons.notifications_rounded;
    }
  }

  Color get color {
    switch (type) {
      case 'email_reply':
        return const Color(0xFF7C4DFF);
      case 'event':
        return const Color(0xFF1565C0);
      case 'call':
        return const Color(0xFF2E7D32);
      default:
        return const Color(0xFF455A64);
    }
  }
}

// ─── Service ──────────────────────────────────────────────────────────────────

class NotificationService extends ChangeNotifier {
  final List<AppNotificationModel> _notifications = [];
  bool _isLoading = false;
  String? _error;
  int _unreadCount = 0;
  Timer? _pollTimer;
  String? _lastSeenId;

  List<AppNotificationModel> get notifications =>
      List.unmodifiable(_notifications);
  bool get isLoading => _isLoading;
  String? get error => _error;
  int get unreadCount => _unreadCount;

  NotificationService() {
    load();
    startPolling();
  }

  @override
  void dispose() {
    stopPolling();
    super.dispose();
  }

  // ── Load from backend ─────────────────────────────────────────────────────

  Future<void> load() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final res = await http
          .get(Uri.parse(ApiConstants.notificationsAll))
          .timeout(const Duration(seconds: 15));

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        final list = (data['notifications'] as List<dynamic>)
            .map(
              (e) => AppNotificationModel.fromJson(e as Map<String, dynamic>),
            )
            .toList();

        _notifications
          ..clear()
          ..addAll(list);
        _unreadCount = data['unread'] as int? ?? 0;
        if (list.isNotEmpty) _lastSeenId = list.first.id;
      } else {
        _error = 'Server error ${res.statusCode}';
      }
    } catch (_) {
      _error = 'Could not load notifications.';
    }

    _isLoading = false;
    notifyListeners();
  }

  // ── Mark one as read ──────────────────────────────────────────────────────

  Future<void> markRead(String id) async {
    final idx = _notifications.indexWhere((n) => n.id == id);
    if (idx == -1 || _notifications[idx].isRead) return;
    _notifications[idx].isRead = true;
    _unreadCount = (_unreadCount - 1).clamp(0, 9999);
    notifyListeners();

    try {
      await http
          .patch(Uri.parse('${ApiConstants.notificationsAll}/$id/read'))
          .timeout(const Duration(seconds: 10));
    } catch (_) {}
  }

  // ── Mark all as read ──────────────────────────────────────────────────────

  Future<void> markAllRead() async {
    for (final n in _notifications) n.isRead = true;
    _unreadCount = 0;
    notifyListeners();

    try {
      await http
          .patch(Uri.parse('${ApiConstants.notificationsAll}/read-all'))
          .timeout(const Duration(seconds: 10));
    } catch (_) {}
  }

  // ── Polling every 60s ─────────────────────────────────────────────────────

  void startPolling() {
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(const Duration(seconds: 60), (_) => load());
  }

  void stopPolling() {
    _pollTimer?.cancel();
    _pollTimer = null;
  }
}
