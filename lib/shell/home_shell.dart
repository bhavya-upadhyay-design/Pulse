import 'dart:async';

import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';
import 'package:onestop_ui/index.dart';
import 'package:provider/provider.dart';

import '../demo/demo_console.dart';
import '../home/home_tab.dart';
import '../hub/blood_hub_page.dart';
import '../state/models.dart';
import '../state/pulse_store.dart';
import '../theme/pulse_tokens.dart';
import '../widgets/motion.dart';
import '../widgets/particles.dart';

/// Replica of OneStop's HomePage shell: gradient app bar, floating bottom nav.
/// Only Home is functional; Food / Travel / Profile are placeholders.
class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _index = 0;

  static const _items = [
    ('Home', FluentIcons.home_24_filled, FluentIcons.home_24_regular),
    ('Food', FluentIcons.food_24_filled, FluentIcons.food_24_regular),
    ('Travel', FluentIcons.vehicle_bus_24_filled, FluentIcons.vehicle_bus_24_regular),
    ('Profile', FluentIcons.person_24_filled, FluentIcons.person_24_regular),
  ];

  void _accept() {
    final s = context.read<PulseStore>();
    if (s.phase != AskPhase.open) return;
    s.accept();
    Haptics.success();
    // Make sure the moment plays on Home.
    Navigator.of(context).popUntil((r) => r.isFirst);
    setState(() => _index = 0);
    final size = MediaQuery.sizeOf(context);
    playBurst(context, BurstKind.hearts, origin: Offset(size.width / 2, 220));
  }

  void _openHub() => Navigator.of(context).push(BloodHubPage.route(_accept));

  @override
  Widget build(BuildContext context) {
    final s = context.watch<PulseStore>();
    final askOpen = s.phase == AskPhase.open;
    final bottomInset = MediaQuery.viewPaddingOf(context).bottom;
    return Scaffold(
      extendBody: true,
      backgroundColor: OColor.gray100,
      appBar: _appBar(askOpen),
      body: Stack(
        children: [
          // Chrome tint: 4% crimson wash while the ask is open.
          Positioned.fill(
            child: AnimatedContainer(
              duration: PulseMotion.standard,
              color: askOpen ? PulseColors.crimson.withValues(alpha: 0.04) : Colors.transparent,
            ),
          ),
          Positioned.fill(
            child: IndexedStack(
              index: _index,
              children: [
                HomeTab(onAccept: _accept, openHub: _openHub),
                const _PlaceholderTab(name: 'Food', icon: FluentIcons.food_24_regular),
                const _PlaceholderTab(name: 'Travel', icon: FluentIcons.vehicle_bus_24_regular),
                const _PlaceholderTab(name: 'Profile', icon: FluentIcons.person_24_regular),
              ],
            ),
          ),
          Positioned(bottom: bottomInset, left: 0, right: 0, child: _nav(askOpen)),
          const PushBanner(),
        ],
      ),
    );
  }

  PreferredSizeWidget _appBar(bool askOpen) {
    return AppBar(
      backgroundColor: Colors.transparent,
      automaticallyImplyLeading: false,
      scrolledUnderElevation: 0,
      elevation: 0,
      flexibleSpace: AnimatedContainer(
        duration: PulseMotion.standard,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [askOpen ? PulseColors.blush : OColor.green100, OColor.gray100.withValues(alpha: 0)],
          ),
        ),
      ),
      title: Row(
        children: [
          Text('One', style: OTextStyle.headingLarge.copyWith(color: OColor.gray800, fontWeight: FontWeight.bold)),
          Text('.', style: OTextStyle.headingLarge.copyWith(color: askOpen ? PulseColors.crimson : OColor.green600)),
          const Spacer(),
          const DemoConsoleButton(),
          IconButton(
            onPressed:
                () => ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    behavior: SnackBarBehavior.floating,
                    content: Text('Notifications are not part of this prototype.'),
                  ),
                ),
            icon: Icon(FluentIcons.alert_24_regular, color: OColor.gray800),
          ),
        ],
      ),
    );
  }

  Widget _nav(bool askOpen) {
    return Container(
      margin: const EdgeInsets.all(8).copyWith(bottom: 8),
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: OColor.white,
        borderRadius: BorderRadius.circular(OCornerRadius.l),
        boxShadow: [
          BoxShadow(color: OColor.black.withValues(alpha: 0.06), blurRadius: 9, offset: const Offset(0, 6)),
          BoxShadow(color: OColor.black.withValues(alpha: 0.02), blurRadius: 23, offset: const Offset(0, 12)),
        ],
      ),
      child: Row(
        children: [
          for (var i = 0; i < _items.length; i++)
            Expanded(
              child: InkWell(
                borderRadius: BorderRadius.circular(OCornerRadius.m),
                onTap: () => setState(() => _index = i),
                child: AnimatedContainer(
                  duration: PulseMotion.standard,
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: _index == i ? OColor.green100 : null,
                    borderRadius: BorderRadius.circular(OCornerRadius.m),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Stack(
                        clipBehavior: Clip.none,
                        children: [
                          Icon(
                            _index == i ? _items[i].$2 : _items[i].$3,
                            color: _index == i ? OColor.green600 : OColor.gray800,
                            size: 24,
                          ),
                          if (i == 0 && askOpen)
                            Positioned(
                              right: -3,
                              top: -2,
                              child: Heartbeat(
                                strength: 3,
                                child: Container(
                                  width: 9,
                                  height: 9,
                                  decoration: BoxDecoration(
                                    color: PulseColors.crimson,
                                    shape: BoxShape.circle,
                                    border: Border.all(color: OColor.white, width: 1.5),
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _items[i].$1,
                        style: OTextStyle.bodyXSmall.copyWith(
                          color: _index == i ? OColor.green600 : OColor.gray800,
                          letterSpacing: 0.48,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _PlaceholderTab extends StatelessWidget {
  final String name;
  final IconData icon;
  const _PlaceholderTab({required this.name, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(color: OColor.gray200, shape: BoxShape.circle),
              child: Icon(icon, size: 32, color: OColor.gray500),
            ),
            const SizedBox(height: 16),
            Text(name, style: PText.h2(OColor.gray800)),
            const SizedBox(height: 6),
            Text(
              'This tab is unchanged from the existing OneStop app and is not part of the Pulse prototype.',
              textAlign: TextAlign.center,
              style: PText.body(OColor.gray600),
            ),
          ],
        ),
      ),
    );
  }
}

/// In-app stand-in for a push notification. Slides down, auto-hides.
class PushBanner extends StatefulWidget {
  const PushBanner({super.key});

  @override
  State<PushBanner> createState() => _PushBannerState();
}

class _PushBannerState extends State<PushBanner> {
  PushNote? _note;
  bool _show = false;
  Timer? _hide;
  late final ValueNotifier<PushNote?> _src;

  @override
  void initState() {
    super.initState();
    _src = context.read<PulseStore>().pushes;
    _src.addListener(_onPush);
  }

  void _onPush() {
    final n = _src.value;
    if (n == null) return;
    _hide?.cancel();
    setState(() {
      _note = n;
      _show = true;
    });
    Haptics.medium();
    _hide = Timer(const Duration(seconds: 4), () {
      if (mounted) setState(() => _show = false);
    });
  }

  @override
  void dispose() {
    _src.removeListener(_onPush);
    _hide?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final n = _note;
    return AnimatedPositioned(
      duration: PulseMotion.emphasis,
      curve: _show ? Curves.easeOutBack : Curves.easeIn,
      top: _show ? 6 : -140,
      left: 10,
      right: 10,
      child:
          n == null
              ? const SizedBox.shrink()
              : GestureDetector(
                onTap: () => setState(() => _show = false),
                onVerticalDragEnd: (_) => setState(() => _show = false),
                child: Material(
                  color: Colors.transparent,
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: OColor.white.withValues(alpha: 0.98),
                      borderRadius: BorderRadius.circular(OCornerRadius.l),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.14),
                          blurRadius: 24,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            gradient: PulseColors.card,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(n.icon, color: Colors.white, size: 22),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    'ONESTOP',
                                    style: OTextStyle.labelXSmall.copyWith(
                                      color: OColor.gray500,
                                      letterSpacing: 0.8,
                                      fontSize: 10,
                                    ),
                                  ),
                                  const Spacer(),
                                  Text(
                                    'now',
                                    style: OTextStyle.labelXSmall.copyWith(color: OColor.gray500, fontSize: 10),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 2),
                              Text(
                                n.title,
                                style: PText.label(OColor.gray800).copyWith(fontWeight: FontWeight.w700),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                n.body,
                                style: PText.bodyX(OColor.gray600),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
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
