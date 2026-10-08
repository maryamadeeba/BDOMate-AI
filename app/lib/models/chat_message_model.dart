enum MessageSender { user, ai }
enum MessageType { text, suggestion, action }

class ChatMessageModel {
  final String id;
  final String content;
  final MessageSender sender;
  final MessageType type;
  final DateTime timestamp;
  final List<String> suggestions;
  bool isLoading;

  ChatMessageModel({
    required this.id,
    required this.content,
    required this.sender,
    this.type = MessageType.text,
    required this.timestamp,
    this.suggestions = const [],
    this.isLoading = false,
  });

  factory ChatMessageModel.user(String content) => ChatMessageModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        content: content,
        sender: MessageSender.user,
        timestamp: DateTime.now(),
      );

  factory ChatMessageModel.ai(String content, {List<String> suggestions = const []}) =>
      ChatMessageModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        content: content,
        sender: MessageSender.ai,
        timestamp: DateTime.now(),
        suggestions: suggestions,
      );

  factory ChatMessageModel.loading() => ChatMessageModel(
        id: 'loading',
        content: '',
        sender: MessageSender.ai,
        timestamp: DateTime.now(),
        isLoading: true,
      );
}
