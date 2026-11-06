import 'package:flutter/material.dart';

/// Odometer-style countdown: each digit rolls vertically when it changes.
class Odometer extends StatelessWidget {
  final Duration left;
  final TextStyle style;
  final bool showHours;
  const Odometer({super.key, required this.left, required this.style, this.showHours = true});

  @override
  Widget build(BuildContext context) {
    final h = left.inHours.toString().padLeft(2, '0');
    final m = (left.inMinutes % 60).toString().padLeft(2, '0');
    final s = (left.inSeconds % 60).toString().padLeft(2, '0');
    final text = showHours ? '$h:$m:$s' : '$m:$s';
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < text.length; i++)
          text[i] == ':' ? Text(':', style: style) : _Digit(key: ValueKey('d$i'), digit: text[i], style: style),
      ],
    );
  }
}

class _Digit extends StatelessWidget {
  final String digit;
  final TextStyle style;
  const _Digit({super.key, required this.digit, required this.style});

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 280),
        transitionBuilder: (child, anim) {
          final incoming = child.key == ValueKey(digit);
          final offset = Tween<Offset>(
            begin: incoming ? const Offset(0, -1) : const Offset(0, 1),
            end: Offset.zero,
          ).animate(CurvedAnimation(parent: anim, curve: Curves.easeOutCubic));
          return SlideTransition(position: offset, child: child);
        },
        layoutBuilder: (cur, prev) => Stack(alignment: Alignment.center, children: [...prev, if (cur != null) cur]),
        child: Text(digit, key: ValueKey(digit), style: style),
      ),
    );
  }
}
