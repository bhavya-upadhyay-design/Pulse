import 'dart:async';
import 'dart:ui';

import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';
import 'package:onestop_ui/index.dart';
import 'package:provider/provider.dart';

import '../event/event_card.dart';
import '../request/lifeline_card.dart';
import '../state/models.dart';
import '../state/pulse_store.dart';
import '../theme/pulse_tokens.dart';
import '../widgets/motion.dart';
import 'onestop_placeholders.dart';

/// OneStop Home. Everything except the blood-donation card is a static,
/// non-functional replica of the existing Home so the takeover can be judged
/// in context.
class HomeTab extends StatefulWidget {
  final VoidCallback onAccept;
  final VoidCallback openHub;
  const HomeTab({super.key, required this.onAccept, required this.openHub});

  @override
  State<HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<HomeTab> {
  bool _later = false;
  Timer? _momentTimer;
  AskPhase? _lastPhase;

  @override
  void dispose() {
    _momentTimer?.cancel();
    super.dispose();
  }

  void _nudge(PulseStore s) {
    final name = s.request?.patientName ?? 'this';
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: OColor.gray800,
          content: Text("Answer $name's request first?"),
          action: SnackBarAction(
            label: 'Later',
            textColor: PulseColors.gold,
            onPressed: () => setState(() => _later = true),
          ),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final s = context.watch<PulseStore>();
    if (_lastPhase != s.phase) {
      if (s.phase == AskPhase.open) _later = false;
      _lastPhase = s.phase;
    }
    final takeover = s.phase == AskPhase.open && !_later;
    final inMoment =
        s.acceptedAt != null && DateTime.now().difference(s.acceptedAt!) < const Duration(milliseconds: 2400);
    if (inMoment && (_momentTimer == null || !_momentTimer!.isActive)) {
      _momentTimer = Timer(const Duration(milliseconds: 2450), () => mounted ? setState(() {}) : null);
    }

    Widget? pinned;
    if (s.phase == AskPhase.open) {
      pinned = KeyedSubtree(key: const ValueKey('ask'), child: LifelineCard(onAccepted: widget.onAccept));
    } else if (inMoment) {
      pinned = const KeyedSubtree(key: ValueKey('moment'), child: _AcceptedMoment());
    } else if (s.eventActive) {
      pinned = const KeyedSubtree(key: ValueKey('event'), child: DonationEventCard());
    } else if (s.request != null &&
        const [AskPhase.covered, AskPhase.expired, AskPhase.declined, AskPhase.cancelled].contains(s.phase)) {
      pinned = KeyedSubtree(key: ValueKey('closed-${s.phase}'), child: _ClosedAskCard(store: s));
    }

    final rest = Column(
      children: const [
        HomeCarouselPlaceholder(),
        SizedBox(height: 10),
        TimetablePlaceholder(),
        SizedBox(height: 8),
        FoodGateLogRow(),
        SizedBox(height: 8),
      ],
    );

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(OCornerRadius.l),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AnimatedSize(
                duration: PulseMotion.morph,
                curve: PulseMotion.standardCurve,
                alignment: Alignment.topCenter,
                child: AnimatedSwitcher(
                  duration: PulseMotion.morph,
                  switchInCurve: PulseMotion.springCurve,
                  switchOutCurve: Curves.easeIn,
                  transitionBuilder:
                      (c, a) => FadeTransition(
                        opacity: a,
                        child: SlideTransition(
                          position: Tween(begin: const Offset(0, -0.06), end: Offset.zero).animate(a),
                          child: ScaleTransition(scale: Tween(begin: 0.96, end: 1.0).animate(a), child: c),
                        ),
                      ),
                  layoutBuilder:
                      (cur, prev) => Stack(alignment: Alignment.topCenter, children: [...prev, if (cur != null) cur]),
                  child:
                      pinned == null
                          ? const SizedBox(key: ValueKey('none'), width: double.infinity)
                          : Padding(key: pinned.key, padding: const EdgeInsets.only(bottom: 12), child: pinned),
                ),
              ),
              // Everything else goes secondary while the ask is open.
              _Dimmable(
                dim: takeover,
                onBlockedTap: () => _nudge(s),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    rest,
                    QuickAccessGrid(openHub: widget.openHub),
                    const SizedBox(height: 10),
                    const QuickLinksPlaceholder(),
                    const SizedBox(height: 140),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Dimmable extends StatelessWidget {
  final bool dim;
  final Widget child;
  final VoidCallback onBlockedTap;
  const _Dimmable({required this.dim, required this.child, required this.onBlockedTap});

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(end: dim ? 1 : 0),
      duration: PulseMotion.standard,
      curve: PulseMotion.standardCurve,
      builder: (_, v, c) {
        Widget w = Opacity(opacity: 1 - 0.6 * v, child: Transform.scale(scale: 1 - 0.02 * v, child: c));
        if (v > 0.01) {
          w = ImageFiltered(imageFilter: ImageFilter.blur(sigmaX: 2 * v, sigmaY: 2 * v), child: w);
        }
        return Stack(
          children: [
            w,
            if (dim) Positioned.fill(child: GestureDetector(behavior: HitTestBehavior.opaque, onTap: onBlockedTap)),
          ],
        );
      },
      child: child,
    );
  }
}

/// Crimson → green sweep with heart burst; then morphs into the Event Card.
class _AcceptedMoment extends StatelessWidget {
  const _AcceptedMoment();

  @override
  Widget build(BuildContext context) {
    final s = context.read<PulseStore>();
    final who = s.request?.patientName != null ? "${s.request!.patientName}'s family has" : 'The family has';
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeInOut,
      builder:
          (_, v, child) => Container(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(OCornerRadius.l),
              gradient: LinearGradient(
                colors: const [Color(0xFF1AB056), Color(0xFF085E2A), Color(0xFFEF3354), Color(0xFFAF0D2A)],
                stops: [0, v, (v + 0.001).clamp(0, 1), 1],
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF148440).withValues(alpha: 0.28 * v),
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: child,
          ),
      child: Row(
        children: [
          Heartbeat(
            strength: 2,
            child: Container(
              width: 56,
              height: 56,
              decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
              child: Icon(FluentIcons.heart_24_filled, color: OColor.green600, size: 30),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                EnterIn(
                  delay: const Duration(milliseconds: 250),
                  child: Text(
                    "You're in, ${s.firstName}.",
                    style: PText.h1(Colors.white).copyWith(fontWeight: FontWeight.w800),
                  ),
                ),
                const SizedBox(height: 4),
                EnterIn(
                  delay: const Duration(milliseconds: 380),
                  child: Text("$who been told someone's coming.", style: PText.body(Colors.white)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ClosedAskCard extends StatelessWidget {
  final PulseStore store;
  const _ClosedAskCard({required this.store});

  @override
  Widget build(BuildContext context) {
    final (icon, title, body, color) = switch (store.phase) {
      AskPhase.covered => (
        FluentIcons.heart_24_filled,
        'Covered! ${store.request?.units ?? 3} heroes said yes.',
        "We'll call on you next time, ${store.firstName}.",
        OColor.green600,
      ),
      AskPhase.expired => (
        FluentIcons.clock_24_regular,
        'No worries, we found others this time.',
        "The request window closed. You're still on the Lifeline list.",
        OColor.gray600,
      ),
      AskPhase.declined => (
        FluentIcons.hand_wave_24_regular,
        'Thanks for telling us quickly.',
        "We've passed this to the next donor.",
        OColor.gray600,
      ),
      AskPhase.cancelled => (
        FluentIcons.checkmark_circle_24_regular,
        'Not needed anymore, thank you.',
        'The hospital found blood. Nothing counts against you.',
        OColor.green600,
      ),
      _ => (FluentIcons.info_24_regular, '', '', OColor.gray600),
    };
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: OColor.white,
        borderRadius: BorderRadius.circular(OCornerRadius.m),
        border: Border.all(color: OColor.gray200),
      ),
      child: Row(
        children: [
          Icon(icon, color: color),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: PText.label(OColor.gray800).copyWith(fontWeight: FontWeight.w700)),
                Text(body, style: PText.bodyX(OColor.gray600)),
              ],
            ),
          ),
          IconButton(
            onPressed: store.dismissAsk,
            icon: Icon(FluentIcons.dismiss_20_regular, color: OColor.gray500, size: 18),
          ),
        ],
      ),
    );
  }
}
