import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:onestop_ui/index.dart';
import 'package:provider/provider.dart';

import '../blood/blood_shell.dart';
import '../blood/flows/actions.dart';
import '../blood/flows/event_card.dart';
import '../blood/widgets/motion.dart';
import '../blood/widgets/nss_console.dart';
import '../blood/widgets/request_widget.dart';
import '../state/models.dart';
import '../state/pulse_store.dart';

/// OneStop HomePage, rebuilt from onestop_flutter `lib/pages/home/home.dart`
/// and its widgets, in OneStop's dark theme. Only Home and the Blood
/// donation entry point are functional; other tabs and tiles are stubs.
class OneStopHome extends StatefulWidget {
  const OneStopHome({super.key});
  @override
  State<OneStopHome> createState() => _OneStopHomeState();
}

class _OneStopHomeState extends State<OneStopHome> {
  int _index = 0;

  static const _items = [
    ('Home', FluentIcons.home_24_filled, FluentIcons.home_24_regular),
    ('Food', FluentIcons.food_24_filled, FluentIcons.food_24_regular),
    ('Travel', FluentIcons.vehicle_bus_24_filled, FluentIcons.vehicle_bus_24_regular),
    ('Profile', FluentIcons.person_24_filled, FluentIcons.person_24_regular),
  ];

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewPaddingOf(context).bottom;
    return Scaffold(
      extendBody: true,
      backgroundColor: OColor.gray100,
      appBar: _appBar(context),
      body: Stack(
        children: [
          Positioned.fill(
            child: IndexedStack(
              index: _index,
              children: const [_HomeTab(), _Stub(name: 'Food'), _Stub(name: 'Travel'), _Stub(name: 'Profile')],
            ),
          ),
          Positioned(bottom: bottomInset + 8, left: 0, right: 0, child: _bottomNav()),
          const PushBanner(),
        ],
      ),
    );
  }

  // lib/widgets/ui/appbar.dart
  PreferredSizeWidget _appBar(BuildContext context) => AppBar(
    backgroundColor: Colors.transparent,
    automaticallyImplyLeading: false,
    scrolledUnderElevation: 0,
    elevation: 0,
    flexibleSpace: Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [OColor.green100, OColor.gray100.withValues(alpha: 0)],
        ),
      ),
    ),
    title: Row(
      children: [
        OText(text: 'One', style: OTextStyle.headingLarge.copyWith(color: OColor.gray800, fontWeight: FontWeight.bold)),
        OText(text: '.', style: OTextStyle.headingLarge.copyWith(color: OColor.green600)),
        const Spacer(),
        const NssConsoleButton(),
        const SizedBox(width: 8),
        CircleAvatar(
          backgroundColor: OColor.white,
          child: IconButton(
            tooltip: 'Notifications',
            onPressed: () => _stub(context, 'Notifications'),
            icon: Icon(FluentIcons.alert_24_regular, color: OColor.green600),
          ),
        ),
      ],
    ),
  );

  // HomePage._bottomNavBar (iOS radius 40, as in the Figma screenshot).
  Widget _bottomNav() => Container(
    margin: const EdgeInsets.symmetric(horizontal: 8),
    padding: const EdgeInsets.all(6),
    decoration: BoxDecoration(
      color: OColor.white,
      borderRadius: BorderRadius.circular(40),
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
              borderRadius: BorderRadius.circular(40),
              onTap: () => setState(() => _index = i),
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: _index == i ? OColor.green100 : null, borderRadius: BorderRadius.circular(40)),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(_index == i ? _items[i].$2 : _items[i].$3, color: _index == i ? OColor.green600 : OColor.gray800, size: 24),
                    const SizedBox(height: 4),
                    OText(
                      text: _items[i].$1,
                      style: OTextStyle.bodyXSmall.copyWith(color: _index == i ? OColor.green600 : OColor.gray800, letterSpacing: 0.48),
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

void _stub(BuildContext context, String what) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: OColor.gray200,
        content: OText(text: '$what is not part of this prototype.', style: OTextStyle.bodySmall.copyWith(color: OColor.gray800)),
      ),
    );
}

class _Stub extends StatelessWidget {
  final String name;
  const _Stub({required this.name});
  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(32),
      child: OText(
        text: '$name is unchanged from OneStop and not part of this prototype.',
        textAlign: TextAlign.center,
        style: OTextStyle.bodyMedium.copyWith(color: OColor.gray600),
      ),
    ),
  );
}

/// lib/pages/home/home_tab.dart
class _HomeTab extends StatelessWidget {
  const _HomeTab();

