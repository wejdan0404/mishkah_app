class JournalEntry {
  const JournalEntry({
    required this.id,
    required this.title,
    required this.body,
    required this.createdAt,
    required this.updatedAt,
    this.isPinned = false,
    this.topicId,
    this.mood,
    this.bodyDelta,
  });

  final String id;
  final String title;
  final String body;

  /// Optional Quill Delta JSON (the `body_delta` field) — the rich version of
  /// [body]. Null for old/plain notes, which keep loading from [body]. [body]
  /// always holds a readable plain-text fallback.
  final List<dynamic>? bodyDelta;

  final DateTime createdAt;

  /// Timestamp of the last content edit. Equals [createdAt] until the entry is
  /// edited. Pinning does NOT bump this — it isn't a content change.
  final DateTime updatedAt;
  final bool isPinned;
  final String? topicId;

  /// Optional mood-slug tag for the entry (admin-managed mood catalogue).
  final String? mood;

  JournalEntry copyWith({
    String? id,
    String? title,
    String? body,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isPinned,
    String? topicId,
    String? mood,
    List<dynamic>? bodyDelta,
  }) =>
      JournalEntry(
        id: id ?? this.id,
        title: title ?? this.title,
        body: body ?? this.body,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
        isPinned: isPinned ?? this.isPinned,
        topicId: topicId ?? this.topicId,
        mood: mood ?? this.mood,
        bodyDelta: bodyDelta ?? this.bodyDelta,
      );

  /// Parses the /me/journal wire shape (snake_case). `updated_at` falls back to
  /// `created_at` for entries saved before edit-tracking existed.
  factory JournalEntry.fromJson(Map<String, dynamic> json) {
    final DateTime created =
        DateTime.tryParse(json['created_at'] as String? ?? '')?.toLocal() ??
            DateTime.now();
    final String? updatedRaw = json['updated_at'] as String?;
    return JournalEntry(
      id: json['id'] as String,
      title: json['title'] as String? ?? '',
      body: json['body'] as String? ?? '',
      createdAt: created,
      updatedAt: updatedRaw != null
          ? (DateTime.tryParse(updatedRaw)?.toLocal() ?? created)
          : created,
      isPinned: (json['is_pinned'] as bool?) ?? false,
      topicId: json['topic_id'] as String?,
      mood: json['mood'] as String?,
      // Backward compatible: null when the backend doesn't send body_delta yet,
      // or when an old note has none — the editor then loads from plain `body`.
      bodyDelta: json['body_delta'] is List
          ? json['body_delta'] as List<dynamic>
          : null,
    );
  }
}

/// Formats a journal timestamp as «اليوم/أمس h:mm ص/م» for today/yesterday,
/// otherwise «YYYY/M/D h:mm ص/م». Shared by the journal list and the writing
/// screen so both render the date identically.
String formatJournalTimestamp(DateTime dt) {
  final DateTime now = DateTime.now();
  final DateTime today = DateTime(now.year, now.month, now.day);
  final DateTime yesterday = today.subtract(const Duration(days: 1));
  final DateTime entryDay = DateTime(dt.year, dt.month, dt.day);

  final int hour12 =
      dt.hour == 0 ? 12 : (dt.hour > 12 ? dt.hour - 12 : dt.hour);
  final String minute = dt.minute.toString().padLeft(2, '0');
  final String period = dt.hour >= 12 ? 'م' : 'ص';
  final String time = '$hour12:$minute $period';

  if (entryDay == today) return 'اليوم $time';
  if (entryDay == yesterday) return 'أمس $time';
  return '${dt.year}/${dt.month}/${dt.day} $time';
}
