import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:onestop_ui/index.dart';
import 'package:provider/provider.dart';

import '../state/models.dart';
import '../state/pulse_store.dart';
import '../theme/pulse_tokens.dart';
import '../widgets/motion.dart';
import '../widgets/shapes.dart';

/// Static stand-ins for OneStop's existing Home widgets. They look like the
/// real thing but are non-functional in this prototype.
void notInPrototype(BuildContext context, [String what = 'This']) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: OColor.gray800,
        content: Text('$what is part of the existing OneStop app, not this prototype.'),
        duration: const Duration(seconds: 2),
      ),
    );
}

/// OneStop's `HomeWidget` container.
class HomeWidgetBox extends StatelessWidget {
  final Widget child;
  final EdgeInsets padding;
  const HomeWidgetBox({super.key, required this.child, this.padding = const EdgeInsets.all(16)});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: OColor.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: OColor.gray200),
        boxShadow: [
          BoxShadow(color: OColor.gray300.withValues(alpha: 0.1), blurRadius: 10, offset: const Offset(0, 2)),
        ],
      ),
      child: child,
    );
  }
}

class HomeCarouselPlaceholder extends StatelessWidget {
  const HomeCarouselPlaceholder({super.key});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => notInPrototype(context, 'The banner carousel'),
      child: Column(
        children: [
          AspectRatio(
            aspectRatio: 16 / 9,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(OCornerRadius.l),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [OColor.green600, OColor.green800],
                ),
              ),
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  PChip(text: 'CAMPUS', bg: Colors.white24, fg: Colors.white),
                  const SizedBox(height: 8),
                  Text(
                    'Alcheringa 2027 passes are live',
                    style: PText.h2(Colors.white).copyWith(fontWeight: FontWeight.w700),
                  ),
                  Text('Tap to know more', style: PText.bodyX(Colors.white70)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              for (var i = 0; i < 3; i++)
                Container(
                  width: 5,
                  height: 5,
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  decoration: BoxDecoration(shape: BoxShape.circle, color: i == 0 ? OColor.green600 : OColor.gray300),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class TimetablePlaceholder extends StatelessWidget {
  const TimetablePlaceholder({super.key});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => notInPrototype(context, 'Timetable'),
      child: HomeWidgetBox(
        child: Row(
          children: [
            SvgPicture.asset('assets/icons/timetable.svg', width: 32, height: 32),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('NEXT CLASS • 11:00 AM', style: PText.bodyX(OColor.gray500)),
                  Text('CS 344 • Databases', style: PText.h3(OColor.gray800)),
                  Text('Lecture Hall 2', style: PText.bodyX(OColor.gray600)),
                ],
              ),
            ),
            Icon(FluentIcons.chevron_right_24_regular, color: OColor.gray400, size: 16),
          ],
        ),
      ),
    );
  }
}

class FoodGateLogRow extends StatelessWidget {
  const FoodGateLogRow({super.key});

  Widget _tile(BuildContext context, String icon, String title, String meta, String body) {
    return Expanded(
      child: GestureDetector(
        onTap: () => notInPrototype(context, title),
        child: HomeWidgetBox(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  SvgPicture.asset(icon, width: 32, height: 32),
                  const SizedBox(width: 12),
                  Expanded(child: Text(title, style: OTextStyle.headingSmall.copyWith(color: OColor.black))),
                  Icon(FluentIcons.chevron_right_24_regular, color: OColor.gray400, size: 16),
                ],
              ),
              const SizedBox(height: 12),
              Text(meta, style: OTextStyle.bodyXSmall.copyWith(color: OColor.gray500)),
              const SizedBox(height: 4),
              Text(
                body,
                style: OTextStyle.bodyXSmall.copyWith(color: OColor.black, fontWeight: FontWeight.w500, height: 1.5),
                maxLines: 4,
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 170,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _tile(
            context,
            'assets/icons/food.svg',
            'Food',
            'LUNCH • ENDS 2:30 PM',
            'Jeera rice\nDal makhani\nAloo gobi\nCurd',
          ),
          const SizedBox(width: 8),
          _tile(context, 'assets/icons/gate_log.svg', 'GateLog', 'STATUS', 'Inside campus\nLast entry 9:12 AM'),
        ],
      ),
    );
  }
}

