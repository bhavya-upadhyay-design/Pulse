import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../state/models.dart';
import '../../state/pulse_store.dart';
import '../../theme/bd.dart';
import '../widgets/common.dart';
import '../widgets/motion.dart';
import 'actions.dart';
import 'bingo.dart';
import 'outcome.dart';

/// Replaces the request widget once accepted. Same card family as the
/// request widget; a tracker the NSS coordinator moves forward and the
/// logistics they add appear inside the inner #262626 card.
class DonationEventCard extends StatelessWidget {
  const DonationEventCard({super.key});

  @override
  Widget build(BuildContext context) {
    final s = context.watch<PulseStore>();
    final r = s.request;
    if (r == null) return const SizedBox.shrink();
    final justAccepted = s.acceptedAt != null && DateTime.now().difference(s.acceptedAt!).inSeconds < 4;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(12, 24, 12, 16),
      decoration: BoxDecoration(
        gradient: BD.requestGradient,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: BD.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Heartbeat(strength: 0.6, child: const DropMedallion(size: 40)),
              gap12,
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AnimatedSwitcher(
                      duration: BD.medium,
                      child: Text(
                        justAccepted ? "You're in, ${s.firstName}!" : _headline(s),
                        key: ValueKey(justAccepted ? 'in' : s.stage),
                        style: T.bold(16),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      justAccepted
                          ? "${r.requester}'s family has been told someone's coming."
                          : '${r.group} for ${r.requester} • ${r.hospital}',
                      style: T.regular(12, BD.textSecondary),
                    ),
                  ],
                ),
              ),
              _Overflow(store: s),
            ],
          ),
          const SizedBox(height: 20),
          _Tracker(index: s.stage.trackerIndex, done: s.stage == EventStage.donated),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: BD.card, borderRadius: BorderRadius.circular(16)),
            child: AnimatedSwitcher(
              duration: BD.medium,
              transitionBuilder: (c, a) => FadeTransition(opacity: a, child: SizeTransition(sizeFactor: a, child: c)),
              child: KeyedSubtree(key: ValueKey(s.stage), child: _StageBody(store: s)),
            ),
          ),
        ],
      ),
    );
  }

  String _headline(PulseStore s) => switch (s.stage) {
    EventStage.accepted => 'Coordinate with the POC',
    EventStage.scheduled => 'Your slot is set',
    EventStage.donated => "You're a hero, ${s.firstName}",
    EventStage.missed => s.deferred ? 'You showed up. That counts.' : 'Life happens',
    EventStage.closed => '',
  };
}

class _Overflow extends StatelessWidget {
  final PulseStore store;
  const _Overflow({required this.store});

  @override
  Widget build(BuildContext context) {
    final canDrop = [EventStage.accepted, EventStage.scheduled].contains(store.stage);
    if (!canDrop) return const SizedBox.shrink();
    return PopupMenuButton<String>(
      tooltip: 'More',
      color: BD.card,
      icon: const Icon(FluentIcons.more_vertical_20_regular, color: BD.textSecondary, size: 20),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: const BorderSide(color: BD.border)),
      onSelected:
          (_) => showBdSheet(
            context,
            builder:
                (_) => ReasonSheet(
                  title: "Can't make it anymore?",
                  subtitle: "That's okay. We'll alert Sneha and bring in a standby donor.",
                  reasons: declineReasons.where((r) => r.label != 'Donated recently').toList(),
                  doneTitle: 'Thanks for the heads-up',
                  doneBody: 'Kabir from standby is stepping in.',
                  onPick: (r, _) => store.dropOut(r),
                ),
          ),
      itemBuilder: (_) => [PopupMenuItem(value: 'drop', child: Text("I can't make it anymore", style: T.medium(13, BD.toggleOn)))],
    );
  }
}

/// Five dots on a 2 px line; done steps green, current step pulses.
class _Tracker extends StatelessWidget {
  final int index;
  final bool done;
  const _Tracker({required this.index, required this.done});

