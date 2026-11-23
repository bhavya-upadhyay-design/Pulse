import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';

import '../../state/models.dart';
import '../../state/pulse_store.dart';
import '../../theme/bd.dart';
import '../widgets/common.dart';
import '../widgets/motion.dart';

/// Hero wall (Figma 1810:8200): heroes card, hostel leaderboard, all donors.
class HeroWallTab extends StatelessWidget {
  const HeroWallTab({super.key});

  @override
  Widget build(BuildContext context) {
    final s = context.watch<PulseStore>();
    final bottom = MediaQuery.viewPaddingOf(context).bottom;
    return ListView(
      padding: EdgeInsets.fromLTRB(0, 39, 0, 100 + bottom),
      children: [
        Padding(padding: const EdgeInsets.symmetric(horizontal: 12), child: EnterIn(child: HeroesCard(store: s))),
        const SizedBox(height: 20),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 13),
          child: EnterIn(delay: const Duration(milliseconds: 80), child: Leaderboard(scores: s.leaderboard)),
        ),
        const SizedBox(height: 32),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: EnterIn(delay: const Duration(milliseconds: 160), child: _AllDonors(donors: s.donors)),
        ),
      ],
    );
  }
}

/// "24 heroes donated blood this month" (Figma Frame 310).
class HeroesCard extends StatelessWidget {
  final PulseStore store;
  const HeroesCard({super.key, required this.store});

