import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_tokens.dart';

class AppTheme {
  const AppTheme._();

  static ThemeData get light => _build(
    brightness: Brightness.light,
    colors: AppColors.light,
    scheme: ColorScheme.fromSeed(
      seedColor: AppPalettePurple.shade100,
      brightness: Brightness.light,
      surface: AppNeutralColors.white,
      onSurface: AppNeutralColors.shade700,
      primary: AppPalettePurple.shade100,
      onPrimary: AppNeutralColors.white,
      error: AppDangerColors.shade500,
      onError: AppNeutralColors.white,
    ),
  );

  static ThemeData get dark => _build(
    brightness: Brightness.dark,
    colors: AppColors.dark,
    scheme: ColorScheme.fromSeed(
      seedColor: AppPalettePurple.shade100,
      brightness: Brightness.dark,
      surface: AppNeutralColorsDark.white,
      onSurface: AppNeutralColorsDark.shade700,
      primary: AppPalettePurple.shade200,
      onPrimary: AppNeutralColorsDark.shade50,
      error: AppDangerColors.shade400,
      onError: AppNeutralColorsDark.shade50,
    ),
  );

  static ThemeData _build({
    required Brightness brightness,
    required AppColors colors,
    required ColorScheme scheme,
  }) {
    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: colors.shade50,
      // Tap feedback (ripple + sustained highlight) tinted light purple from
      // the design system instead of the default translucent grey.
      splashColor: AppPalettePurple.shade500.withValues(alpha: 0.15),
      highlightColor: AppPalettePurple.shade500.withValues(alpha: 0.15),
      fontFamily: AppFontFamily.text,
      textTheme: _textTheme(colors),
      appBarTheme: AppBarTheme(
        backgroundColor: colors.white,
        foregroundColor: colors.shade700,
        elevation: 0,
        centerTitle: true,
      ),
      dividerTheme: DividerThemeData(
        color: colors.shade200,
        thickness: 1,
        space: 1,
      ),
      extensions: <ThemeExtension<dynamic>>[colors],
      // Use iOS-style slide transitions on every platform so push/pop feels
      // like the native iOS gesture across the app.
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: <TargetPlatform, PageTransitionsBuilder>{
          TargetPlatform.android: CupertinoPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.macOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.windows: CupertinoPageTransitionsBuilder(),
          TargetPlatform.linux: CupertinoPageTransitionsBuilder(),
          TargetPlatform.fuchsia: CupertinoPageTransitionsBuilder(),
        },
      ),
    );
  }

  static TextTheme _textTheme(AppColors colors) => TextTheme(
    displayLarge: TextStyle(
      fontFamily: AppFontFamily.title,
      fontSize: AppFontSizes.xxxl,
      fontWeight: AppFontWeights.bold,
      color: colors.shade700,
      height: 1.2,
      fontFeatures: AppFontFamily.titleFeatures,
    ),
    displayMedium: TextStyle(
      fontFamily: AppFontFamily.title,
      fontSize: AppFontSizes.xxl,
      fontWeight: AppFontWeights.bold,
      color: colors.shade700,
      height: 1.25,
      fontFeatures: AppFontFamily.titleFeatures,
    ),
    headlineLarge: TextStyle(
      fontFamily: AppFontFamily.title,
      fontSize: AppFontSizes.xl,
      fontWeight: AppFontWeights.medium,
      color: colors.shade700,
      height: 1.3,
      fontFeatures: AppFontFamily.titleFeatures,
    ),
    headlineMedium: TextStyle(
      fontFamily: AppFontFamily.title,
      fontSize: AppFontSizes.lg,
      fontWeight: AppFontWeights.medium,
      color: colors.shade700,
      height: 1.3,
      fontFeatures: AppFontFamily.titleFeatures,
    ),
    titleLarge: TextStyle(
      fontFamily: AppFontFamily.text,
      fontSize: AppFontSizes.md,
      fontWeight: AppFontWeights.medium,
      color: colors.shade600,
      height: 1.4,
    ),
    bodyLarge: TextStyle(
      fontFamily: AppFontFamily.text,
      fontSize: AppFontSizes.sm,
      fontWeight: AppFontWeights.regular,
      color: colors.shade600,
      height: 1.5,
    ),
    bodyMedium: TextStyle(
      fontFamily: AppFontFamily.text,
      fontSize: AppFontSizes.xs,
      fontWeight: AppFontWeights.regular,
      color: colors.shade500,
      height: 1.5,
    ),
    bodySmall: TextStyle(
      fontFamily: AppFontFamily.text,
      fontSize: AppFontSizes.xxs,
      fontWeight: AppFontWeights.regular,
      color: colors.shade400,
      height: 1.5,
    ),
    labelLarge: TextStyle(
      fontFamily: AppFontFamily.text,
      fontSize: AppFontSizes.xs,
      fontWeight: AppFontWeights.medium,
      color: colors.shade600,
      height: 1.4,
    ),
  );
}
