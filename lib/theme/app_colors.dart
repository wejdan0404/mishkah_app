import 'package:flutter/material.dart';

import 'app_tokens.dart';

/// Theme-resolved neutral palette, carried on [ThemeData] as a
/// [ThemeExtension] and read through `context.colors`. Because the values flip
/// with the active brightness, any widget that reads them follows light/dark
/// automatically — unlike the compile-time constants in [AppNeutralColors].
///
/// Field names mirror [AppNeutralColors] exactly so migrating a call site is a
/// mechanical swap of `AppNeutralColors.x` → `context.colors.x`. The migration
/// is intentionally gradual: both APIs coexist while screens move over one by
/// one.
///
/// In addition to the neutral ramp, a few *semantic* tokens live here for
/// cases where the light and dark values are not a simple inversion of one
/// ramp (e.g. a hairline divider needs more contrast in dark; a soft-purple
/// surface inverts to a deep purple). See [divider], [surfaceRaised],
/// [purpleSoftBg], [purpleSoftFg].
@immutable
class AppColors extends ThemeExtension<AppColors> {
  const AppColors({
    required this.shade50,
    required this.shade100,
    required this.shade200,
    required this.shade300,
    required this.shade400,
    required this.shade500,
    required this.shade600,
    required this.shade700,
    required this.white,
    required this.black,
    required this.divider,
    required this.surfaceRaised,
    required this.purpleSoftBg,
    required this.purpleSoftFg,
  });

  final Color shade50;
  final Color shade100;
  final Color shade200;
  final Color shade300;
  final Color shade400;
  final Color shade500;
  final Color shade600;
  final Color shade700;

  /// Elevated surface (cards, app bars). Literal white in light mode, dark
  /// grey in dark mode — see the class doc.
  final Color white;

  /// Max-contrast ink. Literal black in light mode, white in dark mode. Not
  /// for shadows/overlays — those keep [Colors.black].
  final Color black;

  /// Hairline separator. Subtle in both modes but tuned so it stays visible on
  /// the dark card surface (where a plain [shade100] would vanish).
  final Color divider;

  /// A surface that sits *above* the card and must read as raised — lighter
  /// than [white] in dark mode (where [white] is already a dark grey card).
  final Color surfaceRaised;

  /// Soft-purple fill (badges, suggestion cards). Light lavender in light
  /// mode, deep purple in dark mode.
  final Color purpleSoftBg;

  /// Foreground/ink to pair with [purpleSoftBg] — the inverse purple so text
  /// stays legible on the fill in both modes.
  final Color purpleSoftFg;

  static const AppColors light = AppColors(
    shade50: AppNeutralColors.shade50,
    shade100: AppNeutralColors.shade100,
    shade200: AppNeutralColors.shade200,
    shade300: AppNeutralColors.shade300,
    shade400: AppNeutralColors.shade400,
    shade500: AppNeutralColors.shade500,
    shade600: AppNeutralColors.shade600,
    shade700: AppNeutralColors.shade700,
    white: AppNeutralColors.white,
    black: AppNeutralColors.black,
    divider: Color(0xFFF7F7F7),
    surfaceRaised: AppNeutralColors.white,
    purpleSoftBg: AppPalettePurple.shade600,
    purpleSoftFg: AppPalettePurple.shade100,
  );

  static const AppColors dark = AppColors(
    shade50: AppNeutralColorsDark.shade50,
    shade100: AppNeutralColorsDark.shade100,
    shade200: AppNeutralColorsDark.shade200,
    shade300: AppNeutralColorsDark.shade300,
    shade400: AppNeutralColorsDark.shade400,
    shade500: AppNeutralColorsDark.shade500,
    shade600: AppNeutralColorsDark.shade600,
    shade700: AppNeutralColorsDark.shade700,
    white: AppNeutralColorsDark.white,
    black: AppNeutralColorsDark.black,
    divider: Color(0xFF2E2E2E),
    surfaceRaised: Color(0xFF2C2C2C),
    purpleSoftBg: Color(0xFF292640),
    purpleSoftFg: AppPalettePurple.shade600,
  );

