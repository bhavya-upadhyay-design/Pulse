import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';
import 'package:onestop_ui/index.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../request/decline_sheet.dart';
import '../state/models.dart';
import '../state/pulse_store.dart';
import '../theme/pulse_tokens.dart';
import '../widgets/motion.dart';
import '../widgets/shapes.dart';

// ───────────────────────── Water: 4 × 500 ml ─────────────────────────
void showWaterSheet(BuildContext context) {
  showPulseSheet(context, builder: (_) => const _WaterSheet());
}

class _WaterSheet extends StatelessWidget {
  const _WaterSheet();

  @override
  Widget build(BuildContext context) {
    final s = context.watch<PulseStore>();
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('Drink 2 L today', style: PText.h2(OColor.gray800)),
          const SizedBox(height: 4),
          Text('Tap a glass each time you finish 500 ml.', style: PText.body(OColor.gray600)),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              for (var i = 0; i < 4; i++)
                Semantics(
                  button: true,
                  label: 'Glass ${i + 1}',
                  value: i < s.glasses ? 'Full' : 'Empty',
                  onTap: i == s.glasses ? () => s.addGlass() : null,
                  excludeSemantics: true,
                  child: Pressable(
                    onTap: i == s.glasses ? () => s.addGlass() : null,
                    child: _Glass(filled: i < s.glasses, next: i == s.glasses),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          AnimatedSwitcher(
            duration: PulseMotion.standard,
            child: Text(
              s.glasses >= 4 ? 'Hydrated! Tile ticked.' : '${(s.glasses * 0.5).toStringAsFixed(1)} L of 2 L',
              key: ValueKey(s.glasses),
              style: PText.label(
                s.glasses >= 4 ? OColor.green600 : OColor.gray700,
              ).copyWith(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}

class _Glass extends StatelessWidget {
  final bool filled;
  final bool next;
  const _Glass({required this.filled, required this.next});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 56,
      height: 80,
      decoration: BoxDecoration(
        border: Border.all(color: next ? OColor.blue500 : OColor.gray300, width: 2),
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(14), top: Radius.circular(4)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          Align(
            alignment: Alignment.bottomCenter,
            child: TweenAnimationBuilder<double>(
              tween: Tween(end: filled ? 0.86 : 0),
              duration: const Duration(milliseconds: 650),
              curve: Curves.easeOutBack,
              builder:
                  (_, v, _) => FractionallySizedBox(
                    heightFactor: v.clamp(0, 1),
                    widthFactor: 1,
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [OColor.blue300, OColor.blue500],
                        ),
                      ),
                    ),
                  ),
            ),
          ),
          if (next) Center(child: Icon(FluentIcons.add_20_filled, color: OColor.blue500, size: 20)),
        ],
      ),
    );
  }
}

// ───────────────────────── Meal coupon ─────────────────────────
void showCouponSheet(BuildContext context) {
  showPulseSheet(context, builder: (_) => const _CouponSheet());
}

class _CouponSheet extends StatelessWidget {
  const _CouponSheet();

  @override
  Widget build(BuildContext context) {
    final s = context.watch<PulseStore>();
    final c = s.coupon;
    if (!s.donationConfirmed) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(FluentIcons.lock_closed_24_regular, size: 36, color: OColor.yellow600),
            const SizedBox(height: 10),
            Text('Your meal unlocks soon', style: PText.h2(OColor.gray800)),
            const SizedBox(height: 6),
            Text(
              'Sneha confirms your donation with the blood bank, usually within a couple of hours. Your coupon appears here right after.',
              style: PText.body(OColor.gray600),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      child: AnimatedSwitcher(
        duration: PulseMotion.emphasis,
        child:
            c == null
                ? Column(
                  key: const ValueKey('gen'),
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Heartbeat(child: Icon(FluentIcons.food_24_filled, size: 40, color: OColor.green600)),
                    const SizedBox(height: 10),
                    Text('Your iron-rich meal is on us', style: PText.h2(OColor.gray800)),
                    const SizedBox(height: 6),
                    Text(
                      'Generate a one-time coupon for ${s.mess}. Valid for 48 hours.',
                      style: PText.body(OColor.gray600),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: PrimaryButton(
                        label: 'Generate coupon',
                        leadingIcon: FluentIcons.ticket_diagonal_24_regular,
                        onPressed: () {
                          Haptics.success();
                          s.generateCoupon();
                        },
                      ),
                    ),
                  ],
                )
                : _CouponTicket(key: const ValueKey('ticket'), coupon: c, store: s),
      ),
    );
  }
}

