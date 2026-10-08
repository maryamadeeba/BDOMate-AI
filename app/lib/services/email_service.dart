import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../models/email_model.dart';

class EmailService extends ChangeNotifier {
  static const String _baseUrl = 'http://localhost:8000';

  List<EmailModel> _emails = [];
  bool _isLoading = false;
  bool _isGenerating = false;

  // Variables to track the currently logged-in account details
  String currentUserEmail;
  String currentUserName;

  List<EmailModel> get emails => _emails;
  List<EmailModel> get sent =>
      _emails.where((e) => e.status == EmailStatus.sent).toList();
  List<EmailModel> get drafts =>
      _emails.where((e) => e.status == EmailStatus.draft).toList();
  List<EmailModel> get scheduled =>
      _emails.where((e) => e.status == EmailStatus.scheduled).toList();
  bool get isLoading => _isLoading;
  bool get isGenerating => _isGenerating;
  int get unreadCount =>
      _emails.where((e) => !e.isRead && e.status == EmailStatus.sent).length;

  /// Updated Constructor: Accepts current session details dynamically
  EmailService({this.currentUserEmail = '', this.currentUserName = ''}) {
    _loadFromBackend();
  }

  /// Call this when a new user signs in to sync their specific active session
  void updateSessionUser({required String email, required String name}) {
    currentUserEmail = email;
    currentUserName = name;
    _loadFromBackend();
  }

