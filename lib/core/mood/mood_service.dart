import '../api/api_client.dart';
import '../api/api_endpoints.dart';
import '../journey/journey_service.dart';

// MoodService — thin wrapper around the mood check-in endpoint.
//
// The home screen calls `checkIn(slug)` after the user confirms the mood
// picker sheet. Network errors don't throw — the UI already shows the
// "تم تسجيل شعورك" card based on local state, so a flaky network just
// means the entry will retry next time. Surface the error via `lastError`
// if a caller wants to display a toast.
//
// On success, JourneyService.refresh() is fired so the رحلتي screen's
// weekly trend + balance + highlights pick up the new entry the next
// time the user opens that tab (or right now if they're already on it).
class MoodService {
  MoodService._();
  static final MoodService instance = MoodService._();

  String? _lastError;
  String? get lastError => _lastError;

  /// POST a mood check-in. Returns whether the call succeeded and, on
  /// success, the admin-managed `mood_message` from the resource (may be
  /// null if the backend didn't supply one for the active locale — callers
  /// should fall back to a local string in that case).
  Future<({bool ok, String? message})> checkIn(
    String slug, {
    String? note,
  }) async {
    try {
      final dynamic data = await ApiClient.instance.post(
        ApiEndpoints.moodCheckIn,
        body: {
          'mood': slug,
          if (note != null && note.trim().isNotEmpty) 'note': note.trim(),
          'source': 'manual',
        },
      );
      _lastError = null;
      // Fire-and-forget — refresh the journey snapshot so رحلتي reflects
      // this check-in without the user having to pull-to-refresh. The
      // service collapses concurrent calls, so a tab switch that also
      // triggers a refresh won't double-hit the API.
      JourneyService.instance.refresh();
      String? message;
      if (data is Map<String, dynamic>) {
        final dynamic entry = data['entry'];
        if (entry is Map<String, dynamic>) {
          final dynamic raw = entry['mood_message'];
          if (raw is String) message = raw;
        }
      }
      return (ok: true, message: message);
    } catch (e) {
      _lastError = e.toString();
      return (ok: false, message: null);
    }
  }

  /// Fetch the daily dominant moods for [month] (its calendar). Returns a
  /// `day-of-month → mood slug` map (only days that have a mood); empty on any
  /// error. Used by the رحلتي الشهر calendar so any selected month renders its
  /// own moods, not just the current one carried by the journey snapshot.
  Future<Map<int, String>> monthCalendar(DateTime month) async {
    final String ym =
        '${month.year.toString().padLeft(4, '0')}-${month.month.toString().padLeft(2, '0')}';
    try {
      final dynamic data = await ApiClient.instance.get(
        ApiEndpoints.moodCalendar,
        query: {'month': ym},
      );
      final Map<int, String> out = <int, String>{};
      if (data is Map<String, dynamic> && data['days'] is List) {
        for (final dynamic d in data['days'] as List) {
          if (d is Map<String, dynamic>) {
            final dynamic date = d['date'];
            final dynamic slug = d['dominant_mood'];
            if (date is String && slug is String && slug.isNotEmpty) {
              final DateTime? dt = DateTime.tryParse(date);
              if (dt != null) out[dt.day] = slug;
            }
          }
        }
      }
      return out;
    } catch (_) {
      return const <int, String>{};
    }
  }

  /// Best-effort fetch of today's recorded mood so the home screen can show
  /// the "تم تسجيل شعورك" card on a fresh app open instead of the picker.
  ///
  /// `GET /mood/today` returns (after ApiClient unwraps `data`) a Map shaped
  /// like `{ date, entries: [...] (oldest-first), entry_count, calm_score,
  /// dominant_mood }`. Under the once-per-day rule there is at most one entry,
  /// but we read the LAST entry generally. Returns the entry's `mood` slug and
  /// `mood_message`. Returns nulls on any error or when entries is empty.
  Future<({String? slug, String? message})> todayMoodInfo() async {
    try {
      final data = await ApiClient.instance.get(ApiEndpoints.moodToday);
      if (data is! Map<String, dynamic>) return (slug: null, message: null);
      final entries = data['entries'];
      if (entries is! List || entries.isEmpty) {
        return (slug: null, message: null);
      }
      final last = entries.last;
      if (last is! Map<String, dynamic>) return (slug: null, message: null);
      final slug = last['mood'];
      final message = last['mood_message'];
      return (
        slug: slug is String ? slug : null,
        message: message is String ? message : null,
      );
    } catch (_) {
      return (slug: null, message: null);
    }
  }
}
