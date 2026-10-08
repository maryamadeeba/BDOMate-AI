enum EventType { seminar, workshop, mou_signing, networking, alumni_meet, sponsor_meet, webinar, conference }
enum EventStatus { upcoming, ongoing, completed, cancelled }

class EventModel {
  final String id;
  String title;
  String description;
  EventType type;
  EventStatus status;
  DateTime startDate;
  DateTime endDate;
  String venue;
  int expectedAttendees;
  int? actualAttendees;
  int? predictedAttendees;
  List<String> invitedPartnerIds;
  List<String> confirmedPartnerIds;
  String organizer;
  String? bannerUrl;
  String? meetingLink;
  bool isVirtual;
  String? notes;

  EventModel({
    required this.id,
    required this.title,
    required this.description,
    required this.type,
    this.status = EventStatus.upcoming,
    required this.startDate,
    required this.endDate,
    required this.venue,
    this.expectedAttendees = 0,
    this.actualAttendees,
    this.predictedAttendees,
    this.invitedPartnerIds = const [],
    this.confirmedPartnerIds = const [],
    required this.organizer,
    this.bannerUrl,
    this.meetingLink,
    this.isVirtual = false,
    this.notes,
  });

  factory EventModel.fromJson(Map<String, dynamic> json) => EventModel(
        id: json['id'] ?? '',
        title: json['title'] ?? '',
        description: json['description'] ?? '',
        type: EventType.values.firstWhere(
          (e) => e.name == json['type'],
          orElse: () => EventType.seminar,
        ),
        status: EventStatus.values.firstWhere(
          (e) => e.name == json['status'],
          orElse: () => EventStatus.upcoming,
        ),
        startDate: DateTime.tryParse(json['startDate'] ?? '') ?? DateTime.now(),
        endDate: DateTime.tryParse(json['endDate'] ?? '') ?? DateTime.now(),
        venue: json['venue'] ?? '',
        expectedAttendees: json['expectedAttendees'] ?? 0,
        actualAttendees: json['actualAttendees'],
        predictedAttendees: json['predictedAttendees'],
        invitedPartnerIds: List<String>.from(json['invitedPartnerIds'] ?? []),
        confirmedPartnerIds: List<String>.from(json['confirmedPartnerIds'] ?? []),
        organizer: json['organizer'] ?? '',
        bannerUrl: json['bannerUrl'],
        meetingLink: json['meetingLink'],
        isVirtual: json['isVirtual'] ?? false,
        notes: json['notes'],
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'description': description,
        'type': type.name,
        'status': status.name,
        'startDate': startDate.toIso8601String(),
        'endDate': endDate.toIso8601String(),
        'venue': venue,
        'expectedAttendees': expectedAttendees,
        'actualAttendees': actualAttendees,
        'predictedAttendees': predictedAttendees,
        'invitedPartnerIds': invitedPartnerIds,
        'confirmedPartnerIds': confirmedPartnerIds,
        'organizer': organizer,
        'bannerUrl': bannerUrl,
        'meetingLink': meetingLink,
        'isVirtual': isVirtual,
        'notes': notes,
      };

  String get typeLabel {
    switch (type) {
      case EventType.seminar: return 'Seminar';
      case EventType.workshop: return 'Workshop';
      case EventType.mou_signing: return 'MOU Signing';
      case EventType.networking: return 'Networking';
      case EventType.alumni_meet: return 'Alumni Meet';
      case EventType.sponsor_meet: return 'Sponsor Meet';
      case EventType.webinar: return 'Webinar';
      case EventType.conference: return 'Conference';
    }
  }
}
