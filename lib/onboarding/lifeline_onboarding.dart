import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';
import 'package:onestop_ui/index.dart';
import 'package:provider/provider.dart';

import '../state/models.dart';
import '../state/pulse_store.dart';
import '../theme/pulse_tokens.dart';
import '../widgets/motion.dart';
import '../widgets/shapes.dart';

/// Optional final step of OneStop's profile setup. Under 20 seconds, skippable.
class LifelineOnboarding extends StatefulWidget {
  final VoidCallback onDone;
  const LifelineOnboarding({super.key, required this.onDone});

  @override
  State<LifelineOnboarding> createState() => _LifelineOnboardingState();
}

class _LifelineOnboardingState extends State<LifelineOnboarding> {
  String? _group;
  bool _unknown = false;
  DateTime? _last;
  bool? _never;
  bool? _weight;
  bool _finished = false;

  int get _answered => [(_group != null || _unknown), _never != null, _weight != null].where((b) => b).length;

  static const _facts = {
    'O−': 'O− is the universal donor. Only about 1 in 15 people share it.',
    'O+': 'O+ is the most common group, so it\'s the most requested too.',
    'A+': 'A+ is one of the most common groups. You\'ll be in demand.',
    'A−': 'A− is rare: only about 1 in 50 people share it.',
    'B+': 'B+ is common in India, so B+ requests come often.',
    'B−': 'B− is rare: about 1 in 50 people. Every donation counts.',
    'AB+': 'AB+ plasma can be given to anyone. You\'re a universal plasma donor.',
    'AB−': 'AB− is the rarest group. You\'re one of very few.',
  };

  void _finish() {
    final s = context.read<PulseStore>();
    s.completeOnboarding(
      group: _group,
      unknown: _unknown,
      last: _last,
      never: _never ?? true,
      weight: _weight ?? false,
    );
    setState(() => _finished = true);
    Haptics.success();
    Future.delayed(const Duration(milliseconds: 2200), widget.onDone);
  }

  @override
  Widget build(BuildContext context) {
    final s = context.read<PulseStore>();
    return Scaffold(
      backgroundColor: OColor.white,
      body: SafeArea(child: AnimatedSwitcher(duration: PulseMotion.emphasis, child: _finished ? _done(s) : _form(s))),
    );
  }

