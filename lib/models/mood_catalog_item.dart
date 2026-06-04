/// One mood as defined by the admin-managed catalogue (GET /api/v1/moods).
///
/// Only the content fields the UI sources dynamically are kept here — emoji,
/// Arabic label, and the post-check-in message. Colours stay in the app's
/// design tokens (keyed by slug), so the catalogue can change copy/emoji
/// without affecting layout or theme.
class MoodCatalogItem {
  const MoodCatalogItem({
    required this.slug,
    required this.nameAr,
    required this.emoji,
    this.messageAr,
    this.colorSeed = '',
    this.displayOrder = 0,
  });

  final String slug;
  final String nameAr;
  final String emoji;
  final String? messageAr;

  /// Admin color token (purple/yellow/success/…) or a #RRGGBB custom hex.
  final String colorSeed;
  final int displayOrder;

  factory MoodCatalogItem.fromJson(Map<String, dynamic> json) {
    return MoodCatalogItem(
      slug: json['slug'] is String ? json['slug'] as String : '',
      nameAr: json['name_ar'] is String ? json['name_ar'] as String : '',
      emoji: json['emoji'] is String ? json['emoji'] as String : '',
      messageAr: json['message_ar'] is String ? json['message_ar'] as String : null,
      colorSeed: json['color_seed'] is String ? json['color_seed'] as String : '',
      displayOrder: (json['display_order'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
        'slug': slug,
        'name_ar': nameAr,
        'emoji': emoji,
        'message_ar': messageAr,
        'color_seed': colorSeed,
        'display_order': displayOrder,
      };
}
