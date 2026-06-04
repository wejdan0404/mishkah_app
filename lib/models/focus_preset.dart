// FocusPreset — DTO for /api/v1/focus/presets entries.
//
// Mirrors `app/Http/Resources/Api/V1/FocusPresetResource.php`. Defensive
// fromJson so a stale server response (missing field, new field) never
// crashes the التركيز tab — falls back to neutral placeholders.

class FocusPreset {
  const FocusPreset({
    required this.slug,
    required this.nameAr,
    required this.nameEn,
    required this.descriptionAr,
    required this.descriptionEn,
    required this.durationSeconds,
    required this.emoji,
    required this.colorSeed,
    required this.displayOrder,
  });

  final String slug;
  final String nameAr;
  final String nameEn;
  final String descriptionAr;
  final String descriptionEn;
  final int durationSeconds;
  final String emoji;
  final String colorSeed;
  final int displayOrder;

  factory FocusPreset.fromJson(Map<String, dynamic> j) => FocusPreset(
        slug: j['slug'] as String? ?? '',
        nameAr: j['name_ar'] as String? ?? '',
        nameEn: j['name_en'] as String? ?? '',
        descriptionAr: j['description_ar'] as String? ?? '',
        descriptionEn: j['description_en'] as String? ?? '',
        durationSeconds: (j['duration_seconds'] as num?)?.toInt() ?? 0,
        emoji: j['emoji'] as String? ?? '✨',
        colorSeed: j['color_seed'] as String? ?? 'neutral',
        displayOrder: (j['display_order'] as num?)?.toInt() ?? 0,
      );

  /// "٢٥ دقيقة" — best-effort Arabic-Indic minutes label for the card.
  int get durationMinutes => (durationSeconds / 60).round();
}
