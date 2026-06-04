import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../constants/app_icons.dart';
import '../../core/auth/auth_service.dart';
import '../../core/journal/journal_store.dart';
import '../../models/journal_entry.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../theme/app_tokens.dart';
import '../../widgets/app_toast.dart';
import '../../widgets/nav/app_top_nav.dart';
import 'topic_picker_dialog.dart';

class WritingScreen extends StatefulWidget {
  const WritingScreen({
    super.key,
    this.entry,
    this.initialTitle,
    this.initialTopicId,
  });

  /// When provided, the screen opens in edit mode pre-populated with the
  /// entry's content and saving updates the existing entry in place.
  final JournalEntry? entry;

  /// Seed for the title field when creating a new entry (e.g. picked topic).
  /// Ignored if [entry] is also provided.
  final String? initialTitle;

  /// Topic id to attach to a newly-created entry. Only used when [entry] is
  /// null — existing entries keep their original topic.
  final String? initialTopicId;

  @override
  State<WritingScreen> createState() => _WritingScreenState();
}

class _WritingScreenState extends State<WritingScreen> {
  late final TextEditingController _titleController;
  late final QuillController _quillController;
  final FocusNode _bodyFocusNode = FocusNode();
  final ScrollController _editorScrollController = ScrollController();
  late bool _hasContent;

  @override
  void initState() {
    super.initState();
    final String seedTitle =
        widget.entry?.title ?? widget.initialTitle ?? '';
    _titleController = TextEditingController(text: seedTitle);
    _quillController = _buildQuillController();
    _hasContent = widget.entry != null || seedTitle.isNotEmpty;
    _titleController.addListener(_onTextChanged);
    _quillController.addListener(_onTextChanged);
  }

  /// Builds the editor controller from, in order of preference: the entry's
  /// rich [JournalEntry.bodyDelta] (Quill Delta JSON), then its plain [body]
  /// (old notes have no delta), then an empty document for a brand-new entry.
  QuillController _buildQuillController() {
    final List<dynamic>? delta = widget.entry?.bodyDelta;
    if (delta != null && delta.isNotEmpty) {
      try {
        return QuillController(
          document: Document.fromJson(delta),
          selection: const TextSelection.collapsed(offset: 0),
        );
      } catch (_) {
        // Malformed delta — fall back to the plain body below.
      }
    }
    final String plain = widget.entry?.body ?? '';
    if (plain.isNotEmpty) {
      final Document doc = Document()..insert(0, plain);
      return QuillController(
        document: doc,
        selection: TextSelection.collapsed(offset: doc.length - 1),
      );
    }
    return QuillController.basic();
  }

  @override
  void dispose() {
    _titleController.removeListener(_onTextChanged);
    _quillController.removeListener(_onTextChanged);
    _titleController.dispose();
    _quillController.dispose();
    _bodyFocusNode.dispose();
    _editorScrollController.dispose();
    super.dispose();
  }

  String get _bodyPlainText => _quillController.document.toPlainText().trim();

  void _onTextChanged() {
    final bool hasContent =
        _titleController.text.trim().isNotEmpty || _bodyPlainText.isNotEmpty;
    if (hasContent != _hasContent) {
      setState(() => _hasContent = hasContent);
    }
  }

  void _onSave() {
    // Journal entries save to the account — gated for guests (stay on the
    // screen so the user keeps their text instead of silently losing it).
    if (AuthService.isGuest) {
      showLoginRequiredToast(context);
      return;
    }
    // body = readable plain-text fallback; body_delta = the rich version.
    final String plain = _bodyPlainText;
    final List<dynamic> delta = _quillController.document.toDelta().toJson();
    final JournalEntry? existing = widget.entry;
    if (existing != null) {
      JournalStore.instance.update(
        id: existing.id,
        title: _titleController.text,
        body: plain,
        bodyDelta: delta,
      );
    } else {
      JournalStore.instance.add(
        title: _titleController.text,
        body: plain,
        topicId: widget.initialTopicId,
        bodyDelta: delta,
      );
    }
    Navigator.of(context).maybePop();
  }

  void _onBack() {
    // If editing an existing entry that's now empty, delete it.
    final JournalEntry? existing = widget.entry;
    if (existing != null && !_hasContent) {
      JournalStore.instance.remove(existing.id);
    }
    Navigator.of(context).maybePop();
  }

