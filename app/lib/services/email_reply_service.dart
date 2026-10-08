// lib/services/email_reply_service.dart  (REPLACE existing file)
import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../models/email_reply_model.dart';
import 'api_constants.dart';

class EmailReplyService extends ChangeNotifier {
  final List<EmailReplyModel> _replies = [];
  bool _isLoading = false;
  bool _isGenerating = false;
  bool _isSendingReply = false;
  String? _error;
  int _unreadCount = 0;
  Timer? _pollTimer;

  List<EmailReplyModel> get replies => List.unmodifiable(_replies);
  bool get isLoading => _isLoading;
  bool get isGenerating => _isGenerating;
  bool get isSendingReply => _isSendingReply;
  String? get error => _error;
  int get unreadCount => _unreadCount;
  int get totalCount => _replies.length;

  EmailReplyService() {
    loadReplies();
    startPolling();
  }

  @override
  void dispose() {
    stopPolling();
    super.dispose();
  }

  // ── Load / refresh all replies ─────────────────────────────────────────────

  Future<void> loadReplies() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final res = await http
          .get(Uri.parse(ApiConstants.emailReplies))
          .timeout(const Duration(seconds: 15));

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        _replies
          ..clear()
          ..addAll(
            (data['replies'] as List<dynamic>).map(
              (e) => EmailReplyModel.fromJson(e as Map<String, dynamic>),
            ),
          );
        _unreadCount = data['unread'] as int? ?? 0;
      } else {
        _error = 'Server error ${res.statusCode}';
      }
    } catch (_) {
      _error = 'Could not load replies. Check your connection.';
    }

    _isLoading = false;
    notifyListeners();
  }

  // ── Mark one reply as read ─────────────────────────────────────────────────

  Future<void> markRead(String id) async {
    final idx = _replies.indexWhere((r) => r.id == id);
    if (idx == -1 || _replies[idx].isRead) return;
    _replies[idx].isRead = true;
    _unreadCount = (_unreadCount - 1).clamp(0, 9999);
    notifyListeners();

    try {
      await http
          .patch(Uri.parse('${ApiConstants.emailReplies}/$id/read'))
          .timeout(const Duration(seconds: 10));
    } catch (_) {}
  }

  // ── Mark all as read ───────────────────────────────────────────────────────

  Future<void> markAllRead() async {
    for (final r in _replies) r.isRead = true;
    _unreadCount = 0;
    notifyListeners();

    try {
      await http
          .patch(Uri.parse('${ApiConstants.emailReplies}/read-all'))
          .timeout(const Duration(seconds: 10));
    } catch (_) {}
  }

  // ── Delete a reply ─────────────────────────────────────────────────────────

  Future<void> deleteReply(String id) async {
    final wasUnread =
        _replies.firstWhere((r) => r.id == id, orElse: _dummyReply).isRead ==
        false;
    _replies.removeWhere((r) => r.id == id);
    if (wasUnread) _unreadCount = (_unreadCount - 1).clamp(0, 9999);
    notifyListeners();

    try {
      await http
          .delete(Uri.parse('${ApiConstants.emailReplies}/$id'))
          .timeout(const Duration(seconds: 10));
    } catch (_) {}
  }

  // ── Generate AI reply via Gemini (backend) ─────────────────────────────────
  // Returns a map: { generated_body, reply_subject, reply_to_email, reply_to_name }
  // or throws a String error message.

  Future<Map<String, String>> generateReply(String replyId) async {
    _isGenerating = true;
    notifyListeners();

    try {
      final res = await http
          .post(
            Uri.parse('${ApiConstants.emailReplies}/$replyId/generate-reply'),
            headers: {'Content-Type': 'application/json'},
          )
          .timeout(const Duration(seconds: 120));

      _isGenerating = false;
      notifyListeners();

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        return {
          'generated_body': data['generated_body'] as String? ?? '',
          'reply_subject': data['reply_subject'] as String? ?? '',
          'reply_to_email': data['reply_to_email'] as String? ?? '',
          'reply_to_name': data['reply_to_name'] as String? ?? '',
        };
      } else {
        final msg = (jsonDecode(res.body) as Map)['detail'] ?? 'AI error';
        throw msg.toString();
      }
    } catch (e) {
      _isGenerating = false;
      notifyListeners();
      rethrow;
    }
  }

  // ── Send a reply email ─────────────────────────────────────────────────────

  Future<bool> sendReply({
    required String replyId,
    required String toEmail,
    required String toName,
    required String subject,
    required String body,
  }) async {
    _isSendingReply = true;
    notifyListeners();

    try {
      final res = await http
          .post(
            Uri.parse('${ApiConstants.emailReplies}/$replyId/send-reply'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'to_email': toEmail,
              'to_name': toName,
              'subject': subject,
              'body': body,
            }),
          )
          .timeout(const Duration(seconds: 30));

      _isSendingReply = false;
      notifyListeners();
      return res.statusCode == 200;
    } catch (_) {
      _isSendingReply = false;
      notifyListeners();
      return false;
    }
  }

  // ── Background poll ────────────────────────────────────────────────────────

  void startPolling() {
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(const Duration(seconds: 60), (_) async {
      try {
        final res = await http
            .get(Uri.parse(ApiConstants.emailUnreadCount))
            .timeout(const Duration(seconds: 10));
        if (res.statusCode == 200) {
          final serverUnread =
              (jsonDecode(res.body) as Map<String, dynamic>)['unread']
                  as int? ??
              0;
          if (serverUnread > _unreadCount) {
            await loadReplies();
          } else if (serverUnread != _unreadCount) {
            _unreadCount = serverUnread;
            notifyListeners();
          }
        }
      } catch (_) {}
    });
  }

  void stopPolling() {
    _pollTimer?.cancel();
    _pollTimer = null;
  }

  EmailReplyModel? getById(String id) {
    try {
      return _replies.firstWhere((r) => r.id == id);
    } catch (_) {
      return null;
    }
  }

  EmailReplyModel Function() get _dummyReply =>
      () => EmailReplyModel(
        id: '',
        senderEmail: '',
        senderName: '',
        subject: '',
        body: '',
        isRead: true,
        receivedAt: DateTime.now(),
      );
}
