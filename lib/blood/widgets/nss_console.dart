import 'dart:async';

import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../state/models.dart';
import '../../state/pulse_store.dart';
import '../../theme/bd.dart';
import 'common.dart';
import 'motion.dart';

/// Demo-only: plays the admin and NSS coordinator side (no backend).
class NssConsoleButton extends StatelessWidget {
  final bool compact;
  const NssConsoleButton({super.key, this.compact = true});

  // `?clean=1` hides the demo button (still tappable) for presentation screenshots.
  static final bool _clean = Uri.base.queryParameters['clean'] == '1';

  @override
  Widget build(BuildContext context) => Opacity(opacity: _clean ? 0 : 1, child: _button(context));

  Widget _button(BuildContext context) => Semantics(
    button: true,
    label: 'NSS console',
    excludeSemantics: true,
    onTap: () => showNssConsole(context),
    child: Pressable(
      onTap: () => showNssConsole(context),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: const Color(0xFF323232),
          borderRadius: BorderRadius.circular(71),
          border: Border.all(color: BD.border),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(FluentIcons.wrench_16_regular, color: BD.text700, size: 14),
            const SizedBox(width: 4),
            Text('NSS', style: T.medium(11, BD.text700)),
          ],
        ),
      ),
    ),
  );
}

void showNssConsole(BuildContext context) => showBdSheet(context, builder: (_) => const _Console());

class _Console extends StatelessWidget {
  const _Console();

  @override
  Widget build(BuildContext context) {
    final s = context.watch<PulseStore>();
    final open = s.phase == AskPhase.open;
    final ev = s.eventActive;
    Widget head(String t) => Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      child: Text(t.toUpperCase(), style: T.medium(10, BD.textSecondary).copyWith(letterSpacing: 1)),
    );
    Widget act(String label, IconData icon, bool on, VoidCallback f, {bool close = true}) => ListTile(
      dense: true,
      enabled: on,
      leading: Icon(icon, size: 20, color: on ? Colors.white : const Color(0xFF555555)),
      title: Text(label, style: T.regular(14, on ? Colors.white : const Color(0xFF555555))),
      onTap:
          on
              ? () {
                if (close) Navigator.of(context).pop();
                f();
              }
              : null,
    );
    return ConstrainedBox(
      constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(context).height * 0.8),
      child: ListView(
        shrinkWrap: true,
        padding: const EdgeInsets.only(top: 12, bottom: 16),
        children: [
          Padding(padding: const EdgeInsets.symmetric(horizontal: 16), child: Text('NSS console (demo)', style: T.bold(16))),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
            child: Text(
              'Plays the admin and NSS coordinator side. Now: ${s.phase.name}${ev ? ' • ${s.stage.name}' : ''}',
              style: T.regular(12, BD.textSecondary),
            ),
          ),
          head('Admin • request'),
          act('Raise request (3 units, 2 h)', FluentIcons.drop_20_regular, !ev, () => s.adminRaiseRequest()),
          act('Raise critical request (30 min)', FluentIcons.alert_urgent_20_regular, !ev, () => s.adminRaiseRequest(critical: true)),
          act('Another student accepts', FluentIcons.person_add_20_regular, open, s.adminOtherAccepts, close: false),
          act('Units filled without you', FluentIcons.people_checkmark_20_regular, open, s.adminFillWithoutYou),
          act('Expire response window', FluentIcons.timer_off_20_regular, open, s.adminExpire),
          act('Hospital cancels request', FluentIcons.dismiss_circle_20_regular, open || ev, s.adminCancel),
          head('NSS coordinator • event'),
          act('Set donation slot', FluentIcons.calendar_add_20_regular, ev && s.stage == EventStage.accepted, s.adminSchedule),
          act('Arrange requested ride', FluentIcons.vehicle_car_20_regular, ev && s.ride == RideStatus.requested, s.adminArrangeRide),
          act('Decline ride request', FluentIcons.dismiss_circle_20_regular, ev && s.ride == RideStatus.requested, s.adminDeclineRide),
          head('After donation'),
          act(
            'Confirm donation (unlocks meal)',
            FluentIcons.checkmark_starburst_20_regular,
            s.stage == EventStage.donated && !s.donationConfirmed,
            s.adminConfirmDonation,
          ),
          act(
            'A nominated friend registers',
            FluentIcons.people_add_20_regular,
            s.friends.any((f) => !f.registered),
            s.adminFriendRegisters,
          ),
          head('Profile'),
          act('Use a ready donor profile (O+)', FluentIcons.person_available_20_regular, true, s.seedProfile),
          act('Reset app (fresh install)', FluentIcons.arrow_reset_20_regular, true, s.resetAll),
        ],
      ),
    );
  }
}

/// In-app stand-in for a push notification.
class PushBanner extends StatefulWidget {
  const PushBanner({super.key});
  @override
  State<PushBanner> createState() => _PushBannerState();
}

class _PushBannerState extends State<PushBanner> {
  PushNote? _n;
  bool _show = false;
  Timer? _t;
  late final ValueNotifier<PushNote?> _src = context.read<PulseStore>().pushes;

  @override
  void initState() {
    super.initState();
    _src.addListener(_on);
  }

  void _on() {
    final n = _src.value;
    if (n == null) return;
    _t?.cancel();
    setState(() {
      _n = n;
      _show = true;
    });
    Haptics.medium();
    _t = Timer(const Duration(seconds: 4), () => mounted ? setState(() => _show = false) : null);
  }

  @override
  void dispose() {
    _src.removeListener(_on);
    _t?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.viewPaddingOf(context).top;
    final n = _n;
    return AnimatedPositioned(
      duration: BD.slow,
      curve: _show ? Curves.easeOutBack : Curves.easeIn,
      top: _show ? top + 6 : -160,
      left: 10,
      right: 10,
      child:
          n == null
              ? const SizedBox.shrink()
              : GestureDetector(
                onTap: () => setState(() => _show = false),
                child: Material(
                  color: Colors.transparent,
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF2C2C2C),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: BD.border),
                      boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.5), blurRadius: 24, offset: const Offset(0, 8))],
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 38,
                          height: 38,
                          decoration: BoxDecoration(gradient: BD.requestGradient, color: BD.page, borderRadius: BorderRadius.circular(10)),
                          alignment: Alignment.center,
                          child: bdSvg('drop_flame', width: 15, height: 18),
                        ),
                        gap12,
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('ONESTOP • now', style: T.medium(10, BD.textSecondary)),
                              const SizedBox(height: 2),
                              Text(n.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: T.bold(13)),
                              Text(n.body, maxLines: 2, overflow: TextOverflow.ellipsis, style: T.regular(12, BD.text700)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
    );
  }
}
