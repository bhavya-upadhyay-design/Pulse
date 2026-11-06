import 'dart:math';

import 'package:flutter/material.dart';

import 'motion.dart';
import 'shapes.dart';

enum BurstKind { hearts, confetti, dropsToHearts }

/// Plays a one-shot particle effect above everything, then removes itself.
void playBurst(BuildContext context, BurstKind kind, {Offset? origin, int count = 0}) {
  if (reduceMotion(context)) return;
  final overlay = Overlay.of(context, rootOverlay: true);
  late OverlayEntry entry;
  entry = OverlayEntry(
    builder:
        (_) => IgnorePointer(child: _Burst(kind: kind, origin: origin, count: count, onDone: () => entry.remove())),
  );
  overlay.insert(entry);
}

class _Particle {
  final double angle, speed, size, spin, delay, drift;
  final Color color;
  final int shape; // 0 heart, 1 rect, 2 circle, 3 drop
  _Particle(this.angle, this.speed, this.size, this.spin, this.delay, this.drift, this.color, this.shape);
}

class _Burst extends StatefulWidget {
  final BurstKind kind;
  final Offset? origin;
  final int count;
  final VoidCallback onDone;
  const _Burst({required this.kind, this.origin, required this.count, required this.onDone});

  @override
  State<_Burst> createState() => _BurstState();
}

class _BurstState extends State<_Burst> with SingleTickerProviderStateMixin {
  late final AnimationController _c;
  late final List<_Particle> _ps;
  final _rng = Random();

  static const _confetti = [
    Color(0xFFDE1135),
    Color(0xFF148440),
    Color(0xFFF6B83C),
    Color(0xFF52E08B),
    Color(0xFFEF3354),
    Color(0xFF4D9AFE),
  ];

  @override
  void initState() {
    super.initState();
    final dur = switch (widget.kind) {
      BurstKind.hearts => 1100,
      BurstKind.confetti => 2600,
      BurstKind.dropsToHearts => 2800,
    };
    _c = AnimationController(vsync: this, duration: Duration(milliseconds: dur))..forward().whenComplete(widget.onDone);
    final n =
        widget.count > 0
            ? widget.count
            : switch (widget.kind) {
              BurstKind.hearts => 12,
              BurstKind.confetti => 90,
              BurstKind.dropsToHearts => 28,
            };
    _ps = List.generate(n, (i) {
      switch (widget.kind) {
        case BurstKind.hearts:
          return _Particle(
            i / n * 2 * pi + _rng.nextDouble() * 0.3,
            90 + _rng.nextDouble() * 70,
            12 + _rng.nextDouble() * 10,
            _rng.nextDouble() - 0.5,
            0,
            0,
            i.isEven ? const Color(0xFFDE1135) : const Color(0xFFEF3354),
            0,
          );
        case BurstKind.confetti:
          return _Particle(
            -pi / 2 + (_rng.nextDouble() - 0.5) * 1.6,
            500 + _rng.nextDouble() * 500,
            6 + _rng.nextDouble() * 6,
            (_rng.nextDouble() - 0.5) * 12,
            _rng.nextDouble() * 0.15,
            (_rng.nextDouble() - 0.5) * 120,
            _confetti[i % _confetti.length],
            i % 3 == 0 ? 2 : 1,
          );
        case BurstKind.dropsToHearts:
          return _Particle(
            0,
            0,
            14 + _rng.nextDouble() * 12,
            (_rng.nextDouble() - 0.5) * 2,
            _rng.nextDouble() * 0.45,
            _rng.nextDouble(),
            const Color(0xFFDE1135),
            3,
          );
      }
    });
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final origin = widget.origin ?? Offset(size.width / 2, size.height / 2);
    return AnimatedBuilder(
      animation: _c,
      builder: (_, _) => CustomPaint(size: size, painter: _BurstPainter(widget.kind, _ps, _c.value, origin, size)),
    );
  }
}

class _BurstPainter extends CustomPainter {
  final BurstKind kind;
  final List<_Particle> ps;
  final double t;
  final Offset origin;
  final Size screen;
  _BurstPainter(this.kind, this.ps, this.t, this.origin, this.screen);

  void _heart(Canvas c, Offset o, double s, Paint p) {
    final path =
        Path()
          ..moveTo(o.dx, o.dy + s * 0.35)
          ..cubicTo(o.dx - s * 0.9, o.dy - s * 0.25, o.dx - s * 0.35, o.dy - s * 0.85, o.dx, o.dy - s * 0.3)
          ..cubicTo(o.dx + s * 0.35, o.dy - s * 0.85, o.dx + s * 0.9, o.dy - s * 0.25, o.dx, o.dy + s * 0.35)
          ..close();
    c.drawPath(path, p);
  }

  @override
  void paint(Canvas canvas, Size size) {
    for (final p in ps) {
      final lt = ((t - p.delay) / (1 - p.delay)).clamp(0.0, 1.0);
      if (lt <= 0) continue;
      final paint = Paint()..color = p.color.withValues(alpha: (1 - Curves.easeIn.transform(lt)).clamp(0, 1));
      switch (kind) {
        case BurstKind.hearts:
          final e = Curves.easeOutCubic.transform(lt);
          final o = origin + Offset(cos(p.angle), sin(p.angle)) * p.speed * e + Offset(0, -20 * e);
          _heart(canvas, o, p.size * (0.6 + 0.4 * (1 - lt)), paint);
        case BurstKind.confetti:
          final x = origin.dx + cos(p.angle) * p.speed * lt + p.drift * lt;
          final y = origin.dy + sin(p.angle) * p.speed * lt + 900 * lt * lt;
          canvas.save();
          canvas.translate(x, y);
          canvas.rotate(p.spin * lt);
          if (p.shape == 2) {
            canvas.drawCircle(Offset.zero, p.size / 2, paint);
          } else {
            canvas.drawRect(Rect.fromCenter(center: Offset.zero, width: p.size, height: p.size * 0.5), paint);
          }
          canvas.restore();
        case BurstKind.dropsToHearts:
          final x = p.drift * screen.width;
          final y = -40 + (screen.height * 0.75) * Curves.easeIn.transform(lt);
          final morph = lt > 0.55;
          final a = lt < 0.85 ? 1.0 : (1 - (lt - 0.85) / 0.15);
          final pp = Paint()..color = (morph ? const Color(0xFFEF3354) : p.color).withValues(alpha: a.clamp(0, 1));
          if (morph) {
            _heart(canvas, Offset(x, y), p.size, pp);
          } else {
            canvas.save();
            canvas.translate(x - p.size * 0.39, y - p.size / 2);
            canvas.drawPath(dropPath(Size(p.size * 0.78, p.size)), pp);
            canvas.restore();
          }
      }
    }
  }

  @override
  bool shouldRepaint(covariant _BurstPainter old) => old.t != t;
}