  @override
  Widget build(BuildContext context) {
    final n = trackerLabels.length;
    return LayoutBuilder(
      builder: (context, c) {
        final step = (c.maxWidth - 12) / (n - 1);
        return SizedBox(
          height: 34,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned(left: 6, right: 6, top: 5, child: Container(height: 2, color: BD.unitBar.withValues(alpha: 0.5))),
              Positioned(
                left: 6,
                top: 5,
                child: TweenAnimationBuilder<double>(
                  tween: Tween(end: index * step),
                  duration: const Duration(milliseconds: 600),
                  curve: Curves.easeInOutCubic,
                  builder: (_, v, _) => Container(width: v, height: 2, color: BD.green),
                ),
              ),
              for (var i = 0; i < n; i++)
                Positioned(
                  left: i * step,
                  top: 0,
                  child: i == index && !done ? Heartbeat(strength: 2, child: _dot(true, true)) : _dot(i <= index, false),
                ),
              for (var i = 0; i < n; i++)
                Positioned(
                  left: (i * step + 6 - 30).clamp(-2.0, c.maxWidth - 58),
                  width: 60,
                  top: 18,
                  child: Text(
                    trackerLabels[i],
                    textAlign: i == 0 ? TextAlign.left : (i == n - 1 ? TextAlign.right : TextAlign.center),
                    style: (i == index ? T.medium(10) : T.regular(10, BD.textSecondary)),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _dot(bool on, bool current) => AnimatedContainer(
    duration: BD.medium,
    width: 12,
    height: 12,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      color: on ? (current ? Colors.white : BD.green) : BD.card,
      border: Border.all(color: on ? BD.green : BD.unitBar, width: 2),
    ),
  );
}

class _StageBody extends StatelessWidget {
  final PulseStore store;
  const _StageBody({required this.store});

  @override
  Widget build(BuildContext context) {
    final s = store;
    final r = s.request!;
    final slot = s.slot;
    void contactNss() =>
        showContactSheet(context, r.coordinator, line: 'Sneha coordinates your slot and can arrange a ride if you need one.');
    void contactPoc() =>
        showContactSheet(context, r.poc, line: 'Coordinate your visit and ask anything about the patient or the blood bank.');

    switch (s.stage) {
      case EventStage.accepted:
        // Before a slot: NSS coordinator is the main contact.
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _Line(icon: FluentIcons.clock_20_regular, text: 'Sneha will share your donation slot here once it is agreed with the POC.'),
            gap4,
            _RideBlock(store: s),
            gap12,
            BdButton(label: 'Contact NSS coordinator', icon: FluentIcons.chat_20_filled, onTap: contactNss),
            gap8,
            BdButton(label: 'Contact POC', outline: true, icon: FluentIcons.call_20_regular, onTap: contactPoc),
          ],
        );
      case EventStage.scheduled:
        // After the slot: POC becomes the main contact; the student can mark
        // the donation done at any point.
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                DateBadge(date: slot.slotAt!),
                gap12,
                Expanded(
                  child: EventInfo(
                    title: '${r.hospital} Blood Bank',
                    line1: '${dayLabel(slot.slotAt!)} • ${timeLabel(slot.slotAt!)}',
                    line2: 'Donation ~10 min • about 1 h in all',
                  ),
                ),
              ],
            ),
            gap12,
            _Info(fresh: slot.isFresh('address'), icon: FluentIcons.location_20_regular, k: 'Address', v: slot.address!),
            _Info(fresh: slot.isFresh('note'), icon: FluentIcons.food_20_regular, k: 'Before you go', v: slot.note!),
            gap4,
            _RideBlock(store: s),
            gap12,
            BdButton(label: 'Contact POC', icon: FluentIcons.call_20_filled, onTap: contactPoc),
            gap8,
            BdButton(label: 'Contact NSS coordinator', outline: true, icon: FluentIcons.chat_20_regular, onTap: contactNss),
            gap16,
            Container(height: 1, color: BD.border),
            gap16,
            BdButton(
              label: 'Mark donation as completed',
              icon: FluentIcons.heart_20_filled,
              color: BD.toggleOn,
              onTap: () => openDonatedCelebration(context),
            ),
            Center(
              child: TextButton(
                onPressed: () => showMissedSheet(context),
                child: Text("I couldn't make it", style: T.medium(12, BD.textSecondary)),
              ),
            ),
          ],
        );
      case EventStage.donated:
        final done = s.ticked.length;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                SizedBox(
                  width: 42,
                  height: 42,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      TweenAnimationBuilder<double>(
                        tween: Tween(end: done / 9),
                        duration: BD.slow,
                        builder:
                            (_, v, _) => CircularProgressIndicator(
                              value: v,
                              strokeWidth: 3,
                              color: BD.green,
                              backgroundColor: BD.unitBar.withValues(alpha: 0.4),
                            ),
                      ),
                      Text('$done/9', style: T.bold(11)),
                    ],
                  ),
                ),
                gap12,
                Expanded(
                  child: Text(
                    s.donationConfirmed
                        ? 'NSS confirmed your donation. ${9 - done} recovery missions left.'
                        : 'Awaiting NSS confirmation. Start recovering now: ${9 - done} missions.',
                    style: T.regular(12, BD.text700),
                  ),
                ),
              ],
            ),
            gap12,
            BdButton(
              label: done == 0 ? 'Start Recovery Bingo' : 'Continue Recovery Bingo',
              icon: FluentIcons.grid_20_filled,
              onTap: () => Navigator.of(context).push(BingoPage.route()),
            ),
          ],
        );
      case EventStage.missed:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              s.deferred
                  ? 'A deferral is common. Eat iron-rich food and try again soon. You still earned the "Showed up" badge.'
                  : "You're still on the Lifeline list. We'll ask again when it suits you.",
              style: T.regular(12, BD.text700),
              textAlign: TextAlign.center,
            ),
            gap12,
            BdButton(label: 'Done', onTap: s.closeMissed),
          ],
        );
      case EventStage.closed:
        return const SizedBox.shrink();
    }
  }
}

