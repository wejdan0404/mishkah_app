import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../constants/app_ai_images.dart';
import '../../constants/app_icons.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_tokens.dart';
import '../../widgets/buttons/app_button.dart';
import '../../widgets/nav/app_top_nav.dart';

class SmartCompanionOnboardingScreen extends StatelessWidget {
  const SmartCompanionOnboardingScreen({super.key});

  static const String routeName = '/smart-companion';

  static const double _illustrationWidth = 241;
  static const double _illustrationHeight = 237;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.colors.shade50,
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const AppTopNav(title: 'اسأل مِشْكَاة'),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.xxl,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Image.asset(
                        AppAiImages.smileCharacter,
                        width: _illustrationWidth,
                        height: _illustrationHeight,
                        fit: BoxFit.contain,
                        semanticLabel: 'شعار المرافق الذكي',
                      ),
                      const SizedBox(height: AppSpacing.xxxl),
                      SizedBox(
                        width: double.infinity,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(
                              'أهلا أنا مِشْكَاة، مُرافقك الذكي',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontFamily: AppFontFamily.title,
                                fontSize: AppFontSizes.md,
                                fontWeight: AppFontWeights.bold,
                                color: context.colors.shade600,
                                height: 1.35,
                                fontFeatures: const [
                                  FontFeature('salt'),
                                  FontFeature('swsh'),
                                  FontFeature('ss05'),
                                ],
                              ),
                            ),
                            const SizedBox(height: AppSpacing.md),
                            Text(
                              'تقدر تشاركني اللي تحس فيه أو اللي يشغل تفكيرك، '
                              'وأساعدك بخطوات بسيطة تناسبك.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontFamily: AppFontFamily.text,
                                fontSize: AppFontSizes.sm,
                                fontWeight: AppFontWeights.regular,
                                color: context.colors.shade600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.xxl,
                  AppSpacing.xl,
                  AppSpacing.xxl,
                  AppSpacing.xxl,
                ),
                child: AppButton(
                  label: 'ابدأ المحادثة',
                  expand: true,
                  trailing: SvgPicture.asset(
                    AppSvgIcons.arrowLeft,
                    width: 20,
                    height: 20,
                    colorFilter: const ColorFilter.mode(
                      AppNeutralColors.white,
                      BlendMode.srcIn,
                    ),
                  ),
                  onPressed: () {
                    Navigator.of(
                      context,
                    ).pushReplacementNamed('/smart-companion/chat');
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
