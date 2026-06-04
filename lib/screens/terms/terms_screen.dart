import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../constants/app_icons.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../theme/app_tokens.dart';
import '../../widgets/cards/app_section_card.dart';
import '../../widgets/nav/app_top_nav.dart';

class TermsScreen extends StatefulWidget {
  const TermsScreen({super.key});

  static const String routeName = '/terms';

  @override
  State<TermsScreen> createState() => _TermsScreenState();
}

class _TermsScreenState extends State<TermsScreen> {
  static const List<_TermsEntry> _entries = [
    _TermsEntry(
      iconAsset: AppSvgIcons.termsAcceptance,
      title: 'قبول الشروط',
      blocks: [
        _TermsBlock.text(
          'باستخدامك لتطبيق مِشْكَاة، أنت توافق تلتزم بشروط '
          'الاستخدام هذي، وبأي تحديثات تننشر لاحقًا داخل المنصة.',
        ),
      ],
    ),
    _TermsEntry(
      iconAsset: AppSvgIcons.termsAccount,
      title: 'الحساب والمسؤولية',
      blocks: [
        _TermsBlock.text('أنت مسؤول عن:'),
        _TermsBlock.pill('كل النشاطات اللي تتم من حسابك.'),
        _TermsBlock.pill('تحافظ على سرية بيانات حسابك.'),
        _TermsBlock.pill('صحة المعلومات اللي تدخلها.'),
        _TermsBlock.text(
          'لو شكّيت بأي استخدام غير مصرّح به، بلّغنا على طول.',
        ),
      ],
    ),
    _TermsEntry(
      iconAsset: AppSvgIcons.termsAccuracy,
      title: 'دقة المعلومات',
      blocks: [
        _TermsBlock.text('نحرص نقدّم لك محتوى دقيق ومفيد، بس:'),
        _TermsBlock.pill('ما نضمن إن كل المعلومات خالية من الأخطاء.'),
        _TermsBlock.pill('المحتوى إرشادي بس وما يغني عن الاستشارة المتخصصة.'),
      ],
    ),
    _TermsEntry(
      iconAsset: AppSvgIcons.termsPrivacy,
      title: 'الخصوصية وحماية البيانات',
      blocks: [
        _TermsBlock.text('نلتزم بحماية بياناتك، وتُستخدم بس:'),
        _TermsBlock.pill('عشان نحسّن تجربتك داخل التطبيق.'),
        _TermsBlock.pill('عشان نقدّم لك محتوى مناسب.'),
        _TermsBlock.text(
          'ما تنشارك بياناتك بدون إذنك، إلا في الحالات اللي يتطلبها النظام.',
        ),
      ],
    ),
    _TermsEntry(
      iconAsset: AppSvgIcons.termsOutage,
      title: 'انقطاع الخدمة',
      blocks: [
        _TermsBlock.text(
          'ممكن يصير توقف مؤقت للخدمة بسبب الصيانة أو ظروف تقنية، ونحرص '
          'دايم نقلّل هذا عشان تجربتك تستمر بأفضل شكل.',
        ),
      ],
    ),
    _TermsEntry(
      iconAsset: AppSvgIcons.termsIp,
      title: 'الملكية الفكرية',
      blocks: [
        _TermsBlock.text(
          'محتوى مِشْكَاة ملك للتطبيق وما يُسمح تستخدمه بدون إذن.',
        ),
      ],
    ),
    _TermsEntry(
      iconAsset: AppSvgIcons.termsChanges,
      title: 'التعديلات على الشروط',
      blocks: [
        _TermsBlock.text(
          'ممكن نحدّث هذي الشروط من وقت لوقت، وراح نشعرك بأي '
          'تغييرات مهمة داخل التطبيق.',
        ),
      ],
    ),
    _TermsEntry(
      iconAsset: AppSvgIcons.termsTermination,
      title: 'إنهاء الاستخدام',
      blocks: [
        _TermsBlock.text('يحق لنا:'),
        _TermsBlock.pill('تعليق أو إيقاف الحساب لو خالفت الشروط.'),
        _TermsBlock.text('وكمستخدم يحق لك:'),
        _TermsBlock.pill('توقف استخدام التطبيق في أي وقت.'),
      ],
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
              const AppTopNav(title: 'شروط الاستخدام'),
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
                  itemBuilder: (_, i) => _TermsCard(
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

class _TermsEntry {
  const _TermsEntry({
    required this.iconAsset,
    required this.title,
    required this.blocks,
  });

  final String iconAsset;
  final String title;
  final List<_TermsBlock> blocks;
}

enum _TermsBlockKind { text, pill }

class _TermsBlock {
  const _TermsBlock._(this.kind, this.text);
  const _TermsBlock.text(String text) : this._(_TermsBlockKind.text, text);
  const _TermsBlock.pill(String text) : this._(_TermsBlockKind.pill, text);

  final _TermsBlockKind kind;
  final String text;
}

class _TermsCard extends StatelessWidget {
  const _TermsCard({
    required this.entry,
    required this.isExpanded,
    required this.onTap,
  });

  final _TermsEntry entry;
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
              child: _TermsBody(blocks: entry.blocks),
            ),
          ),
        ],
      ),
    );
  }
}

class _TermsBody extends StatelessWidget {
  const _TermsBody({required this.blocks});

  final List<_TermsBlock> blocks;

  @override
  Widget build(BuildContext context) {
    final List<Widget> children = [];
    for (int i = 0; i < blocks.length; i++) {
      if (i != 0) children.add(const SizedBox(height: AppSpacing.md));
      final block = blocks[i];
      switch (block.kind) {
        case _TermsBlockKind.text:
          children.add(_TermsParagraph(text: block.text));
          break;
        case _TermsBlockKind.pill:
          children.add(_TermsPill(text: block.text));
          break;
      }
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: children,
    );
  }
}

class _TermsParagraph extends StatelessWidget {
  const _TermsParagraph({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      textAlign: TextAlign.right,
      style: TextStyle(
        fontFamily: AppFontFamily.text,
        fontSize: AppFontSizes.xs,
        fontWeight: AppFontWeights.regular,
        color: context.colors.shade500,
        height: 1.55,
      ),
    );
  }
}

class _TermsPill extends StatelessWidget {
  const _TermsPill({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: context.colors.purpleSoftBg,
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Text(
        text,
        textAlign: TextAlign.right,
        style: TextStyle(
          fontFamily: AppFontFamily.text,
          fontSize: AppFontSizes.xxs,
          fontWeight: AppFontWeights.regular,
          color: context.colors.purpleSoftFg,
          height: 1.5,
        ),
      ),
    );
  }
}
