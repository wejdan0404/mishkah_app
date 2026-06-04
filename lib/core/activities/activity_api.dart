import '../api/api_client.dart';
import '../api/api_endpoints.dart';

/// Stable backend slugs for the four bespoke activity screens. The screens
/// are hardcoded UIs; these slugs link each one to its backend Activity row.
class ActivitySlugs {
  const ActivitySlugs._();

  static const String understandFeelings = 'understand_feelings';
  static const String activateSenses = 'activate_senses';
  static const String emotionCards = 'emotion_cards';
  static const String smileFace = 'smile_face';
  static const String breatheCalmly = 'breathe_calmly';
  static const String releasePressure = 'release_pressure';
  static const String stopSpiral = 'stop_spiral';
  static const String sleepCalm = 'sleep_calm';

  static const Set<String> all = {
    understandFeelings,
    activateSenses,
    emotionCards,
    smileFace,
    breatheCalmly,
    releasePressure,
    stopSpiral,
    sleepCalm,
  };
}

/// Navigator route names for the category "hub" screens an activity is launched
/// from. Used so exiting an in-progress activity can pop back to its own
/// category list instead of all the way to the app root.
class ActivityCategoryRoutes {
  const ActivityCategoryRoutes._();

  static const String balanceStation = 'activity-balance-station';
  static const String playArea = 'activity-play-area';
}

/// Thin wrapper over the activity-completion lifecycle. All write calls are
/// best-effort (fire-and-forget): a network/consent error must never block
/// the calming activity flow. Mirrors FocusSessionApi.
class ActivityApi {
  const ActivityApi._();

  /// POST /activities/{slug}/start. Returns true on success.
  static Future<bool> start(String slug) async {
    try {
      await ApiClient.instance.post(ApiEndpoints.activityStart(slug));
      return true;
    } catch (_) {
      return false;
    }
  }

  /// POST /activities/{slug}/complete with an optional result payload.
  static Future<void> complete(
    String slug, {
    Map<String, dynamic>? result,
  }) async {
    try {
      await ApiClient.instance.post(
        ApiEndpoints.activityComplete(slug),
        body: result == null ? null : <String, dynamic>{'result': result},
      );
    } catch (_) {
      // best-effort
    }
  }

  /// POST /activities/{slug}/abandon.
  static Future<void> abandon(String slug) async {
    try {
      await ApiClient.instance.post(ApiEndpoints.activityAbandon(slug));
    } catch (_) {
      // best-effort
    }
  }

  /// GET /activities/daily-suggestion — returns the admin-managed "مقترح
  /// اليوم" body for today. Best-effort: returns null on any error so the
  /// screen falls back to its hardcoded default line.
  static Future<String?> dailySuggestion() async {
    try {
      final dynamic data = await ApiClient.instance.get(
        ApiEndpoints.activitiesDailySuggestion,
      );
      if (data is Map && data['message'] is String) {
        final message = (data['message'] as String).trim();
        if (message.isNotEmpty) return message;
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  /// GET /activities/recommended — the backend's mood-scored top picks. By
  /// default it reads the user's most recent mood; pass [mood] to pin the picks
  /// to a specific mood slug (the home uses this to keep "أنشطة تناسب مزاجك" on
  /// the manually-recorded mood while "ابدأ نشاطك" follows the افهم شعورك mood).
  /// Returns the ordered slugs, filtered to the ones the app can deep-link.
  /// Empty on any error (best-effort).
  static Future<List<String>> recommended({String? mood}) async {
    try {
      final dynamic data = await ApiClient.instance.get(
        ApiEndpoints.activitiesRecommended,
        query: (mood != null && mood.isNotEmpty) ? {'mood': mood} : null,
      );
      final out = <String>[];
      if (data is List) {
        for (final dynamic item in data) {
          if (item is Map && item['slug'] is String) {
            final slug = item['slug'] as String;
            if (ActivitySlugs.all.contains(slug)) out.add(slug);
          }
        }
      }
      return out;
    } catch (_) {
      return const <String>[];
    }
  }

  /// GET /activities — returns the subset of ActivitySlugs.all that the
  /// backend reports active. Throws on network error (callers default to
  /// showing all cards when this fails).
  static Future<Set<String>> activeSlugs() async {
    final dynamic data = await ApiClient.instance.get(ApiEndpoints.activities);
    final out = <String>{};
    if (data is List) {
      for (final dynamic item in data) {
        if (item is Map && item['slug'] is String) {
          final slug = item['slug'] as String;
          if (ActivitySlugs.all.contains(slug)) out.add(slug);
        }
      }
    }
    return out;
  }
}
