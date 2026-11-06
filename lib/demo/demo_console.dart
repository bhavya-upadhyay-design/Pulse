import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';
import 'package:onestop_ui/index.dart';
import 'package:provider/provider.dart';

import '../request/decline_sheet.dart';
import '../state/models.dart';
import '../state/pulse_store.dart';
import '../theme/pulse_tokens.dart';
import '../widgets/motion.dart';

/// Floating button that opens the NSS / admin simulator. There is no backend
/// in this prototype: these actions play the admin and coordinator side.
class DemoConsoleButton extends StatelessWidget {
  const DemoConsoleButton({super.key});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'NSS console',
      excludeSemantics: true,
      onTap: () => showDemoConsole(context),
      child: Pressable(
        onTap: () => showDemoConsole(context),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: OColor.gray800,
            borderRadius: BorderRadius.circular(OCornerRadius.xl),
            boxShadow: [
              BoxShadow(color: Colors.black.withValues(alpha: 0.2), blurRadius: 12, offset: const Offset(0, 4)),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(FluentIcons.wrench_screwdriver_20_regular, color: Colors.white, size: 18),
              const SizedBox(width: 6),
              Text(
                'NSS console',
                style: OTextStyle.labelXSmall.copyWith(color: Colors.white, fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

void showDemoConsole(BuildContext context) {
  showPulseSheet(context, builder: (_) => const _Console());
}

class _Console extends StatelessWidget {
  const _Console();

  @override
  Widget build(BuildContext context) {
    final s = context.watch<PulseStore>();
    final open = s.phase == AskPhase.open;
    final ev = s.eventActive;

    Widget act(String label, IconData icon, bool enabled, VoidCallback f, {bool close = true}) => ListTile(
      dense: true,
      enabled: enabled,
      leading: Icon(icon, size: 20, color: enabled ? OColor.gray800 : OColor.gray400),
      title: Text(label, style: PText.body(enabled ? OColor.gray800 : OColor.gray400)),
      onTap:
          enabled
              ? () {
                if (close) Navigator.of(context).pop();
                f();
              }
              : null,
    );

    Widget head(String t) => Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 2),
      child: Text(t.toUpperCase(), style: OTextStyle.labelXSmall.copyWith(color: OColor.gray500, letterSpacing: 1)),
    );

    return ConstrainedBox(
      constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(context).height * 0.8),
      child: ListView(
        shrinkWrap: true,
        padding: const EdgeInsets.only(bottom: 16),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: Row(
              children: [
                Icon(FluentIcons.wrench_screwdriver_24_regular, color: PulseColors.crimson),
                const SizedBox(width: 8),
                Expanded(child: Text('NSS console (demo)', style: PText.h2(OColor.gray800))),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
            child: Text(
              'Plays the admin and NSS coordinator side. Current: ${s.phase.name}${ev ? ' • ${s.stage.name}' : ''}',
              style: PText.bodyX(OColor.gray500),
            ),
          ),
          head('Admin: request'),
          act('Raise request (3 units, 2 h)', FluentIcons.drop_24_regular, !ev, () => s.adminRaiseRequest()),
          act(
            'Raise critical request (30 min)',
            FluentIcons.alert_urgent_24_regular,
            !ev,
            () => s.adminRaiseRequest(critical: true),
          ),
          act(
            'Raise request, no patient consent',
            FluentIcons.eye_off_24_regular,
            !ev,
            () => s.adminRaiseRequest(consent: false),
          ),
          act('Another student accepts', FluentIcons.person_add_24_regular, open, s.adminOtherAccepts, close: false),
          act('Units filled without you', FluentIcons.people_checkmark_24_regular, open, s.adminFillWithoutYou),
          act('Expire response window', FluentIcons.timer_off_24_regular, open, s.adminExpire),
          act('Hospital cancels request', FluentIcons.dismiss_circle_24_regular, open || ev, s.adminCancel),
          head('NSS coordinator: event'),
          act(
            'Schedule slot + pickup',
            FluentIcons.calendar_add_24_regular,
            ev && s.stage == EventStage.accepted,
            s.adminSchedule,
          ),
          act(
            'Pickup on the way',
            FluentIcons.vehicle_car_24_regular,
            ev && s.stage.index < EventStage.pickup.index,
            s.adminPickup,
          ),
          act(
            'Donor at the blood bank',
            FluentIcons.building_24_regular,
            ev && s.stage.index < EventStage.atBank.index,
            s.adminAtBank,
          ),
          act(
            'Slot time has passed',
            FluentIcons.clock_24_regular,
            ev && s.stage.index < EventStage.awaitingOutcome.index,
            s.adminPassSlot,
          ),
          head('After donation'),
          act(
            'Confirm donation (unlocks coupon)',
            FluentIcons.checkmark_starburst_24_regular,
            s.stage == EventStage.donated && !s.donationConfirmed,
            s.adminConfirmDonation,
          ),
          act(
            'A nominated friend registers',
            FluentIcons.people_add_24_regular,
            s.friends.any((f) => !f.registered),
            () => s.adminFriendRegisters(),
          ),
          head('Profile'),
          act('Use a ready donor profile (B+)', FluentIcons.person_available_24_regular, true, s.seedProfile),
          act('Reset app (fresh install)', FluentIcons.arrow_reset_24_regular, true, s.resetAll),
        ],
      ),
    );
  }
}