  static const _avatars = ['avatar_1', 'avatar_2', 'avatar_3', 'avatar_4', 'avatar_5'];

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 258,
      decoration: BoxDecoration(color: BD.card, borderRadius: BorderRadius.circular(24), border: Border.all(color: BD.border)),
      clipBehavior: Clip.antiAlias,
      child: LayoutBuilder(
        builder: (context, c) {
          final sx = c.maxWidth / 336;
          return Stack(
            children: [
              Positioned(
                left: 10 * sx,
                top: 7,
                width: 315 * sx,
                height: 187,
                child: SvgPicture.asset('assets/blood/hero_card_bg.svg', fit: BoxFit.fill),
              ),
              Positioned(
                left: 0,
                right: 0,
                top: 33,
                child: Column(
                  children: [
                    Container(
                      height: 39,
                      padding: const EdgeInsets.fromLTRB(22, 0, 16, 0),
                      decoration: BoxDecoration(color: BD.heroPill, borderRadius: BorderRadius.circular(108)),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          TweenAnimationBuilder<double>(
                            tween: Tween(begin: 0, end: store.heroesThisMonth.toDouble()),
                            duration: const Duration(milliseconds: 1200),
                            curve: Curves.easeOutCubic,
                            builder: (_, v, _) => Text('${v.round()} heroes', style: T.bold(17)),
                          ),
                          const SizedBox(width: 4),
                          Heartbeat(child: Image.asset('assets/blood/hero_badge.png', width: 25, height: 34)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text('donated blood this month', style: T.regular(16)),
                    const SizedBox(height: 31),
                    SizedBox(
                      width: 241,
                      height: 41,
                      child: Row(
                        children: [
                          for (var i = 0; i < 5; i++) ...[
                            if (i > 0) const SizedBox(width: 9),
                            EnterIn(
                              delay: Duration(milliseconds: 200 + 70 * i),
                              dy: 8,
                              child: Container(
                                width: 41,
                                height: 41,
                                decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                                clipBehavior: Clip.antiAlias,
                                child: Image.asset('assets/blood/${_avatars[i]}.png', fit: BoxFit.cover),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Positioned(
                left: 11 * sx,
                right: 18 * sx,
                top: 196,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Total lives touched', style: T.medium(12, BD.text700)),
                    Text('${store.livesTouched}+', style: T.medium(28)),
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

/// Leaderboard podium (Figma 1810:8268). Uses Figtree as in the file.
class Leaderboard extends StatelessWidget {
  final List<HostelScore> scores; // [2nd, 1st, 3rd] left → right
  const Leaderboard({super.key, required this.scores});

  static const _fig = 'Figtree';

  @override
  Widget build(BuildContext context) {
    final left = scores[0], mid = scores[1], right = scores[2];
    return Container(
      height: 338,
      decoration: BoxDecoration(color: BD.card, borderRadius: BorderRadius.circular(16)),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          Positioned.fill(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 32, 16, 16),
              child: Column(
                children: [
                  Text(
                    'LEADERBOARD',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontFamily: _fig,
                      fontWeight: FontWeight.w900,
                      fontStyle: FontStyle.italic,
                      fontSize: 22,
                      height: 20 / 22,
                      letterSpacing: 3,
                      color: Colors.white,
                      shadows: [Shadow(color: Color(0x40FFFFFF), offset: Offset(0, 2))],
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text('Top 3 hostels', style: TextStyle(fontFamily: _fig, fontSize: 14, height: 20 / 14, color: Color(0x99FFFFFF))),
                  const SizedBox(height: 32),
                  SizedBox(
                    height: 210,
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: SizedBox(
                        width: 328,
                        height: 210,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              _Column(
                                width: 104,
                                score: left,
                                iconSize: const Size(44, 34),
                                cap: 'podium_top_left',
                                blockHeight: 76,
                                gradient: const [Color(0xFF2A764D), Color(0xFF1C3627)],
                                delay: 250,
                              ),
                              _Column(
                                width: 120,
                                score: mid,
                                iconSize: const Size(56, 38),
                                cap: 'podium_top_mid',
                                blockHeight: 108,
                                gradient: const [Color(0xFF58A279), Color(0xFF103A23)],
                                leader: true,
                                delay: 100,
                              ),
                              _Column(
                                width: 104,
                                score: right,
                                iconSize: const Size(52, 37),
                                cap: 'podium_top_right',
                                blockHeight: 60,
                                gradient: const [Color(0xFF235539), Color(0xFF154229)],
                                delay: 400,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Curved floor (Vector 5315) over the bottom of the podium.
          Positioned(left: 0, top: 297, child: SvgPicture.asset('assets/blood/podium_floor.svg', width: 360, height: 96)),
        ],
      ),
    );
  }
}

class _Column extends StatelessWidget {
  final double width;
  final HostelScore score;
  final Size iconSize;
  final String cap;
  final double blockHeight;
  final List<Color> gradient;
  final bool leader;
  final int delay;
  const _Column({
    required this.width,
    required this.score,
    required this.iconSize,
    required this.cap,
    required this.blockHeight,
    required this.gradient,
    required this.delay,
    this.leader = false,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(4, 0, 4, 8),
            child: Column(
              children: [
                SizedBox(
                  width: width - 8,
                  height: iconSize.height,
                  child: Stack(
                    clipBehavior: Clip.none,
                    alignment: Alignment.bottomCenter,
                    children: [
                      Image.asset(score.asset, width: iconSize.width, height: iconSize.height, fit: BoxFit.contain),
                      if (leader)
                        Positioned(
                          left: 74 - 4,
                          top: -5,
                          child: Heartbeat(child: SvgPicture.asset('assets/blood/leader_badge.svg', width: 22.29, height: 24)),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  height: 20,
                  child: Center(
                    child: Text(
                      score.name,
                      style: const TextStyle(
                        fontFamily: 'Figtree',
                        fontWeight: FontWeight.w500,
                        fontSize: 12,
                        height: 16 / 12,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          // Podium rises in.
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: 1),
            duration: Duration(milliseconds: 700 + delay),
            curve: Interval(delay / (700 + delay), 1, curve: Curves.easeOutBack),
            builder: (_, v, child) => Align(alignment: Alignment.bottomCenter, heightFactor: v.clamp(0.0, 1.0), child: child),
            child: Column(
              children: [
                SvgPicture.asset('assets/blood/$cap.svg', width: width, height: 12, fit: BoxFit.fill),
                Container(
                  width: width,
                  height: blockHeight,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: gradient),
                  ),
                  alignment: Alignment.topCenter,
                  child: SizedBox(
                    height: 28,
                    child: Center(
                      child: Text(
                        '${score.heroes}',
                        style: const TextStyle(
                          fontFamily: 'Figtree',
                          fontWeight: FontWeight.w800,
                          fontSize: 22,
                          height: 28 / 22,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// "All donors" feed (Figma 1810:8205).
class _AllDonors extends StatelessWidget {
  final List<Donor> donors;
  const _AllDonors({required this.donors});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('All donors', style: T.medium(18)),
        const SizedBox(height: 20),
        SvgPicture.asset('assets/blood/divider_h.svg', height: 1, fit: BoxFit.fill),
        const SizedBox(height: 24),
        for (var i = 0; i < donors.length; i++) ...[
          if (i > 0) const SizedBox(height: 24),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              InitialsDot(initials: donors[i].initials, highlight: donors[i].isYou),
              gap12,
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      donors[i].isYou ? '${donors[i].name} (you)' : donors[i].name,
                      style: T.medium(14, BD.text700).copyWith(height: 20 / 14),
                    ),
                    Text('Donated on ${donors[i].date.day} ${monthShort(donors[i].date)}', style: T.regular(14, BD.text600, 20 / 14)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}