  Widget _done(PulseStore s) {
    return Center(
      key: const ValueKey('done'),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Heartbeat(
              strength: 1.4,
              child: LiquidDrop(
                fill: 1,
                height: 150,
                color: PulseColors.crimson,
                empty: PulseColors.blush,
                child: Text(_group ?? '?', style: PText.h1(Colors.white).copyWith(fontWeight: FontWeight.w800)),
              ),
            ),
            const SizedBox(height: 24),
            EnterIn(
              child: Text(
                _group != null ? "You're a Lifeline, ${s.firstName}" : 'Thanks, ${s.firstName}',
                style: PText.h1(OColor.gray800).copyWith(fontWeight: FontWeight.w700),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 8),
            EnterIn(
              delay: const Duration(milliseconds: 120),
              child: Text(
                _group != null
                    ? "When someone on campus needs ${_group!}, you might be one of the few we ask."
                    : "We'll offer you a free blood-group test at the next NSS camp.",
                style: PText.body(OColor.gray600),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _form(PulseStore s) {
    final now = DateTime.now();
    final months = List.generate(18, (i) => DateTime(now.year, now.month - i));
    return Column(
      key: const ValueKey('form'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 8, 0),
          child: Row(
            children: [
              Text('Step 4 of 4 • optional', style: PText.bodyX(OColor.gray500)),
              const Spacer(),
              TextButton(
                onPressed: () {
                  s.skipOnboarding();
                  widget.onDone();
                },
                child: Text('Skip for now', style: PText.label(OColor.gray600)),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(2),
            child: LinearProgressIndicator(
              value: 0.75 + 0.25 * _answered / 3,
              minHeight: 4,
              color: OColor.green600,
              backgroundColor: OColor.gray200,
            ),
          ),
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Become a Lifeline',
                          style: PText.h1(OColor.gray800).copyWith(fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          '3 quick answers so we only ask you when you can really help.',
                          style: PText.body(OColor.gray600),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  LiquidDrop(
                    fill: _answered / 3,
                    height: 84,
                    color: PulseColors.crimson,
                    empty: PulseColors.blush,
                    child:
                        _group != null
                            ? Text(
                              _group!,
                              style: OTextStyle.labelSmall.copyWith(color: Colors.white, fontWeight: FontWeight.w800),
                            )
                            : null,
                  ),
                ],
              ),
              const SizedBox(height: 24),
              _Q(n: 1, title: 'Your blood group'),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final g in bloodGroups)
                    _GroupChip(
                      text: g,
                      selected: _group == g,
                      onTap:
                          () => setState(() {
                            _group = g;
                            _unknown = false;
                          }),
                    ),
                  _GroupChip(
                    text: "I don't know",
                    selected: _unknown,
                    wide: true,
                    onTap:
                        () => setState(() {
                          _unknown = true;
                          _group = null;
                        }),
                  ),
                ],
              ),
              AnimatedSize(
                duration: PulseMotion.standard,
                curve: PulseMotion.standardCurve,
                child:
                    (_group != null || _unknown)
                        ? Padding(
                          padding: const EdgeInsets.only(top: 12),
                          child: EnterIn(
                            key: ValueKey(_group ?? 'unk'),
                            from: const Offset(0, 8),
                            duration: PulseMotion.standard,
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: PulseColors.goldSoft,
                                borderRadius: BorderRadius.circular(OCornerRadius.m),
                              ),
                              child: Row(
                                children: [
                                  Icon(FluentIcons.lightbulb_24_filled, color: OColor.yellow600, size: 20),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      _unknown
                                          ? 'No problem. We\'ll offer you a free grouping test at the next NSS camp.'
                                          : _facts[_group]!,
                                      style: PText.bodyX(OColor.gray800),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        )
                        : const SizedBox(width: double.infinity),
              ),
              const SizedBox(height: 24),
              _Q(n: 2, title: 'Last donated on'),
              const SizedBox(height: 10),
              SizedBox(
                height: 40,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    _GroupChip(
                      text: 'Never donated',
                      selected: _never == true,
                      wide: true,
                      onTap:
                          () => setState(() {
                            _never = true;
                            _last = null;
                          }),
                    ),
                    for (final m in months)
                      Padding(
                        padding: const EdgeInsets.only(left: 8),
                        child: _GroupChip(
                          text: monthYear(m),
                          wide: true,
                          selected: _never == false && _last == m,
                          onTap:
                              () => setState(() {
                                _never = false;
                                _last = m;
                              }),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              _Q(n: 3, title: 'Do you weigh more than 45 kg?'),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: _GroupChip(
                      text: 'Yes',
                      selected: _weight == true,
                      wide: true,
                      onTap: () => setState(() => _weight = true),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _GroupChip(
                      text: 'No',
                      selected: _weight == false,
                      wide: true,
                      onTap: () => setState(() => _weight = false),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Icon(FluentIcons.lock_closed_16_regular, size: 16, color: OColor.gray500),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      "Only the NSS team sees your blood group. It's never shown to other students.",
                      style: PText.bodyX(OColor.gray500),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
          child: PrimaryButton(
            label: _answered == 3 ? 'Become a Lifeline' : 'Answer ${3 - _answered} more',
            enabled: _answered == 3,
            onPressed: _answered == 3 ? _finish : null,
          ),
        ),
      ],
    );
  }
}

class _Q extends StatelessWidget {
  final int n;
  final String title;
  const _Q({required this.n, required this.title});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 22,
          height: 22,
          decoration: BoxDecoration(color: OColor.gray100, shape: BoxShape.circle),
          alignment: Alignment.center,
          child: Text('$n', style: OTextStyle.labelXSmall.copyWith(color: OColor.gray700)),
        ),
        const SizedBox(width: 8),
        Text(title, style: PText.h3(OColor.gray800)),
      ],
    );
  }
}

class _GroupChip extends StatelessWidget {
  final String text;
  final bool selected;
  final bool wide;
  final VoidCallback onTap;
  const _GroupChip({required this.text, required this.selected, required this.onTap, this.wide = false});

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onTap: onTap,
      child: AnimatedContainer(
        duration: PulseMotion.micro,
        width: wide ? null : 64,
        height: 40,
        padding: wide ? const EdgeInsets.symmetric(horizontal: 16) : null,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? PulseColors.crimson : OColor.white,
          borderRadius: BorderRadius.circular(OCornerRadius.m),
          border: Border.all(color: selected ? PulseColors.crimson : OColor.gray300),
          boxShadow:
              selected
                  ? [
                    BoxShadow(
                      color: PulseColors.crimson.withValues(alpha: 0.25),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ]
                  : null,
        ),
        child: Text(
          text,
          style: OTextStyle.labelMedium.copyWith(
            color: selected ? Colors.white : OColor.gray800,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
