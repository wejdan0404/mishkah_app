import 'package:flutter/material.dart';

import '../../core/activities/activity_api.dart';
import '../../theme/app_tokens.dart';
import '../activities/activate_senses_exercise_screen.dart';
import '../activities/breathe_calmly_learn_more_screen.dart';
import '../activities/emotion_cards_game_screen.dart';
import '../activities/release_pressure_learn_more_screen.dart';
import '../activities/sleep_calm_learn_more_screen.dart';
import '../activities/smile_face_game_screen.dart';
import '../activities/stop_spiral_learn_more_screen.dart';
import '../activities/understand_feelings_exercise_screen.dart';

/// The card colours for one activity, taken straight from the design tokens
/// (no opacity). The text flips light/dark so it always reads against the
/// background:
///   • background  → shade25  (light)  / shade950 (dark)
///   • border      → shade300
///   • title       → shade500 (light)  / shade200 (dark)
///   • subtitle    → shade400 (light)  / shade300 (dark)
class ActivityColors {
  const ActivityColors({
    required this.background,
    required this.backgroundDark,
    required this.border,
    required this.title,
    required this.titleDark,
    required this.subtitle,
    required this.subtitleDark,
  });

  final Color background; // shade25
  final Color backgroundDark; // shade950
  final Color border; // shade300
  final Color title; // shade500 (light)
  final Color titleDark; // shade200 (dark)
  final Color subtitle; // shade400 (light)
  final Color subtitleDark; // shade300 (dark)
}

const ActivityColors _informationColors = ActivityColors(
  background: AppInformationColors.shade25,
  backgroundDark: AppInformationColors.shade950,
  border: AppInformationColors.shade300,
  title: AppInformationColors.shade500,
  titleDark: AppInformationColors.shade200,
  subtitle: AppInformationColors.shade400,
  subtitleDark: AppInformationColors.shade300,
);

const ActivityColors _warningColors = ActivityColors(
  background: AppWarningColors.shade25,
  backgroundDark: AppWarningColors.shade950,
  border: AppWarningColors.shade300,
  title: AppWarningColors.shade500,
  titleDark: AppWarningColors.shade200,
  subtitle: AppWarningColors.shade400,
  subtitleDark: AppWarningColors.shade300,
);

const ActivityColors _dangerColors = ActivityColors(
  background: AppDangerColors.shade25,
  backgroundDark: AppDangerColors.shade950,
  border: AppDangerColors.shade300,
  title: AppDangerColors.shade500,
  titleDark: AppDangerColors.shade200,
  subtitle: AppDangerColors.shade400,
  subtitleDark: AppDangerColors.shade300,
);

// AppPalettePurple has an inverted scale and no shade25/shade950, so it can't
// follow the same rule — map to its nearest available tones: lightest (600)
// for the light background, darkest (100) for the dark background.
// Purple's scale is inverted (shade100 darkest → shade600 lightest), so its
// dark-mode text goes to the lightest tones (500/400) instead of 200/300.
const ActivityColors _purpleColors = ActivityColors(
  background: AppPalettePurple.shade600,
  backgroundDark: AppPalettePurple.shade100,
  border: AppPalettePurple.shade400,
  title: AppPalettePurple.shade200,
  titleDark: AppPalettePurple.shade500,
  subtitle: AppPalettePurple.shade300,
  subtitleDark: AppPalettePurple.shade400,
);

/// A resolved activity suggestion: the data the chat screen needs to render
/// the tappable card under an assistant message and open the activity.
class ActivitySuggestion {
  const ActivitySuggestion({
    required this.colors,
    required this.label,
    required this.description,
    required this.open,
  });

  /// The activity's card colours (background, border, title, subtitle).
  final ActivityColors colors;

  /// The activity's Arabic display name (the card title).
  final String label;

  /// A short Arabic line describing the activity, shown under the title.
  final String description;

