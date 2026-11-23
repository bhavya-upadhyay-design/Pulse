import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../state/models.dart';
import '../../state/pulse_store.dart';
import '../../theme/bd.dart';
import '../flows/actions.dart';
import '../flows/event_card.dart';
import '../flows/sheets.dart';
import '../widgets/common.dart';
import '../widgets/motion.dart';
import '../widgets/request_widget.dart';

/// My Donations (Figma 1810:6337).
class MyDonationsTab extends StatelessWidget {
  final VoidCallback goExplore;
  const MyDonationsTab({super.key, required this.goExplore});

  @override
  Widget build(BuildContext context) {
    final s = context.watch<PulseStore>();
    final bottom = MediaQuery.viewPaddingOf(context).bottom;
    return ListView(
      padding: EdgeInsets.fromLTRB(12, 39, 12, 100 + bottom),
      children: [
        Padding(padding: const EdgeInsets.only(left: 2), child: EnterIn(child: EligibilityHeader(store: s))),
        const SizedBox(height: 21),
        EnterIn(
          delay: const Duration(milliseconds: 60),
          child: BdCard(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 20),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Available for requests', style: T.bold(14)),
                      gap8,
                      Text(
                        s.available
                            ? 'We will notify you when you are eligible.\nYou can pause anytime'
                            : "Paused. You won't get requests until you turn this back on.",
                        style: T.regular(12, BD.textSecondary),
                      ),
                    ],
                  ),
                ),
                gap8,
                BdToggle(value: s.available, onChanged: s.setAvailable, label: 'Available for requests'),
              ],
            ),
          ),
        ),
        const SizedBox(height: 7),
        _LiveCard(store: s),
        const SizedBox(height: 21),
        EnterIn(
          delay: const Duration(milliseconds: 120),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SectionTitle('Your Donations'),
              const SizedBox(height: 17),
              if (s.history.isEmpty)
                BdCard(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Text('No donations yet', style: T.bold(14)),
                      gap8,
                      Text(
                        'Pick a camp in Explore and your first donation shows up here.',
                        textAlign: TextAlign.center,
                        style: T.regular(12, BD.textSecondary),
                      ),
                      gap12,
                      BdButton(label: 'See upcoming camps', outline: true, onTap: goExplore),
                    ],
                  ),
                ),
              for (final h in s.history) ...[_DonationRow(record: h), const SizedBox(height: 17)],
            ],
          ),
        ),
      ],
    );
  }
}

/// Request widget, event card or a closed-ask note, morphing between them.
class _LiveCard extends StatelessWidget {
  final PulseStore store;
  const _LiveCard({required this.store});

  @override
  Widget build(BuildContext context) {
    final s = store;
    Widget? child;
    if (s.phase == AskPhase.open) {
      child = RequestWidget(
        key: const ValueKey('ask'),
        onAccept: () => acceptRequest(context),
        onDetails: () => openRequestDetails(context),
        onDecline: () => openDecline(context),
      );
    } else if (s.eventActive) {
      child = const DonationEventCard(key: ValueKey('event'));
    } else if (s.request != null) {
      child = ClosedAskNote(key: ValueKey(s.phase), store: s);
    }
    return AnimatedSize(
      duration: BD.slow,
      curve: Curves.easeOutCubic,
      alignment: Alignment.topCenter,
      child: AnimatedSwitcher(
        duration: BD.slow,
        transitionBuilder:
            (c, a) => FadeTransition(opacity: a, child: ScaleTransition(scale: Tween(begin: 0.96, end: 1.0).animate(a), child: c)),
        layoutBuilder: (cur, prev) => Stack(alignment: Alignment.topCenter, children: [...prev, if (cur != null) cur]),
        child:
            child == null
                ? const SizedBox(key: ValueKey('none'), width: double.infinity)
                : Padding(key: child.key, padding: const EdgeInsets.only(top: 1), child: child),
      ),
    );
  }
}

/// Ring + "You'll be eligible to donate in / 45 days" (Figma Frame 344).
class EligibilityHeader extends StatelessWidget {
  final PulseStore store;
  const EligibilityHeader({super.key, required this.store});

