import 'dart:math';

import 'package:flutter/material.dart';
import 'package:onestop_ui/index.dart';

/// Coupon / ticket shape: rounded rect with semicircle notches on both sides
/// at [notchAt] (0..1 of height when vertical == false).
class TicketClipper extends CustomClipper<Path> {
  final double radius;
  final double notch;
  final double notchAt;
  final bool horizontalNotches;
  const TicketClipper({this.radius = 12, this.notch = 8, this.notchAt = 0.5, this.horizontalNotches = false});

  @override
  Path getClip(Size size) {
    final base = Path()..addRRect(RRect.fromRectAndRadius(Offset.zero & size, Radius.circular(radius)));
    final cut = Path();
    if (horizontalNotches) {
      final x = size.width * notchAt;
      cut
        ..addOval(Rect.fromCircle(center: Offset(x, 0), radius: notch))
        ..addOval(Rect.fromCircle(center: Offset(x, size.height), radius: notch));
    } else {
      final y = size.height * notchAt;
      cut
        ..addOval(Rect.fromCircle(center: Offset(0, y), radius: notch))
        ..addOval(Rect.fromCircle(center: Offset(size.width, y), radius: notch));
    }
    return Path.combine(PathOperation.difference, base, cut);
  }

  @override
  bool shouldReclip(covariant TicketClipper old) =>
      old.notchAt != notchAt || old.radius != radius || old.notch != notch;
}

class DashedLine extends StatelessWidget {
  final Color color;
  final Axis axis;
  final double dash;
  final double gap;
  const DashedLine({super.key, required this.color, this.axis = Axis.horizontal, this.dash = 5, this.gap = 4});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: axis == Axis.horizontal ? const Size(double.infinity, 1) : const Size(1, double.infinity),
      painter: _DashPainter(color, axis, dash, gap),
    );
  }
}

class _DashPainter extends CustomPainter {
  final Color color;
  final Axis axis;
  final double dash, gap;
  _DashPainter(this.color, this.axis, this.dash, this.gap);

  @override
  void paint(Canvas canvas, Size size) {
    final p =
        Paint()
          ..color = color
          ..strokeWidth = 1;
    final len = axis == Axis.horizontal ? size.width : size.height;
    for (double i = 0; i < len; i += dash + gap) {
      if (axis == Axis.horizontal) {
        canvas.drawLine(Offset(i, 0), Offset(min(i + dash, len), 0), p);
      } else {
        canvas.drawLine(Offset(0, i), Offset(0, min(i + dash, len)), p);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DashPainter old) => old.color != color;
}

/// Blood-drop path in a [size] box (tip at top-centre).
Path dropPath(Size s) {
  final w = s.width, h = s.height;
  return Path()
    ..moveTo(w / 2, 0)
    ..cubicTo(w * 0.5, 0, w * 0.98, h * 0.48, w * 0.98, h * 0.66)
    ..arcToPoint(Offset(w * 0.02, h * 0.66), radius: Radius.circular(w * 0.48), clockwise: true)
    ..cubicTo(w * 0.02, h * 0.48, w * 0.5, 0, w / 2, 0)
    ..close();
}

class DropShape extends StatelessWidget {
  final double size;
  final Color color;
  final Widget? child;
  const DropShape({super.key, this.size = 24, required this.color, this.child});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size * 0.78,
      height: size,
      child: CustomPaint(
        painter: _DropPainter(color),
        child: child == null ? null : Padding(padding: EdgeInsets.only(top: size * 0.3), child: Center(child: child)),
      ),
    );
  }
}

class _DropPainter extends CustomPainter {
  final Color color;
  _DropPainter(this.color);
  @override
  void paint(Canvas canvas, Size size) => canvas.drawPath(dropPath(size), Paint()..color = color);
  @override
  bool shouldRepaint(covariant _DropPainter old) => old.color != color;
}

/// A drop that fills from the bottom with a moving liquid surface.
class LiquidDrop extends StatefulWidget {
  final double fill; // 0..1
  final double height;
  final Color color;
  final Color empty;
  final Widget? child;
  const LiquidDrop({
    super.key,
    required this.fill,
    this.height = 160,
    required this.color,
    required this.empty,
    this.child,
  });

  @override
  State<LiquidDrop> createState() => _LiquidDropState();
}

class _LiquidDropState extends State<LiquidDrop> with SingleTickerProviderStateMixin {
  late final AnimationController _wave = AnimationController(vsync: this, duration: const Duration(milliseconds: 2200))
    ..repeat();

  @override
  void dispose() {
    _wave.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(end: widget.fill),
      duration: const Duration(milliseconds: 700),
      curve: Curves.easeOutCubic,
      builder:
          (_, f, _) => AnimatedBuilder(
            animation: _wave,
            builder:
                (_, _) => SizedBox(
                  width: widget.height * 0.78,
                  height: widget.height,
                  child: CustomPaint(
                    painter: _LiquidPainter(f, _wave.value, widget.color, widget.empty),
                    child:
                        widget.child == null
                            ? null
                            : Padding(
                              padding: EdgeInsets.only(top: widget.height * 0.32),
                              child: Center(child: widget.child),
                            ),
                  ),
                ),
          ),
    );
  }
}

class _LiquidPainter extends CustomPainter {
  final double fill, t;
  final Color color, empty;
  _LiquidPainter(this.fill, this.t, this.color, this.empty);

