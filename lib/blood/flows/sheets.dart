import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../state/models.dart';
import '../../state/pulse_store.dart';
import '../../theme/bd.dart';
import '../widgets/common.dart';
import '../widgets/motion.dart';
import 'actions.dart';

/// "Become a Lifeline": blood group, last donated, weight.
/// Full screen at first launch; also reachable from My Donations.
class BecomeLifeline extends StatefulWidget {
  final bool asSheet;
  const BecomeLifeline({super.key, this.asSheet = false});
  @override
  State<BecomeLifeline> createState() => _BecomeLifelineState();
}

class _BecomeLifelineState extends State<BecomeLifeline> {
  String? _group;
  bool _unknown = false;
  DateTime? _last;
  bool? _never;
  bool? _weight;
  bool _done = false;

  int get _answered => [_group != null || _unknown, _never != null, _weight != null].where((b) => b).length;

  void _finish() {
    context.read<PulseStore>().completeOnboarding(group: _unknown ? null : _group, last: _never == true ? null : _last);
    setState(() => _done = true);
    Haptics.success();
    playBurst(context);
    Future.delayed(const Duration(milliseconds: 1800), () {
      if (mounted && widget.asSheet) Navigator.of(context).pop();
    });
  }

  @override
  Widget build(BuildContext context) {
    final s = context.read<PulseStore>();
    final now = DateTime.now();
    // This month back 12 months (e.g. Nov 2026 … Nov 2025), then "Before Nov 2025".
    final months = List.generate(13, (i) => DateTime(now.year, now.month - i));
    final oldest = months.last;
    final before = DateTime(oldest.year, oldest.month - 1);
    final body = AnimatedSwitcher(
      duration: BD.slow,
      child:
          _done
              ? Padding(
                key: const ValueKey('done'),
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Heartbeat(strength: 1.4, child: const DropMedallion(size: 72)),
                    gap24,
                    Text(
                      _unknown ? 'Thanks, ${s.firstName}' : "You're a Lifeline, ${s.firstName}",
                      style: T.bold(22),
                      textAlign: TextAlign.center,
                    ),
                    gap8,
                    Text(
                      _unknown
                          ? "We'll offer you a free blood-group test at the next NSS camp."
                          : 'When someone on campus needs $_group, you might be one of the few we ask.',
                      textAlign: TextAlign.center,
                      style: T.regular(14, BD.textSecondary),
                    ),
                  ],
                ),
              )
              : ListView(
                key: const ValueKey('form'),
                shrinkWrap: widget.asSheet,
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
                children: [
                  Container(
                    padding: const EdgeInsets.fromLTRB(16, 24, 16, 20),
                    decoration: BoxDecoration(
                      gradient: BD.requestGradient,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: BD.border),
                    ),
                    child: Column(
                      children: [
                        const DropMedallion(),
                        const SizedBox(height: 15),
                        Text('Become a Lifeline', style: T.bold(18)),
                        gap16,
                        UnitsBar(units: 3, confirmed: _answered),
                      ],
                    ),
                  ),
                  gap24,
                  _Q('Your blood group'),
                  gap12,
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final g in bloodGroups)
                        ChipPill(
                          text: g,
                          width: 60,
                          selected: _group == g,
                          onTap:
                              () => setState(() {
                                _group = g;
                                _unknown = false;
                              }),
                        ),
                      ChipPill(
                        text: "I don't know",
                        selected: _unknown,
                        onTap:
                            () => setState(() {
                              _unknown = true;
                              _group = null;
                            }),
                      ),
                    ],
                  ),
                  gap24,
                  _Q('Last donated on'),
                  gap12,
                  SizedBox(
                    height: 36,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      children: [
                        ChipPill(
                          text: 'Never',
                          selected: _never == true,
                          onTap:
                              () => setState(() {
                                _never = true;
                                _last = null;
                              }),
                        ),
                        for (final m in months) ...[
                          gap8,
                          ChipPill(
                            text: '${monthShort(m)} ${m.year}',
                            selected: _never == false && _last == m,
                            onTap:
                                () => setState(() {
                                  _never = false;
                                  _last = m;
                                }),
                          ),
                        ],
                        gap8,
                        ChipPill(
                          text: 'Before ${monthShort(oldest)} ${oldest.year}',
                          selected: _never == false && _last == before,
                          onTap:
                              () => setState(() {
                                _never = false;
                                _last = before;
                              }),
                        ),
                      ],
                    ),
                  ),
                  gap24,
                  _Q('Do you weigh more than 45 kg?'),
                  gap12,
                  Row(
                    children: [
                      Expanded(child: ChipPill(text: 'Yes', selected: _weight == true, onTap: () => setState(() => _weight = true))),
                      gap8,
                      Expanded(child: ChipPill(text: 'No', selected: _weight == false, onTap: () => setState(() => _weight = false))),
                    ],
                  ),
                  gap24,
                  Row(
                    children: [
                      const Icon(FluentIcons.lock_closed_16_regular, size: 14, color: BD.textSecondary),
                      gap8,
                      Expanded(
                        child: Text(
                          "Only the NSS team sees your blood group. It's never shown to other students.",
                          style: T.regular(11, BD.textSecondary),
                        ),
                      ),
                    ],
                  ),
                  gap24,
                  BdButton(
                    label: _answered == 3 ? 'Become a Lifeline' : 'Answer ${3 - _answered} more',
                    onTap: _answered == 3 ? _finish : null,
                  ),
                  if (!widget.asSheet) ...[
                    gap16,
                    TextButton(onPressed: s.skipOnboarding, child: Text('Skip for now', style: T.medium(13, BD.textSecondary))),
                  ],
                ],
              ),
    );
    if (widget.asSheet) return body;
    return Scaffold(
      backgroundColor: BD.page,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: Row(
                children: [
                  Text('Profile setup • step 4 of 4', style: T.regular(12, BD.textSecondary)),
                  const Spacer(),
                  Text('Optional', style: T.medium(12, BD.textSecondary)),
                ],
              ),
            ),
            Expanded(child: Center(child: body)),
          ],
        ),
      ),
    );
  }
}

