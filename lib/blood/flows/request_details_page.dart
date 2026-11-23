import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../state/models.dart';
import '../../state/pulse_store.dart';
import '../../theme/bd.dart';
import '../blood_shell.dart';
import '../widgets/common.dart';
import '../widgets/motion.dart';
import '../widgets/request_widget.dart';
import 'actions.dart';

/// "See details": calm and factual. Is it real → is it safe → what do I get.
class RequestDetailsPage extends StatelessWidget {
  const RequestDetailsPage({super.key});

  static Route route() => PageRouteBuilder(
    transitionDuration: const Duration(milliseconds: 380),
    reverseTransitionDuration: const Duration(milliseconds: 240),
    pageBuilder: (_, _, _) => const RequestDetailsPage(),
    transitionsBuilder: (_, a, _, c) {
      final cu = CurvedAnimation(parent: a, curve: Curves.easeOutCubic);
      return FadeTransition(
        opacity: cu,
        child: SlideTransition(position: Tween(begin: const Offset(0, 0.04), end: Offset.zero).animate(cu), child: c),
      );
    },
  );

  @override
  Widget build(BuildContext context) {
    final s = context.watch<PulseStore>();
    final r = s.request;
    final bottom = MediaQuery.viewPaddingOf(context).bottom;
    return Scaffold(
      backgroundColor: BD.page,
      body: Column(
        children: [
          const BdAppBar(title: 'Request details'),
          Expanded(
            child:
                r == null
                    ? Center(child: Text('This request has closed.', style: T.regular(14, BD.textSecondary)))
                    : Stack(
                      children: [
                        ListView(
                          padding: EdgeInsets.fromLTRB(12, 16, 12, 150 + bottom),
                          children: [
                            _Hero(r: r, s: s),
                            gap24,
                            _Section(title: 'The need', delay: 1, child: _Need(r: r, s: s)),
                            _Section(
                              title: 'Your point of contact',
                              delay: 2,
                              child: _Person(c: r.poc, line: 'Ask anything about the patient or the blood bank.'),
                            ),
                            _Section(
                              title: 'Your NSS coordinator',
                              delay: 3,
                              child: _Person(c: r.coordinator, line: 'Sneha shares your slot and can arrange a ride if you need one.'),
                            ),
                            const _Section(title: 'What to expect', delay: 4, child: _Expect()),
                            const _Section(title: 'What you get', delay: 5, padded: false, child: _Rewards()),
                            const _Section(title: 'Is it safe?', delay: 6, child: _Faq()),
                            Text(
                              "Medical answers here are pre-screens. The blood bank's check-up is final.",
                              textAlign: TextAlign.center,
                              style: T.regular(11, BD.text600),
                            ),
                          ],
                        ),
                        Positioned(
                          left: 0,
                          right: 0,
                          bottom: 0,
                          child: Container(
                            padding: EdgeInsets.fromLTRB(16, 14, 16, 10 + bottom),
                            decoration: const BoxDecoration(color: BD.bar, border: Border(top: BorderSide(color: BD.border))),
                            child:
                                s.phase == AskPhase.open
                                    ? Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(0),
                                          decoration: BoxDecoration(borderRadius: BorderRadius.circular(71), gradient: BD.requestGradient),
                                          child: SlideToSayYes(
                                            onCommit: () {
                                              Navigator.of(context).pop();
                                              acceptRequest(context);
                                            },
                                          ),
                                        ),
                                        TextButton(
                                          onPressed: () => openDecline(context),
                                          child: Text('I can’t this time', style: T.medium(12, BD.textSecondary)),
                                        ),
                                      ],
                                    )
                                    : Padding(
                                      padding: const EdgeInsets.symmetric(vertical: 10),
                                      child: Text(
                                        s.phase == AskPhase.accepted
                                            ? "You're in. Track it from My Donations."
                                            : 'This request is no longer open.',
                                        textAlign: TextAlign.center,
                                        style: T.medium(13, BD.text700),
                                      ),
                                    ),
                          ),
                        ),
                      ],
                    ),
          ),
        ],
      ),
    );
  }
}

class _Hero extends StatelessWidget {
  final BloodRequest r;
  final PulseStore s;
  const _Hero({required this.r, required this.s});

