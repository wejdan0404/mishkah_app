import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../constants/app_icons.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../theme/app_tokens.dart';
import '../../widgets/cards/app_section_card.dart';
import '../../widgets/nav/app_top_nav.dart';

class AboutMishkatScreen extends StatelessWidget {
  const AboutMishkatScreen({super.key});

  static const String routeName = '/about';

  static const List<_AboutEntry> _entries = [
    _AboutEntry(
      iconAsset: AppSvgIcons.aboutGrowth,
      title: 'تجربة تطوير ذات هادئة',
      description:
          'مِشْكَاة مساحة رقمية تساعدك تطوّر نفسك بطريقة بسيطة '
          'ومتوازنة، عبر رحلة شخصية تجمع بين التأمل والأنشطة '
          'والتوجيه الذاتي.',
    ),
    _AboutEntry(
      iconAsset: AppSvgIcons.aboutVision,
      title: 'رؤيتنا',
      description:
          'نبي مِشْكَاة يكون رفيقك في رحلة الوعي والتوازن، ودعوة لك '
          'تعيش حياة أهدأ وأوضح.',
    ),
    _AboutEntry(
      iconAsset: AppSvgIcons.aboutJourney,
      title: 'رحلة موجّهة لك',
      description:
          'التطبيق يرافقك خطوة بخطوة عبر أنشطة مصمّمة بعناية، تساعدك '
          'تبني عادات إيجابية وتفهم نفسك أعمق، بدون ضغط أو تعقيد.',
    ),
    _AboutEntry(
      iconAsset: AppSvgIcons.aboutNotifications,
      title: 'توجيهات يومية',
      description:
          'توصلك إشعارات يومية فيها نصائح تحفيزية وأفكار جديدة '
          'تخلّيك على المسار الصح لتحقيق أهدافك.',
    ),
    _AboutEntry(
      iconAsset: AppSvgIcons.aboutProgress,
      title: 'تحليل التقدم',
      description:
          'تقدر تتابع تقدّمك بوضوح عبر الرسوم البيانية والتقارير '
          'اللي تعكس تطوّرك في رحلة بناء العادات.',
    ),
  ];

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
              const AppTopNav(title: 'عـن مِشْكَاة'),
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
                  itemBuilder: (_, i) => _AboutCard(entry: _entries[i]),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AboutEntry {
  const _AboutEntry({
    required this.iconAsset,
    required this.title,
    required this.description,
  });

  final String iconAsset;
  final String title;
  final String description;
}

class _AboutCard extends StatelessWidget {
  const _AboutCard({required this.entry});

  final _AboutEntry entry;

  @override
  Widget build(BuildContext context) {
    return AppSectionCard(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.xxxl,
        vertical: AppSpacing.xl,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
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
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
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
        ],
      ),
    );
  }
}
