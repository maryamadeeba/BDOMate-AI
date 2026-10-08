// lib/models/email_reply_model.dart

class EmailReplyModel {
  final String id;
  final String senderEmail;
  final String senderName;
  final String subject;
  final String body;
  bool isRead;
  final DateTime receivedAt;

  EmailReplyModel({
    required this.id,
    required this.senderEmail,
    required this.senderName,
    required this.subject,
    required this.body,
    required this.isRead,
    required this.receivedAt,
  });

  factory EmailReplyModel.fromJson(Map<String, dynamic> json) {
    return EmailReplyModel(
      id: json['id'].toString(),
      senderEmail: json['sender_email'] as String? ?? '',
      senderName: json['sender_name'] as String? ?? '',
      subject: json['subject'] as String? ?? '(No subject)',
      body: json['body'] as String? ?? '',
      isRead: json['is_read'] as bool? ?? false,
      // ✅ Fix: replace space with T so DateTime.tryParse handles
      // both "2026-06-06 20:16:02+05:00" and "2026-06-06T20:16:02Z"
      receivedAt: _parseDate(
        json['received_at'] as String? ?? json['created_at'] as String? ?? '',
      ),
    );
  }

  static DateTime _parseDate(String raw) {
    if (raw.isEmpty) return DateTime.now();
    // Normalize: replace space separator with T for ISO 8601
    final normalized = raw.replaceFirst(' ', 'T');
    return DateTime.tryParse(normalized) ?? DateTime.now();
  }

  String get displayName =>
      senderName.trim().isNotEmpty ? senderName.trim() : senderEmail;

  String get initials {
    final parts = displayName.split(' ').where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return (parts[0][0] + parts[1][0]).toUpperCase();
  }
}
