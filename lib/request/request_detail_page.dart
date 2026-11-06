import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';
import 'package:onestop_ui/index.dart';
import 'package:provider/provider.dart';

import '../state/models.dart';
import '../state/pulse_store.dart';
import '../theme/pulse_tokens.dart';
import '../widgets/motion.dart';
import '../widgets/shapes.dart';
import 'decline_sheet.dart';
import 'lifeline_card.dart';
import 'slide_to_accept.dart';

/// "See details": calm, factual. Answers is it real → is it safe → what do I get.
class RequestDetailPage extends StatelessWidget {
  final VoidCallback onAccepted;
  const RequestDetailPage({super.key, required this.onAccepted});

  static Route route(VoidCallback onAccepted) => PageRouteBuilder(
    transitionDuration: PulseMotion.morph,
    reverseTransitionDuration: PulseMotion.standard,
    pageBuilder: (_, _, _) => RequestDetailPage(onAccepted: onAccepted),
    transitionsBuilder: (_, a, _, child) {
      final c = CurvedAnimation(parent: a, curve: PulseMotion.standardCurve);
      return FadeTransition(
        opacity: c,
        child: ScaleTransition(
          scale: Tween(begin: 0.94, end: 1.0).animate(c),
          alignment: Alignment.topCenter,
          child: child,
        ),
      );
    },
  );

  @override
  Widget build(BuildContext context) {
    final s = context.watch<PulseStore>();
    final r = s.request;
    if (r == null) {
      return Scaffold(
        backgroundColor: OColor.gray100,
        appBar: AppBar(backgroundColor: OColor.gray100, elevation: 0),
        body: Center(child: Text('This request has closed.', style: PText.body(OColor.gray600))),
      );
    }
    final open = s.phase == AskPhase.open;
    return Scaffold(
      backgroundColor: OColor.gray100,
      body: Stack(
        children: [
          CustomScrollView(
            slivers: [
              SliverToBoxAdapter(child: _Header(store: s, request: r)),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 140),
                sliver: SliverList.list(
                  children: [
                    _Section(delay: 0, title: 'The need', child: _NeedBlock(r: r, s: s)),
                    _Section(
                      delay: 1,
                      title: 'Your point of contact',
                      child: _PersonTile(c: r.poc, line: 'Ask anything about the patient or the blood bank.'),
                    ),
                    _Section(
                      delay: 2,
                      title: 'Your NSS coordinator',
                      child: _PersonTile(
                        c: r.coordinator,
                        line:
                            '${r.coordinator.name.split(' ').first} will plan your pickup and stay with you through it.',
                      ),
                    ),
                    const _Section(delay: 3, title: 'What to expect', child: _ExpectStrip()),
                    const _Section(delay: 4, title: 'What you get', padded: false, child: _RewardsCarousel()),
                    const _Section(delay: 5, title: 'Is it safe?', child: _Faq()),
                    _Section(
                      delay: 6,
                      title: 'Good to know',
                      child: Column(
                        children: const [
                          _Fact(
                            icon: FluentIcons.stethoscope_24_regular,
                            text: 'You get a free mini health check: Hb, blood pressure and weight.',
                          ),
                          _Fact(
                            icon: FluentIcons.arrow_sync_24_regular,
                            text: 'Your body replaces the donated plasma within about a day.',
                          ),
                          _Fact(
                            icon: FluentIcons.timer_24_regular,
                            text: 'The donation itself takes about 10 minutes; door to door about an hour.',
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        'Medical details are pre-screens. The blood bank\'s check-up is final.',
                        style: PText.bodyX(OColor.gray500),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          // Sticky action bar
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              padding: EdgeInsets.fromLTRB(16, 12, 16, 12 + MediaQuery.viewPaddingOf(context).bottom),
              decoration: BoxDecoration(
                color: OColor.white,
                boxShadow: [
                  BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 16, offset: const Offset(0, -4)),
                ],
              ),
              child:
                  open
                      ? Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SlideToAccept(
                            onCrimson: false,
                            onCommit: () {
                              Navigator.of(context).pop();
                              onAccepted();
                            },
                          ),
                          TextButton(
                            onPressed: () => showDeclineSheet(context),
                            child: Text("I can't this time", style: PText.label(OColor.gray600)),
                          ),
                        ],
                      )
                      : Padding(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        child: Text(
                          s.phase == AskPhase.accepted
                              ? "You're in. See your event card on Home."
                              : 'This request is no longer open.',
                          style: PText.label(OColor.gray700),
                          textAlign: TextAlign.center,
                        ),
                      ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final PulseStore store;
  final BloodRequest request;
  const _Header({required this.store, required this.request});

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.viewPaddingOf(context).top;
    return Container(
      decoration: const BoxDecoration(
        gradient: PulseColors.card,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(OCornerRadius.l)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          Positioned(left: 0, right: 0, bottom: 40, child: Opacity(opacity: 0.1, child: EcgLine(color: Colors.white))),
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(height: top),
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 8, 16, 0),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(FluentIcons.arrow_left_24_regular, color: Colors.white),
                    ),
                    Expanded(child: Text('Request ${request.id}', style: PText.label(Colors.white70))),
                  ],
                ),
              ),
              UrgencyStrip(request: request, left: store.timeLeft, finalMinutes: store.finalMinutes),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${request.patientLabel} needs ${request.group} blood at ${request.hospital}.',
                      style: PText.h1(Colors.white).copyWith(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 14),
                    WhyYouChips(store: store),
                    const SizedBox(height: 14),
                    FewOfUsRow(store: store),
                  ],
                ),
              ),
            ],
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
  Widget build(BuildContext context) {
    return EnterIn(
      delay: Duration(milliseconds: 200 + 50 * delay),
      child: Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 4, bottom: 8),
              child: Text(title, style: PText.h3(OColor.gray800)),
            ),
            padded
                ? Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: OColor.white,
                    borderRadius: BorderRadius.circular(OCornerRadius.m),
                    border: Border.all(color: OColor.gray200),
                  ),
                  child: child,
                )
                : child,
          ],
        ),
      ),
    );
  }
}

