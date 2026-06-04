import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../constants/app_icons.dart';
import '../../core/journal/journal_store.dart';
import '../../models/journal_entry.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../theme/app_tokens.dart';
import '../../widgets/buttons/app_button.dart';
import '../../widgets/cards/app_section_card.dart';
import '../../widgets/nav/app_top_nav.dart';
import 'topic_picker_dialog.dart';
import 'writing_screen.dart';

class JournalingSpaceScreen extends StatelessWidget {
  const JournalingSpaceScreen({super.key});

  void _onWrite(BuildContext context) {
    Navigator.of(
      context,
    ).push(MaterialPageRoute<void>(builder: (_) => const WritingScreen()));
  }

  Future<void> _onPickTopic(BuildContext context) async {
    final JournalTopic? topic = await showTopicPickerDialog(context);
    if (topic == null || !context.mounted) return;
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => WritingScreen(initialTopicId: topic.id),
      ),
    );
  }

  void _openEntry(BuildContext context, JournalEntry entry) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => WritingScreen(entry: entry)),
    );
  }

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
              const AppTopNav(
                title: 'مساحة التدوين',
                subtitle: 'مساحة هادئة للكتابة وترتيب الأفكار',
              ),
              Expanded(
                child: AnimatedBuilder(
                  animation: JournalStore.instance,
                  builder: (context, _) {
                    final List<JournalEntry> entries =
                        JournalStore.instance.entries;
                    if (entries.isEmpty) return const _EmptyState();
                    return ListView.separated(
                      padding: const EdgeInsets.fromLTRB(
                        AppSpacing.xxl,
                        AppSpacing.md,
                        AppSpacing.xxl,
                        AppSpacing.xl,
                      ),
                      itemCount: entries.length,
                      separatorBuilder: (_, _) =>
                          const SizedBox(height: AppSpacing.md),
                      itemBuilder: (_, i) {
                        final JournalEntry entry = entries[i];
                        return Dismissible(
                          key: ValueKey(entry.id),
                          direction: DismissDirection.horizontal,
                          background: const _SwipeBackground(
                            color: AppDangerColors.shade500,
                            iconAsset: AppSvgIcons.profileDeleteAccount,
                            alignment: AlignmentDirectional.centerStart,
                          ),
                          secondaryBackground: _SwipeBackground(
                            color: AppPalettePurple.shade200,
                            iconAsset: entry.isPinned
                                ? AppSvgIcons.activitiesJournalUnpin
                                : AppSvgIcons.activitiesJournalPin,
                            alignment: AlignmentDirectional.centerEnd,
                          ),
                          confirmDismiss: (direction) async {
                            if (direction == DismissDirection.startToEnd) {
                              // Physical left swipe in RTL → confirm before
                              // deleting (the entry can't be restored).
                              final bool? confirmed = await showDialog<bool>(
                                context: context,
                                barrierColor: Colors.black54,
                                builder: (_) => const _DeleteEntryDialog(),
                              );
                              return confirmed == true;
                            }
                            // Physical right swipe in RTL → pin/unpin
                            final bool toggled = await JournalStore.instance
                                .togglePin(entry.id);
                            if (!toggled && context.mounted) {
                              ScaffoldMessenger.of(context)
                                ..hideCurrentSnackBar()
                                ..showSnackBar(
                                  SnackBar(
                                    content: const Text(
                                      'تقدر تثبّت 3 تدوينات كحد أقصى',
                                      textAlign: TextAlign.right,
                                      style: TextStyle(
                                        fontFamily: AppFontFamily.text,
                                        fontSize: AppFontSizes.xs,
                                      ),
                                    ),
                                    behavior: SnackBarBehavior.floating,
                                    duration: const Duration(seconds: 2),
                                    backgroundColor: context.colors.shade700,
                                  ),
                                );
                            }
                            return false;
                          },
                          onDismissed: (_) =>
                              JournalStore.instance.remove(entry.id),
                          child: _EntryCard(
                            entry: entry,
                            onTap: () => _openEntry(context, entry),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.xxl,
                  0,
                  AppSpacing.xxl,
                  AppSpacing.xl,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: AppButton(
                        label: 'ابدأ بالكتابة',
                        expand: true,
                        onPressed: () => _onWrite(context),
                        trailing: SvgPicture.asset(
                          AppSvgIcons.activitiesJournalWrite,
                          width: 24,
                          height: 24,
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: _SecondaryPillButton(
                        label: 'اختر موضوعًا',
                        iconAsset: AppSvgIcons.activitiesJournalTopic,
                        onPressed: () => _onPickTopic(context),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EntryCard extends StatelessWidget {
  const _EntryCard({required this.entry, required this.onTap});

  final JournalEntry entry;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final String displayTitle = entry.title.isEmpty
        ? 'بدون عنوان'
        : entry.title;
    final JournalTopic? topic = findJournalTopic(entry.topicId);
    return AppSectionCard(
      onTap: onTap,
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              if (entry.isPinned) ...[
                SvgPicture.asset(
                  AppSvgIcons.activitiesJournalPin,
                  width: 12,
                  height: 12,
                  colorFilter: const ColorFilter.mode(
                    AppPalettePurple.shade200,
                    BlendMode.srcIn,
                  ),
                ),
                const SizedBox(width: AppSpacing.xs),
              ],
              Expanded(
                child: Text(
                  formatJournalTimestamp(entry.updatedAt),
                  textAlign: TextAlign.right,
                  style: TextStyle(
                    fontFamily: AppFontFamily.text,
                    fontSize: AppFontSizes.xxs,
                    fontWeight: AppFontWeights.regular,
                    color: context.colors.shade400,
                    height: 1.4,
                  ),
                ),
              ),
              if (topic != null) ...[
                const SizedBox(width: AppSpacing.sm),
                JournalTopicChip(topic: topic),
              ],
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            displayTitle,
            textAlign: TextAlign.right,
            style: AppTextStyles.thmanyahHeading(context).copyWith(
              fontSize: AppFontSizes.sm,
            ),
          ),
          if (entry.body.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(
              entry.body,
              textAlign: TextAlign.right,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontFamily: AppFontFamily.text,
                fontSize: AppFontSizes.xxs,
                fontWeight: AppFontWeights.regular,
                color: context.colors.shade500,
                height: 1.5,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _SwipeBackground extends StatelessWidget {
  const _SwipeBackground({
    required this.color,
    required this.iconAsset,
    required this.alignment,
  });

  final Color color;
  final String iconAsset;
  final AlignmentGeometry alignment;

  @override
  Widget build(BuildContext context) {
    return Container(
      alignment: alignment,
      padding: const EdgeInsetsDirectional.symmetric(
        horizontal: AppSpacing.xxl,
      ),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(AppRadius.xl),
      ),
      child: SvgPicture.asset(
        iconAsset,
        width: 24,
        height: 24,
        colorFilter: const ColorFilter.mode(
          AppNeutralColors.white,
          BlendMode.srcIn,
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SvgPicture.asset(
            AppSvgIcons.activitiesJournalEmpty,
            width: 30,
            height: 30,
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'ما دوّنت شي حاليًا',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: AppFontFamily.text,
              fontSize: AppFontSizes.xs,
              fontWeight: AppFontWeights.regular,
              color: context.colors.shade400,
              height: 1.4,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'ابدأ بأول سطر',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: AppFontFamily.text,
              fontSize: AppFontSizes.xs,
              fontWeight: AppFontWeights.regular,
              color: context.colors.shade400,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}

class _SecondaryPillButton extends StatelessWidget {
  const _SecondaryPillButton({
    required this.label,
    required this.iconAsset,
    required this.onPressed,
  });

  final String label;
  final String iconAsset;
  final VoidCallback onPressed;

  static const double _height = 44;

  @override
  Widget build(BuildContext context) {
    final BorderRadius radius = BorderRadius.circular(AppRadius.lg);
    return SizedBox(
      height: _height,
      child: Material(
        color: context.colors.white,
        borderRadius: radius,
        child: InkWell(
          onTap: onPressed,
          borderRadius: radius,
          child: Container(
            alignment: Alignment.center,
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            decoration: BoxDecoration(
              borderRadius: radius,
              border: Border.all(color: AppPalettePurple.shade200, width: 1),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Flexible(
                  child: Text(
                    label,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontFamily: AppFontFamily.text,
                      fontSize: AppFontSizes.sm,
                      fontWeight: AppFontWeights.bold,
                      color: AppPalettePurple.shade200,
                      height: 1.25,
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                SvgPicture.asset(iconAsset, width: 24, height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Confirmation shown before a journal entry is deleted (swipe-to-delete is
/// irreversible). Pops `true` from "حذف", `false`/null from "إلغاء"/dismiss.
class _DeleteEntryDialog extends StatelessWidget {
  const _DeleteEntryDialog();

  static const double _iconSize = 72;

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Center(
        child: Material(
          color: Colors.transparent,
          child: Container(
            width: 325,
            padding: const EdgeInsets.all(AppSpacing.xxxl),
            decoration: BoxDecoration(
              color: context.colors.white,
              borderRadius: BorderRadius.circular(AppRadius.xxl),
              boxShadow: AppShadows.md,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: SvgPicture.asset(
                    AppSvgIcons.profileDeleteModal,
                    width: _iconSize,
                    height: _iconSize,
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),
                Text(
                  'هل تود حذف التدوينة؟',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.thmanyahHeading(context).copyWith(
                    fontSize: AppFontSizes.sm,
                    color: context.colors.shade600,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  'لن تتمكن من استعادتها بعد الحذف',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: AppFontFamily.text,
                    fontSize: AppFontSizes.xxs,
                    fontWeight: AppFontWeights.regular,
                    color: context.colors.shade500,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: AppSpacing.xxxl),
                Row(
                  children: [
                    Expanded(
                      child: _DeleteDialogButton(
                        label: 'حذف',
                        filled: true,
                        onTap: () => Navigator.of(context).pop(true),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: _DeleteDialogButton(
                        label: 'إلغاء',
                        filled: false,
                        onTap: () => Navigator.of(context).pop(false),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DeleteDialogButton extends StatelessWidget {
  const _DeleteDialogButton({
    required this.label,
    required this.filled,
    required this.onTap,
  });

  final String label;
  final bool filled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final BorderRadius radius = BorderRadius.circular(AppRadius.lg);
    return Material(
      color: filled ? AppDangerColors.shade500 : context.colors.white,
      borderRadius: radius,
      child: InkWell(
        onTap: onTap,
        borderRadius: radius,
        child: Container(
          height: 40,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: radius,
            boxShadow: filled ? AppShadows.xs : null,
            border: filled
                ? null
                : Border.all(color: context.colors.shade300, width: 1),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontFamily: AppFontFamily.text,
              fontSize: AppFontSizes.xs,
              fontWeight: AppFontWeights.semibold,
              color: filled ? AppNeutralColors.white : context.colors.shade700,
              height: 1.2,
            ),
          ),
        ),
      ),
    );
  }
}
