enum MouStatus { draft, pending_review, signed, active, expired, terminated }

class MouModel {
  final String id;
  String title;
  String partnerId;
  String partnerName;
  String partnerOrganization;
  MouStatus status;
  String content;
  String universityRepresentative;
  String partnerRepresentative;
  DateTime createdAt;
  DateTime? signedAt;
  DateTime? startDate;
  DateTime? expiryDate;
  String purpose;
  List<String> obligations;
  String? pdfUrl;
  bool isAiGenerated;
  String? notes;

  MouModel({
    required this.id,
    required this.title,
    required this.partnerId,
    required this.partnerName,
    required this.partnerOrganization,
    this.status = MouStatus.draft,
    required this.content,
    required this.universityRepresentative,
    required this.partnerRepresentative,
    required this.createdAt,
    this.signedAt,
    this.startDate,
    this.expiryDate,
    required this.purpose,
    this.obligations = const [],
    this.pdfUrl,
    this.isAiGenerated = false,
    this.notes,
  });

  factory MouModel.fromJson(Map<String, dynamic> json) => MouModel(
        id: json['id'] ?? '',
        title: json['title'] ?? '',
        partnerId: json['partnerId'] ?? '',
        partnerName: json['partnerName'] ?? '',
        partnerOrganization: json['partnerOrganization'] ?? '',
        status: MouStatus.values.firstWhere(
          (e) => e.name == json['status'],
          orElse: () => MouStatus.draft,
        ),
        content: json['content'] ?? '',
        universityRepresentative: json['universityRepresentative'] ?? '',
        partnerRepresentative: json['partnerRepresentative'] ?? '',
        createdAt: DateTime.tryParse(json['createdAt'] ?? '') ?? DateTime.now(),
        signedAt: json['signedAt'] != null ? DateTime.tryParse(json['signedAt']) : null,
        startDate: json['startDate'] != null ? DateTime.tryParse(json['startDate']) : null,
        expiryDate: json['expiryDate'] != null ? DateTime.tryParse(json['expiryDate']) : null,
        purpose: json['purpose'] ?? '',
        obligations: List<String>.from(json['obligations'] ?? []),
        pdfUrl: json['pdfUrl'],
        isAiGenerated: json['isAiGenerated'] ?? false,
        notes: json['notes'],
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'partnerId': partnerId,
        'partnerName': partnerName,
        'partnerOrganization': partnerOrganization,
        'status': status.name,
        'content': content,
        'universityRepresentative': universityRepresentative,
        'partnerRepresentative': partnerRepresentative,
        'createdAt': createdAt.toIso8601String(),
        'signedAt': signedAt?.toIso8601String(),
        'startDate': startDate?.toIso8601String(),
        'expiryDate': expiryDate?.toIso8601String(),
        'purpose': purpose,
        'obligations': obligations,
        'pdfUrl': pdfUrl,
        'isAiGenerated': isAiGenerated,
        'notes': notes,
      };

  String get statusLabel {
    switch (status) {
      case MouStatus.draft: return 'Draft';
      case MouStatus.pending_review: return 'Pending Review';
      case MouStatus.signed: return 'Signed';
      case MouStatus.active: return 'Active';
      case MouStatus.expired: return 'Expired';
      case MouStatus.terminated: return 'Terminated';
    }
  }

  bool get isExpired => expiryDate != null && expiryDate!.isBefore(DateTime.now());

  int? get daysUntilExpiry {
    if (expiryDate == null) return null;
    return expiryDate!.difference(DateTime.now()).inDays;
  }
}
