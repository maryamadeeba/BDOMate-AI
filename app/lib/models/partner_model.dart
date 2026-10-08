enum PartnerType { industry, alumni, sponsor, institution }
enum PartnerStatus { active, inactive, pending, blacklisted }

class PartnerModel {
  final String id;
  String name;
  String email;
  String phone;
  String organization;
  PartnerType type;
  PartnerStatus status;
  String? address;
  String? website;
  String? notes;
  String? avatar;
  DateTime createdAt;
  DateTime? lastContactedAt;
  List<String> tags;
  double engagementScore;

  PartnerModel({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.organization,
    required this.type,
    this.status = PartnerStatus.active,
    this.address,
    this.website,
    this.notes,
    this.avatar,
    required this.createdAt,
    this.lastContactedAt,
    this.tags = const [],
    this.engagementScore = 0.0,
  });

  factory PartnerModel.fromJson(Map<String, dynamic> json) => PartnerModel(
        id: json['id'] ?? '',
        name: json['name'] ?? '',
        email: json['email'] ?? '',
        phone: json['phone'] ?? '',
        organization: json['organization'] ?? '',
        type: PartnerType.values.firstWhere(
          (e) => e.name == json['type'],
          orElse: () => PartnerType.industry,
        ),
        status: PartnerStatus.values.firstWhere(
          (e) => e.name == json['status'],
          orElse: () => PartnerStatus.active,
        ),
        address: json['address'],
        website: json['website'],
        notes: json['notes'],
        avatar: json['avatar'],
        createdAt: DateTime.tryParse(json['createdAt'] ?? '') ?? DateTime.now(),
        lastContactedAt: json['lastContactedAt'] != null
            ? DateTime.tryParse(json['lastContactedAt'])
            : null,
        tags: List<String>.from(json['tags'] ?? []),
        engagementScore: (json['engagementScore'] ?? 0).toDouble(),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'email': email,
        'phone': phone,
        'organization': organization,
        'type': type.name,
        'status': status.name,
        'address': address,
        'website': website,
        'notes': notes,
        'avatar': avatar,
        'createdAt': createdAt.toIso8601String(),
        'lastContactedAt': lastContactedAt?.toIso8601String(),
        'tags': tags,
        'engagementScore': engagementScore,
      };

  String get typeLabel {
    switch (type) {
      case PartnerType.industry: return 'Industry';
      case PartnerType.alumni: return 'Alumni';
      case PartnerType.sponsor: return 'Sponsor';
      case PartnerType.institution: return 'Institution';
    }
  }

  String get statusLabel {
    switch (status) {
      case PartnerStatus.active: return 'Active';
      case PartnerStatus.inactive: return 'Inactive';
      case PartnerStatus.pending: return 'Pending';
      case PartnerStatus.blacklisted: return 'Blacklisted';
    }
  }
}