  @override
  AppColors copyWith({
    Color? shade50,
    Color? shade100,
    Color? shade200,
    Color? shade300,
    Color? shade400,
    Color? shade500,
    Color? shade600,
    Color? shade700,
    Color? white,
    Color? black,
    Color? divider,
    Color? surfaceRaised,
    Color? purpleSoftBg,
    Color? purpleSoftFg,
  }) {
    return AppColors(
      shade50: shade50 ?? this.shade50,
      shade100: shade100 ?? this.shade100,
      shade200: shade200 ?? this.shade200,
      shade300: shade300 ?? this.shade300,
      shade400: shade400 ?? this.shade400,
      shade500: shade500 ?? this.shade500,
      shade600: shade600 ?? this.shade600,
      shade700: shade700 ?? this.shade700,
      white: white ?? this.white,
      black: black ?? this.black,
      divider: divider ?? this.divider,
      surfaceRaised: surfaceRaised ?? this.surfaceRaised,
      purpleSoftBg: purpleSoftBg ?? this.purpleSoftBg,
      purpleSoftFg: purpleSoftFg ?? this.purpleSoftFg,
    );
  }

  @override
  AppColors lerp(ThemeExtension<AppColors>? other, double t) {
    if (other is! AppColors) return this;
    return AppColors(
      shade50: Color.lerp(shade50, other.shade50, t)!,
      shade100: Color.lerp(shade100, other.shade100, t)!,
      shade200: Color.lerp(shade200, other.shade200, t)!,
      shade300: Color.lerp(shade300, other.shade300, t)!,
      shade400: Color.lerp(shade400, other.shade400, t)!,
      shade500: Color.lerp(shade500, other.shade500, t)!,
      shade600: Color.lerp(shade600, other.shade600, t)!,
      shade700: Color.lerp(shade700, other.shade700, t)!,
      white: Color.lerp(white, other.white, t)!,
      black: Color.lerp(black, other.black, t)!,
      divider: Color.lerp(divider, other.divider, t)!,
      surfaceRaised: Color.lerp(surfaceRaised, other.surfaceRaised, t)!,
      purpleSoftBg: Color.lerp(purpleSoftBg, other.purpleSoftBg, t)!,
      purpleSoftFg: Color.lerp(purpleSoftFg, other.purpleSoftFg, t)!,
    );
  }
}

/// Ergonomic access to the neutral palette for the current theme.
/// Prefer `context.colors.shade600` over `AppNeutralColors.shade600` in new
/// and migrated code.
extension AppColorsContext on BuildContext {
  AppColors get colors =>
      Theme.of(this).extension<AppColors>() ?? AppColors.light;

  /// Maps a light-mode "soft purple" fill to the unified deep purple
  /// ([AppColors.purpleSoftBg]) in dark mode, while keeping the original light
  /// value untouched in light mode. Use for any light-lavender background fill
  /// so dark mode reads as one deep purple instead of a glaring pale tint.
  Color purpleSoftFill(Color lightValue) =>
      Theme.of(this).brightness == Brightness.dark
          ? colors.purpleSoftBg
          : lightValue;

  /// Returns [light] in light mode and [dark] in dark mode. Use to swap a
  /// pale semantic fill (success/warning/danger/info shade 25–200) for the
  /// deep `…shade950` of the same family in dark mode, where the pale tint
  /// would otherwise glare on the dark surface.
  Color forDark(Color light, Color dark) =>
      Theme.of(this).brightness == Brightness.dark ? dark : light;

  /// Darkens a mood/feeling fill for dark mode while preserving its hue, so a
  /// pale mood colour (admin-driven or bundled) becomes a deep shade of the
  /// SAME family instead of a glaring pastel. Returns the colour unchanged in
  /// light mode. Generic (works for any hue) so it also covers admin-managed
  /// `color_seed` moods, not just the bundled palette.
  Color moodFill(Color light) {
    if (Theme.of(this).brightness != Brightness.dark) return light;
    final HSLColor hsl = HSLColor.fromColor(light);
    return hsl
        .withLightness((hsl.lightness * 0.22).clamp(0.0, 1.0))
        .withSaturation((hsl.saturation * 0.85).clamp(0.0, 1.0))
        .toColor();
  }
}
