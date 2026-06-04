import 'package:flutter_test/flutter_test.dart';
import 'package:mishkat/models/mood_catalog_item.dart';

void main() {
  test('MoodCatalogItem.fromJson reads the /moods shape', () {
    final item = MoodCatalogItem.fromJson(const {
      'slug': 'bored',
      'name_ar': 'ملول',
      'name_en': 'Bored',
      'emoji': '🥱',
      'tier': 4,
      'color_seed': 'warning',
      'message_ar': 'جرّب نشاط بسيط',
      'display_order': 5,
    });

    expect(item.slug, 'bored');
    expect(item.nameAr, 'ملول');
    expect(item.emoji, '🥱');
    expect(item.messageAr, 'جرّب نشاط بسيط');
  });

  test('MoodCatalogItem.fromJson tolerates missing optional fields', () {
    final item = MoodCatalogItem.fromJson(const {'slug': 'calm', 'emoji': '😌'});

    expect(item.slug, 'calm');
    expect(item.emoji, '😌');
    expect(item.nameAr, '');
    expect(item.messageAr, isNull);
  });
}