class _NeedBlock extends StatelessWidget {
  final BloodRequest r;
  final PulseStore s;
  const _NeedBlock({required this.r, required this.s});

  @override
  Widget build(BuildContext context) {
    Widget row(IconData i, String k, String v) => Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(i, size: 20, color: OColor.gray500),
          const SizedBox(width: 10),
          SizedBox(width: 92, child: Text(k, style: PText.body(OColor.gray600))),
          Expanded(child: Text(v, style: PText.body(OColor.gray800).copyWith(fontWeight: FontWeight.w500))),
        ],
      ),
    );
    return Column(
      children: [
        row(
          FluentIcons.person_24_regular,
          'Patient',
          '${r.patientLabel}${r.patientName != null ? ', ${r.patientAge}' : ''} • ${r.patientNote.toLowerCase()}',
        ),
        row(FluentIcons.drop_24_regular, 'Blood group', '${r.group} (whole blood)'),
        row(FluentIcons.box_multiple_24_regular, 'Units', '${r.units} needed • ${s.confirmed} confirmed'),
        row(
          FluentIcons.clock_24_regular,
          'Required by',
          'Within 6 hours • by ${timeLabel(r.deadline.add(const Duration(hours: 4)))}',
        ),
        row(FluentIcons.building_24_regular, 'Hospital', '${r.hospital} Blood Bank, ${r.hospitalArea}'),
        const SizedBox(height: 4),
        // Map thumbnail placeholder
        ClipRRect(
          borderRadius: BorderRadius.circular(OCornerRadius.m),
          child: Container(
            height: 110,
            color: OColor.blue100,
            child: Stack(
              children: [
                Positioned.fill(child: CustomPaint(painter: _MapPainter(OColor.white, OColor.blue200))),
                Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Heartbeat(child: DropShape(size: 30, color: PulseColors.crimson)),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: OColor.white,
                          borderRadius: BorderRadius.circular(OCornerRadius.xl),
                        ),
                        child: Text(
                          '${r.hospital} • ${r.distanceMins.round()} min by NSS van',
                          style: PText.bodyX(OColor.gray800),
                        ),
                      ),
                    ],
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

class _MapPainter extends CustomPainter {
  final Color road, block;
  _MapPainter(this.road, this.block);
  @override
  void paint(Canvas canvas, Size size) {
    final b = Paint()..color = block;
    for (var i = 0; i < 6; i++) {
      for (var j = 0; j < 3; j++) {
        canvas.drawRRect(
          RRect.fromRectAndRadius(Rect.fromLTWH(10 + i * 64.0, 8 + j * 36.0, 48, 24), const Radius.circular(4)),
          b,
        );
      }
    }
    final r =
        Paint()
          ..color = road
          ..strokeWidth = 6
          ..style = PaintingStyle.stroke;
    canvas.drawPath(
      Path()
        ..moveTo(0, size.height * 0.8)
        ..quadraticBezierTo(size.width * 0.4, size.height * 0.2, size.width, size.height * 0.4),
      r,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _PersonTile extends StatelessWidget {
  final Contact c;
  final String line;
  const _PersonTile({required this.c, required this.line});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            InitialsAvatar(initials: c.initials, tint: c.tint, size: 44),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(child: Text(c.name, style: PText.h3(OColor.gray800))),
                      const SizedBox(width: 4),
                      Icon(FluentIcons.checkmark_starburst_16_filled, size: 16, color: OColor.blue500),
                    ],
                  ),
                  Text(c.role, style: PText.bodyX(OColor.gray600)),
                ],
              ),
            ),
            _RoundIcon(
              icon: FluentIcons.call_20_filled,
              onTap:
                  () => showContactSheet(
                    context,
                    name: c.name,
                    role: c.role,
                    phone: c.phone,
                    initials: c.initials,
                    tint: c.tint,
                  ),
            ),
            const SizedBox(width: 8),
            _RoundIcon(
              icon: FluentIcons.chat_20_filled,
              onTap:
                  () => showContactSheet(
                    context,
                    name: c.name,
                    role: c.role,
                    phone: c.phone,
                    initials: c.initials,
                    tint: c.tint,
                  ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Text(line, style: PText.body(OColor.gray600)),
      ],
    );
  }
}

