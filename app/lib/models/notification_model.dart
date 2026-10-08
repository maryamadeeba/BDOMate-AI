enum NotificationType { call, email, event, mou, campaign, system, reminder }
enum NotificationPriority { low, normal, high, urgent }

class NotificationModel {
  final String id;
  String title;
  String message;
  NotificationType type;
  NotificationPriority priority;
  bool isRead;
  DateTime createdAt;
  String? actionRoute;
  String? actionId;
  Map<String, dynamic> data;

  NotificationModel({
    required this.id,
    required this.title,
    required this.message,
    required this.type,
    this.priority = NotificationPriority.normal,
    this.isRead = false,
    required this.createdAt,
    this.actionRoute,
    this.actionId,
    this.data = const {},
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) => NotificationModel(
        id: json['id'] ?? '',
        title: json['title'] ?? '',
        message: json['message'] ?? '',
        type: NotificationType.values.firstWhere(
          (e) => e.name == json['type'],
          orElse: () => NotificationType.system,
        ),
        priority: NotificationPriority.values.firstWhere(
          (e) => e.name == json['priority'],
          orElse: () => NotificationPriority.normal,
        ),
        isRead: json['isRead'] ?? false,
        createdAt: DateTime.tryParse(json['createdAt'] ?? '') ?? DateTime.now(),
        actionRoute: json['actionRoute'],
        actionId: json['actionId'],
        data: Map<String, dynamic>.from(json['data'] ?? {}),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'message': message,
        'type': type.name,
        'priority': priority.name,
        'isRead': isRead,
        'createdAt': createdAt.toIso8601String(),
        'actionRoute': actionRoute,
        'actionId': actionId,
        'data': data,
      };
}
