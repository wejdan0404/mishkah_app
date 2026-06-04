/// The single source of truth for mood → activity recommendation across the
/// app's Flutter-owned surfaces (Activities "مقترح اليوم ✨" and the Home
/// single "خطوتك التالية ✨" recommendation card).
///
/// Home "ابدأ نشاطك" (افهم شعورك) and the AI suggestion card are scored by the
/// BACKEND, so they don't read this map. This file is pure data so it can be
/// shared without coupling to the widget/navigation layer.
library;

/// Where a mood recommendation sends the user. The actual navigation for each
/// target lives in the UI layer (Activities + Home each route by target).
enum MoodTarget {
  focus,
  journey,
  /// مسترخي: Journey if the route is available, else Focus.
  journeyOrFocus,
  games,
  journal,
  understandFeelings,

  /// متوتر: open Balance Station / breathing detail — NOT the session directly,
  /// so the official "قبل ما تبدأ" flow is preserved.
  breathing,
  ai,
  activitiesDefault,
}

/// One mood's approved recommendation (locked copy — do not rewrite).
/// [cardTitle] is the short activity name shown on the Home recommendation card;
/// [sentence] is the one-line description (shared with Activities "مقترح اليوم").
class MoodRecommendation {
  const MoodRecommendation({
    required this.slug,
    required this.emoji,
    required this.label,
    required this.target,
    required this.cardTitle,
    required this.sentence,
  });

  final String slug;
  final String emoji;
  final String label;
  final MoodTarget target;
  final String cardTitle;
  final String sentence;
}

/// The approved mapping, keyed by mood slug. This REPLACES every older mapping.
const Map<String, MoodRecommendation> kMoodRecommendations =
    <String, MoodRecommendation>{
  'excited': MoodRecommendation(
    slug: 'excited',
    emoji: '🤩',
    label: 'متحمس',
    target: MoodTarget.focus,
    cardTitle: 'جلسة تركيز',
    sentence: 'وجّه حماسك بجلسة تركيز قصيرة.',
  ),
  'happy': MoodRecommendation(
    slug: 'happy',
    emoji: '😊',
    label: 'سعيد',
    target: MoodTarget.journey,
    cardTitle: 'رحلتي',
    sentence: 'خلّ لحظتك الحلوة تكمل في رحلتك.',
  ),
  'relaxed': MoodRecommendation(
    slug: 'relaxed',
    emoji: '😌',
    label: 'مسترخي',
    target: MoodTarget.journeyOrFocus,
    cardTitle: 'رحلتي',
    sentence: 'استثمر هدوءك بخطوة تناسبك.',
  ),
  'calm': MoodRecommendation(
    slug: 'calm',
    emoji: '🙂',
    label: 'هادئ',
    target: MoodTarget.focus,
    cardTitle: 'جلسة تركيز',
    sentence: 'ابدأ جلسة تركيز وأنت بهدوءك.',
  ),
  'bored': MoodRecommendation(
    slug: 'bored',
    emoji: '😩',
    label: 'ملول',
    target: MoodTarget.games,
    cardTitle: 'منطقة اللعب',
    sentence: 'غيّر الجو بنشاط تفاعلي خفيف.',
  ),
  'sad': MoodRecommendation(
    slug: 'sad',
    emoji: '😞',
    label: 'حزين',
    target: MoodTarget.journal,
    cardTitle: 'مساحة التدوين',
    sentence: 'اكتب سطرًا يخفف ثقل الشعور.',
  ),
  'upset': MoodRecommendation(
    slug: 'upset',
    emoji: '😠',
    label: 'منزعج',
    target: MoodTarget.understandFeelings,
    cardTitle: 'افهم شعورك',
    sentence: 'افهم شعورك خطوة بخطوة.',
  ),
  'tense': MoodRecommendation(
    slug: 'tense',
    emoji: '😰',
    label: 'متوتر',
    target: MoodTarget.breathing,
    cardTitle: 'تمرين تنفّس',
    sentence: 'ابدأ بتنفس قصير يهدّي التوتر.',
  ),
  'neutral': MoodRecommendation(
    slug: 'neutral',
    emoji: '😐',
    label: 'محايد',
    target: MoodTarget.ai,
    cardTitle: 'اسأل مشكاة',
    sentence: 'اسأل مشكاة يساعدك تختار خطوة مناسبة.',
  ),
};

/// Fallback when no mood is recorded (or an unknown slug): guide to اسأل مشكاة,
/// and the UI falls back to the Activities screen if AI isn't reachable.
const MoodRecommendation kNoMoodRecommendation = MoodRecommendation(
  slug: '',
  emoji: '',
  label: '',
  target: MoodTarget.ai,
  cardTitle: 'خطوتك التالية',
  sentence: 'ابدأ بخطوة بسيطة تناسب وقتك.',
);

/// The single lookup used everywhere: the approved recommendation for a mood
/// slug, or the no-mood fallback when null/unknown.
MoodRecommendation moodRecommendationFor(String? slug) =>
    kMoodRecommendations[slug] ?? kNoMoodRecommendation;