class _RoundIcon extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _RoundIcon({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(color: OColor.green100, shape: BoxShape.circle),
        child: Icon(icon, size: 20, color: OColor.green600),
      ),
    );
  }
}

class _ExpectStrip extends StatelessWidget {
  const _ExpectStrip();

  @override
  Widget build(BuildContext context) {
    const steps = [
      (FluentIcons.vehicle_car_24_regular, 'Pickup', 'From your hostel'),
      (FluentIcons.stethoscope_24_regular, 'Check-up', 'Hb, BP • 10 min'),
      (FluentIcons.drop_24_regular, 'Donate', '~10 min'),
      (FluentIcons.food_cake_24_regular, 'Rest', 'Snacks • 15 min'),
    ];
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < steps.length; i++) ...[
          Expanded(
            child: Column(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(color: PulseColors.blush, shape: BoxShape.circle),
                  child: Icon(steps[i].$1, color: PulseColors.crimson, size: 22),
                ),
                const SizedBox(height: 6),
                Text(steps[i].$2, style: PText.label(OColor.gray800).copyWith(fontWeight: FontWeight.w600)),
                Text(steps[i].$3, style: PText.bodyX(OColor.gray500), textAlign: TextAlign.center),
              ],
            ),
          ),
          if (i < steps.length - 1)
            Padding(
              padding: const EdgeInsets.only(top: 20),
              child: SizedBox(width: 12, child: DashedLine(color: OColor.gray300, dash: 3, gap: 2)),
            ),
        ],
      ],
    );
  }
}