  @override
  Widget build(BuildContext context) {
    final s = context.watch<PulseStore>();
    Widget top;
    if (s.phase == AskPhase.open) {
      top = RequestWidget(
        key: const ValueKey('ask'),
        onAccept: () => acceptRequest(context),
        onDetails: () => openRequestDetails(context),
        onDecline: () => openDecline(context),
      );
    } else if (s.eventActive) {
      top = Column(key: const ValueKey('event'), children: const [DonationEventCard(), SizedBox(height: 8), _TimeTable()]);
    } else {
      top = const _TimeTable(key: ValueKey('tt'));
    }
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(OCornerRadius.l),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 4),
              AnimatedSize(
                duration: const Duration(milliseconds: 420),
                curve: Curves.easeOutCubic,
                alignment: Alignment.topCenter,
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 420),
                  transitionBuilder:
                      (c, a) =>
                          FadeTransition(opacity: a, child: ScaleTransition(scale: Tween(begin: 0.96, end: 1.0).animate(a), child: c)),
                  layoutBuilder: (cur, prev) => Stack(alignment: Alignment.topCenter, children: [...prev, if (cur != null) cur]),
                  child: top,
                ),
              ),
              const Padding(padding: EdgeInsets.symmetric(vertical: 8), child: SizedBox(height: 220, child: _FoodGateLogRow())),
              const _QuickAccess(),
              const SizedBox(height: 10),
              const _QuickLinks(),
              const SizedBox(height: 160),
            ],
          ),
        ),
      ),
    );
  }
}

/// lib/widgets/home/home_widget.dart
class _HomeWidget extends StatelessWidget {
  final Widget child;
  const _HomeWidget({required this.child});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: OColor.white,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: OColor.gray200),
      boxShadow: [BoxShadow(color: OColor.gray300.withValues(alpha: 0.1), blurRadius: 10, offset: const Offset(0, 2))],
    ),
    child: child,
  );
}

/// lib/widgets/home/date_course.dart (no-classes state).
class _TimeTable extends StatelessWidget {
  const _TimeTable({super.key});

