enum CampaignType { email, social_media, sms, whatsapp, mixed }
enum CampaignStatus { draft, scheduled, active, paused, completed }

class CampaignModel {
  final String id;
  String title;
  String description;
  CampaignType type;
  CampaignStatus status;
  String content;
  List<String> targetAudience;
  int totalReach;
  int opened;
  int clicked;
  int converted;
  DateTime createdAt;
  DateTime? scheduledAt;
  DateTime? completedAt;
  bool isAiGenerated;
  String? imageUrl;
  String? platform;
  Map<String, dynamic> metrics;

  CampaignModel({
    required this.id,
    required this.title,
    required this.description,
    required this.type,
    this.status = CampaignStatus.draft,
    required this.content,
    this.targetAudience = const [],
    this.totalReach = 0,
    this.opened = 0,
    this.clicked = 0,
    this.converted = 0,
    required this.createdAt,
    this.scheduledAt,
    this.completedAt,
    this.isAiGenerated = false,
    this.imageUrl,
    this.platform,
    this.metrics = const {},
  });

  double get openRate => totalReach > 0 ? (opened / totalReach) * 100 : 0;
  double get clickRate => opened > 0 ? (clicked / opened) * 100 : 0;
  double get conversionRate => clicked > 0 ? (converted / clicked) * 100 : 0;

  factory CampaignModel.fromJson(Map<String, dynamic> json) => CampaignModel(
        id: json['id'] ?? '',
        title: json['title'] ?? '',
        description: json['description'] ?? '',
        type: CampaignType.values.firstWhere(
          (e) => e.name == json['type'],
          orElse: () => CampaignType.email,
        ),
        status: CampaignStatus.values.firstWhere(
          (e) => e.name == json['status'],
          orElse: () => CampaignStatus.draft,
        ),
        content: json['content'] ?? '',
        targetAudience: List<String>.from(json['targetAudience'] ?? []),
        totalReach: json['totalReach'] ?? 0,
        opened: json['opened'] ?? 0,
        clicked: json['clicked'] ?? 0,
        converted: json['converted'] ?? 0,
        createdAt: DateTime.tryParse(json['createdAt'] ?? '') ?? DateTime.now(),
        scheduledAt: json['scheduledAt'] != null ? DateTime.tryParse(json['scheduledAt']) : null,
        completedAt: json['completedAt'] != null ? DateTime.tryParse(json['completedAt']) : null,
        isAiGenerated: json['isAiGenerated'] ?? false,
        imageUrl: json['imageUrl'],
        platform: json['platform'],
        metrics: Map<String, dynamic>.from(json['metrics'] ?? {}),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'description': description,
        'type': type.name,
        'status': status.name,
        'content': content,
        'targetAudience': targetAudience,
        'totalReach': totalReach,
        'opened': opened,
        'clicked': clicked,
        'converted': converted,
        'createdAt': createdAt.toIso8601String(),
        'scheduledAt': scheduledAt?.toIso8601String(),
        'completedAt': completedAt?.toIso8601String(),
        'isAiGenerated': isAiGenerated,
        'imageUrl': imageUrl,
        'platform': platform,
        'metrics': metrics,
      };
}
