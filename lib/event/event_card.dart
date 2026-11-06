import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';
import 'package:onestop_ui/index.dart';
import 'package:provider/provider.dart';

import '../bingo/bingo_page.dart';
import '../request/decline_sheet.dart';
import '../request/request_detail_page.dart';
import '../state/models.dart';
import '../state/pulse_store.dart';
import '../theme/pulse_tokens.dart';
import '../widgets/motion.dart';
import '../widgets/shapes.dart';
import 'outcome_flows.dart';

/// Pinned at the top of Home after accepting. Live-order style tracker that
/// the NSS coordinator moves forward; logistics appear as they're added.
class DonationEventCard extends StatelessWidget {
  const DonationEventCard({super.key});

  @override
  Widget build(BuildContext context) {
    final s = context.watch<PulseStore>();
    final r = s.request;
    if (r == null) return const SizedBox.shrink();
    return Container(
      decoration: BoxDecoration(
        color: OColor.white,
        borderRadius: BorderRadius.circular(OCornerRadius.l),
        border: Border.all(color: OColor.gray200),
        boxShadow: [
          BoxShadow(color: OColor.gray300.withValues(alpha: 0.25), blurRadius: 14, offset: const Offset(0, 4)),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          Positioned(
            left: 0,
            top: 0,
            bottom: 0,
            child: AnimatedContainer(
              duration: PulseMotion.standard,
              width: 4,
              color: s.stage == EventStage.donated ? OColor.green600 : PulseColors.crimson,
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 14, 8, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    DropShape(size: 18, color: PulseColors.crimson),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'BLOOD DONATION • ${r.group} • ${r.hospital}',
                        style: OTextStyle.labelXSmall.copyWith(
                          color: PulseColors.crimson,
                          letterSpacing: 0.6,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    if (s.standby)
                      PChip(
                        text: 'Standby',
                        bg: PulseColors.goldSoft,
                        fg: OColor.yellow700,
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      ),
                    _Overflow(store: s),
                  ],
                ),
                const SizedBox(height: 10),
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: Tracker(index: s.stage.trackerIndex, done: s.stage == EventStage.donated),
                ),
                const SizedBox(height: 14),
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: AnimatedSwitcher(
                    duration: PulseMotion.standard,
                    transitionBuilder:
                        (c, a) => FadeTransition(
                          opacity: a,
                          child: SlideTransition(
                            position: Tween(begin: const Offset(0, 0.08), end: Offset.zero).animate(a),
                            child: c,
                          ),
                        ),
                    layoutBuilder:
                        (cur, prev) => Stack(alignment: Alignment.topLeft, children: [...prev, if (cur != null) cur]),
                    child: KeyedSubtree(key: ValueKey(s.stage), child: _StageBody(store: s)),
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

class _Overflow extends StatelessWidget {
  final PulseStore store;
  const _Overflow({required this.store});

  @override
  Widget build(BuildContext context) {
    final canDrop = [EventStage.accepted, EventStage.scheduled, EventStage.pickup].contains(store.stage);
    return PopupMenuButton<String>(
      icon: Icon(FluentIcons.more_vertical_20_regular, color: OColor.gray500, size: 20),
      padding: EdgeInsets.zero,
      color: OColor.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(OCornerRadius.m)),
      onSelected: (v) {
        if (v == 'details') Navigator.of(context).push(RequestDetailPage.route(() {}));
        if (v == 'drop') {
          showPulseSheet(
            context,
            builder:
                (_) => ReasonSheet(
                  title: "Can't make it anymore?",
                  subtitle: "That's okay. We'll alert Sneha and bring in a standby donor.",
                  reasons: declineReasons.where((r) => r.label != 'Donated recently').toList(),
                  confirmTitle: 'Thanks for the heads-up',
                  confirmBody: 'Kabir from standby is stepping in.',
                  onPick: (r, _) => Future.delayed(const Duration(milliseconds: 1500), () => store.dropOut(r)),
                ),
          );
        }
      },
      itemBuilder:
          (_) => [
            PopupMenuItem(value: 'details', child: Text('Request details', style: PText.body(OColor.gray800))),
            if (canDrop)
              PopupMenuItem(value: 'drop', child: Text("I can't make it anymore", style: PText.body(OColor.red500))),
          ],
    );
  }
}

/// 6-dot tracker with a blood drop that rides between stages.
class Tracker extends StatelessWidget {
  final int index;
  final bool done;
  const Tracker({super.key, required this.index, this.done = false});

  @override
  Widget build(BuildContext context) {
    final n = trackerLabels.length;
    return LayoutBuilder(
      builder: (context, c) {
        final w = c.maxWidth;
        final step = (w - 14) / (n - 1);
        return SizedBox(
          height: 46,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned(
                left: 7,
                right: 7,
                top: 13,
                child: Container(
                  height: 3,
                  decoration: BoxDecoration(color: OColor.gray200, borderRadius: BorderRadius.circular(2)),
                ),
              ),
              Positioned(
                left: 7,
                top: 13,
                child: TweenAnimationBuilder<double>(
                  tween: Tween(end: index * step),
                  duration: const Duration(milliseconds: 600),
                  curve: PulseMotion.standardCurve,
                  builder:
                      (_, v, _) => Container(
                        width: v,
                        height: 3,
                        decoration: BoxDecoration(
                          color: done ? OColor.green600 : PulseColors.crimson,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                ),
              ),
              for (var i = 0; i < n; i++)
                Positioned(
                  left: i * step + 7 - (i == index ? 7 : 5),
                  top: 14.5 - (i == index ? 7 : 5),
                  child: AnimatedContainer(
                    duration: PulseMotion.emphasis,
                    curve: Curves.easeOutBack,
                    width: i == index ? 14 : 10,
                    height: i == index ? 14 : 10,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: i <= index ? (done ? OColor.green600 : PulseColors.crimson) : OColor.white,
                      border: Border.all(color: i <= index ? Colors.transparent : OColor.gray300, width: 2),
                      boxShadow:
                          i == index
                              ? [
                                BoxShadow(
                                  color: (done ? OColor.green600 : PulseColors.crimson).withValues(alpha: 0.3),
                                  blurRadius: 0,
                                  spreadRadius: 4,
                                ),
                              ]
                              : null,
                    ),
                  ),
                ),
              // The riding drop
              TweenAnimationBuilder<double>(
                tween: Tween(end: index * step),
                duration: const Duration(milliseconds: 600),
                curve: PulseMotion.standardCurve,
                builder:
                    (_, v, _) => Positioned(
                      left: v + 7 - 6,
                      top: -6,
                      child: Heartbeat(child: DropShape(size: 12, color: done ? OColor.green600 : PulseColors.crimson)),
                    ),
              ),
              for (var i = 0; i < n; i++)
                Positioned(
                  left: (i * step + 7 - 30).clamp(-4.0, w - 56),
                  width: 60,
                  top: 26,
                  child: Text(
                    trackerLabels[i],
                    textAlign: i == 0 ? TextAlign.left : (i == n - 1 ? TextAlign.right : TextAlign.center),
                    style: OTextStyle.bodyXSmall.copyWith(
                      fontSize: 10,
                      color: i == index ? OColor.gray800 : OColor.gray500,
                      fontWeight: i == index ? FontWeight.w700 : FontWeight.w400,
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _StageBody extends StatelessWidget {
  final PulseStore store;
  const _StageBody({required this.store});

  @override
  Widget build(BuildContext context) {
    final s = store;
    final r = s.request;
    if (r == null) return const SizedBox.shrink();
    final slot = s.slot;
    final coord = r.coordinator;

    Widget headline(String t, [String? sub]) => Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(t, style: PText.h2(OColor.gray800).copyWith(fontSize: 19)),
        if (sub != null) ...[const SizedBox(height: 4), Text(sub, style: PText.body(OColor.gray600))],
      ],
    );

    final contactCoordinator = _Cta(
      label: 'Contact NSS coordinator',
      icon: FluentIcons.chat_24_filled,
      primary: true,
      onTap:
          () => showContactSheet(
            context,
            name: coord.name,
            role: coord.role,
            phone: coord.phone,
            initials: coord.initials,
            tint: coord.tint,
            line: '${coord.name.split(' ').first} is planning your slot and pickup.',
          ),
    );
    final contactPoc = _Cta(
      label: 'Contact POC',
      icon: FluentIcons.call_24_regular,
      onTap:
          () => showContactSheet(
            context,
            name: r.poc.name,
            role: r.poc.role,
            phone: r.poc.phone,
            initials: r.poc.initials,
            tint: r.poc.tint,
          ),
    );

    switch (s.stage) {
      case EventStage.accepted:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            headline(
              "You're in. ${coord.name.split(' ').first} will set your slot.",
              'Usually within 3 hours. We\'ll ping you the moment it\'s set.',
            ),
            const SizedBox(height: 12),
            _Calendared(),
            const SizedBox(height: 12),
            contactCoordinator,
            const SizedBox(height: 8),
            contactPoc,
          ],
        );
      case EventStage.scheduled:
      case EventStage.pickup:
      case EventStage.atBank:
        final pickupStage = s.stage == EventStage.pickup;
        final bank = s.stage == EventStage.atBank;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (bank)
              headline(
                "You've got this, ${s.firstName}",
                'Breathe slowly and keep sipping water. Sneha is right there.',
              )
            else if (pickupStage)
              headline('Your ride leaves ${slot.pickupPoint} soon', 'Be at the gate by ${timeLabel(slot.pickupAt!)}.')
            else
              headline('${dayLabel(slot.slotAt!)} • ${timeLabel(slot.slotAt!)}', 'Your donation slot is booked.'),
            const SizedBox(height: 12),
            _InfoRow(
              fresh: slot.isFresh('pickup'),
              icon: FluentIcons.vehicle_car_24_regular,
              k: 'Pickup',
              v: '${slot.pickupPoint} • ${timeLabel(slot.pickupAt!)}',
            ),
            _InfoRow(
              fresh: slot.isFresh('address'),
              icon: FluentIcons.location_24_regular,
              k: 'Address',
              v: slot.address!,
            ),
            if (slot.vehicle != null)
              _InfoRow(
                fresh: slot.isFresh('vehicle'),
                icon: FluentIcons.vehicle_bus_24_regular,
                k: 'Vehicle',
                v: slot.vehicle!,
              ),
            if (slot.note != null)
              _InfoRow(
                fresh: slot.isFresh('note'),
                icon: FluentIcons.food_24_regular,
                k: 'Before you go',
                v: slot.note!,
              ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child:
                      pickupStage
                          ? _Cta(
                            label: 'Call coordinator',
                            icon: FluentIcons.call_24_filled,
                            primary: true,
                            onTap:
                                () => showContactSheet(
                                  context,
                                  name: coord.name,
                                  role: coord.role,
                                  phone: coord.phone,
                                  initials: coord.initials,
                                  tint: coord.tint,
                                ),
                          )
                          : bank
                          ? contactPoc
                          : _Cta(
                            label: 'Add to calendar',
                            icon: FluentIcons.calendar_add_24_regular,
                            primary: true,
                            onTap:
                                () => ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Added to your phone calendar (prototype)'),
                                    behavior: SnackBarBehavior.floating,
                                  ),
                                ),
                          ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child:
                      pickupStage
                          ? _Cta(
                            label: 'Directions',
                            icon: FluentIcons.directions_24_regular,
                            onTap:
                                () => ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Opening maps (prototype)'),
                                    behavior: SnackBarBehavior.floating,
                                  ),
                                ),
                          )
                          : bank
                          ? contactCoordinator
                          : contactPoc,
                ),
              ],
            ),
          ],
        );
      case EventStage.awaitingOutcome:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            headline('How did it go, ${s.firstName}?', 'Your slot time has passed. Let us know in one tap.'),
            const SizedBox(height: 14),
            Heartbeat(
              strength: 0.4,
              child: _Cta(
                label: 'I donated',
                icon: FluentIcons.heart_24_filled,
                primary: true,
                crimson: true,
                onTap: () => openDonatedCelebration(context),
              ),
            ),
            const SizedBox(height: 8),
            _Cta(
              label: "I couldn't make it",
              icon: FluentIcons.dismiss_circle_24_regular,
              onTap: () => showMissedSheet(context),
            ),
          ],
        );
      case EventStage.donated:
        final done = s.ticked.length;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            headline(
              'Hero #${s.heroNumber} this month',
              s.donationConfirmed
                  ? 'NSS confirmed your donation. Recovery has begun.'
                  : 'Awaiting NSS confirmation. Start recovering now.',
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Ring(
                  value: done / 9,
                  size: 44,
                  stroke: 4,
                  color: OColor.green600,
                  track: OColor.gray200,
                  child: Text(
                    '$done/9',
                    style: OTextStyle.labelXSmall.copyWith(color: OColor.gray800, fontWeight: FontWeight.w700),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Recovery Bingo: ${9 - done} missions left. Full house closes your event.',
                    style: PText.body(OColor.gray700),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _Cta(
              label: done == 0 ? 'Start Recovery Bingo' : 'Continue Bingo',
              icon: FluentIcons.grid_24_filled,
              primary: true,
              onTap: () => Navigator.of(context).push(BingoPage.route()),
            ),
          ],
        );
      case EventStage.missed:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            headline(
              s.deferred ? 'You showed up. That counts.' : 'Life happens.',
              s.deferred
                  ? 'A deferral is common. Eat iron-rich food and you can try again soon. You earned the "Showed up" badge.'
                  : "You're still on the Lifeline list. We'll ask again when it suits you.",
            ),
            const SizedBox(height: 12),
            _Cta(label: 'Done', icon: FluentIcons.checkmark_24_regular, primary: true, onTap: s.closeMissed),
          ],
        );
      case EventStage.closed:
        return const SizedBox.shrink();
    }
  }
}

