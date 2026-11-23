import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

bool reduceMotion(BuildContext c) => MediaQuery.maybeDisableAnimationsOf(c) ?? false;

class Haptics {
  static void light() => HapticFeedback.lightImpact();
  static void medium() => HapticFeedback.mediumImpact();
  static void success() {
    HapticFeedback.mediumImpact();
    Future.delayed(const Duration(milliseconds: 90), HapticFeedback.heavyImpact);
  }
}

/// Scales down a touch while pressed.
class Pressable extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  const Pressable({super.key, required this.child, this.onTap});
  @override
  State<Pressable> createState() => _PressableState();
}

class _PressableState extends State<Pressable> {
  bool _down = false;
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: widget.onTap == null ? null : (_) => setState(() => _down = true),
      onTapCancel: () => setState(() => _down = false),
      onTapUp: (_) => setState(() => _down = false),
      onTap:
          widget.onTap == null
              ? null
              : () {
                Haptics.light();
                widget.onTap!();
              },
      child: AnimatedScale(scale: _down ? 0.97 : 1, duration: const Duration(milliseconds: 120), child: widget.child),
    );
  }
}

/// Fades and lifts its child in after [delay].
class EnterIn extends StatefulWidget {
  final Widget child;
  final Duration delay;
  final double dy;
  const EnterIn({super.key, required this.child, this.delay = Duration.zero, this.dy = 12});
  @override
  State<EnterIn> createState() => _EnterInState();
}

class _EnterInState extends State<EnterIn> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 380));
  @override
  void initState() {
    super.initState();
    Future.delayed(widget.delay, () => mounted ? _c.forward() : null);
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (reduceMotion(context)) return widget.child;
    final cu = CurvedAnimation(parent: _c, curve: Curves.easeOutCubic);
    return AnimatedBuilder(
      animation: cu,
      builder:
          (_, child) => Opacity(opacity: cu.value, child: Transform.translate(offset: Offset(0, widget.dy * (1 - cu.value)), child: child)),
      child: widget.child,
    );
  }
}

/// Double-beat pulse: 1 → 1.06 → 1 → 1.04 → 1, then rest (1.1 s).
class Heartbeat extends StatefulWidget {
  final Widget child;
  final bool active;
  final double strength;
  const Heartbeat({super.key, required this.child, this.active = true, this.strength = 1});
  @override
  State<Heartbeat> createState() => _HeartbeatState();
}

class _HeartbeatState extends State<Heartbeat> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 1100));

  @override
  void initState() {
    super.initState();
    if (widget.active) _c.repeat();
  }

  @override
  void didUpdateWidget(covariant Heartbeat old) {
    super.didUpdateWidget(old);
    if (widget.active && !_c.isAnimating) _c.repeat();
    if (!widget.active && _c.isAnimating) _c.stop();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  static double _beat(double t) {
    double bump(double c, double h) {
      final d = (t - c) / 0.1;
      return d.abs() > 1 ? 0 : h * (0.5 + 0.5 * cos(pi * d));
    }

    return bump(0.1, 0.06) + bump(0.32, 0.04);
  }

  @override
  Widget build(BuildContext context) {
    if (reduceMotion(context)) return widget.child;
    return AnimatedBuilder(
      animation: _c,
      builder: (_, child) => Transform.scale(scale: 1 + _beat(_c.value) * widget.strength, child: child),
      child: widget.child,
    );
  }
}

/// One-shot particle burst (hearts or confetti) over everything.
void playBurst(BuildContext context, {bool confetti = false, Offset? origin}) {
  if (reduceMotion(context)) return;
  final overlay = Overlay.of(context, rootOverlay: true);
  late OverlayEntry e;
  e = OverlayEntry(builder: (_) => IgnorePointer(child: _Burst(confetti: confetti, origin: origin, onDone: () => e.remove())));
  overlay.insert(e);
}

class _Burst extends StatefulWidget {
  final bool confetti;
  final Offset? origin;
  final VoidCallback onDone;
  const _Burst({required this.confetti, required this.origin, required this.onDone});
  @override
  State<_Burst> createState() => _BurstState();
}

class _BurstState extends State<_Burst> with SingleTickerProviderStateMixin {
  late final AnimationController _c;
  final _r = Random();
  late final List<List<double>> _p;
  static const _colors = [Color(0xFFFD445F), Color(0xFF2CB462), Color(0xFFF6B83C), Color(0xFFC8596C), Colors.white];

  @override
  void initState() {
    super.initState();
    _c = AnimationController(vsync: this, duration: Duration(milliseconds: widget.confetti ? 2400 : 1100))
      ..forward().whenComplete(widget.onDone);
    final n = widget.confetti ? 80 : 14;
    _p = List.generate(
      n,
      (i) => [
        widget.confetti ? -pi / 2 + (_r.nextDouble() - 0.5) * 1.6 : i / n * 2 * pi,
        widget.confetti ? 450 + _r.nextDouble() * 450 : 80 + _r.nextDouble() * 60,
        6 + _r.nextDouble() * 8,
        _r.nextDouble() * 0.15,
        (_r.nextDouble() - 0.5) * 10,
        i.toDouble(),
      ],
    );
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = MediaQuery.sizeOf(context);
    final o = widget.origin ?? Offset(s.width / 2, s.height / 2);
    return AnimatedBuilder(animation: _c, builder: (_, _) => CustomPaint(size: s, painter: _P(_p, _c.value, o, widget.confetti)));
  }
}

class _P extends CustomPainter {
  final List<List<double>> p;
  final double t;
  final Offset o;
  final bool confetti;
  _P(this.p, this.t, this.o, this.confetti);

  @override
  void paint(Canvas canvas, Size size) {
    for (final q in p) {
      final lt = ((t - q[3]) / (1 - q[3])).clamp(0.0, 1.0);
      if (lt <= 0) continue;
      final color = _BurstState._colors[q[5].toInt() % _BurstState._colors.length];
      final paint = Paint()..color = (confetti ? color : const Color(0xFFFD445F)).withValues(alpha: 1 - lt);
      if (confetti) {
        final x = o.dx + cos(q[0]) * q[1] * lt;
        final y = o.dy + sin(q[0]) * q[1] * lt + 800 * lt * lt;
        canvas.save();
        canvas.translate(x, y);
        canvas.rotate(q[4] * lt);
        canvas.drawRect(Rect.fromCenter(center: Offset.zero, width: q[2], height: q[2] * 0.5), paint);
        canvas.restore();
      } else {
        final e = Curves.easeOutCubic.transform(lt);
        final c = o + Offset(cos(q[0]), sin(q[0])) * q[1] * e;
        final sz = q[2];
        final path =
            Path()
              ..moveTo(c.dx, c.dy + sz * 0.35)
              ..cubicTo(c.dx - sz * 0.9, c.dy - sz * 0.25, c.dx - sz * 0.35, c.dy - sz * 0.85, c.dx, c.dy - sz * 0.3)
              ..cubicTo(c.dx + sz * 0.35, c.dy - sz * 0.85, c.dx + sz * 0.9, c.dy - sz * 0.25, c.dx, c.dy + sz * 0.35);
        canvas.drawPath(path, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _P old) => old.t != t;
}
