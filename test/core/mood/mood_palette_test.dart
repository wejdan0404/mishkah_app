import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mishkat/core/mood/mood_palette.dart';
import 'package:mishkat/theme/app_tokens.dart';

void main() {
  test('maps a known token seed to the matching design tokens', () {
    final MoodColors purple = MoodPalette.forSeed('purple');
    expect(purple.ring, AppPalettePurple.shade300);
    expect(purple.gradient.length, 3);

    final MoodColors yellow = MoodPalette.forSeed('yellow');
    expect(yellow.bg, AppPaletteButteryYellow.shade400);
  });

  test('parses a custom #RRGGBB seed (admin custom colour)', () {
    final MoodColors c = MoodPalette.forSeed('#1570EF');
    expect(c.ring, const Color(0xFF1570EF));
    expect(c.gradient.length, 3);
  });

  test('falls back to the neutral palette for an unknown/blank seed', () {
    expect(MoodPalette.forSeed('zzz').ring, MoodPalette.forSeed('neutral').ring);
    expect(MoodPalette.forSeed('').ring, MoodPalette.forSeed('neutral').ring);
  });
}
