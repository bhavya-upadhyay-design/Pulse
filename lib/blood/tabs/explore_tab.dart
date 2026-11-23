import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';

import '../../state/models.dart';
import '../../state/pulse_store.dart';
import '../../theme/bd.dart';
import '../flows/learn.dart';
import '../widgets/common.dart';
import '../widgets/motion.dart';

/// Explore (Figma 1810:6450): upcoming camps + "Learn in 30 secs".
class ExploreTab extends StatelessWidget {
  const ExploreTab({super.key});

  @override
  Widget build(BuildContext context) {
    final s = context.watch<PulseStore>();
    final bottom = MediaQuery.viewPaddingOf(context).bottom;
    final eligibleCamp = _eligibleCamp(s);
    return ListView(
      padding: EdgeInsets.fromLTRB(0, 26, 0, 100 + bottom),
      children: [
        const Padding(padding: EdgeInsets.symmetric(horizontal: 12), child: SectionTitle('Upcoming donation camps')),
        const SizedBox(height: 16),
        for (var i = 0; i < s.camps.length; i++) ...[
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: EnterIn(
              delay: Duration(milliseconds: 50 * i),
              child:
                  s.camps[i] == eligibleCamp
                      ? EligibleCampBanner(
                        camp: s.camps[i],
                        joined: s.campsJoined.contains(s.camps[i].id),
                        onToggle: () => s.toggleCamp(s.camps[i].id),
                      )
                      : CampRow(
                        camp: s.camps[i],
                        joined: s.campsJoined.contains(s.camps[i].id),
                        onToggle: () => s.toggleCamp(s.camps[i].id),
                      ),
            ),
          ),
          SizedBox(height: s.camps[i] == eligibleCamp ? 16 : 16),
        ],
        const SizedBox(height: 8),
        const Padding(padding: EdgeInsets.symmetric(horizontal: 12), child: SectionTitle('Learn in 30 secs')),
        const SizedBox(height: 16),
        SizedBox(
          height: 212,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            scrollDirection: Axis.horizontal,
            itemCount: learnTopics.length,
            separatorBuilder: (_, _) => const SizedBox(width: 16),
            itemBuilder:
                (_, i) => EnterIn(
                  delay: Duration(milliseconds: 200 + 60 * i),
                  child: Semantics(
                    button: true,
                    label: learnTopics[i].title,
                    excludeSemantics: true,
                    child: Pressable(
                      onTap: () => openLearn(context, learnTopics[i]),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: Image.asset(learnTopics[i].card, width: 240, height: 212, fit: BoxFit.cover),
                      ),
                    ),
                  ),
                ),
          ),
        ),
      ],
    );
  }

  /// The first camp on or after the day the student becomes eligible.
  Camp? _eligibleCamp(PulseStore s) {
    if (!s.hasLifeline) return null;
    final from = s.nextEligible ?? DateTime.now();
    for (final c in s.camps) {
      if (!c.date.isBefore(DateTime(from.year, from.month, from.day))) return c;
    }
    return null;
  }
}

/// "You're eligible for this next camp" banner (Figma 1810:6475):
/// 1 px #aa4657 border, wavy crimson header, tent illustration, camp row.
class EligibleCampBanner extends StatelessWidget {
  final Camp camp;
  final bool joined;
  final VoidCallback onToggle;
  const EligibleCampBanner({super.key, required this.camp, required this.joined, required this.onToggle});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 165,
      decoration: BoxDecoration(color: BD.card, borderRadius: BorderRadius.circular(16), border: Border.all(color: BD.crimsonBorder)),
      clipBehavior: Clip.antiAlias,
      child: LayoutBuilder(
        builder: (context, c) {
          final w = c.maxWidth;
          return Stack(
            clipBehavior: Clip.none,
            children: [
              // Wavy header (Union) + wave line (Vector 1235), scaled to card width.
              Positioned(
                left: 0,
                top: 0.98,
                width: w * 358 / 335,
                height: 69.02,
                child: SvgPicture.asset('assets/blood/banner_wave.svg', fit: BoxFit.fill),
              ),
              Positioned(
                left: 0,
                top: 62.45,
                width: w * 358 / 335,
                height: 8.58,
                child: SvgPicture.asset('assets/blood/banner_wave_line.svg', fit: BoxFit.fill),
              ),
              Positioned(
                left: 12,
                top: 14,
                width: 169,
                child: Text('You’re eligible for this next camp', style: T.medium(14).copyWith(height: 1.5, letterSpacing: 0.6656)),
              ),
              // Tent (image 1979, flipped horizontally as in the file).
              Positioned(
                left: w * 223 / 335,
                top: 5 - 10.79,
                width: 93.55,
                height: 93.55,
                child: Heartbeat(
                  strength: 0.25,
                  child: Transform.flip(flipX: true, child: Image.asset('assets/blood/camp_tent.png', fit: BoxFit.cover)),
                ),
              ),
              Positioned(
                left: 12,
                right: 12,
                top: 93,
                child: Row(
                  children: [
                    DateBadge(date: camp.date),
                    gap12,
                    Expanded(child: EventInfo(title: camp.name, line1: camp.place, line2: camp.hours, sub: BD.bannerSub)),
                    GoPill(joined: joined, onTap: onToggle),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
