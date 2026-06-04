import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

/// A permission dialog styled like the operating system's own alerts —
/// [CupertinoAlertDialog] on Apple platforms, [AlertDialog] elsewhere.
///
/// Text direction follows the content language: pass [TextDirection.ltr] for
/// English copy; the default [TextDirection.rtl] suits Arabic.
///
/// Returns `true` when the user taps the primary (confirm) action, `false`
/// when they cancel or dismiss it.
Future<bool> showSystemPermissionDialog(
  BuildContext context, {
  required String title,
  required String message,
  required String confirmLabel,
  required String cancelLabel,
  TextDirection textDirection = TextDirection.rtl,
}) async {
  final TargetPlatform platform = Theme.of(context).platform;
  final bool isApple =
      platform == TargetPlatform.iOS || platform == TargetPlatform.macOS;

  final bool? result = await showDialog<bool>(
    context: context,
    barrierColor: Colors.black54,
    builder: (ctx) => Directionality(
      textDirection: textDirection,
      child: isApple
          ? CupertinoAlertDialog(
              title: Text(title),
              content: Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(message),
              ),
              actions: [
                CupertinoDialogAction(
                  onPressed: () => Navigator.of(ctx).pop(false),
                  child: Text(cancelLabel),
                ),
                CupertinoDialogAction(
                  isDefaultAction: true,
                  onPressed: () => Navigator.of(ctx).pop(true),
                  child: Text(confirmLabel),
                ),
              ],
            )
          : AlertDialog(
              title: Text(title),
              content: Text(message),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(false),
                  child: Text(cancelLabel),
                ),
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(true),
                  child: Text(confirmLabel),
                ),
              ],
            ),
    ),
  );
  return result ?? false;
}
