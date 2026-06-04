/// Client mirror of the backend `CoreEmotionMoodMapper`: bridges the six
/// افهم شعورك core emotions into the nine-slug mood catalogue, modulated by
/// intensity. Kept in sync with
/// `app/Domain/Activities/Support/CoreEmotionMoodMapper.php` so the home can
/// resolve the "ابدأ نشاطك" mood without waiting on a server round-trip.
///
/// [emotion] is the backend emotion id carried through the flow ('happy',
/// 'anger', 'disgust', 'surprise', 'sadness', 'fear'); [intensity] is 1–5.
/// Returns a mood slug from the catalogue, or null for an unknown emotion.
String? mapEmotionToMood(String emotion, int intensity) {
  final int i = intensity.clamp(1, 5);
  switch (emotion) {
    case 'happy':
      if (i <= 1) return 'relaxed';
      if (i >= 5) return 'excited';
      return 'happy';
    case 'surprise':
      return 'neutral';
    case 'fear':
      return i >= 4 ? 'upset' : 'tense';
    case 'anger':
    case 'disgust':
      return 'upset';
    case 'sadness':
      return i <= 2 ? 'upset' : 'sad';
    default:
      return null;
  }
}
