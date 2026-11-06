import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';
import 'package:onestop_ui/index.dart';
import 'package:provider/provider.dart';

import '../event/event_card.dart';
import '../request/lifeline_card.dart';
import '../request/slide_to_accept.dart';
import '../state/models.dart';
import '../state/pulse_store.dart';
import '../theme/pulse_tokens.dart';
import '../widgets/motion.dart';
import '../widgets/particles.dart';
import '../widgets/shapes.dart';

/// Quick Access → Blood Donation. The student's home base for everything blood.
class BloodHubPage extends StatelessWidget {
  final VoidCallback onAcceptFromHub;
  const BloodHubPage({super.key, required this.onAcceptFromHub});

  static Route route(VoidCallback onAccept) => PageRouteBuilder(
    transitionDuration: const Duration(milliseconds: 350),
    reverseTransitionDuration: PulseMotion.standard,
    pageBuilder: (_, _, _) => BloodHubPage(onAcceptFromHub: onAccept),
    transitionsBuilder: (_, a, _, c) {
      // Shared-axis Y (OneStop style).
      final cu = CurvedAnimation(parent: a, curve: PulseMotion.standardCurve);
      return FadeTransition(
        opacity: cu,
        child: SlideTransition(position: Tween(begin: const Offset(0, 0.04), end: Offset.zero).animate(cu), child: c),
      );
    },
  );

  @override
  Widget build(BuildContext context) {
    final s = context.watch<PulseStore>();
    return Scaffold(
      backgroundColor: OColor.gray100,
      appBar: AppBar(
        backgroundColor: OColor.gray100,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        leading: Padding(
          padding: const EdgeInsets.all(8),
          child: CircleAvatar(
            backgroundColor: OColor.green100,
            child: IconButton(
              icon: Icon(FluentIcons.arrow_left_24_regular, color: OColor.green600, size: 20),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ),
        ),
        title: Text('Blood Donation', style: PText.h2(OColor.gray800)),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 40),
        children: [
          EnterIn(child: _StatusCard(store: s)),
          const SizedBox(height: 16),
          if (s.phase == AskPhase.open) ...[
            const _H('Your live request'),
            EnterIn(
              delay: const Duration(milliseconds: 60),
              child: LifelineCard(onAccepted: onAcceptFromHub, compact: true),
            ),
            const SizedBox(height: 16),
          ] else if (s.eventActive) ...[
            const _H('Your donation'),
            const EnterIn(delay: Duration(milliseconds: 60), child: DonationEventCard()),
            const SizedBox(height: 16),
          ],
          if (!s.registeredForNext) ...[
            EnterIn(delay: const Duration(milliseconds: 100), child: _RegisterCard(store: s)),
            const SizedBox(height: 16),
          ],
          const _H('This month on campus'),
          EnterIn(delay: const Duration(milliseconds: 140), child: _MonthStats(store: s)),
          const SizedBox(height: 16),
          const _H('Hero Wall'),
          EnterIn(delay: const Duration(milliseconds: 180), child: _HeroWall(store: s)),
          const SizedBox(height: 16),
          const _H('My donations'),
          EnterIn(delay: const Duration(milliseconds: 220), child: _History(store: s)),
          const SizedBox(height: 16),
          const _H('Learn in 30 seconds'),
          const EnterIn(delay: Duration(milliseconds: 260), child: _Learn()),
          const SizedBox(height: 16),
          const _H('Upcoming NSS camps'),
          EnterIn(delay: const Duration(milliseconds: 300), child: _Camps(store: s)),
        ],
      ),
    );
  }
}

class _H extends StatelessWidget {
  final String t;
  const _H(this.t);
  @override
  Widget build(BuildContext context) =>
      Padding(padding: const EdgeInsets.only(left: 4, bottom: 8), child: Text(t, style: PText.h3(OColor.gray800)));
}

Widget _card({required Widget child, EdgeInsets padding = const EdgeInsets.all(16)}) => Container(
  padding: padding,
  decoration: BoxDecoration(
    color: OColor.white,
    borderRadius: BorderRadius.circular(OCornerRadius.m),
    border: Border.all(color: OColor.gray200),
    boxShadow: [BoxShadow(color: OColor.gray300.withValues(alpha: 0.1), blurRadius: 10, offset: const Offset(0, 2))],
  ),
  child: child,
);

// ───────────────────────── 1. Status ─────────────────────────
class _StatusCard extends StatelessWidget {
  final PulseStore store;
  const _StatusCard({required this.store});