class _CouponTicket extends StatelessWidget {
  final Coupon coupon;
  final PulseStore store;
  const _CouponTicket({super.key, required this.coupon, required this.store});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        EnterIn(
          from: const Offset(0, 30),
          child: Container(
            decoration: BoxDecoration(
              boxShadow: PulseColors.floatShadow,
              borderRadius: BorderRadius.circular(OCornerRadius.l),
            ),
            child: ClipPath(
              clipper: const TicketClipper(notchAt: 0.36, notch: 12, radius: 16),
              child: Container(
                color: OColor.white,
                child: Column(
                  children: [
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: const BoxDecoration(gradient: PulseColors.success),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'HERO MEAL • ${coupon.mess.toUpperCase()}',
                            style: OTextStyle.labelXSmall.copyWith(color: Colors.white70, letterSpacing: 1),
                          ),
                          const SizedBox(height: 4),
                          Text(coupon.dish, style: PText.h3(Colors.white)),
                          const SizedBox(height: 4),
                          Text(
                            'Valid for Lunch or Dinner till ${dayLabel(coupon.validUntil)}, ${timeLabel(coupon.validUntil)}',
                            style: PText.bodyX(Colors.white),
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: DashedLine(color: OColor.gray300),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          AnimatedOpacity(
                            duration: PulseMotion.standard,
                            opacity: coupon.redeemed ? 0.3 : 1,
                            child: QrImageView(data: coupon.code, size: 110, padding: EdgeInsets.zero),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Show at the mess counter', style: PText.bodyX(OColor.gray500)),
                                const SizedBox(height: 6),
                                Text(coupon.code, style: PText.mono(OColor.gray800, 16)),
                                const SizedBox(height: 10),
                                coupon.redeemed
                                    ? PChip(
                                      text: 'Redeemed • tile ticked',
                                      icon: FluentIcons.checkmark_16_filled,
                                      bg: OColor.green100,
                                      fg: OColor.green600,
                                    )
                                    : PChip(text: 'One-time use', bg: PulseColors.goldSoft, fg: OColor.yellow700),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        if (!coupon.redeemed)
          SizedBox(
            width: double.infinity,
            child: SecondaryButton(
              label: 'Simulate mess scan (demo)',
              leadingIcon: FluentIcons.qr_code_24_regular,
              onPressed: () {
                Haptics.success();
                store.redeemCoupon();
                Future.delayed(const Duration(milliseconds: 900), () {
                  if (context.mounted) Navigator.of(context).pop();
                });
              },
            ),
          ),
      ],
    );
  }
}

// ───────────────────────── Nominate 2 friends ─────────────────────────
void showNominateSheet(BuildContext context) {
  showPulseSheet(context, builder: (_) => const _NominateSheet());
}

class _NominateSheet extends StatefulWidget {
  const _NominateSheet();
  @override
  State<_NominateSheet> createState() => _NominateSheetState();
}

class _NominateSheetState extends State<_NominateSheet> {
  static const _suggest = [
    ('Kunal Verma', '220104033'),
    ('Ananya Das', '220104051'),
    ('Rishabh Jain', '220106019'),
    ('Pooja Nair', '220103008'),
    ('Vikram Rao', '220104077'),
  ];
  final Set<int> _picked = {};

  @override
  Widget build(BuildContext context) {
    final s = context.watch<PulseStore>();
    if (s.friends.isNotEmpty) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Your nominations', style: PText.h2(OColor.gray800)),
            const SizedBox(height: 4),
            Text('The tile ticks when both have set their blood group.', style: PText.body(OColor.gray600)),
            const SizedBox(height: 12),
            for (final f in s.friends)
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: InitialsAvatar(initials: f.name.substring(0, 1), tint: OColor.blue500),
                title: Text(f.name, style: PText.label(OColor.gray800)),
                subtitle: Text(f.roll, style: PText.bodyX(OColor.gray500)),
                trailing: AnimatedSwitcher(
                  duration: PulseMotion.emphasis,
                  child:
                      f.registered
                          ? PChip(
                            key: const ValueKey('y'),
                            text: 'Joined',
                            icon: FluentIcons.checkmark_16_filled,
                            bg: OColor.green100,
                            fg: OColor.green600,
                          )
                          : PChip(
                            key: const ValueKey('n'),
                            text: 'Invite sent',
                            bg: OColor.gray100,
                            fg: OColor.gray600,
                          ),
                ),
              ),
          ],
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Nominate 2 friends', style: PText.h2(OColor.gray800)),
          const SizedBox(height: 4),
          Text(
            'They get a soft invite: "${s.firstName} thinks you\'d make a great Lifeline."',
            style: PText.body(OColor.gray600),
          ),
          const SizedBox(height: 12),
          for (var i = 0; i < _suggest.length; i++)
            CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              value: _picked.contains(i),
              activeColor: OColor.green600,
              onChanged:
                  (v) => setState(() {
                    if (v == true && _picked.length < 2) _picked.add(i);
                    if (v == false) _picked.remove(i);
                  }),
              title: Text(_suggest[i].$1, style: PText.label(OColor.gray800)),
              subtitle: Text('Roll ${_suggest[i].$2} • from your Contacts', style: PText.bodyX(OColor.gray500)),
              secondary: InitialsAvatar(initials: _suggest[i].$1.substring(0, 1), tint: OColor.blue500),
            ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: PrimaryButton(
              label: _picked.length == 2 ? 'Send 2 invites' : 'Pick ${2 - _picked.length} more',
              enabled: _picked.length == 2,
              onPressed:
                  _picked.length == 2
                      ? () {
                        final store = context.read<PulseStore>();
                        store.nominate([for (final i in _picked) Friend(_suggest[i].$2, _suggest[i].$1)]);
                        Haptics.success();
                        // Demo: friends sign up a few seconds later.
                        Future.delayed(const Duration(seconds: 4), store.adminFriendRegisters);
                        Future.delayed(const Duration(seconds: 8), store.adminFriendRegisters);
                      }
                      : null,
            ),
          ),
        ],
      ),
    );
  }
}