  @override
  Widget build(BuildContext context) {
    final left = s.timeLeft;
    final hh = left.inHours.toString().padLeft(2, '0');
    final mm = (left.inMinutes % 60).toString().padLeft(2, '0');
    final ss = (left.inSeconds % 60).toString().padLeft(2, '0');
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 29, 16, 20),
      decoration: BoxDecoration(
        gradient: BD.requestGradient,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: BD.border),
      ),
      child: Column(
        children: [
          Heartbeat(strength: 0.8, child: const DropMedallion()),
          const SizedBox(height: 15),
          Text('${r.requester} needs ${r.group} blood', textAlign: TextAlign.center, style: T.bold(16)),
          const SizedBox(height: 11),
          Text(r.reason, textAlign: TextAlign.center, style: T.regular(12, BD.textSecondary)),
          gap24,
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(color: BD.card, borderRadius: BorderRadius.circular(71)),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(FluentIcons.timer_16_regular, color: BD.toggleOn, size: 16),
                const SizedBox(width: 6),
                Text('$hh:$mm:$ss', style: T.bold(13).copyWith(fontFeatures: const [FontFeature.tabularFigures()])),
                const SizedBox(width: 6),
                Text('left to respond', style: T.regular(12, BD.textSecondary)),
              ],
            ),
          ),
          gap16,
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 20),
            decoration: BoxDecoration(color: BD.card, borderRadius: BorderRadius.circular(16)),
            child: Column(
              children: [
                Text('${r.units} units of blood needed', style: T.bold(14)),
                gap8,
                Text('Only ${r.asked} students were asked. ${s.confirmed} confirmed', style: T.regular(12, BD.textSecondary)),
                gap12,
                UnitsBar(units: r.units, confirmed: s.confirmed),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  final String title;
  final Widget child;
  final int delay;
  final bool padded;
  const _Section({required this.title, required this.child, required this.delay, this.padded = true});

  @override
  Widget build(BuildContext context) => EnterIn(
    delay: Duration(milliseconds: 60 * delay),
    child: Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SectionTitle(title),
          const SizedBox(height: 17),
          padded ? BdCard(padding: const EdgeInsets.all(16), child: child) : child,
        ],
      ),
    ),
  );
}

class _Need extends StatelessWidget {
  final BloodRequest r;
  final PulseStore s;
  const _Need({required this.r, required this.s});

  @override
  Widget build(BuildContext context) {
    Widget row(IconData i, String k, String v) => Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(i, size: 18, color: BD.textSecondary),
          gap12,
          SizedBox(width: 86, child: Text(k, style: T.regular(12, BD.textSecondary))),
          Expanded(child: Text(v, style: T.medium(12))),
        ],
      ),
    );
    return Column(
      children: [
        row(FluentIcons.person_20_regular, 'Requested by', '${r.requester} (family member in surgery)'),
        row(FluentIcons.drop_20_regular, 'Blood group', '${r.group} whole blood'),
        row(FluentIcons.box_multiple_20_regular, 'Units', '${r.units} needed • ${s.confirmed} confirmed'),
        row(FluentIcons.building_20_regular, 'Hospital', '${r.hospital} Blood Bank, ${r.hospitalArea}'),
        Padding(
          padding: EdgeInsets.zero,
          child: Row(
            children: [
              const Icon(FluentIcons.vehicle_car_20_regular, size: 18, color: BD.textSecondary),
              gap12,
              Expanded(
                child: Text(
                  'Most donors travel on their own. Need a ride? Request one after you say yes.',
                  style: T.regular(12, BD.text700),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _Person extends StatelessWidget {
  final Contact c;
  final String line;
  const _Person({required this.c, required this.line});

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(
        children: [
          InitialsDot(initials: c.initials, size: 40),
          gap12,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(child: Text(c.name, style: T.bold(14))),
                    const SizedBox(width: 4),
                    const Icon(FluentIcons.checkmark_starburst_16_filled, size: 14, color: BD.green),
                  ],
                ),
                Text(c.role, style: T.regular(10, BD.textSecondary)),
              ],
            ),
          ),
          _Round(icon: FluentIcons.call_20_filled, onTap: () => showContactSheet(context, c, line: line)),
          gap8,
          _Round(icon: FluentIcons.chat_20_filled, onTap: () => showContactSheet(context, c, line: line)),
        ],
      ),
      gap12,
      Text(line, style: T.regular(12, BD.text700)),
    ],
  );
}

