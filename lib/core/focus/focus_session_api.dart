import '../api/api_client.dart';
import '../api/api_endpoints.dart';

// FocusSessionApi — narrow wrapper over the backend session lifecycle.
//
// Returns the server-issued session id (string UUID) on start; the
// session screen stashes it in state and uses it for complete/abandon.
// All methods throw ApiException on failure; callers decide whether
// to surface the error or fire-and-forget (the abandon path on leave
// is intentionally swallowed).
class FocusSessionApi {
  const FocusSessionApi._();

  /// Backend task ids are UUIDs. Anything else (e.g. a legacy local
  /// microsecond-timestamp id from a task created before backend sync) is
  /// rejected by /focus/sessions/start with a 422, which surfaced as
  /// "ما قدرنا نبدأ الجلسة". We drop such ids defensively so the timer always
  /// starts — worst case the session just isn't linked to a task.
  static final RegExp _uuid = RegExp(
    r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$',
  );

  /// POST /focus/sessions/start with a planned duration in SECONDS
  /// and an optional task_id. Returns the new session row's id.
  static Future<String> start({
    required int plannedDurationSeconds,
    String? taskId,
  }) async {
    final bool hasValidTask =
        taskId != null && taskId.isNotEmpty && _uuid.hasMatch(taskId);
    final body = <String, dynamic>{
      'planned_duration_seconds': plannedDurationSeconds,
      if (hasValidTask) 'task_id': taskId,
    };
    final dynamic data = await ApiClient.instance.post(
      ApiEndpoints.focusSessionsStart,
      body: body,
    );
    if (data is Map<String, dynamic>) {
      final id = data['id'];
      if (id is String && id.isNotEmpty) return id;
    }
    throw const _UnexpectedShape();
  }

  static Future<void> complete(String sessionId) async {
    await ApiClient.instance.post(ApiEndpoints.focusSessionComplete(sessionId));
  }

  static Future<void> abandon(String sessionId) async {
    await ApiClient.instance.post(ApiEndpoints.focusSessionAbandon(sessionId));
  }
}

class _UnexpectedShape implements Exception {
  const _UnexpectedShape();
  @override
  String toString() => 'Unexpected /focus/sessions/start response shape.';
}
