enum AiMessageRole { user, assistant }

class AiMessage {
  const AiMessage({
    required this.id,
    required this.role,
    required this.content,
    this.isFlagged = false,
    this.provider,
    this.model,
    this.createdAt,
    this.suggestedActivitySlug,
    this.suggestedActivityName,
  });

  final String id;
  final AiMessageRole role;
  final String content;
  final bool isFlagged;
  final String? provider;
  final String? model;
  final String? createdAt;

  /// Backend-grounded deep-link: the slug of the in-app activity the companion
  /// recommended for this (assistant) message, or null when it suggested none.
  /// Sourced from the `suggested_activity` object on GET messages.
  final String? suggestedActivitySlug;
  final String? suggestedActivityName;

  factory AiMessage.fromJson(Map<String, dynamic> json) {
    final suggested = json['suggested_activity'] as Map<String, dynamic>?;
    return AiMessage(
      id: json['id'] as String,
      role: (json['role'] as String?) == 'user'
          ? AiMessageRole.user
          : AiMessageRole.assistant,
      content: json['content'] as String? ?? '',
      isFlagged: json['is_flagged'] as bool? ?? false,
      provider: json['provider'] as String?,
      model: json['model'] as String?,
      createdAt: json['created_at'] as String?,
      suggestedActivitySlug: suggested?['slug'] as String?,
      suggestedActivityName: suggested?['name'] as String?,
    );
  }
}

/// Streaming event from POST /ai/threads/{id}/messages (SSE).
sealed class AiStreamEvent {
  const AiStreamEvent();
}

class AiStreamMessageReceived extends AiStreamEvent {
  const AiStreamMessageReceived({required this.id, required this.isFlagged});
  final String id;
  final bool isFlagged;
}

class AiStreamDelta extends AiStreamEvent {
  const AiStreamDelta(this.text);
  final String text;
}

class AiStreamComplete extends AiStreamEvent {
  const AiStreamComplete({
    required this.threadId,
    this.suggestedActivitySlug,
    this.suggestedActivityName,
  });
  final String threadId;

  /// The suggested activity carried by the SSE `message.complete` event, so a
  /// freshly-streamed reply can show the activity button without a re-fetch.
  final String? suggestedActivitySlug;
  final String? suggestedActivityName;
}

class AiStreamError extends AiStreamEvent {
  const AiStreamError(this.message);
  final String message;
}
