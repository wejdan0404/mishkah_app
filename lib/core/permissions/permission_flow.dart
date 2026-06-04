import 'package:permission_handler/permission_handler.dart';

/// Reads the current status of a single permission.
typedef PermissionStatusReader = Future<PermissionStatus> Function();

/// Fires the real OS permission request and returns the resulting status.
typedef PermissionRequester = Future<PermissionStatus> Function();

/// Shows a dialog and returns whether the user tapped its primary action.
typedef PermissionDialogPresenter = Future<bool> Function();

/// Opens the system Settings page for this app.
typedef SettingsOpener = Future<bool> Function();

/// Runs the standard Apple permission flow for one permission and returns
/// whether it ends up granted *right now*:
///
///  * already granted        → returns true, shows nothing
///  * permanently denied      → denied dialog → (if confirmed) open Settings →
///                              returns false (a later grant is detected when
///                              the app resumes from Settings)
///  * otherwise (first ask)    → priming dialog → (if accepted) OS request →
///                              returns whether the OS granted it
///
/// Pass [showPrimingDialog] as null to skip the priming step and go straight to
/// the OS prompt on first ask (used by the microphone flow, where the system
/// dialog stands on its own).
///
/// Pass [showDeniedDialog] as null to skip the explainer when permanently denied
/// and open the system Settings page directly (used by the microphone flow,
/// since iOS never re-shows its own prompt once denied).
Future<bool> runPermissionFlow({
  required PermissionStatusReader readStatus,
  required PermissionRequester request,
  required SettingsOpener openSettings,
  PermissionDialogPresenter? showPrimingDialog,
  PermissionDialogPresenter? showDeniedDialog,
}) async {
  final PermissionStatus status = await readStatus();
  if (status.isGranted) return true;

  if (status.isPermanentlyDenied || status.isRestricted) {
    final bool goToSettings =
        showDeniedDialog == null ? true : await showDeniedDialog();
    if (goToSettings) await openSettings();
    return false;
  }

  if (showPrimingDialog != null) {
    final bool allow = await showPrimingDialog();
    if (!allow) return false;
  }

  final PermissionStatus result = await request();
  return result.isGranted;
}
