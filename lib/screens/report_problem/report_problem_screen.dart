import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../constants/app_icons.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../theme/app_tokens.dart';
import '../../widgets/buttons/app_button.dart';
import '../../widgets/cards/app_section_card.dart';
import '../../widgets/nav/app_top_nav.dart';
import '../auth/success_screen.dart';
import '../home/main_shell.dart';

class ReportProblemScreen extends StatefulWidget {
  const ReportProblemScreen({super.key});

  static const String routeName = '/report-problem';

  @override
  State<ReportProblemScreen> createState() => _ReportProblemScreenState();
}

class _ReportProblemScreenState extends State<ReportProblemScreen> {
  static const List<String> _typeOptions = [
    'خطأ تقني',
    'مشكلة في الحساب',
    'اقتراح',
    'أخرى',
  ];

  String? _selectedType;
  final TextEditingController _subjectController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  String? _attachmentName;

  String? _typeError;
  String? _subjectError;
  String? _descriptionError;

  static const String _requiredMessage = 'هذا الحقل مطلوب';

  @override
  void dispose() {
    _subjectController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _onTypeSelected(String value) {
    setState(() {
      _selectedType = value;
      _typeError = null;
    });
  }

  Future<void> _onPickAttachment() async {
    final _AttachmentSource? source = await _showAttachmentSourceSheet();
    if (source == null || !mounted) return;
    // Stub: no file_picker/image_picker package wired up yet.
    final String fakeName = switch (source) {
      _AttachmentSource.photos => 'image.jpg',
      _AttachmentSource.files => 'document.pdf',
    };
    setState(() => _attachmentName = fakeName);
  }

  Future<_AttachmentSource?> _showAttachmentSourceSheet() {
    final bool isIos = defaultTargetPlatform == TargetPlatform.iOS;
    if (isIos) {
      return showCupertinoModalPopup<_AttachmentSource>(
        context: context,
        builder: (popupContext) => CupertinoActionSheet(
          actions: [
            CupertinoActionSheetAction(
              onPressed: () => Navigator.of(popupContext)
                  .pop(_AttachmentSource.photos),
              child: const Text('الصور'),
            ),
            CupertinoActionSheetAction(
              onPressed: () => Navigator.of(popupContext)
                  .pop(_AttachmentSource.files),
              child: const Text('الملفات'),
            ),
          ],
          cancelButton: CupertinoActionSheetAction(
            isDestructiveAction: true,
            onPressed: () => Navigator.of(popupContext).pop(),
            child: const Text('إلغاء'),
          ),
        ),
      );
    }
    return showModalBottomSheet<_AttachmentSource>(
      context: context,
      backgroundColor: context.colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xxl)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _SheetTile(
                icon: Icons.photo_library_outlined,
                label: 'الصور',
                onTap: () => Navigator.of(sheetContext)
                    .pop(_AttachmentSource.photos),
              ),
              _SheetTile(
                icon: Icons.folder_outlined,
                label: 'الملفات',
                onTap: () => Navigator.of(sheetContext)
                    .pop(_AttachmentSource.files),
              ),
              const SizedBox(height: AppSpacing.md),
            ],
          ),
        );
      },
    );
  }

  void _onSubmit() {
    final String? typeError = _selectedType == null ? _requiredMessage : null;
    final String? subjectError = _subjectController.text.trim().isEmpty
        ? _requiredMessage
        : null;
    final String? descriptionError = _descriptionController.text.trim().isEmpty
        ? _requiredMessage
        : null;

    setState(() {
      _typeError = typeError;
      _subjectError = subjectError;
      _descriptionError = descriptionError;
    });

    if (typeError != null ||
        subjectError != null ||
        descriptionError != null) {
      return;
    }

    final NavigatorState navigator = Navigator.of(context);
    navigator.pushReplacement(
      MaterialPageRoute(
        builder: (_) => SuccessScreen(
          title: 'تـم استـلام بلاغـك!',
          subtitle:
              'شكرًا لمساهمتك في تحسين نظام مِشْكَاة،\n'
              'فريقنا راح يراجع المشكلة ويعمل على حلها بأقرب وقت.',
          buttonLabel: 'العودة لحسابي',
          onContinue: () => navigator.pushAndRemoveUntil(
            MaterialPageRoute(
              builder: (_) =>
                  const MainShell(initialIndex: MainShell.accountIndex),
              settings: const RouteSettings(name: '/home'),
            ),
            (_) => false,
          ),
        ),
      ),
    );
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
              const AppTopNav(title: 'الإبلاغ عن مشكلة'),
              const SizedBox(height: AppSpacing.xxxl),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.xxl,
                    0,
                    AppSpacing.xxl,
                    AppSpacing.xl,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      AppSectionCard(
                        padding: const EdgeInsets.all(AppSpacing.xxxl),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _FieldGroup(
                              label: 'نوع المشكلة',
                              required: true,
                              error: _typeError,
                              child: _DropdownField(
                                value: _selectedType,
                                placeholder: 'اختر نوع المشكلة',
                                options: _typeOptions,
                                onSelected: _onTypeSelected,
                                hasError: _typeError != null,
                              ),
                            ),
                            const SizedBox(height: AppSpacing.xl),
                            _FieldGroup(
                              label: 'موضوع المشكلة',
                              required: true,
                              error: _subjectError,
                              child: _TextField(
                                controller: _subjectController,
                                placeholder: 'اكتب موضوع المشكلة هنا ..',
                                textInputAction: TextInputAction.next,
                                hasError: _subjectError != null,
                              ),
                            ),
                            const SizedBox(height: AppSpacing.xl),
                            _FieldGroup(
                              label: 'وصف المشكلة',
                              required: true,
                              error: _descriptionError,
                              child: _TextField(
                                controller: _descriptionController,
                                placeholder:
                                    'اكتب تفاصيل المشكلة هنا ..\nمثلًا: متى ظهرت؟ وش صار؟ وهل تتكرر؟',
                                multiline: true,
                                minLines: 6,
                                maxLines: 6,
                                hasError: _descriptionError != null,
                              ),
                            ),
                            const SizedBox(height: AppSpacing.xl),
                            _FieldGroup(
                              label: 'إرفاق إثبات',
                              required: false,
                              child: _AttachmentDropZone(
                                attachmentName: _attachmentName,
                                onBrowse: _onPickAttachment,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.xxl,
                    AppSpacing.md,
                    AppSpacing.xxl,
                    AppSpacing.md,
                  ),
                  child: AppButton(
                    label: 'إرسال',
                    expand: true,
                    onPressed: _onSubmit,
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

enum _AttachmentSource { photos, files }

class _FieldGroup extends StatelessWidget {
  const _FieldGroup({
    required this.label,
    required this.child,
    this.required = false,
    this.error,
  });

  final String label;
  final Widget child;
  final bool required;
  final String? error;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _FieldLabel(label: label, required: required),
        const SizedBox(height: AppSpacing.lg),
        child,
        if (error != null) ...[
          const SizedBox(height: AppSpacing.xs),
          _ErrorMessage(message: error!),
        ],
      ],
    );
  }
}

class _ErrorMessage extends StatelessWidget {
  const _ErrorMessage({required this.message});

  final String message;

  static const double _iconSize = 16;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.error_outline,
            size: _iconSize,
            color: AppDangerColors.shade500,
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text(
              message,
              textAlign: TextAlign.right,
              style: const TextStyle(
                fontFamily: AppFontFamily.text,
                fontSize: AppFontSizes.xxs,
                fontWeight: AppFontWeights.regular,
                color: AppDangerColors.shade500,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel({required this.label, required this.required});

  final String label;
  final bool required;

  @override
  Widget build(BuildContext context) {
    final TextStyle baseStyle = AppTextStyles.thmanyahHeading(context).copyWith(
      fontSize: AppFontSizes.sm,
      color: context.colors.shade700,
      height: 1.2,
    );
    return Text.rich(
      TextSpan(
        text: label,
        style: baseStyle,
        children: [
          if (required)
            TextSpan(
              text: ' *',
              style: baseStyle.copyWith(color: AppDangerColors.shade500),
            ),
        ],
      ),
      textAlign: TextAlign.right,
    );
  }
}

class _DropdownField extends StatefulWidget {
  const _DropdownField({
    required this.value,
    required this.placeholder,
    required this.options,
    required this.onSelected,
    this.hasError = false,
  });

  final String? value;
  final String placeholder;
  final List<String> options;
  final ValueChanged<String> onSelected;
  final bool hasError;

  @override
  State<_DropdownField> createState() => _DropdownFieldState();
}

class _DropdownFieldState extends State<_DropdownField> {
  final LayerLink _link = LayerLink();
  OverlayEntry? _overlayEntry;
  bool _isOpen = false;

  @override
  void dispose() {
    _removeOverlay();
    super.dispose();
  }

  void _toggle() {
    if (_isOpen) {
      _close();
    } else {
      _open();
    }
  }

  void _open() {
    final RenderBox box = context.findRenderObject() as RenderBox;
    final Size fieldSize = box.size;
    _overlayEntry = OverlayEntry(
      builder: (overlayContext) {
        return Stack(
          children: [
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: _close,
              ),
            ),
            Positioned(
              width: fieldSize.width,
              child: CompositedTransformFollower(
                link: _link,
                showWhenUnlinked: false,
                offset: Offset(0, fieldSize.height + AppSpacing.xs),
                child: Directionality(
                  textDirection: TextDirection.rtl,
                  child: _DropdownMenu(
                    options: widget.options,
                    selected: widget.value,
                    onSelect: (option) {
                      widget.onSelected(option);
                      _close();
                    },
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
    Overlay.of(context).insert(_overlayEntry!);
    setState(() => _isOpen = true);
  }

  void _close() {
    _removeOverlay();
    if (mounted) setState(() => _isOpen = false);
  }

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  @override
  Widget build(BuildContext context) {
    final bool hasValue = widget.value != null && widget.value!.isNotEmpty;
    final Color textColor = hasValue
        ? context.colors.shade700
        : context.colors.shade400;
    final FontWeight weight = hasValue
        ? AppFontWeights.medium
        : AppFontWeights.regular;

    final BorderRadius radius = BorderRadius.circular(AppRadius.lg);
    final Border border = widget.hasError
        ? Border.all(color: AppDangerColors.shade500, width: 1)
        : Border.all(color: context.colors.shade200, width: 0.5);

    return CompositedTransformTarget(
      link: _link,
      child: Material(
        color: context.colors.white,
        borderRadius: radius,
        child: InkWell(
          onTap: _toggle,
          borderRadius: radius,
          child: Container(
            decoration: BoxDecoration(
              color: context.colors.white,
              borderRadius: radius,
              border: border,
            ),
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.xl,
              vertical: AppSpacing.xl,
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    hasValue ? widget.value! : widget.placeholder,
                    textAlign: TextAlign.right,
                    style: TextStyle(
                      fontFamily: AppFontFamily.text,
                      fontSize: AppFontSizes.xxs,
                      fontWeight: weight,
                      color: textColor,
                      height: 1.2,
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.xs),
                AnimatedRotation(
                  duration: const Duration(milliseconds: 180),
                  turns: _isOpen ? 0.5 : 0,
                  child: SvgPicture.asset(
                    AppSvgIcons.chevronDown,
                    width: 20,
                    height: 20,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DropdownMenu extends StatelessWidget {
  const _DropdownMenu({
    required this.options,
    required this.selected,
    required this.onSelect,
  });

  final List<String> options;
  final String? selected;
  final ValueChanged<String> onSelect;

  @override
  Widget build(BuildContext context) {
    final BorderRadius radius = BorderRadius.circular(AppRadius.lg);
    return Material(
      color: Colors.transparent,
      borderRadius: radius,
      child: Container(
        decoration: BoxDecoration(
          color: context.colors.white,
          borderRadius: radius,
          border: Border.all(color: context.colors.shade200, width: 0.5),
          boxShadow: AppShadows.sm,
        ),
        child: ClipRRect(
          borderRadius: radius,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (int i = 0; i < options.length; i++) ...[
                _DropdownMenuItem(
                  label: options[i],
                  isSelected: options[i] == selected,
                  onTap: () => onSelect(options[i]),
                ),
                if (i != options.length - 1)
                  Container(height: 0.5, color: context.colors.shade100),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _DropdownMenuItem extends StatelessWidget {
  const _DropdownMenuItem({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        color: isSelected ? AppPalettePurple.shade600 : null,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.xl,
          vertical: AppSpacing.lg,
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                textAlign: TextAlign.right,
                style: TextStyle(
                  fontFamily: AppFontFamily.text,
                  fontSize: AppFontSizes.xxs,
                  fontWeight: isSelected
                      ? AppFontWeights.semibold
                      : AppFontWeights.regular,
                  color: context.colors.shade700,
                  height: 1.4,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TextField extends StatelessWidget {
  const _TextField({
    required this.controller,
    required this.placeholder,
    this.multiline = false,
    this.minLines,
    this.maxLines,
    this.textInputAction,
    this.hasError = false,
  });

  final TextEditingController controller;
  final String placeholder;
  final bool multiline;
  final int? minLines;
  final int? maxLines;
  final TextInputAction? textInputAction;
  final bool hasError;

  @override
  Widget build(BuildContext context) {
    final BorderRadius radius = BorderRadius.circular(AppRadius.lg);
    final TextStyle textStyle = TextStyle(
      fontFamily: AppFontFamily.text,
      fontSize: AppFontSizes.xxs,
      fontWeight: AppFontWeights.regular,
      color: context.colors.shade700,
      height: 1.5,
    );
    final TextStyle hintStyle = textStyle.copyWith(
      color: context.colors.shade400,
    );

    final int resolvedMaxLines = multiline ? (maxLines ?? 6) : 1;
    final int resolvedMinLines = multiline
        ? (minLines ?? maxLines ?? 6)
        : 1;

    Widget buildField({List<TextInputFormatter>? formatters}) {
      return TextField(
        controller: controller,
        textAlign: TextAlign.right,
        textDirection: TextDirection.rtl,
        cursorColor: AppPalettePurple.shade300,
        maxLines: resolvedMaxLines,
        minLines: resolvedMinLines,
        keyboardType: multiline ? TextInputType.multiline : TextInputType.text,
        textInputAction: textInputAction,
        inputFormatters: formatters,
        style: textStyle,
        decoration: InputDecoration(
          hintText: placeholder,
          hintStyle: hintStyle,
          hintMaxLines: 3,
          isCollapsed: true,
          contentPadding: EdgeInsets.zero,
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
        ),
      );
    }

    // Multiline: cap input by *visible lines* (not characters), so typing
    // stops exactly when the 6-line box is full regardless of script.
    final Widget field = multiline
        ? LayoutBuilder(
            builder: (_, constraints) => buildField(
              formatters: [
                _MaxLinesInputFormatter(
                  maxLines: resolvedMaxLines,
                  textStyle: textStyle,
                  maxWidth: constraints.maxWidth,
                ),
              ],
            ),
          )
        : buildField();

    final Border border = hasError
        ? Border.all(color: AppDangerColors.shade500, width: 1)
        : Border.all(color: context.colors.shade200, width: 0.5);

    return Container(
      decoration: BoxDecoration(
        color: context.colors.white,
        borderRadius: radius,
        border: border,
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.xl,
        vertical: AppSpacing.xl,
      ),
      child: field,
    );
  }
}

class _MaxLinesInputFormatter extends TextInputFormatter {
  _MaxLinesInputFormatter({
    required this.maxLines,
    required this.textStyle,
    required this.maxWidth,
  });

  final int maxLines;
  final TextStyle textStyle;
  final double maxWidth;

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.text.isEmpty) return newValue;
    final TextPainter painter = TextPainter(
      text: TextSpan(text: newValue.text, style: textStyle),
      maxLines: maxLines,
      textDirection: TextDirection.rtl,
    )..layout(maxWidth: maxWidth);
    return painter.didExceedMaxLines ? oldValue : newValue;
  }
}

class _AttachmentDropZone extends StatelessWidget {
  const _AttachmentDropZone({
    required this.attachmentName,
    required this.onBrowse,
  });

  final String? attachmentName;
  final VoidCallback onBrowse;

  @override
  Widget build(BuildContext context) {
    return _DashedBorderBox(
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.xxxl,
          vertical: AppSpacing.xl,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SvgPicture.asset(AppSvgIcons.uploadAttach, width: 24, height: 24),
            const SizedBox(height: AppSpacing.xxxl),
            Text(
              attachmentName ??
                  'أقصى حجم للملف 2 ميجابايت، '
                      'والصيغ المدعومة .jpg و .png و .pdf',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: AppFontFamily.text,
                fontSize: AppFontSizes.xxs,
                fontWeight: AppFontWeights.regular,
                color: context.colors.shade400,
                height: 1.5,
              ),
            ),
            const SizedBox(height: AppSpacing.xxxl),
            _BrowseButton(onTap: onBrowse),
          ],
        ),
      ),
    );
  }
}

class _DashedBorderBox extends StatelessWidget {
  const _DashedBorderBox({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      foregroundPainter: _DashedRectPainter(
        color: context.colors.shade200,
        radius: AppRadius.xl,
        strokeWidth: 0.5,
        dashLength: 6,
        dashGap: 4,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppRadius.xl),
        child: Container(color: context.colors.shade50, child: child),
      ),
    );
  }
}

class _DashedRectPainter extends CustomPainter {
  _DashedRectPainter({
    required this.color,
    required this.radius,
    required this.strokeWidth,
    required this.dashLength,
    required this.dashGap,
  });

  final Color color;
  final double radius;
  final double strokeWidth;
  final double dashLength;
  final double dashGap;

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    final Path path = Path()
      ..addRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(0, 0, size.width, size.height),
          Radius.circular(radius),
        ),
      );

    for (final metric in path.computeMetrics()) {
      double distance = 0;
      while (distance < metric.length) {
        final double next = distance + dashLength;
        canvas.drawPath(
          metric.extractPath(distance, next.clamp(0, metric.length)),
          paint,
        );
        distance = next + dashGap;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DashedRectPainter oldDelegate) {
    return color != oldDelegate.color ||
        radius != oldDelegate.radius ||
        strokeWidth != oldDelegate.strokeWidth ||
        dashLength != oldDelegate.dashLength ||
        dashGap != oldDelegate.dashGap;
  }
}

class _BrowseButton extends StatelessWidget {
  const _BrowseButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final BorderRadius radius = BorderRadius.circular(AppRadius.md);
    return Material(
      color: context.colors.shade200,
      borderRadius: radius,
      child: InkWell(
        onTap: onTap,
        borderRadius: radius,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.md,
          ),
          child: Text(
            'تصفح الملفات',
            style: TextStyle(
              fontFamily: AppFontFamily.text,
              fontSize: AppFontSizes.xs,
              fontWeight: AppFontWeights.medium,
              color: context.colors.shade700,
              height: 1.2,
            ),
          ),
        ),
      ),
    );
  }
}

class _SheetTile extends StatelessWidget {
  const _SheetTile({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.xxl,
          vertical: AppSpacing.xl,
        ),
        child: Row(
          children: [
            Icon(icon, size: 22, color: context.colors.shade700),
            const SizedBox(width: AppSpacing.lg),
            Expanded(
              child: Text(
                label,
                textAlign: TextAlign.right,
                style: TextStyle(
                  fontFamily: AppFontFamily.text,
                  fontSize: AppFontSizes.sm,
                  fontWeight: AppFontWeights.medium,
                  color: context.colors.shade700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