// ───────────────────────── Day-7 check-in ─────────────────────────
void showCheckinSheet(BuildContext context) {
  showPulseSheet(context, builder: (_) => const _CheckinSheet());
}

class _CheckinSheet extends StatefulWidget {
  const _CheckinSheet();
  @override
  State<_CheckinSheet> createState() => _CheckinSheetState();
}

class _CheckinSheetState extends State<_CheckinSheet> {
  int? _feel;
  bool? _weak;

  @override
  Widget build(BuildContext context) {
    final s = context.read<PulseStore>();
    const feels = [
      FluentIcons.emoji_sad_24_regular,
      FluentIcons.emoji_meh_24_regular,
      FluentIcons.emoji_smile_slight_24_regular,
      FluentIcons.emoji_laugh_24_regular,
    ];
    const feelLabels = ['Tired', 'Okay', 'Good', 'Great'];
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('Day-7 check-in', style: PText.h2(OColor.gray800)),
              const SizedBox(width: 8),
              PChip(
                text: 'Demo: unlocked early',
                bg: OColor.gray100,
                fg: OColor.gray600,
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text('1. How are you feeling this week?', style: PText.label(OColor.gray800)),
          const SizedBox(height: 10),
          Row(
            children: [
              for (var i = 0; i < 4; i++)
                Expanded(
                  child: Pressable(
                    onTap: () => setState(() => _feel = i),
                    child: AnimatedContainer(
                      duration: PulseMotion.micro,
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: _feel == i ? OColor.green100 : OColor.white,
                        borderRadius: BorderRadius.circular(OCornerRadius.m),
                        border: Border.all(color: _feel == i ? OColor.green600 : OColor.gray200),
                      ),
                      child: Column(
                        children: [
                          AnimatedScale(
                            scale: _feel == i ? 1.25 : 1,
                            duration: PulseMotion.emphasis,
                            curve: Curves.easeOutBack,
                            child: Icon(feels[i], size: 28, color: _feel == i ? OColor.green600 : OColor.gray600),
                          ),
                          Text(feelLabels[i], style: PText.bodyX(OColor.gray700)),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          Text('2. Any dizziness or weakness?', style: PText.label(OColor.gray800)),
          const SizedBox(height: 10),
          Row(
            children: [
              for (final v in [false, true])
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(v ? 'Yes' : 'No'),
                    selected: _weak == v,
                    onSelected: (_) => setState(() => _weak = v),
                    selectedColor: OColor.green100,
                    showCheckmark: false,
                    side: BorderSide(color: _weak == v ? OColor.green600 : OColor.gray200),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(OCornerRadius.xl)),
                  ),
                ),
            ],
          ),
          if (_weak == true) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: OColor.yellow100, borderRadius: BorderRadius.circular(OCornerRadius.m)),
              child: Row(
                children: [
                  Icon(FluentIcons.stethoscope_24_regular, color: OColor.yellow700),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Please visit the Medical Section at the campus hospital. We\'ve let Sneha know too.',
                      style: PText.bodyX(OColor.gray800),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: PrimaryButton(
              label: 'Submit check-in',
              enabled: _feel != null && _weak != null,
              onPressed:
                  _feel != null && _weak != null
                      ? () {
                        s.checkinWeak = _weak!;
                        s.tick('checkin');
                        Navigator.of(context).pop();
                      }
                      : null,
            ),
          ),
        ],
      ),
    );
  }
}