class _Round extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _Round({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) => Pressable(
    onTap: onTap,
    child: Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: BD.greenCta)),
      child: Icon(icon, size: 18, color: BD.green),
    ),
  );
}

class _Expect extends StatelessWidget {
  const _Expect();

  @override
  Widget build(BuildContext context) {
    const steps = [
      (FluentIcons.vehicle_car_20_regular, 'Travel', 'On your own or NSS ride'),
      (FluentIcons.stethoscope_20_regular, 'Check-up', 'Hb, BP • 10 min'),
      (FluentIcons.drop_20_regular, 'Donate', '~10 min'),
      (FluentIcons.food_cake_20_regular, 'Rest', 'Snacks • 15 min'),
    ];
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final st in steps)
          Expanded(
            child: Column(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(color: BD.greenBadgeBg, borderRadius: BorderRadius.circular(6)),
                  child: Icon(st.$1, color: BD.green, size: 20),
                ),
                gap8,
                Text(st.$2, style: T.bold(12)),
                const SizedBox(height: 2),
                Text(st.$3, textAlign: TextAlign.center, style: T.regular(10, BD.textSecondary)),
              ],
            ),
          ),
      ],
    );
  }
}

class _Rewards extends StatelessWidget {
  const _Rewards();

  @override
  Widget build(BuildContext context) {
    const items = [
      (FluentIcons.ribbon_star_20_filled, 'Hero badge', 'On your OneStop profile'),
      (FluentIcons.food_20_filled, 'Iron-rich meal', 'Free at your mess'),
      (FluentIcons.certificate_20_filled, 'NSS certificate', 'Counts toward NSS hours'),
      (FluentIcons.people_community_20_filled, 'Hero wall', 'Your name, campus-wide'),
    ];
    return SizedBox(
      height: 104,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: items.length,
        separatorBuilder: (_, _) => gap12,
        itemBuilder:
            (_, i) => Container(
              width: 140,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: BD.card,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: i == 0 ? BD.crimsonBorder : BD.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(items[i].$1, color: i == 0 ? BD.toggleOn : BD.green, size: 22),
                  const Spacer(),
                  Text(items[i].$2, style: T.bold(14)),
                  const SizedBox(height: 2),
                  Text(items[i].$3, style: T.regular(10, BD.textSecondary), maxLines: 1, overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
      ),
    );
  }
}

class _Faq extends StatefulWidget {
  const _Faq();
  @override
  State<_Faq> createState() => _FaqState();
}

class _FaqState extends State<_Faq> {
  int? _open;
  static const _qa = [
    ('Does it hurt?', 'A quick pinch when the needle goes in, then nothing much. Most donors say it was easier than they expected.'),
    ('How long until I feel normal?', 'Most people feel fine within a few hours. Drink extra water and skip heavy exercise for 24 hours.'),
    ('Can I eat before?', 'Yes, please do. A light, non-oily meal 2–3 hours before, plus 500 ml of water.'),
    ('What if I feel faint?', "Staff watch you the whole time. You'll lie down with legs raised and it passes in minutes."),
    ("Who shouldn't donate?", 'Anyone unwell, on antibiotics, with a tattoo or piercing in the last 6 months, or under 45 kg.'),
  ];

  @override
  Widget build(BuildContext context) => Column(
    children: [
      for (var i = 0; i < _qa.length; i++) ...[
        InkWell(
          onTap: () => setState(() => _open = _open == i ? null : i),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Row(
              children: [
                Expanded(child: Text(_qa[i].$1, style: T.medium(13))),
                AnimatedRotation(
                  turns: _open == i ? 0.5 : 0,
                  duration: BD.medium,
                  child: const Icon(FluentIcons.chevron_down_16_regular, color: BD.textSecondary, size: 16),
                ),
              ],
            ),
          ),
        ),
        AnimatedSize(
          duration: BD.medium,
          curve: Curves.easeOutCubic,
          child:
              _open == i
                  ? Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Align(alignment: Alignment.centerLeft, child: Text(_qa[i].$2, style: T.regular(12, BD.textSecondary, 1.4))),
                  )
                  : const SizedBox(width: double.infinity),
        ),
        if (i < _qa.length - 1) const Divider(height: 1, color: BD.border),
      ],
    ],
  );
}
