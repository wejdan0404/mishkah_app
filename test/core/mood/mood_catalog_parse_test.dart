import 'package:flutter_test/flutter_test.dart';
import 'package:mishkat/core/mood/mood_catalog.dart';

void main() {
  test('reads the live /moods envelope shape {moods: [...]}', () {
    final list = MoodCatalog.moodListFromResponse({
      'moods': [
        {'slug': 'bored', 'emoji': '🥱'},
      ],
    });
    expect(list, isNotNull);
    expect(list!.length, 1);
    expect((list.first as Map)['emoji'], '🥱');
  });

  test('also accepts a bare list (cached form)', () {
    final list = MoodCatalog.moodListFromResponse([
      {'slug': 'calm', 'emoji': '😌'},
    ]);
    expect(list, isNotNull);
    expect(list!.length, 1);
  });

  test('returns null for an unexpected shape', () {
    expect(MoodCatalog.moodListFromResponse(42), isNull);
    expect(MoodCatalog.moodListFromResponse({'nope': true}), isNull);
  });
}
