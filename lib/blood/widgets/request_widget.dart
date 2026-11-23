import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../state/pulse_store.dart';
import '../../theme/bd.dart';
import 'common.dart';
import 'motion.dart';

/// "New request widget" (Figma 1810:8384). Shown on OneStop Home in place of
/// the Time Table card, and on My Donations, while a matched request is open.
class RequestWidget extends StatelessWidget {
  final VoidCallback onAccept;
  final VoidCallback onDetails;
  final VoidCallback onDecline;
  const RequestWidget({super.key, required this.onAccept, required this.onDetails, required this.onDecline});

  @override
  Widget build(BuildContext context) {
    final s = context.watch<PulseStore>();
    final r = s.request;
    if (r == null) return const SizedBox.shrink();
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(12, 29, 12, 16),
      decoration: BoxDecoration(
        gradient: BD.requestGradient,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: BD.border),
      ),
      child: Column(
        children: [
          // Medallion + copy (gap 15)
          EnterIn(child: Heartbeat(strength: 0.8, child: const DropMedallion())),
          const SizedBox(height: 15),
          SizedBox(
            width: 284,
            child: Column(
              children: [
                EnterIn(
                  delay: const Duration(milliseconds: 80),
                  child: Text("You've been matched to help", textAlign: TextAlign.center, style: T.bold(16)),
                ),
                const SizedBox(height: 11),
                EnterIn(
                  delay: const Duration(milliseconds: 140),
                  child: Text.rich(
                    TextSpan(
                      style: T.regular(12, BD.textSecondary),
                      children: [
                        TextSpan(text: '${r.requester} needs '),
                        TextSpan(text: r.group, style: T.bold(12, BD.textSecondary)),
                        TextSpan(text: ' blood today. ${r.reason}'),
                      ],
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
          // Slider + actions (w 276, gap 8)
          SizedBox(
            width: 276,
            child: Column(
              children: [
                SlideToSayYes(onCommit: onAccept),
                const SizedBox(height: 8),
                Row(
                  children: [
                    SizedBox(
                      width: 136,
                      height: 32,
                      child: Pressable(
                        onTap: onDetails,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            bdSvg('info_circle', width: 16, height: 16),
                            const SizedBox(width: 6),
                            Text('See details', style: T.medium(12)),
                          ],
                        ),
                      ),
                    ),
                    Expanded(child: Center(child: bdSvg('divider_v', width: 1, height: 18))),
                    SizedBox(
                      width: 136,
                      height: 32,
                      child: Pressable(onTap: onDecline, child: Center(child: Text('I can’t this time', style: T.medium(12)))),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
          // Units card (#262626, px 12, py 20, gap 12)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 20),
            decoration: BoxDecoration(color: BD.card, borderRadius: BorderRadius.circular(16)),
            child: Column(
              children: [
                Text('${r.units} units of blood needed', textAlign: TextAlign.center, style: T.bold(14)),
                const SizedBox(height: 8),
                AnimatedSwitcher(
                  duration: BD.medium,
                  child: Text(
                    'Only ${r.asked} students were asked. ${s.confirmed} confirmed',
                    key: ValueKey(s.confirmed),
                    textAlign: TextAlign.center,
                    style: T.regular(12, BD.textSecondary),
                  ),
                ),
                const SizedBox(height: 12),
                UnitsBar(units: r.units, confirmed: s.confirmed),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Slide to say yes (Figma 1810:8397): 42 px track rgba(255,255,255,.35),
/// 42 px halo rgba(255,255,255,.5), 36 px white knob with the heart icon.
class SlideToSayYes extends StatefulWidget {
  final VoidCallback onCommit;
  final String label;
  const SlideToSayYes({super.key, required this.onCommit, this.label = 'Slide to say yes >>'});

  @override
  State<SlideToSayYes> createState() => _SlideToSayYesState();
}

class _SlideToSayYesState extends State<SlideToSayYes> with SingleTickerProviderStateMixin {
  static const _h = 42.0;
  double _x = 0;
  bool _done = false;
  late final AnimationController _spring = AnimationController(vsync: this, duration: const Duration(milliseconds: 380));
  Animation<double>? _back;

  @override
  void initState() {
    super.initState();
    _spring.addListener(() {
      if (_back != null) setState(() => _x = _back!.value);
    });
  }

  @override
  void dispose() {
    _spring.dispose();
    super.dispose();
  }

  void _commit() {
    if (_done) return;
    setState(() {
      _done = true;
      _x = 1;
    });
    Haptics.success();
    Future.delayed(const Duration(milliseconds: 220), widget.onCommit);
  }

  void _release() {
    if (_done) return;
    if (_x > 0.8) {
      _back = Tween(begin: _x, end: 1.0).animate(CurvedAnimation(parent: _spring, curve: Curves.easeOut));
      _spring.forward(from: 0).whenComplete(_commit);
    } else {
      _back = Tween(begin: _x, end: 0.0).animate(CurvedAnimation(parent: _spring, curve: Curves.elasticOut));
      _spring.forward(from: 0);
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) {
        final travel = c.maxWidth - _h;
        final left = travel * _x;
        return Semantics(
          button: true,
          label: 'Slide to say yes',
          onTap: _commit,
          child: GestureDetector(
            onHorizontalDragUpdate: (d) {
              if (!_done) setState(() => _x = (_x + d.delta.dx / travel).clamp(0.0, 1.0));
            },
            onHorizontalDragEnd: (_) => _release(),
            child: Container(
              height: _h,
              decoration: BoxDecoration(color: BD.sliderTrack, borderRadius: BorderRadius.circular(71)),
              child: Stack(
                children: [
                  // Trail behind the halo
                  Positioned(
                    left: 0,
                    top: 0,
                    bottom: 0,
                    width: left + _h,
                    child: Container(decoration: BoxDecoration(color: BD.sliderHalo, borderRadius: BorderRadius.circular(80))),
                  ),
                  // Label
                  Center(
                    child: AnimatedOpacity(
                      duration: BD.fast,
                      opacity: _done ? 0 : (1 - _x * 1.5).clamp(0.0, 1.0),
                      child: Text(
                        widget.label,
                        style: T
                            .medium(12)
                            .copyWith(shadows: const [Shadow(color: Color(0x40000000), offset: Offset(0, 1), blurRadius: 2)]),
                      ),
                    ),
                  ),
                  if (_done) Center(child: EnterIn(dy: 6, child: Text("You're in!", style: T.bold(12, const Color(0xFF6D303A))))),
                  // Knob (36 px, 3 px inset)
                  Positioned(
                    left: left + 3,
                    top: 3,
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                      alignment: Alignment.center,
                      child: AnimatedSwitcher(
                        duration: BD.fast,
                        transitionBuilder: (c, a) => ScaleTransition(scale: a, child: c),
                        child:
                            _done
                                ? const Icon(FluentIcons.heart_24_filled, key: ValueKey('f'), color: BD.toggleOn, size: 24)
                                : Heartbeat(
                                  key: const ValueKey('o'),
                                  active: _x == 0,
                                  strength: 1.6,
                                  child: bdSvg('heart_outline', width: 24, height: 24),
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
