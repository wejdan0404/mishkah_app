import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../constants/app_icons.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../theme/app_tokens.dart';
import '../../widgets/cards/app_section_card.dart';
import '../../widgets/nav/app_top_nav.dart';

class FaqScreen extends StatefulWidget {
  const FaqScreen({super.key});

  static const String routeName = '/faq';

  @override
  State<FaqScreen> createState() => _FaqScreenState();
}

class _FaqScreenState extends State<FaqScreen> {
  static const List<_FaqEntry> _entries = [
    _FaqEntry(
      question: 'لازم ألتزم يوميًا؟',
      answer:
          'الالتزام يساعدك تستفيد أكثر، لكن تقدر تكمل في أي وقت يناسبك. مهمتك تمشي بالوتيرة اللي تريحك.',
    ),
    _FaqEntry(
      question: 'كيف يشتغل المرافق الذكي؟',
      answer:
          'يقدّم لك اقتراحات وتوجيهات حسب استخدامك داخل التطبيق، عشان يساعدك تستمر.',
    ),
    _FaqEntry(
      question: 'بياناتي محفوظة وآمنة؟',
      answer:
          'نعم، خصوصيتك تهمّنا، نحفظ بياناتك ونستخدمها بس عشان نحسّن تجربتك في مِشْكَاة.',
    ),
    _FaqEntry(
      question: 'وش أسوي إذا واجهت مشكلة؟',
      answer:
          'تقدر تستخدم خيار "الإبلاغ عن مشكلة" من صفحة حسابي، وراح يتم مراجعتها بأقرب وقت.',
    ),
  ];

  int? _expandedIndex = 0;

  void _toggle(int index) {
    setState(() {
      _expandedIndex = _expandedIndex == index ? null : index;
    });
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
              const AppTopNav(title: 'الأسئلـة الشائعـة'),
              const SizedBox(height: AppSpacing.xxxl),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.xxl,
                    0,
                    AppSpacing.xxl,
                    AppSpacing.xl,
                  ),
                  child: AppSectionCard(
                    padding: const EdgeInsets.all(AppSpacing.xxxl),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        for (int i = 0; i < _entries.length; i++) ...[
                          if (i != 0) ...[
                            const SizedBox(height: AppSpacing.xl),
                            const _FaqDivider(),
                            const SizedBox(height: AppSpacing.xl),
                          ],
                          _FaqTile(
                            entry: _entries[i],
                            isExpanded: _expandedIndex == i,
                            onTap: () => _toggle(i),
                          ),
                        ],
                      ],
                    ),
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

class _FaqEntry {
  const _FaqEntry({required this.question, required this.answer});

  final String question;
  final String answer;
}

class _FaqTile extends StatelessWidget {
  const _FaqTile({
    required this.entry,
    required this.isExpanded,
    required this.onTap,
  });

  final _FaqEntry entry;
  final bool isExpanded;
  final VoidCallback onTap;

  static const Duration _duration = Duration(milliseconds: 220);
  static const Curve _curve = Curves.easeInOut;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppRadius.md),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  entry.question,
                  textAlign: TextAlign.right,
                  style: AppTextStyles.thmanyahHeading(context).copyWith(
                    fontSize: AppFontSizes.sm,
                    height: 1.4,
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
              entry.answer,
              textAlign: TextAlign.right,
              style: TextStyle(
                fontFamily: AppFontFamily.text,
                fontSize: AppFontSizes.xs,
                fontWeight: AppFontWeights.regular,
                color: context.colors.shade500,
                height: 1.5,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _FaqDivider extends StatelessWidget {
  const _FaqDivider();

  @override
  Widget build(BuildContext context) {
    return Container(height: 0.5, color: context.colors.shade100);
  }
}
