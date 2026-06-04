import 'package:flutter/material.dart';

import '../../theme/app_tokens.dart';

/// The colours one mood needs to render: chip background, ring, chart bar, and
/// the 3-stop card gradient.
class MoodColors {
  const MoodColors({
    required this.bg,
    required this.ring,
    required this.bar,
    required this.gradient,
  });

  final Color bg;
  final Color ring;
  final Color bar;
  final List<Color> gradient;
}

/// Resolves an admin `color_seed` (a token like `purple`/`yellow`/… or a custom
/// `#RRGGBB`) to a [MoodColors] built from the app's design tokens — so mood
/// colours are admin-controlled while staying on-theme. Each token's tuple
/// matches the colours the app shipped for that mood, so existing moods look
/// identical. Unknown/blank seeds fall back to the neutral tuple.
class MoodPalette {
  const MoodPalette._();

  // Tiffany isn't in app_tokens — it was a local accent for the "relaxed" mood.
  static const Color _tiffany25 = Color(0xFFEFFBFA);
  static const Color _tiffany100 = Color(0xFFB9ECE6);
  static const Color _tiffany300 = Color(0xFF81D8D0);

  static MoodColors forSeed(String? seed) {
    final String s = (seed ?? '').trim();

    if (s.startsWith('#')) {
      final Color? hex = _parseHex(s);
      if (hex != null) return _fromHex(hex);
      return _tokens['neutral']!;
    }

    return _tokens[s] ?? _tokens['neutral']!;
  }

  static final Map<String, MoodColors> _tokens = <String, MoodColors>{
    'yellow': const MoodColors(
      bg: AppPaletteButteryYellow.shade400,
      ring: AppPaletteButteryYellow.shade100,
      bar: AppPaletteButteryYellow.shade300,
      gradient: [
        AppPaletteButteryYellow.shade100,
        AppPaletteButteryYellow.shade200,
        AppPaletteButteryYellow.shade300,
      ],
    ),
    'success': const MoodColors(
      bg: AppSuccessColors.shade100,
      ring: AppSuccessColors.shade300,
      bar: AppSuccessColors.shade200,
      gradient: [
        AppSuccessColors.shade300,
        AppSuccessColors.shade200,
        AppSuccessColors.shade100,
      ],
    ),
    'tiffany': const MoodColors(
      bg: _tiffany100,
      ring: _tiffany300,
      bar: _tiffany300,
      gradient: [_tiffany300, _tiffany100, _tiffany25],
    ),
    'info': const MoodColors(
      bg: AppInformationColors.shade50,
      ring: AppInformationColors.shade300,
      bar: AppInformationColors.shade200,
      gradient: [
        AppInformationColors.shade300,
        AppInformationColors.shade100,
        AppInformationColors.shade50,
      ],
    ),
    'warning': const MoodColors(
      bg: AppWarningColors.shade200,
      ring: AppWarningColors.shade400,
      bar: AppWarningColors.shade300,
      gradient: [
        AppWarningColors.shade400,
        AppWarningColors.shade300,
        AppWarningColors.shade200,
      ],
    ),
    'danger': const MoodColors(
      bg: AppDangerColors.shade100,
      ring: AppDangerColors.shade300,
      bar: AppDangerColors.shade200,
      gradient: [
        AppDangerColors.shade300,
        AppDangerColors.shade200,
        AppDangerColors.shade100,
      ],
    ),
    'purple': const MoodColors(
      bg: AppPalettePurple.shade500,
      ring: AppPalettePurple.shade300,
      bar: AppPalettePurple.shade500,
      gradient: [
        AppPalettePurple.shade200,
        AppPalettePurple.shade300,
        AppPalettePurple.shade400,
      ],
    ),
    'neutral': const MoodColors(
      bg: AppNeutralColors.shade200,
      ring: AppNeutralColors.shade400,
      bar: AppNeutralColors.shade300,
      gradient: [
        AppNeutralColors.shade400,
        AppNeutralColors.shade300,
        AppNeutralColors.shade200,
      ],
    ),
  };

  /// Build a tuple from a single custom hex by tinting toward white.
  static MoodColors _fromHex(Color hex) {
    final Color l30 = Color.lerp(hex, Colors.white, 0.30)!;
    final Color l55 = Color.lerp(hex, Colors.white, 0.55)!;
    final Color l80 = Color.lerp(hex, Colors.white, 0.80)!;
    return MoodColors(
      bg: l80,
      ring: hex,
      bar: l30,
      gradient: [l30, l55, l80],
    );
  }

  static Color? _parseHex(String s) {
    final String hex = s.replaceFirst('#', '');
    if (hex.length != 6) return null;
    final int? value = int.tryParse(hex, radix: 16);
    if (value == null) return null;
    return Color(0xFF000000 | value);
  }
}