/// Quick Access grid. "Blood Donation" is the only working tile.
class QuickAccessGrid extends StatelessWidget {
  final VoidCallback openHub;
  const QuickAccessGrid({super.key, required this.openHub});

  static const _tiles = [
    ('GateLog', 'gate_log'),
    ('Library Token', 'lib_token'),
    ('Contacts', 'contacts'),
    ('Cab Sharing', 'cab_sharing'),
    ('SAC Room Booking', 'irbs'),
    ('Complaints', 'complaints'),
    ('Lost and Found', 'lnf'),
    ('Buy and Sell', 'bns'),
    ('GC Score Board', 'gc'),
    ('Medical Section', 'medical'),
    ('LAN', 'LAN'),
  ];

  @override
  Widget build(BuildContext context) {
    final s = context.watch<PulseStore>();
    return Padding(
      padding: const EdgeInsets.only(top: 5, bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Quick Access', style: OTextStyle.headingMedium.copyWith(color: OColor.gray800)),
          const SizedBox(height: 16),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 4,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 0.85,
            padding: EdgeInsets.zero,
            children: [
              _BloodTile(onTap: openHub, live: s.phase == AskPhase.open || s.eventActive),
              for (final t in _tiles)
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => notInPrototype(context, t.$1),
                  child: Column(
                    children: [
                      const SizedBox(height: 8),
                      Expanded(child: SvgPicture.asset('assets/icons/${t.$2}.svg', width: 48, height: 48)),
                      Expanded(
                        child: Text(
                          t.$1,
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          style: OTextStyle.bodySmall.copyWith(color: OColor.gray800, fontWeight: FontWeight.w500),
                        ),
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

class _BloodTile extends StatelessWidget {
  final VoidCallback onTap;
  final bool live;
  const _BloodTile({required this.onTap, required this.live});

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onTap: onTap,
      child: Column(
        children: [
          const SizedBox(height: 8),
          Expanded(
            child: Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.center,
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: PulseColors.blush,
                    borderRadius: BorderRadius.circular(OCornerRadius.m),
                  ),
                  alignment: Alignment.center,
                  child: Heartbeat(
                    active: live,
                    strength: 1.5,
                    child: DropShape(
                      size: 28,
                      color: PulseColors.crimson,
                      child: const Icon(FluentIcons.add_12_filled, color: Colors.white, size: 10),
                    ),
                  ),
                ),
                Positioned(
                  top: -2,
                  right: 4,
                  child:
                      live
                          ? Heartbeat(
                            strength: 3,
                            child: Container(
                              width: 12,
                              height: 12,
                              decoration: BoxDecoration(
                                color: PulseColors.crimson,
                                shape: BoxShape.circle,
                                border: Border.all(color: OColor.white, width: 2),
                              ),
                            ),
                          )
                          : Container(
                            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                            decoration: BoxDecoration(
                              color: OColor.blue500,
                              borderRadius: BorderRadius.circular(OCornerRadius.xl),
                            ),
                            child: Text(
                              'NEW',
                              style: OTextStyle.labelXSmall.copyWith(color: Colors.white, fontSize: 8),
                            ),
                          ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Text(
              'Blood Donation',
              textAlign: TextAlign.center,
              maxLines: 2,
              style: OTextStyle.bodySmall.copyWith(color: OColor.gray800, fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }
}

class QuickLinksPlaceholder extends StatelessWidget {
  const QuickLinksPlaceholder({super.key});

  @override
  Widget build(BuildContext context) {
    final links = ['Academic calendar', 'Course registration', 'Hostel portal'];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Quick Links', style: OTextStyle.headingMedium.copyWith(color: OColor.gray800)),
        const SizedBox(height: 12),
        HomeWidgetBox(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: Column(
            children: [
              for (var i = 0; i < links.length; i++) ...[
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                  onTap: () => notInPrototype(context, links[i]),
                  title: Text(links[i], style: PText.body(OColor.gray800)),
                  trailing: Icon(FluentIcons.open_20_regular, color: OColor.gray400, size: 18),
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
