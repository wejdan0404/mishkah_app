class AiThread {
  const AiThread({
    required this.id,
    this.title,
    this.messageCount = 0,
    this.lastMessageAt,
    this.createdAt,
  });

  final String id;
  final String? title;
  final int messageCount;
  final String? lastMessageAt;
  final String? createdAt;

  factory AiThread.fromJson(Map<String, dynamic> json) => AiThread(
        id: json['id'] as String,
        title: json['title'] as String?,
        messageCount: (json['message_count'] as num?)?.toInt() ?? 0,
        lastMessageAt: json['last_message_at'] as String?,
        createdAt: json['created_at'] as String?,
      );
}
