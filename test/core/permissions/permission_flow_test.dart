import 'package:flutter_test/flutter_test.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:mishkat/core/permissions/permission_flow.dart';

void main() {
  test('granted permission returns true without showing any dialog', () async {
    bool primingShown = false;
    bool deniedShown = false;
    bool requested = false;

    final granted = await runPermissionFlow(
      readStatus: () async => PermissionStatus.granted,
      request: () async {
        requested = true;
        return PermissionStatus.granted;
      },
      showPrimingDialog: () async {
        primingShown = true;
        return true;
      },
      showDeniedDialog: () async {
        deniedShown = true;
        return true;
      },
      openSettings: () async => true,
    );

    expect(granted, isTrue);
    expect(primingShown, isFalse);
    expect(deniedShown, isFalse);
    expect(requested, isFalse);
  });

  test('first ask: priming accepted -> requests OS permission', () async {
    bool requested = false;

    final granted = await runPermissionFlow(
      readStatus: () async => PermissionStatus.denied,
      request: () async {
        requested = true;
        return PermissionStatus.granted;
      },
      showPrimingDialog: () async => true,
      showDeniedDialog: () async => fail('denied dialog should not show'),
      openSettings: () async => fail('settings should not open'),
    );

    expect(requested, isTrue);
    expect(granted, isTrue);
  });

  test('first ask: priming declined -> no OS request, returns false', () async {
    bool requested = false;

    final granted = await runPermissionFlow(
      readStatus: () async => PermissionStatus.denied,
      request: () async {
        requested = true;
        return PermissionStatus.granted;
      },
      showPrimingDialog: () async => false,
      showDeniedDialog: () async => fail('denied dialog should not show'),
      openSettings: () async => fail('settings should not open'),
    );

    expect(requested, isFalse);
    expect(granted, isFalse);
  });

  test('permanently denied: confirm -> opens settings, returns false', () async {
    bool settingsOpened = false;
    bool requested = false;

    final granted = await runPermissionFlow(
      readStatus: () async => PermissionStatus.permanentlyDenied,
      request: () async {
        requested = true;
        return PermissionStatus.granted;
      },
      showPrimingDialog: () async => fail('priming dialog should not show'),
      showDeniedDialog: () async => true,
      openSettings: () async {
        settingsOpened = true;
        return true;
      },
    );

    expect(settingsOpened, isTrue);
    expect(requested, isFalse);
    expect(granted, isFalse);
  });

  test('permanently denied: declined -> does not open settings', () async {
    bool settingsOpened = false;

    final granted = await runPermissionFlow(
      readStatus: () async => PermissionStatus.permanentlyDenied,
      request: () async => PermissionStatus.granted,
      showPrimingDialog: () async => fail('priming dialog should not show'),
      showDeniedDialog: () async => false,
      openSettings: () async {
        settingsOpened = true;
        return true;
      },
    );

    expect(settingsOpened, isFalse);
    expect(granted, isFalse);
  });
}
