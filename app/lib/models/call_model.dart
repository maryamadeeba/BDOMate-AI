enum CallType { outgoing, incoming, missed }
enum CallStatus { completed, missed, failed, ongoing }

class CallModel {
  final String id;
  String contactName;
  String contactPhone;
  String? contactId;
  CallType type;
  CallStatus status;
  int durationSeconds;
  DateTime callTime;
  String? recordingUrl;
  String? transcription;
  String? summary;
  List<String> keyPoints;
  String? notes;
  bool isAiSummarized;

  CallModel({
    required this.id,
    required this.contactName,
    required this.contactPhone,
    this.contactId,
    required this.type,
    required this.status,
    this.durationSeconds = 0,
    required this.callTime,
    this.recordingUrl,
    this.transcription,
    this.summary,
    this.keyPoints = const [],
    this.notes,
    this.isAiSummarized = false,
  });

  factory CallModel.fromJson(Map<String, dynamic> json) => CallModel(
        id: json['id'] ?? '',
        contactName: json['contactName'] ?? '',
        contactPhone: json['contactPhone'] ?? '',
        contactId: json['contactId'],
        type: CallType.values.firstWhere(
          (e) => e.name == json['type'],
          orElse: () => CallType.outgoing,
        ),
        status: CallStatus.values.firstWhere(
          (e) => e.name == json['status'],
          orElse: () => CallStatus.completed,
        ),
        durationSeconds: json['durationSeconds'] ?? 0,
        callTime: DateTime.tryParse(json['callTime'] ?? '') ?? DateTime.now(),
        recordingUrl: json['recordingUrl'],
        transcription: json['transcription'],
        summary: json['summary'],
        keyPoints: List<String>.from(json['keyPoints'] ?? []),
        notes: json['notes'],
        isAiSummarized: json['isAiSummarized'] ?? false,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'contactName': contactName,
        'contactPhone': contactPhone,
        'contactId': contactId,
        'type': type.name,
        'status': status.name,
        'durationSeconds': durationSeconds,
        'callTime': callTime.toIso8601String(),
        'recordingUrl': recordingUrl,
        'transcription': transcription,
        'summary': summary,
        'keyPoints': keyPoints,
        'notes': notes,
        'isAiSummarized': isAiSummarized,
      };

  String get durationFormatted {
    final m = durationSeconds ~/ 60;
    final s = durationSeconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }
}