class _Q extends StatelessWidget {
  final String text;
  const _Q(this.text);
  @override
  Widget build(BuildContext context) => Text(text, style: T.medium(16));
}

void showBecomeLifeline(BuildContext context) {
  showBdSheet(context, builder: (_) => const BecomeLifeline(asSheet: true));
}

/// NSS certificate preview for a past donation.
void showCertificate(BuildContext context, DonationRecord r) {
  final s = context.read<PulseStore>();
  showBdSheet(
    context,
    builder:
        (ctx) => Padding(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (!r.certificate) ...[
                const Icon(FluentIcons.hourglass_half_24_regular, color: BD.textSecondary, size: 32),
                gap12,
                Text('Certificate on its way', style: T.bold(16)),
                gap8,
                Text('It appears here once NSS confirms your donation.', style: T.regular(12, BD.textSecondary)),
              ] else ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: BD.page,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: BD.greenCta, width: 1.5),
                  ),
                  child: Column(
                    children: [
                      bdSvg('certificate', width: 36, height: 36),
                      gap12,
                      Text('CERTIFICATE OF APPRECIATION', style: T.medium(10, BD.green).copyWith(letterSpacing: 1.2)),
                      gap12,
                      Text(s.fullName, style: T.bold(20)),
                      gap8,
                      Text(
                        'donated blood at ${r.name}, ${r.place}\non ${r.date.day} ${monthShort(r.date)} ${r.date.year}',
                        textAlign: TextAlign.center,
                        style: T.regular(12, BD.text700, 1.4),
                      ),
                      gap16,
                      Text('NSS Cell • IIT Guwahati', style: T.medium(11, BD.textSecondary)),
                    ],
                  ),
                ),
                gap16,
                BdButton(
                  label: 'Download',
                  icon: FluentIcons.arrow_download_20_regular,
                  onTap: () {
                    Navigator.of(ctx).pop();
                    ScaffoldMessenger.maybeOf(context)?.showSnackBar(bdSnack('Certificate saved (prototype)'));
                  },
                ),
              ],
            ],
          ),
        ),
  );
}