  @override
  Widget build(BuildContext context) {
    final waiting = store.eligibility == Eligibility.waiting;
    final unknown = store.eligibility == Eligibility.unknown;
    final label =
        unknown
            ? 'Add your blood group to get matched'
            : waiting
            ? 'You’ll be eligible to donate in'
            : 'You’re eligible to donate';
    final value = unknown ? 'Not set' : (waiting ? '${store.daysToEligible} days' : 'Ready now');
    return GestureDetector(
      onTap: unknown ? () => showBecomeLifeline(context) : null,
      child: Row(
        children: [
          EligibilityRing(progress: unknown ? 0 : (waiting ? store.eligibilityProgress : 1)),
          gap16,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [Text(label, style: T.medium(12, BD.text700)), const SizedBox(height: 15), Text(value, style: T.medium(32))],
            ),
          ),
        ],
      ),
    );
  }
}

/// 74 px ring: cream #fdfcf1 track, #fd445f progress arc, #1c1c1c centre,
/// drop icon in the middle (Figma Frame 341 / Ellipse 51-52).
class EligibilityRing extends StatelessWidget {
  final double progress;
  const EligibilityRing({super.key, required this.progress});

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: progress),
      duration: const Duration(milliseconds: 1100),
      curve: Curves.easeOutCubic,
      builder: (_, v, child) => SizedBox(width: 74, height: 74, child: CustomPaint(painter: _RingPainter(v), child: child)),
      child: Center(child: bdSvg('drop_flame', width: 21.875, height: 25.94)),
    );
  }
}

class _RingPainter extends CustomPainter {
  final double v;
  _RingPainter(this.v);

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    canvas.drawCircle(c, 37, Paint()..color = const Color(0xFFFDFCF1));
    if (v > 0) {
      canvas.drawArc(
        Rect.fromCircle(center: c, radius: 35),
        -math.pi / 2,
        2 * math.pi * v,
        false,
        Paint()
          ..color = BD.toggleOn
          ..style = PaintingStyle.stroke
          ..strokeWidth = 4
          ..strokeCap = StrokeCap.round,
      );
    }
    canvas.drawCircle(c, 33, Paint()..color = BD.page);
  }

  @override
  bool shouldRepaint(covariant _RingPainter old) => old.v != v;
}

/// "Your Donations" row: date badge, info, certificate icon (Figma Frame 329).
class _DonationRow extends StatelessWidget {
  final DonationRecord record;
  const _DonationRow({required this.record});

  @override
  Widget build(BuildContext context) {
    return BdCard(
      child: Row(
        children: [
          DateBadge(date: record.date),
          gap12,
          Expanded(child: EventInfo(title: record.name, line1: record.place, line2: record.hours)),
          SizedBox(
            width: 68,
            height: 26,
            child: Semantics(
              button: true,
              label: record.certificate ? 'View certificate' : 'Certificate pending',
              child: Pressable(
                onTap: () => showCertificate(context, record),
                child: Center(child: Opacity(opacity: record.certificate ? 1 : 0.35, child: bdSvg('certificate', width: 24, height: 24))),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Shown after an ask closes without an event (covered, expired, declined…).
class ClosedAskNote extends StatelessWidget {
  final PulseStore store;
  const ClosedAskNote({super.key, required this.store});

  @override
  Widget build(BuildContext context) {
    final (title, body) = switch (store.phase) {
      AskPhase.covered => ('Covered! ${store.request?.units ?? 3} heroes said yes.', "We'll call on you next time, ${store.firstName}."),
      AskPhase.expired => ('No worries, we found others this time.', "The response window closed. You're still on the list."),
      AskPhase.declined => ('Thanks for telling us quickly.', "We've passed this to the next donor."),
      AskPhase.cancelled => ('Not needed anymore, thank you.', 'The hospital found blood. Nothing counts against you.'),
      _ => ('', ''),
    };
    return BdCard(
      padding: const EdgeInsets.fromLTRB(16, 16, 8, 16),
      border: Border.all(color: BD.border),
      child: Row(
        children: [
          const DropMedallion(size: 36),
          gap12,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [Text(title, style: T.bold(14)), const SizedBox(height: 4), Text(body, style: T.regular(12, BD.textSecondary))],
            ),
          ),
          IconButton(
            tooltip: 'Dismiss',
            onPressed: store.dismissAsk,
            icon: const Icon(Icons.close_rounded, color: BD.textSecondary, size: 18),
          ),
        ],
      ),
    );
  }
}