  String _date(DateTime d) {
    var suffix = 'TH';
    if (d.day % 10 == 1 && d.day != 11) suffix = 'ST';
    if (d.day % 10 == 2 && d.day != 12) suffix = 'ND';
    if (d.day % 10 == 3 && d.day != 13) suffix = 'RD';
    const m = ['JANUARY', 'FEBRUARY', 'MARCH', 'APRIL', 'MAY', 'JUNE', 'JULY', 'AUGUST', 'SEPTEMBER', 'OCTOBER', 'NOVEMBER', 'DECEMBER'];
    return '${d.day}$suffix ${m[d.month - 1]}';
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _stub(context, 'Time Table'),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: OColor.white,
          borderRadius: BorderRadius.circular(OCornerRadius.l),
          border: Border.all(color: OColor.gray200),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  SvgPicture.asset('assets/icons/timetable.svg', width: 32, height: 32),
                  const SizedBox(width: 12),
                  OText(text: 'Time Table', style: OTextStyle.headingSmall.copyWith(color: OColor.black, fontWeight: FontWeight.w600)),
                  const SizedBox(width: 8),
                  OText(text: '•', style: OTextStyle.bodySmall.copyWith(color: OColor.gray500)),
                  const SizedBox(width: 8),
                  Expanded(child: OText(text: _date(DateTime.now()), style: OTextStyle.bodySmall.copyWith(color: OColor.gray500))),
                  Icon(FluentIcons.chevron_right_24_regular, color: OColor.gray400, size: 16),
                ],
              ),
              const SizedBox(height: 12),
              OText(
                text: 'No upcoming classes',
                style: OTextStyle.headingMedium.copyWith(color: OColor.gray600, fontWeight: FontWeight.w500),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Food + Gatelog tiles (home_food_tile.dart, home_gatelog_tile.dart).
class _FoodGateLogRow extends StatelessWidget {
  const _FoodGateLogRow();

  @override
  Widget build(BuildContext context) {
    final menu = [
      '1 mix veg masala',
      '2 aloo soyabean',
      '3 moong daal',
      '4 plain rice',
      '5 chapati(butter+plain)',
      '6 fryums',
      '7 Lemon coriander Soup',
    ];
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: GestureDetector(
            onTap: () => _stub(context, 'Food'),
            child: _HomeWidget(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      SvgPicture.asset('assets/icons/food.svg', width: 32, height: 32),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OText(
                          text: 'Food',
                          style: OTextStyle.headingSmall.copyWith(color: OColor.black, fontWeight: FontWeight.w600),
                        ),
                      ),
                      Icon(FluentIcons.chevron_right_24_regular, color: OColor.gray400, size: 16),
                    ],
                  ),
                  const SizedBox(height: 12),
                  OText(text: 'DINNER • ENDS 9:30 PM', style: OTextStyle.bodyXSmall.copyWith(color: OColor.gray500)),
                  const SizedBox(height: 4),
                  Expanded(
                    child: ClipRect(
                      child: OText(
                        text: menu.join('\n'),
                        style: OTextStyle.bodyXSmall.copyWith(color: OColor.black, fontWeight: FontWeight.w500),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: GestureDetector(
            onTap: () => _stub(context, 'Gatelog'),
            child: _HomeWidget(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      SvgPicture.asset('assets/icons/gate_log.svg', width: 32, height: 32),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OText(
                          text: 'Gatelog',
                          style: OTextStyle.headingSmall.copyWith(color: OColor.green600, fontWeight: FontWeight.w600),
                        ),
                      ),
                      Icon(FluentIcons.chevron_right_24_regular, color: OColor.gray400, size: 16),
                    ],
                  ),
                  const Spacer(),
                  OText(
                    text: 'Check into\nCampus',
                    style: OTextStyle.bodyMedium.copyWith(color: OColor.gray800, fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 16),
                  const Spacer(),
                  OText(
                    text: 'ENTER VIA MAIN GATE',
                    style: OTextStyle.bodyXSmall.copyWith(color: OColor.gray500, fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                    decoration: BoxDecoration(border: Border.all(color: OColor.gray300), borderRadius: BorderRadius.circular(20)),
                    child: OText(
                      text: 'Check-In',
                      textAlign: TextAlign.center,
                      style: OTextStyle.bodySmall.copyWith(color: OColor.green600, fontWeight: FontWeight.w500),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// lib/widgets/home/home_services.dart, with "Blood donation" added in the
/// position the Figma puts it.
class _QuickAccess extends StatelessWidget {
  const _QuickAccess();

  static const _before = [
    ('GateLog', 'gate_log', false),
    ('Library Token', 'lib_token', true),
    ('Contacts', 'contacts', false),
    ('Cab Sharing', 'cab_sharing', false),
    ('SAC Room Booking', 'irbs', false),
    ('Complaints', 'complaints', false),
    ('Lost and Found', 'lnf', false),
  ];
  static const _after = [
    ('GC Score Board', 'gc', false),
    ('Medical Section', 'medical', false),
    ('LAN', 'LAN', false),
    ('Buy and Sell', 'bns', false),
  ];

  @override
  Widget build(BuildContext context) {
    final s = context.watch<PulseStore>();
    final live = s.phase == AskPhase.open || s.eventActive;
    Widget tile((String, String, bool) t) => GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => _stub(context, t.$1),
      child: Stack(
        children: [
          Column(
            children: [
              const SizedBox(height: 8),
              Expanded(child: SvgPicture.asset('assets/icons/${t.$2}.svg', width: 48, height: 48)),
              Expanded(
                child: OText(
                  text: t.$1,
                  maxLines: 2,
                  textAlign: TextAlign.center,
                  style: OTextStyle.bodySmall.copyWith(color: OColor.gray800, fontWeight: FontWeight.w500),
                ),
              ),
            ],
          ),
          if (t.$3)
            Positioned(
              top: 8,
              right: 8,
              child: Container(width: 8, height: 8, decoration: BoxDecoration(color: OColor.blue500, shape: BoxShape.circle)),
            ),
        ],
      ),
    );
    return Padding(
      padding: const EdgeInsets.only(top: 5, bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          OText(text: 'Quick Access', style: OTextStyle.headingMedium.copyWith(color: OColor.gray800)),
          const SizedBox(height: 16),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 4,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 0.85,
            padding: EdgeInsets.zero,
            children: [for (final t in _before) tile(t), _BloodTile(live: live), for (final t in _after) tile(t)],
          ),
        ],
      ),
    );
  }
}

/// Figma 1810:8469: 34 px icon frame, "Blood donation" 12 Regular #b8b8b8.
class _BloodTile extends StatelessWidget {
  final bool live;
  const _BloodTile({required this.live});

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    label: 'Blood donation',
    excludeSemantics: true,
    child: Pressable(
      onTap: () => Navigator.of(context).push(BloodShell.route()),
      child: Column(
        children: [
          const SizedBox(height: 8),
          Expanded(
            child: Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 27.76,
                  height: 34.44,
                  child: Center(
                    child: Heartbeat(
                      active: live,
                      strength: 1.6,
                      child: SvgPicture.asset('assets/blood/quick_blood_donation.svg', width: 22.96, height: 28.06),
                    ),
                  ),
                ),
                if (live)
                  Positioned(
                    top: 2,
                    right: 14,
                    child: Heartbeat(
                      strength: 3,
                      child: Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(color: Color(0xFFFD445F), shape: BoxShape.circle),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          Expanded(
            child: Text(
              'Blood donation',
              maxLines: 2,
              textAlign: TextAlign.center,
              style: TextStyle(fontFamily: OTextStyle.fontFamily, fontSize: 12, color: const Color(0xFFB8B8B8)),
            ),
          ),
        ],
      ),
    ),
  );
}

class _QuickLinks extends StatelessWidget {
  const _QuickLinks();
  @override
  Widget build(BuildContext context) {
    const links = ['Academic calendar', 'Course registration', 'Hostel portal'];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        OText(text: 'Quick Links', style: OTextStyle.headingMedium.copyWith(color: OColor.gray800)),
        const SizedBox(height: 12),
        _HomeWidget(
          child: Column(
            children: [
              for (var i = 0; i < links.length; i++) ...[
                InkWell(
                  onTap: () => _stub(context, links[i]),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    child: Row(
                      children: [
                        Expanded(child: OText(text: links[i], style: OTextStyle.bodySmall.copyWith(color: OColor.gray800))),
                        Icon(FluentIcons.open_16_regular, color: OColor.gray400, size: 16),
                      ],
                    ),
                  ),
                ),
                if (i < links.length - 1) Divider(height: 1, color: OColor.gray200),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
