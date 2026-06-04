import 'package:flutter/material.dart';

class AppFontFamily {
  static const String text = 'IBM Plex Sans Arabic';
  static const String title = 'ThmanyahSerifText';
  static const String quran = 'Amiri Quran Colored';

  // OpenType stylistic alternates that give ThmanyahSerifText its extended
  // letterforms. Silently ignored by fonts that lack a given tag, so it is
  // safe to apply wherever the title font is used. Apply this to every
  // TextStyle that sets [title] directly instead of using AppTextStyles.
  static const List<FontFeature> titleFeatures = [
    FontFeature('salt'),
    FontFeature('ss01'),
    FontFeature('ss08'),
  ];
}

class AppFontWeights {
  static const FontWeight regular = FontWeight.w400;
  static const FontWeight medium = FontWeight.w500;
  static const FontWeight semibold = FontWeight.w600;
  static const FontWeight bold = FontWeight.w700;
}

class AppFontSizes {
  static const double xxs = 12;
  static const double xs = 14;
  static const double sm = 16;
  static const double md = 20;
  static const double lg = 24;
  static const double xl = 28;
  static const double xxl = 34;
  static const double xxxl = 40;
}

class AppRadius {
  static const double xs = 2;
  static const double sm = 4;
  static const double md = 8;
  static const double lg = 12;
  static const double xl = 16;
  static const double xxl = 24;
  static const double xxxl = 32;
  static const double xxxxl = 40;
  static const double xxxxxl = 48;
  static const double xxxxxxl = 56;
  static const double xxxxxxxl = 64;
  static const double xxxxxxxxl = 80;
  static const double xxxxxxxxxl = 96;
  static const double xxxxxxxxxxl = 104;
  static const double full = 999;
}

class AppSpacing {
  static const double none = 0;
  static const double xxs = 2;
  static const double xs = 4;
  static const double sm = 6;
  static const double md = 8;
  static const double lg = 12;
  static const double xl = 16;
  static const double xxl = 20;
  static const double xxxl = 24;
  static const double xxxxl = 32;
  static const double xxxxxl = 40;
  static const double xxxxxxl = 48;
  static const double xxxxxxxl = 64;
  static const double xxxxxxxxl = 80;
}

class AppIconSize {
  static const double sm = 16;
  static const double md = 24;
  static const double lg = 32;
  static const double xl = 48;
}

class AppShadows {
  static const Color _shadowColor = Color(0x14101828);
  static const Color _shadowColorSoft = Color(0x0A101828);
  static const Color _glowYellow = Color(0x99FFF6D6);

  static const List<BoxShadow> xs = [
    BoxShadow(color: _shadowColorSoft, offset: Offset(0, 1), blurRadius: 2),
  ];

  static const List<BoxShadow> sm = [
    BoxShadow(color: Color(0x1A101828), offset: Offset(0, 1), blurRadius: 3),
  ];

  static const List<BoxShadow> md = [
    BoxShadow(
      color: Color(0x1A101828),
      offset: Offset(0, 4),
      blurRadius: 8,
      spreadRadius: -2,
    ),
  ];

  static const List<BoxShadow> lg = [
    BoxShadow(color: _shadowColor, offset: Offset(0, 12), blurRadius: 16),
    BoxShadow(color: _shadowColorSoft, offset: Offset(0, 4), blurRadius: 6),
  ];

  static const List<BoxShadow> xl = [
    BoxShadow(color: _shadowColor, offset: Offset(0, 20), blurRadius: 24),
    BoxShadow(color: _shadowColorSoft, offset: Offset(0, 8), blurRadius: 8),
  ];

  static const List<BoxShadow> colorful = [
    BoxShadow(color: _glowYellow, offset: Offset(0, 2), blurRadius: 15),
    BoxShadow(color: _glowYellow, offset: Offset(0, 1), blurRadius: 1),
  ];

  /// Figma "Elevation/1" — used for toggle pills and similar interactive
  /// elements that need a softer, two-layer drop shadow.
  static const List<BoxShadow> elevation1 = [
    BoxShadow(color: Color(0x05000000), offset: Offset(0, 1), blurRadius: 1),
    BoxShadow(color: Color(0x0A000000), offset: Offset(0, 2), blurRadius: 15),
  ];
}

class AppNeutralColors {
  static const Color shade50 = Color(0xFFFCFCFC);
  static const Color shade100 = Color(0xFFF7F7F7);
  static const Color shade200 = Color(0xFFF0F0F0);
  static const Color shade300 = Color(0xFFE5E5E5);
  static const Color shade400 = Color(0xFF999999);
  static const Color shade500 = Color(0xFF4B4B4B);
  static const Color shade600 = Color(0xFF242424);
  static const Color shade700 = Color(0xFF171717);
  static const Color white = Color(0xFFFFFFFF);
  static const Color black = Color(0xFF000000);
}

