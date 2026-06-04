import '../api/api_exception.dart';

/// Maps an auth/network error into a short, friendly, Arabic-first message for
/// the UI. It NEVER returns a raw backend, API, or exception string — callers
/// should route every auth failure through here instead of showing
/// `error.message` or `error.toString()` directly.
///
/// It understands this app's backend error codes (`ApiException.code` /
/// `statusCode`) and, defensively, common Firebase-style codes, with a safe
/// Arabic fallback for anything unknown. Copy follows the existing Mishkat
/// voice (gentle, neutral) rather than introducing a new gendered style.
String mapAuthError(
  Object? error, {
  String fallback = 'صار خطأ غير متوقع، نعيد المحاولة؟',
}) {
  if (error is ApiException) {
    final String? byCode = _messageForCode(error.code);
    if (byCode != null) return byCode;
    switch (error.statusCode) {
      case 0:
        return 'تعذّر الاتصال بالإنترنت، نعيد المحاولة؟';
      case 401:
        return 'البريد أو كلمة المرور غير صحيحة.';
      case 403:
        return 'ما عندك صلاحية لهذا الإجراء.';
      case 404:
        return 'لا يوجد حساب مرتبط بهذا البريد.';
      case 409:
        return 'هذا البريد مستخدم من قبل.';
      case 422:
        return 'بعض البيانات غير صحيحة، نعيد المحاولة؟';
      case 429:
        return 'محاولات كثيرة، نعيد المحاولة بعد شوي.';
    }
    if (error.statusCode >= 500) {
      return 'الخدمة غير متاحة حاليًا، نعيد المحاولة بعد شوي.';
    }
    return fallback;
  }

  // Non-ApiException (network/parse/SDK error): only infer connectivity, never
  // surface the raw text.
  final String s = error?.toString().toLowerCase() ?? '';
  if (s.contains('socketexception') ||
      s.contains('network') ||
      s.contains('failed host lookup') ||
      s.contains('connection')) {
    return 'تعذّر الاتصال بالإنترنت، نعيد المحاولة؟';
  }
  return fallback;
}

/// Code → Arabic message. Returns null when the code is unknown so the caller
/// can fall back to the status-code / generic mapping above.
String? _messageForCode(String code) {
  switch (code) {
    // ---- this app's backend codes ----
    case 'INVALID_CREDENTIALS':
      return 'البريد أو كلمة المرور غير صحيحة.';
    case 'UNAUTHENTICATED':
      return 'انتهت الجلسة، يلزم تسجيل الدخول من جديد.';
    case 'VALIDATION_FAILED':
      return 'بعض البيانات غير صحيحة، نعيد المحاولة؟';
    case 'RATE_LIMITED':
    case 'AI_USAGE_EXCEEDED':
      return 'محاولات كثيرة، نعيد المحاولة بعد شوي.';
    case 'ACCOUNT_PENDING_DELETE':
      return 'هذا الحساب في فترة حذف، وتسجيل الدخول يسترجعه.';
    case 'GOOGLE_SIGN_IN_FAILED':
    case 'GOOGLE_TOKEN_INVALID':
      return 'تعذّر تسجيل الدخول عبر جوجل، نعيد المحاولة؟';

    // ---- Firebase-style codes (defensive, in case any path surfaces them) ----
    case 'wrong-password':
    case 'invalid-credential':
      return 'البريد أو كلمة المرور غير صحيحة.';
    case 'user-not-found':
      return 'لا يوجد حساب مرتبط بهذا البريد.';
    case 'email-already-in-use':
      return 'هذا البريد مستخدم من قبل.';
    case 'invalid-email':
      return 'صيغة البريد الإلكتروني غير صحيحة.';
    case 'weak-password':
      return 'كلمة المرور ضعيفة.';
    case 'network-request-failed':
      return 'تعذّر الاتصال بالإنترنت، نعيد المحاولة؟';
    case 'too-many-requests':
      return 'محاولات كثيرة، نعيد المحاولة بعد شوي.';
    default:
      return null;
  }
}