  // ── Load saved emails dynamically from the database on startup ───────────
  Future<void> _loadFromBackend() async {
    try {
      final response = await http
          .get(Uri.parse('$_baseUrl/email/all'))
          .timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final List emailsJson = data['emails'] ?? [];
        _emails = emailsJson
            .map(
              (e) => EmailModel(
                id: e['id'].toString(),
                subject: e['subject'] ?? '',
                body: e['body'] ?? '',
                toEmail: (e['recipient_email'] ?? e['toEmail'] ?? '')
                    .toString(),
                toName: (e['recipient_name'] ?? e['toName'] ?? 'Partner')
                    .toString(),

                // Checks backend column first. If empty, uses active user session variables
                fromEmail:
                    (e['sender_email'] != null &&
                        e['sender_email'].toString().trim().isNotEmpty)
                    ? e['sender_email'].toString()
                    : currentUserEmail.clampEmpty('No Sender Account'),
                fromName:
                    (e['sender_name'] != null &&
                        e['sender_name'].toString().trim().isNotEmpty)
                    ? e['sender_name'].toString()
                    : currentUserName.clampEmpty('Active Representative'),

                status: e['status'] == 'sent'
                    ? EmailStatus.sent
                    : e['status'] == 'scheduled'
                    ? EmailStatus.scheduled
                    : EmailStatus.draft,
                isAiGenerated: e['is_ai_generated'] ?? true,
                isRead: false,
                createdAt:
                    DateTime.tryParse(e['created_at'] ?? '') ?? DateTime.now(),
                sentAt: e['sent_at'] != null
                    ? DateTime.tryParse(e['sent_at'])
                    : null,
                category: e['email_purpose'],
              ),
            )
            .toList();
      }
    } catch (_) {
      // Backend not reachable — start with empty list
    }
    notifyListeners();
  }

  Future<void> refresh() => _loadFromBackend();

  EmailModel? getById(String id) {
    try {
      return _emails.firstWhere((e) => e.id == id);
    } catch (_) {
      return null;
    }
  }

  // ── AI email generation ──────────────────────────────────────
  Future<String> generateEmail({
    required String recipientName,
    required String recipientOrg,
    required String purpose,
    required String tone,
  }) async {
    _isGenerating = true;
    notifyListeners();

    String generatedBody = '';

    try {
      final response = await http
          .post(
            Uri.parse('$_baseUrl/email/generate'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'recipient_name': recipientName,
              'recipient_org': recipientOrg.isEmpty
                  ? 'their organisation'
                  : recipientOrg,
              'email_purpose': purpose,
              'context': 'Tone: $tone',
            }),
          )
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        generatedBody = (data['body'] ?? '').toString().trim();
      }
    } catch (_) {
      // fall through to local fallback
    }

    if (generatedBody.isEmpty) {
      final salutation = tone == 'formal'
          ? 'Yours sincerely,'
          : 'Warm regards,';
      generatedBody =
          '''Dear $recipientName,

I hope this message finds you in excellent health and high spirits.

I am writing on behalf of the University of South Asia's Business Development Office regarding ${purpose.toLowerCase()}.

We have been closely following ${recipientOrg.isEmpty ? 'your organisation' : recipientOrg}'s work and believe there is a tremendous opportunity for mutually beneficial collaboration.

I would appreciate the opportunity to schedule a brief call or meeting at your convenience.

Thank you for your time and consideration.

$salutation''';
    }

    _isGenerating = false;
    notifyListeners();
    return generatedBody;
  }

  // ── Send email — saves dynamic account user attributes to DB ───────────────
  Future<void> sendEmail(EmailModel email) async {
    _isLoading = true;
    notifyListeners();

    email.status = EmailStatus.sent;
    email.sentAt = DateTime.now();

    String finalId = email.id;

    final cleanEmail = currentUserEmail.trim().isEmpty
        ? 'nooriqbal504@gmail.com'
        : currentUserEmail;
    final cleanName = currentUserName.trim().isEmpty
        ? 'Noor Fatima'
        : currentUserName;

    try {
      final response = await http
          .post(
            Uri.parse('$_baseUrl/email/save'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'recipient_name': email.toName.isEmpty
                  ? email.toEmail
                  : email.toName,
              'recipient_org': '',
              'recipient_email': email.toEmail,
              'subject': email.subject,
              'body': email.body,
              'email_purpose': email.category ?? 'general',
              'status': 'sent',
              'partner_id': null,
              'sender_name': cleanName,
              'sender_email': cleanEmail,
            }),
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        if (data['email_id'] != null) {
          finalId = data['email_id'].toString();
        }
      }
    } catch (_) {
      // Network error
    }

    final updated = EmailModel(
      id: finalId,
      subject: email.subject,
      body: email.body,
      toEmail: email.toEmail,
      toName: email.toName,
      fromEmail: cleanEmail,
      fromName: cleanName,
      status: EmailStatus.sent,
      priority: email.priority,
      isAiGenerated: email.isAiGenerated,
      isRead: email.isRead,
      createdAt: email.createdAt,
      sentAt: email.sentAt,
      category: email.category,
      partnerId: email.partnerId,
    );

    final idx = _emails.indexWhere((e) => e.id == email.id);
    if (idx != -1) {
      _emails[idx] = updated;
    } else {
      _emails.insert(0, updated);
    }

    _isLoading = false;
    notifyListeners();
  }

  // ── Save draft — stores context markers to DB ──────────────
  Future<void> saveDraft(EmailModel email) async {
    String finalId = email.id;

    final cleanEmail = currentUserEmail.trim().isEmpty
        ? 'nooriqbal504@gmail.com'
        : currentUserEmail;
    final cleanName = currentUserName.trim().isEmpty
        ? 'Noor Fatima'
        : currentUserName;

    try {
      final response = await http
          .post(
            Uri.parse('$_baseUrl/email/save'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'recipient_name': email.toName.isEmpty
                  ? email.toEmail
                  : email.toName,
              'recipient_org': '',
              'recipient_email': email.toEmail,
              'subject': email.subject,
              'body': email.body,
              'email_purpose': email.category ?? 'general',
              'status': 'draft',
              'partner_id': null,
              'sender_name': cleanName,
              'sender_email': cleanEmail,
            }),
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        if (data['email_id'] != null) {
          finalId = data['email_id'].toString();
        }
      }
    } catch (_) {
      // Network error
    }

    final updated = EmailModel(
      id: finalId,
      subject: email.subject,
      body: email.body,
      toEmail: email.toEmail,
      toName: email.toName,
      fromEmail: cleanEmail,
      fromName: cleanName,
      status: EmailStatus.draft,
      priority: email.priority,
      isAiGenerated: email.isAiGenerated,
      isRead: email.isRead,
      createdAt: email.createdAt,
      category: email.category,
      partnerId: email.partnerId,
    );

    final idx = _emails.indexWhere((e) => e.id == email.id);
    if (idx != -1) {
      _emails[idx] = updated;
    } else {
      _emails.insert(0, updated);
    }
    notifyListeners();
  }

  Future<void> deleteEmail(String id) async {
    _emails.removeWhere((e) => e.id == id);
    notifyListeners();
  }

  void markRead(String id) {
    final idx = _emails.indexWhere((e) => e.id == id);
    if (idx != -1) {
      _emails[idx].isRead = true;
      notifyListeners();
    }
  }
}

/// Simple helper extension to check for blank strings safely alongside nulls
extension StringFallback on String? {
  String clampEmpty(String fallback) {
    if (this == null || this!.trim().isEmpty) {
      return fallback;
    }
    return this!;
  }
}
