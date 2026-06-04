import 'dart:math' as math;
import 'dart:ui' show lerpDouble;

import 'package:flutter/foundation.dart' show ValueListenable;
import 'package:flutter/material.dart';

import '../../../theme/app_tokens.dart';

/// A calm, Siri-inspired voice visual: the existing Mishkat orb at the centre,
/// now reacting smoothly to the microphone level, wrapped in soft organic wave
/// rings and a blurred halo drawn with a [CustomPainter].
///
/// [amplitude] is a normalized 0..1 microphone level. It may be raw/jittery —
/// it is interpolated internally every frame so the motion stays fluid even
/// though the source updates only a few times per second.
class VoiceReactiveMicAnimation extends StatefulWidget {
  const VoiceReactiveMicAnimation({
    super.key,
    required this.amplitude,
    required this.isListening,
    this.size = 64,
    this.onTap,
  });

  final double amplitude;
  final bool isListening;

  /// Diameter of the central orb. The widget reserves extra room around it for
  /// the waves to breathe.
  final double size;
  final VoidCallback? onTap;

  @override
  State<VoiceReactiveMicAnimation> createState() =>
      _VoiceReactiveMicAnimationState();
}

class _VoiceReactiveMicAnimationState extends State<VoiceReactiveMicAnimation>
    with SingleTickerProviderStateMixin {
  // Slow free-running clock that drives wave motion and idle breathing.
  late final AnimationController _controller;

  // Smoothed microphone level (0..1). Updated every frame; the painter and orb
  // read it live without a setState per frame.
  final ValueNotifier<double> _level = ValueNotifier<double>(0);

  bool _reduced = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
    )..addListener(_onTick);
  }

  void _onTick() {
    final double target =
        widget.isListening ? widget.amplitude.clamp(0.0, 1.0) : 0.0;
    final double current = _level.value;
    // Asymmetric easing: rise a touch quicker than it settles back, so loud
    // moments feel responsive but the decay stays gentle and unhurried.
    final double factor = target > current ? 0.18 : 0.08;
    _level.value = lerpDouble(current, target, factor)!.clamp(0.0, 1.0);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _reduced = MediaQuery.of(context).disableAnimations;
    if (_reduced) {
      _controller.stop();
      _controller.value = 0;
      _level.value = widget.isListening ? widget.amplitude.clamp(0.0, 1.0) : 0;
    } else if (!_controller.isAnimating) {
      _controller.repeat();
    }
  }

  @override
  void didUpdateWidget(covariant VoiceReactiveMicAnimation oldWidget) {
    super.didUpdateWidget(oldWidget);
    // With motion disabled there is no per-frame tick, so mirror the level
    // directly from the incoming amplitude.
    if (_reduced) {
      _level.value = widget.isListening ? widget.amplitude.clamp(0.0, 1.0) : 0;
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_onTick);
    _controller.dispose();
    _level.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Footprint leaves room for the outer waves around the orb.
    final double box = math.max(widget.size * 2.6, 44);
    final Listenable repaint = Listenable.merge(<Listenable>[_controller, _level]);

    return Semantics(
      button: true,
      label: 'إيقاف التسجيل',
      child: GestureDetector(
        onTap: widget.onTap,
        behavior: HitTestBehavior.opaque,
        child: SizedBox(
          width: box,
          height: box,
          child: Stack(
            alignment: Alignment.center,
            children: <Widget>[
              // Waves + halo, drawn behind the orb.
              Positioned.fill(
                child: RepaintBoundary(
                  child: CustomPaint(
                    painter: _VoiceWavePainter(
                      repaint: repaint,
                      phase: _controller,
                      level: _level,
                      orbDiameter: widget.size,
                      reduced: _reduced,
                    ),
                  ),
                ),
              ),
              // Core orb — original gradient, now gently amplitude-reactive.
              AnimatedBuilder(
                animation: repaint,
                builder: (BuildContext context, Widget? child) {
                  final double phase = _controller.value * 2 * math.pi;
                  final double breath =
                      _reduced ? 0 : (math.sin(phase) * 0.5 + 0.5);
                  final double lvl = _level.value;
                  // Idle breathing 1.0..1.03, plus up to +0.10 from the voice.
                  final double scale = 1.0 + breath * 0.03 + lvl * 0.10;
                  return Transform.scale(scale: scale, child: child);
                },
                child: _orb(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _orb() {
    return Container(
      width: widget.size,
      height: widget.size,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: AppShadows.md,
        // Single flat colour (no gradient) per design.
        color: AppPalettePurple.shade300,
      ),
    );
  }
}

class _VoiceWavePainter extends CustomPainter {
  _VoiceWavePainter({
    required Listenable repaint,
    required this.phase,
    required this.level,
    required this.orbDiameter,
    required this.reduced,
  }) : super(repaint: repaint);

  final Animation<double> phase; // 0..1 free-running clock
  final ValueListenable<double> level; // 0..1 smoothed mic level
  final double orbDiameter;
  final bool reduced;

  // Number of concentric ripples emanating from the orb at once.
  static const int _ringCount = 3;
  // Ripple cycles per full revolution of the 6s clock (higher = quicker).
  static const double _rippleSpeed = 2.4;

  @override
  void paint(Canvas canvas, Size size) {
    final Offset center = size.center(Offset.zero);
    final double orbR = orbDiameter / 2;
    final double lvl = level.value;
    final double p = phase.value;
    final double maxAvail = size.shortestSide / 2;

    _paintGlow(canvas, center, orbR, lvl);
    _paintRipples(canvas, center, orbR, maxAvail, lvl, p);
  }

  // Soft, clean halo for depth behind the orb — never a hard ring.
  void _paintGlow(Canvas canvas, Offset c, double orbR, double lvl) {
    final double glowR = orbR * (1.25 + lvl * 0.55);
    final double strength = 0.12 + lvl * 0.20;
    final Rect rect = Rect.fromCircle(center: c, radius: glowR);
    final Paint paint = Paint()
      ..shader = RadialGradient(
        colors: <Color>[
          AppPalettePurple.shade400
              .withValues(alpha: (0.55 * strength).clamp(0.0, 1.0)),
          AppPalettePurple.shade400.withValues(alpha: 0.0),
        ],
        stops: const <double>[0.0, 1.0],
      ).createShader(rect)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10);
    canvas.drawCircle(c, glowR, paint);
  }

  // Clean concentric rings that expand outward from the orb and fade as they
  // travel — a calm, Siri-style ripple. The voice level pushes them farther
  // and brightens them; at rest they shimmer faintly.
  void _paintRipples(
    Canvas canvas,
    Offset c,
    double orbR,
    double maxAvail,
    double lvl,
    double p,
  ) {
    // Outer reach grows with the voice, clamped to the available footprint.
    final double reach = (orbR * (1.5 + lvl * 1.5)).clamp(orbR, maxAvail - 2);
    // Calm idle shimmer, livelier with the voice.
    final double baseAlpha = (0.12 + lvl * 0.45).clamp(0.0, 0.85);

    final double t = reduced ? 0 : p * _rippleSpeed;
    for (int i = 0; i < _ringCount; i++) {
      // Each ring is offset along the ripple cycle so they cascade outward.
      final double prog = (t + i / _ringCount) % 1.0;
      final double r = lerpDouble(orbR * 0.96, reach, prog)!;
      // Brightest just outside the orb, fading to nothing at the edge.
      final double alpha = (baseAlpha * (1.0 - prog)).clamp(0.0, 0.85);
      if (alpha <= 0.001) continue;
      canvas.drawCircle(
        c,
        r,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = lerpDouble(2.6, 0.8, prog)!
          ..color = AppPalettePurple.shade300.withValues(alpha: alpha)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 0.6),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _VoiceWavePainter oldDelegate) {
    return oldDelegate.orbDiameter != orbDiameter ||
        oldDelegate.reduced != reduced;
  }
}