  @override
  Widget build(BuildContext context) {
    final s = store;
    final e = s.eligibility;
    final (chipText, chipBg, chipFg) = switch (e) {
      Eligibility.ready => ('Ready to give', OColor.green100, OColor.green600),
      Eligibility.waiting => ('Eligible in ${s.daysToEligible} days', OColor.yellow100, OColor.yellow700),
      Eligibility.paused => ('Paused', OColor.gray200, OColor.gray600),
      Eligibility.unknown => ('Not set up yet', OColor.gray200, OColor.gray600),
    };
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Ring(
                value: e == Eligibility.waiting ? s.eligibilityProgress : (s.hasLifeline ? 1 : 0),
                size: 76,
                stroke: 5,
                color:
                    e == Eligibility.waiting
                        ? OColor.yellow500
                        : (e == Eligibility.ready ? OColor.green600 : OColor.gray300),
                track: OColor.gray200,
                child:
                    s.registeredForNext
                        ? Heartbeat(
                          child: DropShape(size: 44, color: PulseColors.crimson, child: _GroupText(s.bloodGroup)),
                        )
                        : DropShape(
                          size: 44,
                          color: s.hasLifeline ? PulseColors.crimson : OColor.gray300,
                          child: _GroupText(s.bloodGroup),
                        ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(s.hasLifeline ? 'My Lifeline status' : 'Become a Lifeline', style: PText.h3(OColor.gray800)),
                    const SizedBox(height: 6),
                    PChip(text: chipText, bg: chipBg, fg: chipFg),
                    const SizedBox(height: 6),
                    Text(
                      s.lastDonated != null
                          ? 'Last donated ${monthYear(s.lastDonated!)}'
                          : (s.hasLifeline ? 'Never donated • first-timer' : 'Add your blood group to get started'),
                      style: PText.bodyX(OColor.gray500),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (s.hasLifeline) ...[
            const SizedBox(height: 12),
            Divider(height: 1, color: OColor.gray200),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Available for requests', style: PText.label(OColor.gray800)),
                      Text('Pause during exams, illness or travel', style: PText.bodyX(OColor.gray500)),
                    ],
                  ),
                ),
                Switch(
                  value: s.available,
                  activeThumbColor: Colors.white,
                  activeTrackColor: OColor.green600,
                  onChanged: s.setAvailable,
                ),
              ],
            ),
          ],
          if (s.registeredForNext) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: OColor.green100, borderRadius: BorderRadius.circular(OCornerRadius.m)),
              child: Row(
                children: [
                  Icon(FluentIcons.checkmark_circle_24_filled, color: OColor.green600),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      "You're on the Lifeline list, ${s.firstName}. We'll ping you the moment a ${s.bloodGroup} request comes in.",
                      style: PText.bodyX(OColor.gray800),
                    ),
                  ),
                ],
              ),
            ),
          ],
          if (s.bloodGroup != null && rareGroups.contains(s.bloodGroup)) ...[
            const SizedBox(height: 8),
            PChip(
              text: 'Rare Lifeline • ${s.bloodGroup}',
              icon: FluentIcons.star_16_filled,
              bg: PulseColors.goldSoft,
              fg: OColor.yellow700,
            ),
          ],
        ],
      ),
    );
  }
}

class _GroupText extends StatelessWidget {
  final String? g;
  const _GroupText(this.g);
  @override
  Widget build(BuildContext context) => Text(
    g ?? '?',
    style: OTextStyle.labelSmall.copyWith(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 13),
  );
}

// ───────────────────────── Register for next ─────────────────────────
class _RegisterCard extends StatefulWidget {
  final PulseStore store;
  const _RegisterCard({required this.store});
  @override
  State<_RegisterCard> createState() => _RegisterCardState();
}

class _RegisterCardState extends State<_RegisterCard> {
  late String? _group = widget.store.bloodGroup;
  late bool _never = widget.store.lastDonated == null;
  late DateTime? _last = widget.store.lastDonated;
  final _checks = [true, true, true];