/// Dark-mode counterpart to [AppNeutralColors]. Each field mirrors the same
/// index/role as the light ramp so the semantics are preserved: the
/// background end stays background, the text end stays text — the ramp is just
/// inverted. The scaffold uses a dark grey (not pure black) per dark-UI
/// guidance so elevation and surfaces remain readable.
///
/// Resolve these through the [AppColors] theme extension (`context.colors`),
/// not directly — direct use would hardcode dark values into light mode.
///
/// Naming caveat: [white] and [black] are semantic, not literal. In dark mode
/// [white] is an elevated surface (#1E1E1E) used for cards/app bars, and
/// [black] is the max-contrast ink (#FFFFFF). Literal shadow/overlay blacks
/// must keep using [Colors.black], not this token.
class AppNeutralColorsDark {
  static const Color shade50 = Color(0xFF121212);
  static const Color shade100 = Color(0xFF1A1A1A);
  static const Color shade200 = Color(0xFF262626);
  static const Color shade300 = Color(0xFF333333);
  // Lifted from #707070 to clear WCAG AA (4.5:1) for small body text
  // (bodySmall/captions) on the dark surface, where #707070 fell to ~3.4:1.
  static const Color shade400 = Color(0xFF8A8A8A);
  static const Color shade500 = Color(0xFFA3A3A3);
  static const Color shade600 = Color(0xFFD4D4D4);
  static const Color shade700 = Color(0xFFF5F5F5);
  static const Color white = Color(0xFF1E1E1E);
  static const Color black = Color(0xFFFFFFFF);
}

class AppSuccessColors {
  static const Color shade25 = Color(0xFFF6FEF9);
  static const Color shade50 = Color(0xFFECFDF3);
  static const Color shade100 = Color(0xFFDCFAE6);
  static const Color shade200 = Color(0xFFABEFC6);
  static const Color shade300 = Color(0xFF75E0A7);
  static const Color shade400 = Color(0xFF47CD89);
  static const Color shade500 = Color(0xFF17B26A);
  static const Color shade600 = Color(0xFF079455);
  static const Color shade700 = Color(0xFF067647);
  static const Color shade800 = Color(0xFF085D3A);
  static const Color shade900 = Color(0xFF074D31);
  static const Color shade950 = Color(0xFF053321);
}

class AppWarningColors {
  static const Color shade25 = Color(0xFFFFFCF5);
  static const Color shade50 = Color(0xFFFFFAEB);
  static const Color shade100 = Color(0xFFFEF0C7);
  static const Color shade200 = Color(0xFFFEDF89);
  static const Color shade300 = Color(0xFFFEC84B);
  static const Color shade400 = Color(0xFFFDB022);
  static const Color shade500 = Color(0xFFF79009);
  static const Color shade600 = Color(0xFFDC6803);
  static const Color shade700 = Color(0xFFB54708);
  static const Color shade800 = Color(0xFF93370D);
  static const Color shade900 = Color(0xFF7A2E0E);
  static const Color shade950 = Color(0xFF4E1D09);
}

class AppInformationColors {
  static const Color shade25 = Color(0xFFF5FAFF);
  static const Color shade50 = Color(0xFFE0F2FF);
  static const Color shade100 = Color(0xFFD1E9FF);
  static const Color shade200 = Color(0xFFB2DDFF);
  static const Color shade300 = Color(0xFF84CAFF);
  static const Color shade400 = Color(0xFF53B1FD);
  static const Color shade500 = Color(0xFF2E90FA);
  static const Color shade600 = Color(0xFF1570EF);
  static const Color shade700 = Color(0xFF175CD3);
  static const Color shade800 = Color(0xFF1849A9);
  static const Color shade900 = Color(0xFF194185);
  static const Color shade950 = Color(0xFF102A56);
}

class AppDangerColors {
  static const Color shade25 = Color(0xFFFFFBFA);
  static const Color shade50 = Color(0xFFFEF3F2);
  static const Color shade100 = Color(0xFFFEE4E2);
  static const Color shade200 = Color(0xFFFECDCA);
  static const Color shade300 = Color(0xFFFDA29B);
  static const Color shade400 = Color(0xFFF97066);
  static const Color shade500 = Color(0xFFF04438);
  static const Color shade600 = Color(0xFFD92D20);
  static const Color shade700 = Color(0xFFB42318);
  static const Color shade800 = Color(0xFF912018);
  static const Color shade900 = Color(0xFF7A271A);
  static const Color shade950 = Color(0xFF55160C);
}

class AppPalettePurple {
  static const Color shade100 = Color(0xFF6C67A3);
  static const Color shade200 = Color(0xFF8F89C9);
  static const Color shade300 = Color(0xFFB0A6DF);
  static const Color shade400 = Color(0xFFCDC7EB);
  static const Color shade500 = Color(0xFFE4E1F4);
  static const Color shade600 = Color(0xFFF5F4FB);
}

class AppPaletteButteryYellow {
  static const Color shade25 = Color(0xFFFDC402);
  static const Color shade50 = Color(0xFFFEDD6E);
  static const Color shade100 = Color(0xFFFEE284);
  static const Color shade200 = Color(0xFFFEE9A2);
  static const Color shade300 = Color(0xFFFFF0BD);
  static const Color shade400 = Color(0xFFFFF6D6);
  static const Color shade500 = Color(0xFFFFFDF8);
}
