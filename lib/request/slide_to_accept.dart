import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';
import 'package:onestop_ui/index.dart';

import '../theme/pulse_tokens.dart';
import '../widgets/motion.dart';

/// Swipe-to-commit pill. The heart rides the thumb, a trail fills behind it,
/// past 85% it springs to the end and fires [onCommit].
/// With OS reduce-motion it becomes a 1-second hold button.
class SlideToAccept extends StatefulWidget {
  final String label;
  final VoidCallback onCommit;
  final bool onCrimson;
  const SlideToAccept({super.key, this.label = 'Slide to say yes', required this.onCommit, this.onCrimson = true});

  @override
  State<SlideToAccept> createState() => _SlideToAcceptState();
}

class _SlideToAcceptState extends State<SlideToAccept> with TickerProviderStateMixin {
  static const double _h = 60;
  static const double _pad = 5;
  double _x = 0; // 0..1
  bool _done = false;
  late final AnimationController _spring = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 420),
  );
  late final AnimationController _shimmer = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1800),
  )..repeat();
  late final AnimationController _hold = AnimationController(vsync: this, duration: const Duration(seconds: 1));
  Animation<double>? _back;

  @override
  void initState() {
    super.initState();
    _spring.addListener(() {
      if (_back != null) setState(() => _x = _back!.value);
    });
    _hold.addStatusListener((s) {
      if (s == AnimationStatus.completed) _commit();
    });
  }

  @override
  void dispose() {
    _spring.dispose();
    _shimmer.dispose();
    _hold.dispose();
    super.dispose();
  }

  void _commit() {
    if (_done) return;
    setState(() {
      _done = true;
      _x = 1;
    });
    Haptics.success();
    Future.delayed(const Duration(milliseconds: 180), widget.onCommit);
  }

  void _release() {
    if (_done) return;
    if (_x > 0.85) {
      _back = Tween(begin: _x, end: 1.0).animate(CurvedAnimation(parent: _spring, curve: Curves.easeOut));
      _spring.forward(from: 0).whenComplete(_commit);
    } else {
      _back = Tween(begin: _x, end: 0.0).animate(CurvedAnimation(parent: _spring, curve: Curves.elasticOut));
      _spring.forward(from: 0);
    }
  }

  @override
  Widget build(BuildContext context) {
    final onCrimson = widget.onCrimson;
    final track = onCrimson ? Colors.white.withValues(alpha: 0.18) : PulseColors.blush;
    final trail = onCrimson ? Colors.white.withValues(alpha: 0.28) : PulseColors.crimson.withValues(alpha: 0.22);
    final labelColor = onCrimson ? Colors.white : PulseColors.deep;
    final thumbBg = onCrimson ? Colors.white : PulseColors.crimson;
    final heart = onCrimson ? PulseColors.crimson : Colors.white;

    if (reduceMotion(context)) {
      return GestureDetector(
        onTapDown: (_) => _hold.forward(from: 0),
        onTapUp: (_) => _hold.isCompleted ? null : _hold.reverse(),
        onTapCancel: () => _hold.reverse(),
        child: AnimatedBuilder(
          animation: _hold,
          builder:
              (_, _) => Container(
                height: _h,
                decoration: BoxDecoration(color: track, borderRadius: BorderRadius.circular(OCornerRadius.xl)),
                child: Stack(
                  children: [
                    FractionallySizedBox(
                      widthFactor: _hold.value,
                      child: Container(
                        decoration: BoxDecoration(color: trail, borderRadius: BorderRadius.circular(OCornerRadius.xl)),
                      ),
                    ),
                    Center(
                      child: Text("Hold: Yes, I'll donate", style: OTextStyle.labelMedium.copyWith(color: labelColor)),
                    ),
                  ],
                ),
              ),
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, c) {
        final w = c.maxWidth;
        final thumb = _h - _pad * 2;
        final travel = w - thumb - _pad * 2;
        final left = _pad + travel * _x;
        return Semantics(
          button: true,
          label: widget.label,
          onTap: _commit,
          child: GestureDetector(
            onHorizontalDragUpdate: (d) {
              if (_done) return;
              setState(() => _x = (_x + d.delta.dx / travel).clamp(0.0, 1.0));
            },
            onHorizontalDragEnd: (_) => _release(),
            child: Container(
              height: _h,
              decoration: BoxDecoration(color: track, borderRadius: BorderRadius.circular(OCornerRadius.xl)),
              child: Stack(
                children: [
                  // Trail
                  Positioned(
                    left: 0,
                    top: 0,
                    bottom: 0,
                    width: left + thumb + _pad,
                    child: Container(
                      decoration: BoxDecoration(color: trail, borderRadius: BorderRadius.circular(OCornerRadius.xl)),
                    ),
                  ),
                  // Label with shimmer
                  Positioned.fill(
                    child: Opacity(
                      opacity: (1 - _x * 1.6).clamp(0.0, 1.0),
                      child: AnimatedBuilder(
                        animation: _shimmer,
                        builder:
                            (_, child) => ShaderMask(
                              blendMode: BlendMode.srcIn,
                              shaderCallback:
                                  (r) => LinearGradient(
                                    colors: [
                                      labelColor.withValues(alpha: 0.55),
                                      labelColor,
                                      labelColor.withValues(alpha: 0.55),
                                    ],
                                    stops: const [0.0, 0.5, 1.0],
                                    begin: Alignment(-3 + _shimmer.value * 6 - 1, 0),
                                    end: Alignment(-3 + _shimmer.value * 6 + 1, 0),
                                  ).createShader(r),
                              child: child,
                            ),
                        child: Padding(
                          padding: EdgeInsets.only(left: thumb * 0.8),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                widget.label,
                                style: OTextStyle.labelMedium.copyWith(color: labelColor, fontWeight: FontWeight.w600),
                              ),
                              const SizedBox(width: 6),
                              Icon(FluentIcons.chevron_double_right_20_filled, size: 18, color: labelColor),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  // Done label
                  if (_done)
                    Center(
                      child: EnterIn(
                        from: const Offset(0, 8),
                        duration: PulseMotion.standard,
                        child: Text(
                          "You're in!",
                          style: OTextStyle.labelMedium.copyWith(color: labelColor, fontWeight: FontWeight.w700),
                        ),
                      ),
                    ),
                  // Thumb
                  Positioned(
                    left: left,
                    top: _pad,
                    child: Container(
                      width: thumb,
                      height: thumb,
                      decoration: BoxDecoration(
                        color: thumbBg,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.12),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Heartbeat(
                        active: !_done && _x == 0,
                        strength: 1.6,
                        child: Icon(
                          _done ? FluentIcons.checkmark_24_filled : FluentIcons.heart_24_filled,
                          color: heart,
                          size: 24,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