  /// Pushes the activity's exercise screen onto the navigator.
  final void Function(BuildContext context) open;
}

/// Maps a backend `suggested_activity` slug to the in-app exercise screen it
/// should open, plus the per-activity accent colour and label. The colours are
/// sourced from each activity's own screen (the breathing orb palette, the
/// mindfulness tag, the game card background) so the card reads on-theme.
///
/// Returns null for any slug we can't safely deep-link (e.g. `focus_session`,
/// which has no directly-pushable exercise screen) so the button is simply
/// hidden rather than mis-linking.
ActivitySuggestion? resolveActivitySuggestion(String slug) {
  switch (slug) {
    // Breathing slugs open the exercise's DETAIL (learn-more) screen, which
    // runs the official "قبل ما تبدأ" priming popup before starting the
    // session — never push BreathingExerciseScreen directly from chat.
    case ActivitySlugs.breatheCalmly:
      // Breathing orb palette: blue.
      return ActivitySuggestion(
        colors: _informationColors,
        label: 'تنفّس بهـدوء',
        description: 'هدّي جسمك بنَفَس عميق',
        open: (context) => _push(context, const BreatheCalmlyLearnMoreScreen()),
      );
    case ActivitySlugs.stopSpiral:
      // Breathing orb palette: blue.
      return ActivitySuggestion(
        colors: _informationColors,
        label: 'وقف الدوامـة',
        description: 'صفِّ ذهنك وارجع لإيقاعك',
        open: (context) => _push(context, const StopSpiralLearnMoreScreen()),
      );
    case ActivitySlugs.releasePressure:
      // Breathing orb palette: yellow.
      return ActivitySuggestion(
        colors: _warningColors,
        label: 'أطفئ الضغـط',
        description: 'نفّس توترك بنَفَس بطيء',
        open: (context) =>
            _push(context, const ReleasePressureLearnMoreScreen()),
      );
    case ActivitySlugs.sleepCalm:
      // Breathing orb palette: purple.
      return ActivitySuggestion(
        colors: _purpleColors,
        label: 'نـام بهـدوء',
        description: 'استرخِ وهيّئ نفسك للنوم',
        open: (context) => _push(context, const SleepCalmLearnMoreScreen()),
      );
    case ActivitySlugs.understandFeelings:
      // Mindfulness tag colour (balance station): information blue.
      return ActivitySuggestion(
        colors: _informationColors,
        label: 'افهـم شعورك',
        description: 'اعرف وش تحسّ فيه بالضبط',
        open: (context) =>
            _push(context, const UnderstandFeelingsExerciseScreen()),
      );
    case ActivitySlugs.activateSenses:
      // Mindfulness tag colour (balance station): information blue.
      return ActivitySuggestion(
        colors: _informationColors,
        label: 'فعّـل حواسك',
        description: 'ارجع للحظة بحواسك الخمس',
        open: (context) => _push(context, const ActivateSensesExerciseScreen()),
      );
    case ActivitySlugs.emotionCards:
      // Emotion-cards game card background is a soft rose.
      return ActivitySuggestion(
        colors: _dangerColors,
        label: 'بطاقـات المشاعـر',
        description: 'طابق المشاعر بلعبة هادئة',
        open: (context) => _push(context, const EmotionCardsGameScreen()),
      );
    case ActivitySlugs.smileFace:
      // Smile-face game card background is yellow.
      return ActivitySuggestion(
        colors: _warningColors,
        label: 'الوجـه المبتسـم',
        description: 'لعبة خفيفة ترسم ابتسامة',
        open: (context) => _push(context, const SmileFaceGameScreen()),
      );
    // `focus_session` is a backend pseudo-activity: the focus session screen
    // needs a selected task + duration and isn't a directly-pushable exercise,
    // so we deliberately show no button rather than deep-link incorrectly.
    default:
      return null;
  }
}

void _push(BuildContext context, Widget screen) {
  Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => screen));
}
