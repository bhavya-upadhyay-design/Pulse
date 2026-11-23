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
    EventStage.accepted => 'Sneha is setting your slot',
    EventStage.scheduled => 'Your slot is booked',
    EventStage.pickup => 'Your ride is on the way',
    EventStage.atBank => "You've got this, ${s.firstName}",
    EventStage.awaitingOutcome => 'How did it go?',
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
    final canDrop = [EventStage.accepted, EventStage.scheduled, EventStage.pickup].contains(store.stage);
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
    final coordinator = BdButton(
      label: 'Contact NSS coordinator',
      icon: FluentIcons.chat_20_filled,
      onTap:
          () =>
              showContactSheet(context, r.coordinator, line: 'Sneha is planning your slot and pickup, and will stay with you through it.'),
    );
    final poc = BdButton(
      label: 'Contact POC',
      outline: true,
      icon: FluentIcons.call_20_regular,
      onTap: () => showContactSheet(context, r.poc, line: 'Ask anything about the patient or the blood bank.'),
    );

    switch (s.stage) {
      case EventStage.accepted:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _Line(icon: FluentIcons.calendar_checkmark_20_regular, text: 'Added to your OneStop calendar. Reminder 2 h before.'),
            _Line(icon: FluentIcons.clock_20_regular, text: 'Slot and pickup usually confirmed within 3 hours.'),
            gap12,
            coordinator,
            gap8,
            poc,
          ],
        );
      case EventStage.scheduled:
      case EventStage.pickup:
      case EventStage.atBank:
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
                    line2: 'Donation ~10 min • about 1 h door to door',
                  ),
                ),
              ],
            ),
            gap12,
            _Info(
              fresh: slot.isFresh('pickup'),
              icon: FluentIcons.vehicle_car_20_regular,
              k: 'Pickup',
              v: '${slot.pickupPoint} • ${timeLabel(slot.pickupAt!)}',
            ),
            _Info(fresh: slot.isFresh('address'), icon: FluentIcons.location_20_regular, k: 'Address', v: slot.address!),
            if (slot.vehicle != null)
              _Info(fresh: slot.isFresh('vehicle'), icon: FluentIcons.vehicle_bus_20_regular, k: 'Vehicle', v: slot.vehicle!),
            _Info(fresh: slot.isFresh('note'), icon: FluentIcons.food_20_regular, k: 'Before you go', v: slot.note!),
            gap12,
            coordinator,
            gap8,
            poc,
          ],
        );
      case EventStage.awaitingOutcome:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Your slot time has passed. Let us know in one tap.', style: T.regular(12, BD.textSecondary), textAlign: TextAlign.center),
            gap12,
            Heartbeat(
              strength: 0.3,
              child: BdButton(
                label: 'I donated',
                icon: FluentIcons.heart_20_filled,
                color: BD.toggleOn,
                onTap: () => openDonatedCelebration(context),
              ),
            ),
            gap8,
            BdButton(label: "I couldn't make it", outline: true, color: BD.textSecondary, onTap: () => showMissedSheet(context)),
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