/// Optional ride to the hospital. Most students travel on their own; NSS
/// can arrange a ride on request, or decline if it isn't feasible.
class _RideBlock extends StatelessWidget {
  final PulseStore store;
  const _RideBlock({required this.store});

  @override
  Widget build(BuildContext context) {
    final s = store;
    final slot = s.slot;
    Widget box({required Widget child, Color border = BD.border, Color? bg}) => Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: bg ?? BD.page, borderRadius: BorderRadius.circular(12), border: Border.all(color: border)),
      child: child,
    );
    return AnimatedSwitcher(
      duration: BD.medium,
      child: KeyedSubtree(
        key: ValueKey(s.ride),
        child: switch (s.ride) {
          RideStatus.none => box(
            child: Row(
              children: [
                const Icon(FluentIcons.vehicle_car_20_regular, size: 20, color: BD.textSecondary),
                gap12,
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Travelling on your own?', style: T.bold(12)),
                      const SizedBox(height: 2),
                      Text(
                        'If not, ask NSS for a ride to ${s.request?.hospital ?? 'the hospital'}.',
                        style: T.regular(11, BD.textSecondary),
                      ),
                    ],
                  ),
                ),
                gap8,
                _SmallPill(label: 'Request a ride', onTap: s.requestRide),
              ],
            ),
          ),
          RideStatus.requested => box(
            border: BD.greenCta,
            child: Row(
              children: [
                const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: BD.green)),
                gap12,
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Ride requested', style: T.bold(12)),
                      const SizedBox(height: 2),
                      Text("Sneha will arrange it or let you know if it isn't possible.", style: T.regular(11, BD.textSecondary)),
                    ],
                  ),
                ),
                gap8,
                _SmallPill(label: 'Cancel', onTap: s.cancelRide, muted: true),
              ],
            ),
          ),
          RideStatus.arranged => box(
            border: BD.greenCta,
            bg: BD.greenBadgeBg,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(FluentIcons.checkmark_circle_20_filled, size: 18, color: BD.green),
                    gap8,
                    Text('Ride arranged by NSS', style: T.bold(12, BD.green)),
                  ],
                ),
                gap8,
                _Info(
                  fresh: slot.isFresh('pickup'),
                  icon: FluentIcons.location_20_regular,
                  k: 'Pickup',
                  v: '${slot.pickupPoint} • ${timeLabel(slot.pickupAt!)}',
                ),
                _Info(fresh: slot.isFresh('vehicle'), icon: FluentIcons.vehicle_car_20_regular, k: 'Vehicle', v: slot.vehicle!),
              ],
            ),
          ),
          RideStatus.declined => box(
            child: Row(
              children: [
                const Icon(FluentIcons.vehicle_car_20_regular, size: 20, color: BD.toggleOn),
                gap12,
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("A ride isn't possible right now", style: T.bold(12)),
                      const SizedBox(height: 2),
                      Text('Please travel on your own, or talk to Sneha.', style: T.regular(11, BD.textSecondary)),
                    ],
                  ),
                ),
                gap8,
                _SmallPill(label: 'Ask again', onTap: s.requestRide),
              ],
            ),
          ),
        },
      ),
    );
  }
}

class _SmallPill extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final bool muted;
  const _SmallPill({required this.label, required this.onTap, this.muted = false});

  @override
  Widget build(BuildContext context) => Pressable(
    onTap: onTap,
    child: Container(
      height: 28,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      alignment: Alignment.center,
      decoration: BoxDecoration(border: Border.all(color: muted ? BD.border : BD.greenCta), borderRadius: BorderRadius.circular(71)),
      child: Text(label, style: T.medium(12, muted ? BD.textSecondary : BD.green)),
    ),
  );
}

class _Line extends StatelessWidget {
  final IconData icon;
  final String text;
  const _Line({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Row(children: [Icon(icon, size: 18, color: BD.green), gap8, Expanded(child: Text(text, style: T.regular(12, BD.text700)))]),
  );
}

class _Info extends StatelessWidget {
  final bool fresh;
  final IconData icon;
  final String k;
  final String v;
  const _Info({required this.fresh, required this.icon, required this.k, required this.v});

  @override
  Widget build(BuildContext context) => AnimatedContainer(
    duration: const Duration(milliseconds: 700),
    margin: const EdgeInsets.only(bottom: 6),
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
    decoration: BoxDecoration(color: fresh ? BD.greenBadgeBg : Colors.transparent, borderRadius: BorderRadius.circular(8)),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: BD.textSecondary),
        gap8,
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(fresh ? '$k • Updated just now' : k, style: T.regular(10, fresh ? BD.green : BD.textSecondary)),
              const SizedBox(height: 2),
              Text(v, style: T.medium(12)),
            ],
          ),
        ),
      ],
    ),
  );
}
