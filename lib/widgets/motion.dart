import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/pulse_tokens.dart';

/// Haptics wrapper (named per spec: light for ticks, medium for arrival,
/// success pattern for accept / donated / full house).
class Haptics {
  static void light() => HapticFeedback.lightImpact();
  static void medium() => HapticFeedback.mediumImpact();
  static Future<void> success() async {
    HapticFeedback.mediumImpact();
    await Future.delayed(const Duration(milliseconds: 90));
    HapticFeedback.heavyImpact();
  }
}

bool reduceMotion(BuildContext context) => MediaQuery.maybeDisableAnimationsOf(context) ?? false;

/// Heartbeat: 1.00 → 1.06 → 1.00 → 1.04 → 1.00, then rest. 1100 ms loop.
class Heartbeat extends StatefulWidget {
  final Widget child;
  final bool active;
  final double strength;
  final Duration period;
  const Heartbeat({
    super.key,
    required this.child,
    this.active = true,
    this.strength = 1,
    this.period = PulseMotion.heartbeat,
  });

  @override
  State<Heartbeat> createState() => _HeartbeatState();
}

class _HeartbeatState extends State<Heartbeat> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: widget.period);

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

  static double beat(double t) {
    // Two quick pulses in the first 45% of the cycle, then rest.
    double bump(double x, double c, double w, double h) {
      final d = (x - c) / w;
      return d.abs() > 1 ? 0 : h * (0.5 + 0.5 * cos(pi * d));
    }

    return bump(t, 0.10, 0.10, 0.06) + bump(t, 0.32, 0.10, 0.04);
  }

  @override
  Widget build(BuildContext context) {
    if (reduceMotion(context)) return widget.child;
    return AnimatedBuilder(
      animation: _c,
      builder: (_, child) => Transform.scale(scale: 1 + beat(_c.value) * widget.strength, child: child),
      child: widget.child,
    );
  }
}

/// Slow sine "breath" used for calm states.
class Breath extends StatefulWidget {
  final Widget Function(BuildContext, double) builder;
  const Breath({super.key, required this.builder});

  @override
  State<Breath> createState() => _BreathState();
}

class _BreathState extends State<Breath> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: PulseMotion.breath)..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (reduceMotion(context)) return widget.builder(context, 0.5);
    return AnimatedBuilder(animation: _c, builder: (ctx, _) => widget.builder(ctx, 0.5 + 0.5 * sin(_c.value * 2 * pi)));
  }
}

/// Scales down slightly while pressed (micro token).
class Pressable extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final double scale;
  const Pressable({super.key, required this.child, this.onTap, this.scale = 0.97});

  @override
  State<Pressable> createState() => _PressableState();
}

class _PressableState extends State<Pressable> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) => setState(() => _down = true),
      onTapCancel: () => setState(() => _down = false),
      onTapUp: (_) => setState(() => _down = false),
      onTap:
          widget.onTap == null
              ? null
              : () {
                Haptics.light();
                widget.onTap!();
              },
      child: AnimatedScale(
        scale: _down ? widget.scale : 1,
        duration: PulseMotion.micro,
        curve: Curves.easeOut,
        child: widget.child,
      ),
    );
  }
}

/// Fades + slides a child in after [delay] (stagger helper).
class EnterIn extends StatefulWidget {
  final Widget child;
  final Duration delay;
  final Offset from;
  final Duration duration;
  final Curve curve;
  const EnterIn({
    super.key,
    required this.child,
    this.delay = Duration.zero,
    this.from = const Offset(0, 16),
    this.duration = PulseMotion.emphasis,
    this.curve = PulseMotion.springCurve,
  });

  @override
  State<EnterIn> createState() => _EnterInState();
}

class _EnterInState extends State<EnterIn> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: widget.duration);

  @override
  void initState() {
    super.initState();
    Future.delayed(widget.delay, () {
      if (mounted) _c.forward();
    });
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (reduceMotion(context)) return widget.child;
    final curved = CurvedAnimation(parent: _c, curve: widget.curve);
    return AnimatedBuilder(
      animation: _c,
      builder:
          (_, child) => Opacity(
            opacity: _c.value.clamp(0, 1),
            child: Transform.translate(offset: Offset.lerp(widget.from, Offset.zero, curved.value)!, child: child),
          ),
      child: widget.child,
    );
  }
}

/// Animated integer counter (hub stats).
class CountUp extends StatelessWidget {
  final int value;
  final TextStyle style;
  final Duration duration;
  const CountUp({
    super.key,
    required this.value,
    required this.style,
    this.duration = const Duration(milliseconds: 1200),
  });

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: value.toDouble()),
      duration: duration,
      curve: Curves.easeOutCubic,
      builder: (_, v, _) => Text(v.round().toString(), style: style),
    );
  }
}