  static const _checkLabels = [
    'I weigh more than 45 kg',
    'No illness or antibiotics in the last 2 weeks',
    'No tattoo or piercing in the last 6 months',
  ];

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final months = List.generate(12, (i) => DateTime(now.year, now.month - i));
    final ok = _group != null && _checks.every((c) => c);
    return Container(
      decoration: BoxDecoration(
        color: OColor.white,
        borderRadius: BorderRadius.circular(OCornerRadius.l),
        border: Border.all(color: PulseColors.crimson.withValues(alpha: 0.35), width: 1.5),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(FluentIcons.flash_24_filled, color: PulseColors.crimson),
              const SizedBox(width: 8),
              Expanded(child: Text('Be first in line for the next request', style: PText.h3(OColor.gray800))),
            ],
          ),
          const SizedBox(height: 4),
          Text('Registered donors are asked first. Takes 20 seconds.', style: PText.bodyX(OColor.gray600)),
          if (widget.store.bloodGroup == null) ...[
            const SizedBox(height: 14),
            Text('Blood group', style: PText.label(OColor.gray800)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final g in bloodGroups)
                  _Pick(text: g, selected: _group == g, onTap: () => setState(() => _group = g)),
              ],
            ),
          ],
          const SizedBox(height: 14),
          Text('Last donated on', style: PText.label(OColor.gray800)),
          const SizedBox(height: 8),
          SizedBox(
            height: 36,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                _Pick(
                  text: 'Never',
                  selected: _never,
                  onTap:
                      () => setState(() {
                        _never = true;
                        _last = null;
                      }),
                ),
                for (final m in months)
                  Padding(
                    padding: const EdgeInsets.only(left: 6),
                    child: _Pick(
                      text: monthYear(m),
                      selected: !_never && _last?.year == m.year && _last?.month == m.month,
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
          const SizedBox(height: 14),
          Text('Are you eligible?', style: PText.label(OColor.gray800)),
          for (var i = 0; i < 3; i++)
            CheckboxListTile(
              dense: true,
              contentPadding: EdgeInsets.zero,
              controlAffinity: ListTileControlAffinity.leading,
              activeColor: OColor.green600,
              value: _checks[i],
              onChanged: (v) => setState(() => _checks[i] = v ?? false),
              title: Text(_checkLabels[i], style: PText.body(OColor.gray700)),
            ),
          if (!_checks.every((c) => c))
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                "That's okay. Come back when all three are true. We'll keep your spot warm.",
                style: PText.bodyX(OColor.yellow700),
              ),
            ),
          const SizedBox(height: 8),
          AnimatedOpacity(
            duration: PulseMotion.standard,
            opacity: ok ? 1 : 0.4,
            child: IgnorePointer(
              ignoring: !ok,
              child: SlideToAccept(
                label: 'Slide to register',
                onCrimson: false,
                onCommit: () {
                  playBurst(context, BurstKind.hearts);
                  widget.store.registerForNext(group: _group!, last: _last, never: _never);
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Pick extends StatelessWidget {
  final String text;
  final bool selected;
  final VoidCallback onTap;
  const _Pick({required this.text, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onTap: onTap,
      child: AnimatedContainer(
        duration: PulseMotion.micro,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? PulseColors.crimson : OColor.white,
          borderRadius: BorderRadius.circular(OCornerRadius.xl),
          border: Border.all(color: selected ? PulseColors.crimson : OColor.gray300),
        ),
        child: Text(text, style: OTextStyle.labelSmall.copyWith(color: selected ? Colors.white : OColor.gray800)),
      ),
    );
  }
}

// ───────────────────────── 3. This month ─────────────────────────
class _MonthStats extends StatelessWidget {
  final PulseStore store;
  const _MonthStats({required this.store});

  @override
  Widget build(BuildContext context) {
    final heroes = store.heroes.length;
    final units = store.unitsThisMonth + (store.heroes.any((h) => h.isYou) ? 1 : 0);
    Widget stat(int v, String l, {String suffix = ''}) => Expanded(
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CountUp(value: v, style: PText.counter(OColor.gray800).copyWith(fontSize: 30)),
              if (suffix.isNotEmpty) Text(suffix, style: PText.h3(OColor.gray800)),
            ],
          ),
          Text(l, style: PText.bodyX(OColor.gray500)),
        ],
      ),
    );
    return _card(
      child: Column(
        children: [
          Row(children: [stat(heroes, 'heroes'), stat(units, 'units'), stat(units * 3, 'lives touched', suffix: '*')]),
          const SizedBox(height: 14),
          Row(
            children: [
              Ring(
                value: heroes / store.monthlyGoal,
                size: 48,
                stroke: 5,
                color: PulseColors.crimson,
                track: PulseColors.blush,
                child: Icon(FluentIcons.target_arrow_20_filled, color: PulseColors.crimson, size: 18),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$heroes of ${store.monthlyGoal} heroes this month',
                      style: PText.label(OColor.gray800).copyWith(fontWeight: FontWeight.w600),
                    ),
                    Text(
                      '${store.monthlyGoal - heroes} more to hit the campus goal',
                      style: PText.bodyX(OColor.gray500),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text('*Up to 3 lives per donation', style: PText.bodyX(OColor.gray400)),
        ],
      ),
    );
  }
}

// ───────────────────────── 4. Hero Wall ─────────────────────────
class _HeroWall extends StatelessWidget {
  final PulseStore store;
  const _HeroWall({required this.store});

  @override
  Widget build(BuildContext context) {
    final cup = store.hostelCup.entries.toList();
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(FluentIcons.trophy_20_filled, color: PulseColors.gold, size: 18),
              const SizedBox(width: 6),
              Text('Hostel Cup', style: PText.label(OColor.gray800).copyWith(fontWeight: FontWeight.w700)),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              for (var i = 0; i < cup.length; i++)
                Expanded(
                  child: Container(
                    margin: EdgeInsets.only(right: i == cup.length - 1 ? 0 : 6),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      color: i == 0 ? PulseColors.goldSoft : OColor.gray100,
                      borderRadius: BorderRadius.circular(OCornerRadius.s),
                    ),
                    child: Column(
                      children: [
                        Text('#${i + 1}', style: PText.bodyX(i == 0 ? OColor.yellow700 : OColor.gray500)),
                        Text(
                          cup[i].key,
                          style: PText.label(OColor.gray800).copyWith(fontWeight: FontWeight.w600),
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text('${cup[i].value} heroes', style: PText.bodyX(OColor.gray500)),
                      ],
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 14),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: store.heroes.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4,
              mainAxisSpacing: 12,
              crossAxisSpacing: 8,
              childAspectRatio: 0.78,
            ),
            itemBuilder: (_, i) {
              final h = store.heroes[i];
              return EnterIn(
                delay: Duration(milliseconds: 30 * i),
                from: const Offset(0, 10),
                child: GestureDetector(
                  onTap:
                      () =>
                          ScaffoldMessenger.of(context)
                            ..hideCurrentSnackBar()
                            ..showSnackBar(
                              SnackBar(
                                behavior: SnackBarBehavior.floating,
                                content: Text(
                                  h.anonymous
                                      ? 'Anonymous hero • ${h.hostel}'
                                      : '${h.name}, ${h.hostel} • ${_ord(h.nth)} donation',
                                ),
                              ),
                            ),
                  child: Column(
                    children: [
                      Stack(
                        clipBehavior: Clip.none,
                        children: [
                          h.anonymous
                              ? Container(
                                width: 52,
                                height: 52,
                                decoration: BoxDecoration(color: OColor.gray200, shape: BoxShape.circle),
                                child: Icon(FluentIcons.person_24_filled, color: OColor.gray400),
                              )
                              : InitialsAvatar(
                                initials: h.name.substring(0, 1),
                                tint: h.tint,
                                size: 52,
                                ring: h.isYou ? PulseColors.gold : null,
                              ),
                          Positioned(
                            right: -4,
                            bottom: -2,
                            child: DropShape(
                              size: 22,
                              color: PulseColors.crimson,
                              child: Text(
                                h.group,
                                style: const TextStyle(color: Colors.white, fontSize: 6.5, fontWeight: FontWeight.w800),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        h.isYou ? 'You' : h.name,
                        style: PText.bodyX(OColor.gray800).copyWith(fontWeight: FontWeight.w600),
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        h.hostel,
                        style: OTextStyle.bodyXSmall.copyWith(color: OColor.gray500, fontSize: 10),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

String _ord(int n) => switch (n) {
  1 => '1st',
  2 => '2nd',
  3 => '3rd',
  _ => '${n}th',
};

// ───────────────────────── 5. History ─────────────────────────
class _History extends StatelessWidget {
  final PulseStore store;
  const _History({required this.store});

  @override
  Widget build(BuildContext context) {
    final donated = store.history.where((h) => h.outcome == 'Donated').length;
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text('Lives touched', style: PText.body(OColor.gray600))),
              Text('up to ${donated * 3}', style: PText.h3(PulseColors.crimson)),
            ],
          ),
          const SizedBox(height: 10),
          for (var i = 0; i < store.history.length; i++)
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Column(
                    children: [
                      Container(
                        width: 12,
                        height: 12,
                        margin: const EdgeInsets.only(top: 4),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: store.history[i].outcome == 'Donated' ? PulseColors.crimson : OColor.gray400,
                        ),
                      ),
                      if (i < store.history.length - 1) Expanded(child: Container(width: 2, color: OColor.gray200)),
                    ],
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${store.history[i].outcome} • ${store.history[i].hospital}',
                            style: PText.label(OColor.gray800).copyWith(fontWeight: FontWeight.w600),
                          ),
                          Text(
                            '${dayLabel(store.history[i].date)} ${store.history[i].date.year} • ${store.history[i].group}',
                            style: PText.bodyX(OColor.gray500),
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (store.history[i].outcome == 'Donated')
                    Icon(FluentIcons.certificate_20_regular, color: OColor.green600, size: 20),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

// ───────────────────────── 6. Learn ─────────────────────────
class _Learn extends StatelessWidget {
  const _Learn();

  @override
  Widget build(BuildContext context) {
    final cards = [
      (
        'Who can donate?',
        '18–65 years, over 45 kg, healthy on the day. Gap of about 3 months between donations.',
        FluentIcons.person_available_24_regular,
        OColor.green600,
      ),
      (
        'Myth: it makes you weak',
        'Most people are back to normal within hours. Plasma is replaced within about a day.',
        FluentIcons.lightbulb_24_regular,
        OColor.yellow600,
      ),
      (
        'Eat before & after',
        'Light meal 2–3 h before. Iron-rich food after: spinach, rajma, jaggery, dates.',
        FluentIcons.food_apple_24_regular,
        PulseColors.crimson,
      ),
      (
        'Blood types explained',
        'O− gives to everyone. AB+ receives from everyone. Rare groups are always in demand.',
        FluentIcons.drop_24_regular,
        OColor.blue500,
      ),
    ];
    return SizedBox(
      height: 150,
      child: PageView.builder(
        controller: PageController(viewportFraction: 0.86),
        padEnds: false,
        itemCount: cards.length,
        itemBuilder:
            (_, i) => Padding(
              padding: const EdgeInsets.only(right: 10),
              child: _card(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(cards[i].$3, color: cards[i].$4),
                    const SizedBox(height: 8),
                    Text(cards[i].$1, style: PText.label(OColor.gray800).copyWith(fontWeight: FontWeight.w700)),
                    const SizedBox(height: 4),
                    Text(cards[i].$2, style: PText.bodyX(OColor.gray600), maxLines: 3, overflow: TextOverflow.ellipsis),
                  ],
                ),
              ),
            ),
      ),
    );
  }
}

// ───────────────────────── 7. Camps ─────────────────────────
class _Camps extends StatelessWidget {
  final PulseStore store;
  const _Camps({required this.store});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final camps = [
      ('c1', 'NSS Blood Camp', 'Student Activity Centre', now.add(const Duration(days: 9))),
      ('c2', 'Red Cross Drive', 'Core 1 Lobby', now.add(const Duration(days: 23))),
    ];
    return Column(
      children: [
        for (final c in camps)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: _card(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Container(
                    width: 52,
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    decoration: BoxDecoration(
                      color: PulseColors.blush,
                      borderRadius: BorderRadius.circular(OCornerRadius.s),
                    ),
                    child: Column(
                      children: [
                        Text('${c.$4.day}', style: PText.h2(PulseColors.crimson)),
                        Text(dayLabel(c.$4).split(' ').last.toUpperCase(), style: PText.bodyX(PulseColors.crimson)),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(c.$2, style: PText.label(OColor.gray800).copyWith(fontWeight: FontWeight.w700)),
                        Text('${c.$3} • 10 AM – 4 PM', style: PText.bodyX(OColor.gray500)),
                      ],
                    ),
                  ),
                  Pressable(
                    onTap: () => store.toggleCamp(c.$1),
                    child: AnimatedContainer(
                      duration: PulseMotion.micro,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: store.campsJoined.contains(c.$1) ? OColor.green600 : OColor.white,
                        borderRadius: BorderRadius.circular(OCornerRadius.xl),
                        border: Border.all(color: OColor.green600),
                      ),
                      child: Text(
                        store.campsJoined.contains(c.$1) ? "You're going" : "I'll be there",
                        style: OTextStyle.labelXSmall.copyWith(
                          color: store.campsJoined.contains(c.$1) ? Colors.white : OColor.green600,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}