class _Calendared extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(color: OColor.gray100, borderRadius: BorderRadius.circular(OCornerRadius.m)),
      child: Row(
        children: [
          Icon(FluentIcons.calendar_checkmark_24_regular, color: OColor.green600, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text('Added to your OneStop calendar. Reminder 2 h before.', style: PText.bodyX(OColor.gray700)),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final bool fresh;
  final IconData icon;
  final String k;
  final String v;
  const _InfoRow({required this.fresh, required this.icon, required this.k, required this.v});

  @override
  Widget build(BuildContext context) {
    return EnterIn(
      from: const Offset(0, 8),
      duration: PulseMotion.standard,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 600),
        margin: const EdgeInsets.only(bottom: 6),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: BoxDecoration(
          color: fresh ? OColor.yellow100 : Colors.transparent,
          borderRadius: BorderRadius.circular(OCornerRadius.s),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 18, color: OColor.gray500),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(k, style: PText.bodyX(OColor.gray500)),
                      if (fresh) ...[
                        const SizedBox(width: 6),
                        Text(
                          '• Updated just now',
                          style: PText.bodyX(OColor.yellow700).copyWith(fontWeight: FontWeight.w600),
                        ),
                      ],
                    ],
                  ),
                  Text(v, style: PText.body(OColor.gray800).copyWith(fontWeight: FontWeight.w500)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Cta extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool primary;
  final bool crimson;
  final VoidCallback onTap;
  const _Cta({
    required this.label,
    required this.icon,
    required this.onTap,
    this.primary = false,
    this.crimson = false,
  });

  @override
  Widget build(BuildContext context) {
    final bg = primary ? (crimson ? PulseColors.crimson : OColor.green600) : OColor.white;
    final fg = primary ? Colors.white : OColor.green600;
    return Pressable(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 13, horizontal: 10),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(OCornerRadius.l),
          border: primary ? null : Border.all(color: OColor.green600),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 18, color: fg),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                label,
                style: OTextStyle.labelSmall.copyWith(color: fg, fontWeight: FontWeight.w600),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
