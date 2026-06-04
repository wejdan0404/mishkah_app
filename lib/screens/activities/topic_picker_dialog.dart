import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../constants/app_icons.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../theme/app_tokens.dart';

class JournalTopic {
  const JournalTopic({
    required this.id,
    required this.label,
    required this.color,
    required this.borderColor,
    required this.textColor,
  });

  final String id;
  final String label;
  final Color color;
  final Color borderColor;
  final Color textColor;
}

JournalTopic? findJournalTopic(String? id) {
  if (id == null) return null;
  for (final JournalTopic t in kJournalTopics) {
    if (t.id == id) return t;
  }
  return null;
}

/// The selected-topic chip (sparkle + label) shown both pinned on the writing
/// screen and on each journal entry card, so the topic reads identically in
/// both places.
class JournalTopicChip extends StatelessWidget {
  const JournalTopicChip({super.key, required this.topic});

  final JournalTopic topic;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: topic.color,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: topic.borderColor, width: 0.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SvgPicture.asset(
            AppSvgIcons.activitiesSuggestionSparkle,
            width: 12,
            height: 12,
            colorFilter: ColorFilter.mode(topic.textColor, BlendMode.srcIn),
          ),
          const SizedBox(width: AppSpacing.xs),
          Text(
            topic.label,
            style: TextStyle(
              fontFamily: AppFontFamily.text,
              fontSize: AppFontSizes.xxs,
              fontWeight: AppFontWeights.medium,
              color: topic.textColor,
              height: 1.2,
            ),
          ),
        ],
      ),
    );
  }
}

const List<JournalTopic> kJournalTopics = [
  JournalTopic(
    id: 'anxiety',
    label: 'قلق',
    color: Color(0xFFE4E1F4),
    borderColor: AppPalettePurple.shade300,
    textColor: AppPalettePurple.shade100,
  ),
  JournalTopic(
    id: 'pressure',
    label: 'ضغط',
    color: Color(0xFFFEF3F2),
    borderColor: AppDangerColors.shade300,
    textColor: AppDangerColors.shade500,
  ),
  JournalTopic(
    id: 'beauty',
    label: 'لحظة جميلة',
    color: Color(0xFFFFF6D6),
    borderColor: AppPaletteButteryYellow.shade100,
    textColor: AppWarningColors.shade500,
  ),
  JournalTopic(
    id: 'happy',
    label: 'شي أسعدك',
    color: Color(0xFFFFFAEB),
    borderColor: AppWarningColors.shade300,
    textColor: AppWarningColors.shade500,
  ),
  JournalTopic(
    id: 'self_letter',
    label: 'رسالة للنفس',
    color: Color(0xFFECFDF3),
    borderColor: AppSuccessColors.shade300,
    textColor: AppSuccessColors.shade500,
  ),
  JournalTopic(
    id: 'vent',
    label: 'فضفضة',
    color: Color(0xFFF7F7F7),
    borderColor: AppNeutralColors.shade300,
    textColor: AppNeutralColors.shade500,
  ),
];

/// Returns the selected topic, or null if cancelled.
Future<JournalTopic?> showTopicPickerDialog(BuildContext context) {
  return showDialog<JournalTopic>(
    context: context,
    builder: (_) => Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 29.632),
      backgroundColor: context.colors.white,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.41)),
      child: const Directionality(
        textDirection: TextDirection.rtl,
        child: _TopicPickerContent(),
      ),
    ),
  );
}

class _TopicPickerContent extends StatefulWidget {
  const _TopicPickerContent();

  @override
  State<_TopicPickerContent> createState() => _TopicPickerContentState();
}