  @override
  void paint(Canvas canvas, Size size) {
    final drop = dropPath(size);
    canvas.drawPath(drop, Paint()..color = empty);
    canvas.save();
    canvas.clipPath(drop);
    final level = size.height * (1 - fill);
    final amp = fill <= 0 || fill >= 1 ? 0.0 : 5.0;
    final wave = Path()..moveTo(0, size.height);
    for (double x = 0; x <= size.width; x += 2) {
      wave.lineTo(x, level + sin((x / size.width * 2 * pi) + t * 2 * pi) * amp);
    }
    wave
      ..lineTo(size.width, size.height)
      ..close();
    canvas.drawPath(wave, Paint()..color = color);
    // Highlight.
    canvas.drawOval(
      Rect.fromLTWH(size.width * 0.22, size.height * 0.48, size.width * 0.14, size.height * 0.2),
      Paint()..color = Colors.white.withValues(alpha: 0.28),
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _LiquidPainter old) => old.fill != fill || old.t != t;
}

/// ECG watermark line that drifts through the card.
class EcgLine extends StatefulWidget {
  final Color color;
  final double height;
  const EcgLine({super.key, required this.color, this.height = 60});

  @override
  State<EcgLine> createState() => _EcgLineState();
}

class _EcgLineState extends State<EcgLine> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 2600))
    ..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _c,
        builder:
            (_, _) =>
                CustomPaint(size: Size(double.infinity, widget.height), painter: _EcgPainter(widget.color, _c.value)),
      ),
    );
  }
}

class _EcgPainter extends CustomPainter {
  final Color color;
  final double t;
  _EcgPainter(this.color, this.t);

  double _y(double u) {
    // One beat per 0..1 unit.
    final f = u - u.floorToDouble();
    if (f < 0.40) return 0;
    if (f < 0.44) return -0.15;
    if (f < 0.47) return 0.1;
    if (f < 0.50) return -1.0;
    if (f < 0.53) return 0.55;
    if (f < 0.57) return 0;
    if (f < 0.66) return -0.22 * sin((f - 0.57) / 0.09 * pi);
    return 0;
  }

  @override
  void paint(Canvas canvas, Size size) {
    final p =
        Paint()
          ..color = color
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2
          ..strokeJoin = StrokeJoin.round;
    final path = Path();
    const beatW = 180.0;
    final mid = size.height / 2;
    for (double x = 0; x <= size.width; x += 2) {
      final u = (x / beatW) - t;
      final y = mid + _y(u) * size.height * 0.45;
      x == 0 ? path.moveTo(x, y) : path.lineTo(x, y);
    }
    canvas.drawPath(path, p);
  }

  @override
  bool shouldRepaint(covariant _EcgPainter old) => old.t != t;
}

/// Circular initials avatar.
class InitialsAvatar extends StatelessWidget {
  final String initials;
  final Color tint;
  final double size;
  final Color? ring;
  const InitialsAvatar({super.key, required this.initials, required this.tint, this.size = 40, this.ring});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: tint.withValues(alpha: 0.16),
        border: ring == null ? null : Border.all(color: ring!, width: 2),
      ),
      alignment: Alignment.center,
      child: Text(
        initials,
        style: OTextStyle.labelSmall.copyWith(color: tint, fontSize: size * 0.34, fontWeight: FontWeight.w700),
      ),
    );
  }
}

/// Progress ring with an optional centre child.
class Ring extends StatelessWidget {
  final double value;
  final double size;
  final double stroke;
  final Color color;
  final Color track;
  final Widget? child;
  const Ring({
    super.key,
    required this.value,
    this.size = 56,
    this.stroke = 5,
    required this.color,
    required this.track,
    this.child,
  });

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(end: value),
      duration: const Duration(milliseconds: 900),
      curve: Curves.easeOutCubic,
      builder:
          (_, v, c) => SizedBox(
            width: size,
            height: size,
            child: CustomPaint(painter: _RingPainter(v, stroke, color, track), child: Center(child: c)),
          ),
      child: child,
    );
  }
}

class _RingPainter extends CustomPainter {
  final double v, stroke;
  final Color color, track;
  _RingPainter(this.v, this.stroke, this.color, this.track);

  @override
  void paint(Canvas canvas, Size size) {
    final r = Rect.fromLTWH(stroke / 2, stroke / 2, size.width - stroke, size.height - stroke);
    final base =
        Paint()
          ..color = track
          ..style = PaintingStyle.stroke
          ..strokeWidth = stroke;
    canvas.drawArc(r, 0, 2 * pi, false, base);
    canvas.drawArc(
      r,
      -pi / 2,
      2 * pi * v,
      false,
      base
        ..color = color
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(covariant _RingPainter old) => old.v != v || old.color != color;
}

/// Small rounded chip used on crimson and white surfaces.
class PChip extends StatelessWidget {
  final String text;
  final IconData? icon;
  final Color bg;
  final Color fg;
  final EdgeInsets padding;
  const PChip({
    super.key,
    required this.text,
    this.icon,
    required this.bg,
    required this.fg,
    this.padding = const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(OCornerRadius.xl)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[Icon(icon, size: 14, color: fg), const SizedBox(width: 4)],
          Text(text, style: OTextStyle.labelXSmall.copyWith(color: fg, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
