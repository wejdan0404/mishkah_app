import 'dart:async';
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../constants/app_play_images.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_tokens.dart';

class AiFloatingButton extends StatefulWidget {
  const AiFloatingButton({
    super.key,
    required this.onTap,
    this.label = 'اسأل مِشْكَاة',
    this.activeTab,
    this.tabIndex,
  });

  final VoidCallback onTap;
  final String label;

  /// The shell's currently-selected tab. When [tabIndex] becomes the active
  /// value, the label is revealed then collapses again. Leave null to reveal
  /// once on first mount.
  final ValueListenable<int>? activeTab;

  /// This button's owning tab index, matched against [activeTab].
  final int? tabIndex;

  @override
  State<AiFloatingButton> createState() => _AiFloatingButtonState();
}

class _AiFloatingButtonState extends State<AiFloatingButton>
    with SingleTickerProviderStateMixin {
  static const double _size = 44;
  static const double _radius = 21;
  static const double _imageSize = 32;
  static const double _blur = 12;
  static const double _rim = 1; // gradient rim-light thickness

  /// How long the label stays visible before it slides away.
  static const Duration _visibleDuration = Duration(seconds: 5);

  late final AnimationController _controller;
  late final Animation<double> _reveal;
  Timer? _collapseTimer;
  bool _initialRevealDone = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
      value: 0, // start collapsed; reveal is driven explicitly
    );
    _reveal = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
      reverseCurve: Curves.easeInOut,
    );

    widget.activeTab?.addListener(_onActiveTabChanged);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Reveal once on first mount if this tab is already the active one (or
    // there is no tab wiring at all — e.g. standalone usage). Done here rather
    // than in initState so MediaQuery (reduced-motion) is safe to read.
    if (_initialRevealDone) return;
    _initialRevealDone = true;
    if (widget.activeTab == null ||
        widget.activeTab!.value == widget.tabIndex) {
      _revealThenCollapse();
    }
  }

  void _onActiveTabChanged() {
    if (widget.activeTab!.value == widget.tabIndex) {
      _revealThenCollapse();
    }
  }

  /// Snap the label fully open, then slide it away after [_visibleDuration].
  void _revealThenCollapse() {
    _collapseTimer?.cancel();

    // Respect users who prefer reduced motion: skip the label entirely.
    if (MediaQuery.maybeOf(context)?.disableAnimations ?? false) {
      _controller.value = 0;
      return;
    }
    _controller.value = 1; // expanded, label visible
    _collapseTimer = Timer(_visibleDuration, () {
      if (mounted) _controller.reverse();
    });
  }

  @override
  void dispose() {
    widget.activeTab?.removeListener(_onActiveTabChanged);
    _collapseTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  /// Saturation-boost matrix applied to whatever shows through the glass, so
  /// the backdrop reads vivid behind the blur — the way Apple's system
  /// materials lift color rather than just frosting it.
  static List<double> _saturationMatrix(double s) {
    const double lr = 0.2126, lg = 0.7152, lb = 0.0722;
    return <double>[
      lr * (1 - s) + s, lg * (1 - s), lb * (1 - s), 0, 0,
      lr * (1 - s), lg * (1 - s) + s, lb * (1 - s), 0, 0,
      lr * (1 - s), lg * (1 - s), lb * (1 - s) + s, 0, 0,
      0, 0, 0, 1, 0,
    ];
  }

  @override
  Widget build(BuildContext context) {
    final outerRadius = BorderRadius.circular(_radius);
    final innerRadius = BorderRadius.circular(_radius - _rim);
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    // Glass tuned per theme: a frosted-white pill in light mode, a frosted
    // dark pill (close to the card surface) in dark mode so it doesn't glare.
    final List<Color> rimColors = isDark
        ? const [Color(0x4DFFFFFF), Color(0x0DFFFFFF)]
        : const [Color(0x99FFFFFF), Color(0x1AFFFFFF)];
    final Color glassColor =
        isDark ? const Color(0xCC262626) : const Color(0x59F5F5F5);
    final List<Color> sheenColors = isDark
        ? const [Color(0x1AFFFFFF), Color(0x00FFFFFF)]
        : const [Color(0x40FFFFFF), Color(0x00FFFFFF)];

    return Semantics(
      button: true,
      label: widget.label,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: outerRadius,
          boxShadow: const [
            BoxShadow(
              color: Color(0x14000000),
              offset: Offset(0, 3),
              blurRadius: 8,
            ),
            BoxShadow(
              color: Color(0x0D000000),
              offset: Offset(0, 1),
              blurRadius: 2,
            ),
          ],
        ),
        // Gradient "rim light": a 1px ring that is bright at the top edge and
        // fades toward the bottom, revealed by insetting the glass by _rim.
        child: Container(
          decoration: BoxDecoration(
            borderRadius: outerRadius,
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: rimColors,
            ),
          ),
          padding: const EdgeInsets.all(_rim),
          child: ClipRRect(
            borderRadius: innerRadius,
            child: BackdropFilter(
              filter: ImageFilter.compose(
                outer: ColorFilter.matrix(_saturationMatrix(1.6)),
                inner: ImageFilter.blur(sigmaX: _blur, sigmaY: _blur),
              ),
              child: Material(
                color: glassColor,
                borderRadius: innerRadius,
                clipBehavior: Clip.antiAlias,
                elevation: 0,
                child: InkWell(
                  onTap: widget.onTap,
                  borderRadius: innerRadius,
                  child: Stack(
                    children: [
                      // Glossy top sheen sitting on the glass, behind content.
                      Positioned.fill(
                        child: IgnorePointer(
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              borderRadius: innerRadius,
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.center,
                                colors: sheenColors,
                              ),
                            ),
                          ),
                        ),
                      ),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _buildImage(),
                          _buildAnimatedLabel(context),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildImage() {
    return const SizedBox(
      width: _size,
      height: _size,
      child: Center(
        child: Image(
          image: AssetImage(AppPlayImages.moodHappy),
          width: _imageSize,
          height: _imageSize,
          fit: BoxFit.cover,
        ),
      ),
    );
  }

  Widget _buildAnimatedLabel(BuildContext context) {
    return SizeTransition(
      axis: Axis.horizontal,
      axisAlignment: -1, // collapse toward the image side
      sizeFactor: _reveal,
      child: FadeTransition(
        opacity: _reveal,
        child: Padding(
          // 8px from the pill edge, 2px gap before the image.
          padding: const EdgeInsetsDirectional.only(
            start: 2,
            end: 8,
            top: 2,
            bottom: 2,
          ),
          child: Text(
            widget.label,
            textAlign: TextAlign.right,
            maxLines: 1,
            softWrap: false,
            overflow: TextOverflow.clip,
            style: TextStyle(
              fontFamily: AppFontFamily.text,
              fontSize: 12,
              fontWeight: FontWeight.w400,
              height: 1.0,
              color: context.colors.shade700,
            ),
          ),
        ),
      ),
    );
  }
}
