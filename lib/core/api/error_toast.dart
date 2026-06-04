import 'package:flutter/widgets.dart';

import '../../widgets/app_toast.dart';
import 'api_exception.dart';

/// Show a backend-driven error via the app's error toast. For an
/// [ApiException] the localized backend message (error.message, Arabic) is
/// shown; for any other error (network/parse) the Arabic [fallback] is used.
/// Inline field-validation and auth-field errors should stay inline — do not
/// route those here.
void showApiErrorToast(
  BuildContext context,
  Object error, {
  String fallback = 'صار خطأ غير متوقع، جرّب مرة ثانية.',
}) {
  final message = error is ApiException && error.message.trim().isNotEmpty
      ? error.message
      : fallback;
  showAppToast(context, message, type: AppToastType.error);
}
