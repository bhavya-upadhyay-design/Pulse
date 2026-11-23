import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';

import '../theme/bd.dart';
import 'tabs/explore_tab.dart';
import 'tabs/hero_wall_tab.dart';
import 'tabs/my_donations_tab.dart';
import 'widgets/common.dart';
import 'widgets/nss_console.dart';

/// Blood Donation section, opened from Quick Access. Has its own bottom nav:
/// My Donations · Explore · Hero wall (Figma "Frame 355").
class BloodShell extends StatefulWidget {
  final int initialTab;
  const BloodShell({super.key, this.initialTab = 0});

  static Route route({int tab = 0}) => PageRouteBuilder(
    transitionDuration: const Duration(milliseconds: 320),
    reverseTransitionDuration: const Duration(milliseconds: 240),
    pageBuilder: (_, _, _) => BloodShell(initialTab: tab),
    transitionsBuilder: (_, a, _, c) {
      final cu = CurvedAnimation(parent: a, curve: Curves.easeOutCubic);
      return FadeTransition(
        opacity: cu,
        child: SlideTransition(position: Tween(begin: const Offset(0.06, 0), end: Offset.zero).animate(cu), child: c),
      );
    },
  );

  @override
  State<BloodShell> createState() => _BloodShellState();
}

class _BloodShellState extends State<BloodShell> {
  late int _tab = widget.initialTab;

  void go(int i) => setState(() => _tab = i);

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.viewPaddingOf(context).bottom;
    return Scaffold(
      backgroundColor: BD.page,
      body: Column(
        children: [
          BdAppBar(title: 'Blood Donation', trailing: const NssConsoleButton()),
          Expanded(
            child: Stack(
              children: [
                Positioned.fill(
                  child: AnimatedSwitcher(
                    duration: BD.medium,
                    switchInCurve: Curves.easeOutCubic,
                    transitionBuilder:
                        (c, a) => FadeTransition(
                          opacity: a,
                          child: SlideTransition(position: Tween(begin: const Offset(0, 0.02), end: Offset.zero).animate(a), child: c),
                        ),
                    child: KeyedSubtree(
                      key: ValueKey(_tab),
                      child: switch (_tab) {
                        0 => MyDonationsTab(goExplore: () => go(1)),
                        1 => const ExploreTab(),
                        _ => const HeroWallTab(),
                      },
                    ),
                  ),
                ),
                Positioned(left: 12, right: 12, bottom: 14 + bottom, child: BdNav(index: _tab, onTap: go)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Header: #262626, back arrow, centred 18 Medium title.
class BdAppBar extends StatelessWidget {
  final String title;
  final Widget? trailing;
  const BdAppBar({super.key, required this.title, this.trailing});

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.viewPaddingOf(context).top;
    return Container(
      width: double.infinity,
      color: BD.bar,
      padding: EdgeInsets.only(top: top),
      height: top + 59,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Text(title, style: T.medium(18)),
          Positioned(
            left: 4,
            child: IconButton(
              tooltip: 'Back',
              onPressed: () => Navigator.of(context).maybePop(),
              icon: const Icon(FluentIcons.arrow_left_24_regular, color: Colors.white, size: 22),
            ),
          ),
          if (trailing != null) Positioned(right: 8, child: trailing!),
        ],
      ),
    );
  }
}

/// Bottom nav pill (Figma 1810:6433): #262626, h 57, fully rounded; active
/// item #2c4035 with #2db062 label.
class BdNav extends StatelessWidget {
  final int index;
  final ValueChanged<int> onTap;
  const BdNav({super.key, required this.index, required this.onTap});

  static const _items = [('My Donations', 'nav_my_donations'), ('Explore', 'nav_explore'), ('Hero wall', 'nav_hero_wall')];

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 57,
      padding: const EdgeInsets.fromLTRB(3, 4, 3, 5),
      decoration: BoxDecoration(
        color: BD.card,
        borderRadius: BorderRadius.circular(296),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.35), blurRadius: 16, offset: const Offset(0, 6))],
      ),
      child: Row(
        children: [
          for (var i = 0; i < _items.length; i++)
            Expanded(
              child: Semantics(
                selected: index == i,
                button: true,
                label: _items[i].$1,
                excludeSemantics: true,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => onTap(i),
                  child: AnimatedContainer(
                    duration: BD.medium,
                    curve: Curves.easeOutCubic,
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    decoration: BoxDecoration(
                      color: index == i ? BD.navActiveBg : Colors.transparent,
                      borderRadius: BorderRadius.circular(128),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        AnimatedScale(
                          scale: index == i ? 1.08 : 1,
                          duration: BD.medium,
                          curve: Curves.easeOutBack,
                          child: bdSvg(_items[i].$2, width: 22, height: 22, tint: index == i ? const Color(0xFF2DB563) : BD.navInactive),
                        ),
                        const SizedBox(height: 2),
                        Text(_items[i].$1, style: T.regular(10, index == i ? BD.greenNav : BD.navInactive)),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
