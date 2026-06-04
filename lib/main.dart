// import 'package:flutter/material.dart';

// import 'screens/splash/splash_screen.dart';
// import 'theme/app_theme.dart';

// void main() {
//   runApp(const MishkatApp());
// }

// class MishkatApp extends StatelessWidget {
//   const MishkatApp({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return MaterialApp(
//       title: 'Mishkat',
//       debugShowCheckedModeBanner: false,
//       theme: AppTheme.light,
//       home: const SplashScreen(),
//     );
//   }
// }

import 'dart:async';

import 'package:flutter/material.dart';

import 'core/auth/auth_service.dart';
import 'core/journal/journal_store.dart';
import 'core/notifications/push_service.dart';
import 'core/storage/token_storage.dart';
import 'core/tasks/task_store.dart';
import 'core/theme/theme_controller.dart';
import 'screens/about/about_mishkat_screen.dart';
import 'screens/auth/sign_in_screen.dart';
import 'screens/auth/sign_up_screen.dart';
import 'screens/edit_profile/edit_profile_screen.dart';
import 'screens/faq/faq_screen.dart';
import 'screens/home/main_shell.dart';
import 'screens/notifications/notifications_screen.dart';
import 'screens/privacy/privacy_screen.dart';
import 'screens/report_problem/report_problem_screen.dart';
import 'screens/terms/terms_screen.dart';
import 'screens/onboarding/onboarding_screens.dart';
import 'screens/smart_companion/smart_companion_chat_screen.dart';
import 'screens/smart_companion/smart_companion_onboarding_screen.dart';
import 'screens/splash/splash_screen.dart';
import 'theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await TokenStorage.instance.load();
  await TaskStore.instance.load();
  await JournalStore.instance.load();
  await ThemeController.instance.load();
  // Best-effort FCM registration for an already-signed-in session. This is
  // self-guarded (it initializes Firebase internally and swallows the missing
  // native-config case), so it never blocks startup or crashes when Firebase
  // isn't configured yet — see docs/PUSH_SETUP.md.
  if (AuthService.isLoggedIn) {
    unawaited(PushService.instance.registerIfPossible());
  }
  runApp(const MishkatApp());
}

class MishkatApp extends StatelessWidget {
  const MishkatApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: ThemeController.instance.darkMode,
      builder: (context, isDark, _) {
        return MaterialApp(
          title: 'Mishkat',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light,
          darkTheme: AppTheme.dark,
          themeMode: isDark ? ThemeMode.dark : ThemeMode.light,
          initialRoute: '/',
          routes: _routes,
        );
      },
    );
  }

  static final Map<String, WidgetBuilder> _routes = {
        '/': (context) => const SplashScreen(),
        '/onboarding': (context) => const OnboardingScreen(),
        '/signin': (context) => const SignInScreen(),
        '/signup': (context) => const SignUpScreen(),
        '/home': (context) => const MainShell(),
        '/notifications': (context) => const NotificationsScreen(),
        '/faq': (context) => const FaqScreen(),
        '/edit-profile': (context) => const EditProfileScreen(),
        '/about': (context) => const AboutMishkatScreen(),
        '/report-problem': (context) => const ReportProblemScreen(),
        '/terms': (context) => const TermsScreen(),
        '/privacy': (context) => const PrivacyScreen(),
        '/smart-companion': (context) =>
            const SmartCompanionOnboardingScreen(),
        '/smart-companion/chat': (context) => const SmartCompanionChatScreen(),
  };
}
