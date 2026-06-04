/// Every user-facing string for permission dialogs lives here so the wording
/// stays consistent across onboarding, chat, profile, and the first-launch
/// notifications prompt. Saudi-colloquial voice; unified "مرافقك الذكي".
class PermissionCopy {
  PermissionCopy._();

  // Microphone has no app-side dialogs: the OS prompt stands alone (its
  // localized copy lives in ios/Runner/*.lproj/InfoPlist.strings), and a denied
  // mic opens Settings directly with no explainer. So no mic strings here.

  // Notifications — enable / allow
  static const String notificationsTitle = 'تبي تذكيرات تساعدك تستمر؟';
  static const String notificationsPrimingBody =
      'نرسل لك تنبيهات بسيطة تساعدك تستمر، وتقدر توقفها وقت ما تبي.';

  // Notifications — disable (app can't revoke OS permission; route to Settings)
  static const String notificationsDisableTitle = 'تبي توقف الإشعارات؟';
  static const String notificationsDisableBody =
      'التحكم بالإشعارات من إعدادات جهازك، وسنوجّهك إليها الآن.';

  // Shared button labels
  static const String enableNotificationsLabel = 'تفعيل الإشعارات';
  static const String laterLabel = 'لاحقًا';
  static const String openSettingsLabel = 'فتح الإعدادات';
  static const String cancelLabel = 'إلغاء';
}