  /// Shows the entry's last-edit date when viewing an existing entry; for a
  /// brand-new entry there's nothing saved yet, so we show the current time.
  String _timestampLabel() {
    final JournalEntry? entry = widget.entry;
    return formatJournalTimestamp(entry?.updatedAt ?? DateTime.now());
  }

  @override
  Widget build(BuildContext context) {
    // The topic the entry was started from (new entry) or saved with (existing).
    final JournalTopic? topic =
        findJournalTopic(widget.entry?.topicId ?? widget.initialTopicId);
    return Scaffold(
      backgroundColor: context.colors.shade50,
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AppTopNav(
                title: '',
                onBack: _onBack,
                backButton: _hasContent
                    ? _SaveButton(onTap: _onSave)
                    : null,
              ),
              Expanded(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => _bodyFocusNode.requestFocus(),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.xxl,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const SizedBox(height: AppSpacing.lg),
                        // Pinned topic chip — aligned to the start (right in
                        // RTL) so it sits at the top-right of the page.
                        if (topic != null) ...[
                          Align(
                            alignment: AlignmentDirectional.centerStart,
                            child: JournalTopicChip(topic: topic),
                          ),
                          const SizedBox(height: AppSpacing.md),
                        ],
                        Text(
                          _timestampLabel(),
                          textAlign: TextAlign.right,
                          style: TextStyle(
                            fontFamily: AppFontFamily.text,
                            fontSize: AppFontSizes.xxs,
                            fontWeight: AppFontWeights.regular,
                            color: context.colors.shade400,
                            height: 1.4,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        TextField(
                          controller: _titleController,
                          textAlign: TextAlign.right,
                          textDirection: TextDirection.rtl,
                          textInputAction: TextInputAction.next,
                          style: AppTextStyles.thmanyahHeading(context).copyWith(
                            fontSize: AppFontSizes.md,
                          ),
                          decoration: InputDecoration(
                            hintText: 'إن رغبت، أضف تسمية',
                            hintStyle: TextStyle(
                              fontFamily: AppFontFamily.title,
                              fontSize: AppFontSizes.md,
                              fontWeight: AppFontWeights.bold,
                              color: context.colors.shade400,
                              height: 1.35,
                              fontFeatures: AppFontFamily.titleFeatures,
                            ),
                            border: InputBorder.none,
                            isDense: true,
                            contentPadding: EdgeInsets.zero,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        Expanded(
                          child: QuillEditor(
                            controller: _quillController,
                            focusNode: _bodyFocusNode,
                            scrollController: _editorScrollController,
                            config: QuillEditorConfig(
                              placeholder:
                                  'اكتب ما يدور في بالك .. بدون ترتيب أو حكم.',
                              padding: EdgeInsets.zero,
                              expands: true,
                              autoFocus: false,
                              customStyles: DefaultStyles(
                                paragraph: DefaultTextBlockStyle(
                                  TextStyle(
                                    fontFamily: AppFontFamily.text,
                                    fontSize: AppFontSizes.xs,
                                    fontWeight: AppFontWeights.regular,
                                    color: context.colors.shade600,
                                    height: 1.6,
                                  ),
                                  const HorizontalSpacing(0, 0),
                                  const VerticalSpacing(0, 0),
                                  const VerticalSpacing(0, 0),
                                  null,
                                ),
                                placeHolder: DefaultTextBlockStyle(
                                  TextStyle(
                                    fontFamily: AppFontFamily.text,
                                    fontSize: AppFontSizes.xs,
                                    fontWeight: AppFontWeights.regular,
                                    color: context.colors.shade400,
                                    height: 1.6,
                                  ),
                                  const HorizontalSpacing(0, 0),
                                  const VerticalSpacing(0, 0),
                                  const VerticalSpacing(0, 0),
                                  null,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              if (!_hasContent) const _PrivacyFooter(),
              // Rich-text formatting toolbar (flutter_quill). Sits at the bottom
              // so it floats just above the keyboard when open.
              _QuillToolbar(
                controller: _quillController,
                focusNode: _bodyFocusNode,
              ),
              const SizedBox(height: AppSpacing.md),
            ],
          ),
        ),
      ),
    );
  }
}

class _SaveButton extends StatelessWidget {
  const _SaveButton({required this.onTap});

  final VoidCallback onTap;

  static const double _size = 32;
  static const double _iconSize = 20;

  @override
  Widget build(BuildContext context) {
    // The save circle stays visually 32×32; a 44×44 hit area around it (outer
    // InkResponse, inner Material is visual-only) meets the accessibility
    // tap-target size without enlarging the button.
    return Semantics(
      button: true,
      label: 'حفظ',
      child: InkResponse(
        onTap: onTap,
        radius: 26,
        child: SizedBox(
          width: 44,
          height: 44,
          child: Center(
            child: Material(
              color: AppPalettePurple.shade200,
              shape: const CircleBorder(),
              shadowColor: const Color(0x1A101828),
              elevation: 1,
              child: SizedBox(
                width: _size,
                height: _size,
                child: Center(
                  child: SvgPicture.asset(
                    AppSvgIcons.activitiesJournalSave,
                    width: _iconSize,
                    height: _iconSize,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _PrivacyFooter extends StatelessWidget {
  const _PrivacyFooter();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(
        bottom: AppSpacing.lg,
        top: AppSpacing.md,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          SvgPicture.asset(
            AppSvgIcons.activitiesJournalPrivacy,
            width: 16,
            height: 16,
          ),
          const SizedBox(width: AppSpacing.xs),
          Text(
            'مساحتك خاصة، تقدر تحفظ أو تحذف في أي وقت',
            style: TextStyle(
              fontFamily: AppFontFamily.text,
              fontSize: AppFontSizes.xxs,
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

/// Soft text colors offered in the journal color picker. `null` clears any
/// color back to the default body color.
const List<String?> _kJournalTextColors = <String?>[
  null,
  '#5B6B8C',
  '#7C6BB0',
  '#4FA67A',
  '#C8911F',
  '#C76B8E',
];

/// Rich-text formatting bar for the journal body, driven by [QuillController].
/// Inline toggles (bold/italic/underline/color) + block toggles (heading,
/// bullet/numbered list) + undo/redo. Arabic semantic labels. Rebuilds on
/// selection changes so active buttons highlight subtly.
class _QuillToolbar extends StatefulWidget {
  const _QuillToolbar({required this.controller, required this.focusNode});

  final QuillController controller;
  final FocusNode focusNode;

  @override
  State<_QuillToolbar> createState() => _QuillToolbarState();
}

class _QuillToolbarState extends State<_QuillToolbar> {
  QuillController get _c => widget.controller;

  @override
  void initState() {
    super.initState();
    _c.addListener(_refresh);
  }

  @override
  void dispose() {
    _c.removeListener(_refresh);
    super.dispose();
  }

  void _refresh() {
    if (mounted) setState(() {});
  }

  Map<String, Attribute<dynamic>> get _attrs =>
      _c.getSelectionStyle().attributes;

  // ---- inline (bold / italic / underline) ----
  bool _isInlineActive(Attribute<dynamic> attr) => _attrs.containsKey(attr.key);

  void _toggleInline(Attribute<dynamic> attr) {
    final bool active = _isInlineActive(attr);
    _c.formatSelection(active ? Attribute.clone(attr, null) : attr);
    widget.focusNode.requestFocus();
  }

  // ---- lists (bullet / numbered) ----
  bool _isListActive(Attribute<dynamic> listAttr) {
    final Attribute<dynamic>? current = _attrs[Attribute.list.key];
    return current != null && current.value == listAttr.value;
  }

  void _toggleList(Attribute<dynamic> listAttr) {
    _c.formatSelection(
      _isListActive(listAttr) ? Attribute.clone(listAttr, null) : listAttr,
    );
    widget.focusNode.requestFocus();
  }

  // ---- heading (single level: h2) ----
  bool get _isHeadingActive => _attrs[Attribute.header.key]?.value != null;

  void _toggleHeading() {
    _c.formatSelection(
      _isHeadingActive ? Attribute.clone(Attribute.h2, null) : Attribute.h2,
    );
    widget.focusNode.requestFocus();
  }

  // ---- color ----
  void _applyColor(String? hex) {
    _c.formatSelection(
      hex == null ? Attribute.clone(Attribute.color, null) : ColorAttribute(hex),
    );
    widget.focusNode.requestFocus();
  }

  Future<void> _openColorPicker() async {
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Directionality(
        textDirection: TextDirection.rtl,
        child: Container(
          margin: const EdgeInsets.all(AppSpacing.md),
          padding: const EdgeInsets.all(AppSpacing.xl),
          decoration: BoxDecoration(
            color: context.colors.white,
            borderRadius: BorderRadius.circular(AppRadius.xl),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'لون النص',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: AppFontFamily.text,
                  fontSize: AppFontSizes.sm,
                  fontWeight: AppFontWeights.semibold,
                  color: context.colors.shade700,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Wrap(
                alignment: WrapAlignment.center,
                spacing: AppSpacing.md,
                runSpacing: AppSpacing.md,
                children: [
                  for (final String? hex in _kJournalTextColors)
                    _ColorSwatch(
                      hex: hex,
                      onTap: () {
                        Navigator.of(context).maybePop();
                        _applyColor(hex);
                      },
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: AppSpacing.xxl),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.xs,
        vertical: AppSpacing.xxs,
      ),
      decoration: BoxDecoration(
        color: context.colors.white,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: context.colors.shade300, width: 0.5),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _QuillToolButton(
              icon: Icons.undo_rounded,
              label: 'تراجع',
              onTap: () {
                _c.undo();
                widget.focusNode.requestFocus();
              },
            ),
            _QuillToolButton(
              icon: Icons.redo_rounded,
              label: 'إعادة',
              onTap: () {
                _c.redo();
                widget.focusNode.requestFocus();
              },
            ),
            _QuillToolButton(
              icon: Icons.format_bold_rounded,
              label: 'عريض',
              active: _isInlineActive(Attribute.bold),
              onTap: () => _toggleInline(Attribute.bold),
            ),
            _QuillToolButton(
              icon: Icons.format_italic_rounded,
              label: 'مائل',
              active: _isInlineActive(Attribute.italic),
              onTap: () => _toggleInline(Attribute.italic),
            ),
            _QuillToolButton(
              icon: Icons.format_underline_rounded,
              label: 'تحته خط',
              active: _isInlineActive(Attribute.underline),
              onTap: () => _toggleInline(Attribute.underline),
            ),
            _QuillToolButton(
              icon: Icons.title_rounded,
              label: 'حجم النص',
              active: _isHeadingActive,
              onTap: _toggleHeading,
            ),
            _QuillToolButton(
              icon: Icons.format_list_bulleted_rounded,
              label: 'قائمة نقطية',
              active: _isListActive(Attribute.ul),
              onTap: () => _toggleList(Attribute.ul),
            ),
            _QuillToolButton(
              icon: Icons.format_list_numbered_rounded,
              label: 'قائمة رقمية',
              active: _isListActive(Attribute.ol),
              onTap: () => _toggleList(Attribute.ol),
            ),
            _QuillToolButton(
              icon: Icons.format_color_text_rounded,
              label: 'لون النص',
              onTap: _openColorPicker,
            ),
          ],
        ),
      ),
    );
  }
}

class _QuillToolButton extends StatelessWidget {
  const _QuillToolButton({
    required this.icon,
    required this.label,
    required this.onTap,
    this.active = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool active;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      child: InkResponse(
        onTap: onTap,
        radius: 22,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 2),
          padding: const EdgeInsets.all(AppSpacing.sm),
          decoration: BoxDecoration(
            color: active ? AppPalettePurple.shade100 : Colors.transparent,
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
          child: ExcludeSemantics(
            child: Icon(
              icon,
              size: 20,
              color: active
                  ? AppPalettePurple.shade300
                  : context.colors.shade600,
            ),
          ),
        ),
      ),
    );
  }
}

class _ColorSwatch extends StatelessWidget {
  const _ColorSwatch({required this.hex, required this.onTap});

  /// `null` = clear / default color.
  final String? hex;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final Color? color =
        hex == null ? null : Color(int.parse('FF${hex!.substring(1)}', radix: 16));
    return Semantics(
      button: true,
      label: hex == null ? 'افتراضي' : 'لون',
      child: InkResponse(
        onTap: onTap,
        radius: 28,
        child: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: color ?? context.colors.white,
            shape: BoxShape.circle,
            border: Border.all(
              color: context.colors.shade300,
              width: 1,
            ),
          ),
          child: hex == null
              ? Icon(
                  Icons.format_color_reset_rounded,
                  size: 20,
                  color: context.colors.shade500,
                )
              : null,
        ),
      ),
    );
  }
}