class _RewardsCarousel extends StatelessWidget {
  const _RewardsCarousel();

  @override
  Widget build(BuildContext context) {
    final items = [
      (FluentIcons.ribbon_star_24_filled, 'Hero badge', 'On your OneStop profile', PulseColors.gold),
      (FluentIcons.food_24_filled, 'Iron-rich meal', 'Free at your mess', OColor.green600),
      (FluentIcons.certificate_24_filled, 'NSS certificate', 'Counts toward NSS hours', OColor.blue500),
      (FluentIcons.people_community_24_filled, 'Hero Wall', 'Your name, campus-wide', PulseColors.crimson),
      (FluentIcons.heart_pulse_24_filled, 'Free health check', 'Hb, BP, weight', OColor.red400),
    ];
    return SizedBox(
      height: 118,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: items.length,
        separatorBuilder: (_, _) => const SizedBox(width: 10),
        itemBuilder: (_, i) {
          final it = items[i];
          return ClipPath(
            clipper: const TicketClipper(notchAt: 0.62, notch: 7),
            child: Container(
              width: 150,
              padding: const EdgeInsets.all(12),
              color: OColor.white,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(it.$1, color: it.$4, size: 28),
                  const Spacer(),
                  Text(it.$2, style: PText.label(OColor.gray800).copyWith(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 4),
                  DashedLine(color: OColor.gray300),
                  const SizedBox(height: 4),
                  Text(it.$3, style: PText.bodyX(OColor.gray500), maxLines: 1, overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
          );
        },
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
    (
      'Does it hurt?',
      'A quick pinch when the needle goes in, then nothing much. Most donors say it\'s easier than they expected.',
    ),
    (
      'How long until I feel normal?',
      'Most people feel fine within a few hours. Drink extra water and skip heavy exercise for 24 hours.',
    ),
    ('Can I eat before?', 'Yes, please do. Eat a light, non-oily meal 2–3 hours before and drink 500 ml of water.'),
    (
      'What if I feel faint?',
      'Staff watch you the whole time. You\'ll lie down, legs up, and it passes in minutes. Sneha stays with you.',
    ),
    (
      'Who shouldn\'t donate?',
      'Anyone unwell, on antibiotics, with a recent tattoo or piercing (6 months), or under 45 kg. The blood bank confirms on the spot.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (var i = 0; i < _qa.length; i++) ...[
          InkWell(
            onTap: () => setState(() => _open = _open == i ? null : i),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Row(
                children: [
                  Expanded(
                    child: Text(_qa[i].$1, style: PText.label(OColor.gray800).copyWith(fontWeight: FontWeight.w600)),
                  ),
                  AnimatedRotation(
                    turns: _open == i ? 0.5 : 0,
                    duration: PulseMotion.standard,
                    child: Icon(FluentIcons.chevron_down_20_regular, color: OColor.gray500),
                  ),
                ],
              ),
            ),
          ),
          AnimatedSize(
            duration: PulseMotion.standard,
            curve: PulseMotion.standardCurve,
            child:
                _open == i
                    ? Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Text(_qa[i].$2, style: PText.body(OColor.gray600)),
                      ),
                    )
                    : const SizedBox(width: double.infinity),
          ),
          if (i < _qa.length - 1) Divider(height: 1, color: OColor.gray200),
        ],
      ],
    );
  }
}

class _Fact extends StatelessWidget {
  final IconData icon;
  final String text;
  const _Fact({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: OColor.green600),
          const SizedBox(width: 10),
          Expanded(child: Text(text, style: PText.body(OColor.gray700))),
        ],
      ),
    );
  }
}
