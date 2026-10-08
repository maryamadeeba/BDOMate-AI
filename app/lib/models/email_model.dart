enum EmailStatus { draft, sent, failed, scheduled }
enum EmailPriority { low, normal, high }

class EmailModel {
  final String id;
  String subject;
  String body;
  String toEmail;
  String toName;
  String fromEmail;
  String fromName;
  EmailStatus status;
  EmailPriority priority;
  bool isAiGenerated;
  bool isRead;
  DateTime createdAt;
  DateTime? sentAt;
  DateTime? scheduledAt;
  List<String> attachments;
  String? category;
  String? partnerId;

  EmailModel({
    required this.id,
    required this.subject,
    required this.body,
    required this.toEmail,
    required this.toName,
    required this.fromEmail,
    required this.fromName,
    this.status = EmailStatus.draft,
    this.priority = EmailPriority.normal,
    this.isAiGenerated = false,
    this.isRead = false,
    required this.createdAt,
    this.sentAt,
    this.scheduledAt,
    this.attachments = const [],
    this.category,
    this.partnerId,
  });

  factory EmailModel.fromJson(Map<String, dynamic> json) => EmailModel(
        id: json['id'] ?? '',
        subject: json['subject'] ?? '',
        body: json['body'] ?? '',
        toEmail: json['toEmail'] ?? '',
        toName: json['toName'] ?? '',
        fromEmail: json['fromEmail'] ?? '',
        fromName: json['fromName'] ?? '',
        status: EmailStatus.values.firstWhere(
          (e) => e.name == json['status'],
          orElse: () => EmailStatus.draft,
        ),
        priority: EmailPriority.values.firstWhere(
          (e) => e.name == json['priority'],
          orElse: () => EmailPriority.normal,
        ),
        isAiGenerated: json['isAiGenerated'] ?? false,
        isRead: json['isRead'] ?? false,
        createdAt: DateTime.tryParse(json['createdAt'] ?? '') ?? DateTime.now(),
        sentAt: json['sentAt'] != null ? DateTime.tryParse(json['sentAt']) : null,
        scheduledAt: json['scheduledAt'] != null ? DateTime.tryParse(json['scheduledAt']) : null,
        attachments: List<String>.from(json['attachments'] ?? []),
        category: json['category'],
        partnerId: json['partnerId'],
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'subject': subject,
        'body': body,
        'toEmail': toEmail,
        'toName': toName,
        'fromEmail': fromEmail,
        'fromName': fromName,
        'status': status.name,
        'priority': priority.name,
        'isAiGenerated': isAiGenerated,
        'isRead': isRead,
        'createdAt': createdAt.toIso8601String(),
        'sentAt': sentAt?.toIso8601String(),
        'scheduledAt': scheduledAt?.toIso8601String(),
        'attachments': attachments,
        'category': category,
        'partnerId': partnerId,
      };
}