class _TopicPickerContentState extends State<_TopicPickerContent> {
  String? _selectedId;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: SvgPicture.asset(
              AppSvgIcons.activitiesJournalPicker,
              width: 68,
              height: 68,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'اختر موضوعًا للتدوين',
            textAlign: TextAlign.center,
            style: AppTextStyles.thmanyahHeading(context).copyWith(
              fontSize: 20.41,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'اختر موضوعًا يساعدك على بدء الكتابة',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: AppFontFamily.text,
              fontSize: AppFontSizes.xxs,
              fontWeight: AppFontWeights.regular,
              color: context.colors.shade500,
              height: 1.4,
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          _TopicGrid(
            selectedId: _selectedId,
            onSelect: (id) => setState(
              () => _selectedId = _selectedId == id ? null : id,
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          Row(
            children: [
              Expanded(
                child: _DialogPrimaryButton(
                  label: 'ابدأ بالتدوين',
                  enabled: _selectedId != null,
                  onTap: () {
                    final JournalTopic? selected = _selectedId == null
                        ? null
                        : kJournalTopics.firstWhere(
                            (t) => t.id == _selectedId);
                    Navigator.of(context).pop(selected);
                  },
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: _DialogSecondaryButton(
                  label: 'إلغاء',
                  onTap: () => Navigator.of(context).pop(),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _TopicGrid extends StatelessWidget {
  const _TopicGrid({required this.selectedId, required this.onSelect});

  final String? selectedId;
  final ValueChanged<String> onSelect;

  static const double _gap = 6;

  @override
  Widget build(BuildContext context) {
    Widget rowFor(List<JournalTopic> items) => Row(
          children: [
            for (int i = 0; i < items.length; i++) ...[
              if (i != 0) const SizedBox(width: _gap),
              Expanded(
                child: _TopicChip(
                  topic: items[i],
                  selected: selectedId == items[i].id,
                  onTap: () => onSelect(items[i].id),
                ),
              ),
            ],
          ],
        );
    return Column(
      children: [
        rowFor(kJournalTopics.sublist(0, 3)),
        const SizedBox(height: _gap),
        rowFor(kJournalTopics.sublist(3, 6)),
      ],
    );
  }
}

class _TopicChip extends StatelessWidget {
  const _TopicChip({
    required this.topic,
    required this.selected,
    required this.onTap,
  });

  final JournalTopic topic;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final BorderRadius radius = BorderRadius.circular(8);
    return SizedBox(
      height: 32,
      child: Material(
        // Pale chip fill glares on the dark dialog; moodFill deepens it to the
        // same hue in dark mode while leaving the light pastel untouched.
        color: context.moodFill(topic.color),
        borderRadius: radius,
        child: InkWell(
          onTap: onTap,
          borderRadius: radius,
          child: Container(
            alignment: Alignment.center,
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            decoration: BoxDecoration(
              borderRadius: radius,
              border: Border.all(
                color: selected ? context.colors.shade500 : topic.borderColor,
                width: 1,
              ),
            ),
            child: Text(
              topic.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontFamily: AppFontFamily.text,
                fontSize: AppFontSizes.xxs,
                fontWeight: selected
                    ? AppFontWeights.bold
                    : AppFontWeights.medium,
                color: context.colors.shade500,
                height: 1.2,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _DialogPrimaryButton extends StatelessWidget {
  const _DialogPrimaryButton({
    required this.label,
    required this.enabled,
    required this.onTap,
  });

  final String label;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final BorderRadius radius = BorderRadius.circular(AppRadius.lg);
    return Opacity(
      opacity: enabled ? 1.0 : 0.5,
      child: SizedBox(
        height: 40,
        child: Material(
          color: AppPalettePurple.shade200,
          borderRadius: radius,
          child: InkWell(
            onTap: enabled ? onTap : null,
            borderRadius: radius,
            child: Container(
              alignment: Alignment.center,
              child: Text(
                label,
                style: const TextStyle(
                  fontFamily: AppFontFamily.text,
                  fontSize: AppFontSizes.xs,
                  fontWeight: AppFontWeights.semibold,
                  color: AppNeutralColors.white,
                  height: 1.2,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _DialogSecondaryButton extends StatelessWidget {
  const _DialogSecondaryButton({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final BorderRadius radius = BorderRadius.circular(AppRadius.lg);
    return SizedBox(
      height: 40,
      child: Material(
        color: context.colors.white,
        borderRadius: radius,
        child: InkWell(
          onTap: onTap,
          borderRadius: radius,
          child: Container(
            alignment: Alignment.center,
            decoration: BoxDecoration(
              borderRadius: radius,
              border: Border.all(color: AppPalettePurple.shade200, width: 1),
            ),
            child: Text(
              label,
              style: const TextStyle(
                fontFamily: AppFontFamily.text,
                fontSize: AppFontSizes.xs,
                fontWeight: AppFontWeights.semibold,
                color: AppPalettePurple.shade200,
                height: 1.2,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
