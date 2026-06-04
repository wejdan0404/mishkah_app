import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../constants/app_icons.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../theme/app_tokens.dart';
import '../../widgets/cards/app_section_card.dart';
import '../../widgets/nav/app_top_nav.dart';

class PrivacyScreen extends StatefulWidget {
  const PrivacyScreen({super.key});

  static const String routeName = '/privacy';

  @override
  State<PrivacyScreen> createState() => _PrivacyScreenState();
}

class _PrivacyScreenState extends State<PrivacyScreen> {
  static const List<_PrivacyEntry> _entries = [
    _PrivacyEntry(
      iconAsset: AppSvgIcons.privacyIntro,
      title: 'البند الأول: مقدمة',
      description:
          'سياسة الخصوصية في مِشْكَاة توضّح لك كيف نجمع بياناتك '
          'الشخصية ونستخدمها ونحميها، عشان نضمن لك تجربة آمنة '
          'ومناسبة وانت تستخدم التطبيق.',
    ),
    _PrivacyEntry(
      iconAsset: AppSvgIcons.termsAccount,
      title: 'البند الثاني: بيانات المستخدم',
      description:
          'ممكن نجمع بعض البيانات مثل الاسم والبريد الإلكتروني '
          'ومعلومات الاستخدام، عشان نحسّن تجربتك ونخصّص المحتوى '
          'حسب احتياجاتك.',
    ),
    _PrivacyEntry(
      iconAsset: AppSvgIcons.privacyDataUsage,
      title: 'البند الثالث: كيفية استخدام البيانات',
      description:
          'نستخدم بياناتك عشان نقدّم خدمات التطبيق ونحسّن الأداء '
          'ونخصّص تجربتك، وتساعدنا كمان نطوّر الميزات ونقدّم محتوى '
          'أنسب لك.',
    ),
    _PrivacyEntry(
      iconAsset: AppSvgIcons.termsPrivacy,
      title: 'البند الرابع: حماية البيانات',
      description:
          'نلتزم نحمي بياناتك من أي وصول غير مصرّح به، ونتبع إجراءات '
          'أمنية مناسبة نحافظ فيها على سريتها وسلامتها.',
    ),
    _PrivacyEntry(
      iconAsset: AppSvgIcons.aboutNotifications,
      title: 'البند الخامس: الإشعارات',
      description:
          'ممكن نستخدم بياناتك عشان نرسل لك إشعارات متعلقة باستخدامك للتطبيق، '
          'مثل التذكيرات أو التحديثات، وتقدر تتحكم فيها من الإعدادات.',
    ),
    _PrivacyEntry(
      iconAsset: AppSvgIcons.termsChanges,
      title: 'البند السادس: تعديلات سياسة الخصوصية',
      description:
          'ممكن نحدّث سياسة الخصوصية من وقت لوقت، وراح نشعرك بأي '
          'تغييرات مهمة عشان تبقى على اطلاع.',
    ),
    _PrivacyEntry(
      iconAsset: AppSvgIcons.privacyContact,
      title: 'البند السابع: التواصل',
      description:
          'لو عندك أي استفسار عن سياسة الخصوصية، تقدر تتواصل '
          'معنا عبر قسم الدعم داخل التطبيق.',
    ),
  ];

  int? _expandedIndex = 0;

  void _toggle(int i) {
    setState(() => _expandedIndex = _expandedIndex == i ? null : i);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.colors.shade50,
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: SafeArea(
          bottom: false,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const AppTopNav(title: 'بنود الخصوصية'),
              const SizedBox(height: AppSpacing.xxxl),
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.xxl,
                    0,
                    AppSpacing.xxl,
                    AppSpacing.xl,
                  ),
                  itemCount: _entries.length,
                  separatorBuilder: (_, _) =>
                      const SizedBox(height: AppSpacing.md),
                  itemBuilder: (_, i) => _PrivacyCard(
                    entry: _entries[i],
                    isExpanded: _expandedIndex == i,
                    onTap: () => _toggle(i),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PrivacyEntry {
  const _PrivacyEntry({
    required this.iconAsset,
    required this.title,
    required this.description,
  });

  final String iconAsset;
  final String title;
  final String description;
}

class _PrivacyCard extends StatelessWidget {
  const _PrivacyCard({
    required this.entry,
    required this.isExpanded,
    required this.onTap,
  });

  final _PrivacyEntry entry;
  final bool isExpanded;
  final VoidCallback onTap;

  static const Duration _duration = Duration(milliseconds: 220);
  static const Curve _curve = Curves.easeInOut;

  @override
  Widget build(BuildContext context) {
    return AppSectionCard(
      padding: const EdgeInsets.all(AppSpacing.xxxl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(AppRadius.md),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                SvgPicture.asset(entry.iconAsset, width: 20, height: 20),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Text(
                    entry.title,
                    textAlign: TextAlign.right,
                    style: AppTextStyles.thmanyahHeading(context).copyWith(
                      fontSize: AppFontSizes.sm,
                      height: 1.3,
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.lg),
                AnimatedRotation(
                  duration: _duration,
                  curve: _curve,
                  turns: isExpanded ? 0.5 : 0,
                  child: SvgPicture.asset(
                    AppSvgIcons.chevronDown,
                    width: 20,
                    height: 20,
                  ),
                ),
              ],
            ),
          ),
          AnimatedCrossFade(
            duration: _duration,
            sizeCurve: _curve,
            firstCurve: _curve,
            secondCurve: _curve,
            crossFadeState: isExpanded
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            firstChild: const SizedBox(width: double.infinity),
            secondChild: Padding(
              padding: const EdgeInsets.only(top: AppSpacing.md),
              child: Text(
                entry.description,
                textAlign: TextAlign.right,
                style: TextStyle(
                  fontFamily: AppFontFamily.text,
                  fontSize: AppFontSizes.xs,
                  fontWeight: AppFontWeights.regular,
                  color: context.colors.shade500,
                  height: 1.55,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
