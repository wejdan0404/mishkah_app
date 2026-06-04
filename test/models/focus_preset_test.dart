import 'package:flutter_test/flutter_test.dart';
import 'package:mishkat/models/focus_preset.dart';

void main() {
  test('FocusPreset.fromJson reads the documented shape', () {
    final p = FocusPreset.fromJson({
      'slug': 'pomodoro-25',
      'name_ar': 'بومودورو',
      'name_en': 'Pomodoro',
      'description_ar': 'وصف',
      'description_en': 'desc',
      'duration_seconds': 1500,
      'emoji': '🍅',
      'color_seed': 'success',
      'display_order': 20,
    });

    expect(p.slug, 'pomodoro-25');
    expect(p.nameAr, 'بومودورو');
    expect(p.nameEn, 'Pomodoro');
    expect(p.descriptionAr, 'وصف');
    expect(p.descriptionEn, 'desc');
    expect(p.durationSeconds, 1500);
    expect(p.emoji, '🍅');
    expect(p.colorSeed, 'success');
    expect(p.displayOrder, 20);
  });

  test('FocusPreset.fromJson tolerates missing optional fields', () {
    final p = FocusPreset.fromJson({
      'slug': 'unknown',
      'duration_seconds': 600,
    });

    expect(p.slug, 'unknown');
    expect(p.nameAr, '');
    expect(p.nameEn, '');
    expect(p.descriptionAr, '');
    expect(p.descriptionEn, '');
    expect(p.durationSeconds, 600);
    expect(p.emoji, '✨');
    expect(p.colorSeed, 'neutral');
    expect(p.displayOrder, 0);
  });
}
