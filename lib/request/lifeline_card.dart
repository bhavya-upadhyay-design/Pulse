import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';
import 'package:onestop_ui/index.dart';
import 'package:provider/provider.dart';

import '../state/models.dart';
import '../state/pulse_store.dart';
import '../theme/pulse_tokens.dart';
import '../widgets/countdown.dart';
import '../widgets/motion.dart';
import '../widgets/shapes.dart';
import 'decline_sheet.dart';
import 'request_detail_page.dart';
import 'slide_to_accept.dart';

/// The full-width crimson card that takes over Home while a request is open.
class LifelineCard extends StatelessWidget {
  final VoidCallback onAccepted;
  final bool compact;
  const LifelineCard({super.key, required this.onAccepted, this.compact = false});

  @override
  Widget build(BuildContext context) {
    final s = context.watch<PulseStore>();
    final r = s.request;
    if (r == null) return const SizedBox.shrink();
    return Container(
      decoration: BoxDecoration(
        gradient: PulseColors.card,
        borderRadius: BorderRadius.circular(OCornerRadius.l),
        boxShadow: PulseColors.floatShadow,
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          Positioned(
            left: 0,
            right: 0,
            top: 96,
            child: Opacity(opacity: 0.10, child: EcgLine(color: Colors.white, height: 70)),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              UrgencyStrip(request: r, left: s.timeLeft, finalMinutes: s.finalMinutes),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    EnterIn(
                      delay: const Duration(milliseconds: 120),
                      child: Text(
                        '${s.firstName}, ${r.patientName ?? 'a ${r.patientAge}-year-old'} needs ${r.group} blood today.',
                        style: PText.h1(Colors.white).copyWith(fontSize: 24, fontWeight: FontWeight.w700),
                      ),
                    ),
                    const SizedBox(height: 6),
                    EnterIn(
                      delay: const Duration(milliseconds: 180),
                      child: Text(
                        '${r.patientNote} at ${r.hospital}. ${r.units} units needed.',
                        style: PText.body(Colors.white.withValues(alpha: 0.85)),
                      ),
                    ),
                    const SizedBox(height: 14),
                    EnterIn(delay: const Duration(milliseconds: 240), child: WhyYouChips(store: s, onCrimson: true)),
                    const SizedBox(height: 16),
                    EnterIn(delay: const Duration(milliseconds: 300), child: FewOfUsRow(store: s)),
                    if (!compact) ...[
                      const SizedBox(height: 14),
                      EnterIn(
                        delay: const Duration(milliseconds: 360),
                        child: Row(
                          children: [
                            Heartbeat(child: Icon(FluentIcons.heart_pulse_24_filled, color: Colors.white, size: 20)),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'One donation can help save up to 3 lives.',
                                style: PText.label(Colors.white),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),
                      const EnterIn(delay: Duration(milliseconds: 420), child: RewardTicket()),
                    ],
                    const SizedBox(height: 18),
                    SlideToAccept(onCommit: onAccepted),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Expanded(
                          child: _TextBtn(
                            label: 'See details',
                            icon: FluentIcons.info_16_regular,
                            onTap: () => Navigator.of(context).push(RequestDetailPage.route(onAccepted)),
                          ),
                        ),
                        Container(width: 1, height: 20, color: Colors.white24),
                        Expanded(child: _TextBtn(label: "I can't this time", onTap: () => showDeclineSheet(context))),
                      ],
                    ),
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

class _TextBtn extends StatelessWidget {
  final String label;
  final IconData? icon;
  final VoidCallback onTap;
  const _TextBtn({required this.label, required this.onTap, this.icon});

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (icon != null) ...[Icon(icon, size: 16, color: Colors.white), const SizedBox(width: 6)],
            Text(label, style: OTextStyle.labelSmall.copyWith(color: Colors.white, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}

/// `URGENT • B+ • GMCH` + live countdown. Deepens and beats in the last 15 min.
class UrgencyStrip extends StatelessWidget {
  final BloodRequest request;
  final Duration left;
  final bool finalMinutes;
  const UrgencyStrip({super.key, required this.request, required this.left, required this.finalMinutes});

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: PulseMotion.standard,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      color: finalMinutes ? Colors.black.withValues(alpha: 0.28) : Colors.black.withValues(alpha: 0.14),
      child: Row(
        children: [
          Heartbeat(strength: 2, child: const DropShape(size: 16, color: Colors.white)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '${request.critical ? 'CRITICAL' : 'URGENT'} • ${request.group} • ${request.hospital}, Guwahati',
              style: OTextStyle.labelXSmall.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.6,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Heartbeat(
            active: finalMinutes,
            period: const Duration(seconds: 5),
            strength: 1.5,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Odometer(left: left, style: PText.mono(Colors.white, 15)),
                Text('left to respond', style: OTextStyle.bodyXSmall.copyWith(color: Colors.white70, fontSize: 10)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// "You're B+" • "Eligible since Dec" • "12 min from Lohit".
class WhyYouChips extends StatelessWidget {
  final PulseStore store;
  final bool onCrimson;
  const WhyYouChips({super.key, required this.store, this.onCrimson = true});

  @override
  Widget build(BuildContext context) {
    final r = store.request;
    if (r == null) return const SizedBox.shrink();
    final bg = onCrimson ? Colors.white.withValues(alpha: 0.18) : PulseColors.blush;
    final fg = onCrimson ? Colors.white : PulseColors.deep;
    final ne = store.nextEligible;
    final eligibleText = ne == null ? 'First-timer friendly' : 'Eligible since ${monthYear(ne).split(' ').first}';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('WHY YOU', style: OTextStyle.labelXSmall.copyWith(color: fg.withValues(alpha: 0.75), letterSpacing: 1)),
        const SizedBox(height: 6),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            PChip(text: "You're ${store.bloodGroup ?? r.group}", icon: FluentIcons.drop_16_filled, bg: bg, fg: fg),
            PChip(text: eligibleText, icon: FluentIcons.checkmark_circle_16_filled, bg: bg, fg: fg),
            PChip(
              text: '${r.distanceMins.round()} min from ${store.hostel}',
              icon: FluentIcons.location_16_filled,
              bg: bg,
              fg: fg,
            ),
          ],
        ),
      ],
    );
  }
}

/// Six avatar slots: "You" glows; others fill live as they accept.
class FewOfUsRow extends StatelessWidget {
  final PulseStore store;
  final bool onCrimson;
  const FewOfUsRow({super.key, required this.store, this.onCrimson = true});

  @override
  Widget build(BuildContext context) {
    final r = store.request;
    if (r == null) return const SizedBox.shrink();
    final fg = onCrimson ? Colors.white : OColor.gray800;
    final sub = onCrimson ? Colors.white.withValues(alpha: 0.8) : OColor.gray600;
    final live =
        store.lastLiveEvent != null &&
        store.lastLiveEventAt != null &&
        DateTime.now().difference(store.lastLiveEventAt!).inSeconds < 5;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: onCrimson ? Colors.black.withValues(alpha: 0.14) : OColor.gray100,
        borderRadius: BorderRadius.circular(OCornerRadius.m),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _YouSlot(initials: store.firstName.substring(0, 1)),
              for (var i = 0; i < r.asked - 1; i++)
                Padding(
                  padding: const EdgeInsets.only(left: 6),
                  child: EnterIn(
                    delay: Duration(milliseconds: 360 + 60 * i),
                    from: const Offset(0, 0),
                    child: _Slot(
                      filledName: i < store.othersNames.length ? store.othersNames[i] : null,
                      onCrimson: onCrimson,
                    ),
                  ),
                ),
              const Spacer(),
              AnimatedSwitcher(
                duration: PulseMotion.standard,
                transitionBuilder:
                    (c, a) => SlideTransition(
                      position: Tween(begin: const Offset(0, 0.6), end: Offset.zero).animate(a),
                      child: FadeTransition(opacity: a, child: c),
                    ),
                child:
                    live
                        ? Container(
                          key: ValueKey(store.lastLiveEvent),
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: OColor.green500,
                            borderRadius: BorderRadius.circular(OCornerRadius.xl),
                          ),
                          child: Text('+1', style: OTextStyle.labelXSmall.copyWith(color: Colors.white)),
                        )
                        : const SizedBox.shrink(key: ValueKey('none')),
              ),
            ],
          ),
          const SizedBox(height: 10),
          AnimatedSwitcher(
            duration: PulseMotion.standard,
            child: Text(
              live
                  ? '${store.lastLiveEvent}. ${store.confirmed} of ${r.units} units covered.'
                  : 'Only ${r.asked} students on campus were asked. ${r.units} units needed, ${store.confirmed} confirmed.',
              key: ValueKey(live ? store.lastLiveEvent : 'base${store.confirmed}'),
              style: PText.label(fg),
            ),
          ),
          const SizedBox(height: 8),
          UnitsBar(units: r.units, confirmed: store.confirmed, onCrimson: onCrimson),
          const SizedBox(height: 4),
          Text(
            store.unitsLeft == 0
                ? 'All units covered'
                : '${store.unitsLeft} more ${store.unitsLeft == 1 ? 'hero' : 'heroes'} needed',
            style: PText.bodyX(sub),
          ),
        ],
      ),
    );
  }
}

class UnitsBar extends StatelessWidget {
  final int units;
  final int confirmed;
  final bool onCrimson;
  const UnitsBar({super.key, required this.units, required this.confirmed, this.onCrimson = true});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (var i = 0; i < units; i++)
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(right: i == units - 1 ? 0 : 4),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: Container(
                  height: 6,
                  color: onCrimson ? Colors.white24 : OColor.gray200,
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: AnimatedFractionallySizedBox(
                      duration: PulseMotion.emphasis,
                      curve: Curves.easeOutCubic,
                      widthFactor: i < confirmed ? 1 : 0,
                      child: Container(color: onCrimson ? Colors.white : PulseColors.crimson),
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _YouSlot extends StatelessWidget {
  final String initials;
  const _YouSlot({required this.initials});

  @override
  Widget build(BuildContext context) {
    return Breath(
      builder:
          (_, b) => Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white,
              border: Border.all(color: PulseColors.gold, width: 2.5),
              boxShadow: [BoxShadow(color: PulseColors.gold.withValues(alpha: 0.35 + 0.35 * b), blurRadius: 6 + 8 * b)],
            ),
            alignment: Alignment.center,
            child: Text(
              'You',
              style: OTextStyle.labelXSmall.copyWith(
                color: PulseColors.deep,
                fontWeight: FontWeight.w800,
                fontSize: 11,
              ),
            ),
          ),
    );
  }
}

class _Slot extends StatelessWidget {
  final String? filledName;
  final bool onCrimson;
  const _Slot({this.filledName, required this.onCrimson});

  @override
  Widget build(BuildContext context) {
    final filled = filledName != null;
    return AnimatedSwitcher(
      duration: PulseMotion.emphasis,
      transitionBuilder:
          (c, a) => ScaleTransition(scale: CurvedAnimation(parent: a, curve: Curves.easeOutBack), child: c),
      child: Container(
        key: ValueKey(filled),
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: filled ? OColor.green500 : (onCrimson ? Colors.white.withValues(alpha: 0.18) : OColor.gray200),
          border: Border.all(color: onCrimson ? Colors.white : OColor.white, width: 2),
        ),
        alignment: Alignment.center,
        child:
            filled
                ? Text(
                  filledName!.substring(0, 1),
                  style: OTextStyle.labelXSmall.copyWith(color: Colors.white, fontWeight: FontWeight.w700),
                )
                : Icon(
                  FluentIcons.person_16_filled,
                  size: 16,
                  color: onCrimson ? Colors.white.withValues(alpha: 0.6) : OColor.gray400,
                ),
      ),
    );
  }
}

/// Zomato-coupon-style ticket listing what the student unlocks.
class RewardTicket extends StatelessWidget {
  const RewardTicket({super.key});

  @override
  Widget build(BuildContext context) {
    return ClipPath(
      clipper: const TicketClipper(notchAt: 0.5, notch: 9),
      child: Container(
        decoration: BoxDecoration(gradient: LinearGradient(colors: [const Color(0xFFFFF4DA), PulseColors.goldSoft])),
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(color: PulseColors.gold, shape: BoxShape.circle),
              child: const Icon(FluentIcons.gift_24_filled, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "YOU'LL UNLOCK",
                    style: OTextStyle.labelXSmall.copyWith(color: OColor.yellow700, letterSpacing: 1, fontSize: 10),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Hero badge • Iron-rich mess meal • NSS certificate • Hero Wall spot',
                    style: PText.label(OColor.gray800).copyWith(fontWeight: FontWeight.w600, height: 1.3),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
