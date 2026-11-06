import 'dart:math';

import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';
import 'package:onestop_ui/index.dart';
import 'package:provider/provider.dart';

import '../event/outcome_flows.dart';
import '../state/models.dart';
import '../state/pulse_store.dart';
import '../theme/pulse_tokens.dart';
import '../widgets/motion.dart';
import '../widgets/particles.dart';
import 'bingo_sheets.dart';

/// 3×3 Recovery Bingo. Centre tile = iron-rich mess meal coupon.
class BingoPage extends StatefulWidget {
  const BingoPage({super.key});

  static Route route() => PageRouteBuilder(
    transitionDuration: PulseMotion.morph,
    pageBuilder: (_, _, _) => const BingoPage(),
    transitionsBuilder: (_, a, _, c) {
      final cu = CurvedAnimation(parent: a, curve: PulseMotion.standardCurve);
      return FadeTransition(
        opacity: cu,
        child: SlideTransition(position: Tween(begin: const Offset(0, 0.06), end: Offset.zero).animate(cu), child: c),
      );
    },
  );

  @override
  State<BingoPage> createState() => _BingoPageState();
}

class _BingoPageState extends State<BingoPage> with TickerProviderStateMixin {
  final Set<String> _seenLines = {};
  final Map<String, AnimationController> _lineAnims = {};
  bool _initialised = false;
  bool _fullHouseShown = false;
  late final AnimationController _fold = AnimationController(vsync: this, duration: const Duration(milliseconds: 900));

  static const _bonuses = [
    ('Badge frame', FluentIcons.image_border_24_filled),
    ('Hero raffle entry', FluentIcons.ticket_diagonal_24_filled),
    ('"Superhero" title', FluentIcons.star_emphasis_24_filled),
  ];

  @override
  void dispose() {
    for (final c in _lineAnims.values) {
      c.dispose();
    }
    _fold.dispose();
    super.dispose();
  }

  String _key(List<int> l) => l.join('-');

  void _syncLines(PulseStore s) {
    final lines = s.completedLines;
    if (!_initialised) {
      // Lines already done before opening: draw them without celebration.
      for (final l in lines) {
        _seenLines.add(_key(l));
        _lineAnims[_key(l)] = AnimationController(vsync: this, duration: const Duration(milliseconds: 300), value: 1);
      }
      _initialised = true;
      _fullHouseShown = s.bingoDone;
      if (s.bingoDone) _fold.value = 1;
      return;
    }
    for (final l in lines) {
      final k = _key(l);
      if (_seenLines.contains(k)) continue;
      _seenLines.add(k);
      final c = AnimationController(vsync: this, duration: const Duration(milliseconds: 300));
      _lineAnims[k] = c;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        c.forward();
        final n = _seenLines.length;
        if (!s.bingoDone) {
          playBurst(context, BurstKind.hearts, count: 14);
          Haptics.medium();
          final b = n <= 3 ? _bonuses[n - 1].$1 : null;
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(
              SnackBar(
                behavior: SnackBarBehavior.floating,
                backgroundColor: PulseColors.deep,
                content: Text(b == null ? 'BINGO! Another line.' : 'BINGO! Line $n: $b unlocked'),
              ),
            );
        }
      });
    }
    if (s.bingoDone && !_fullHouseShown) {
      _fullHouseShown = true;
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        await Future.delayed(const Duration(milliseconds: 500));
        if (!mounted) return;
        _fold.forward();
        await Future.delayed(const Duration(milliseconds: 700));
        if (!mounted) return;
        playBurst(context, BurstKind.confetti);
        Haptics.success();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = context.watch<PulseStore>();
    _syncLines(s);
    final lines = s.completedLines.length;
    return Scaffold(
      backgroundColor: OColor.gray100,
      appBar: AppBar(
        backgroundColor: OColor.gray100,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(FluentIcons.arrow_left_24_regular, color: OColor.gray800),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text('Recovery Bingo', style: PText.h2(OColor.gray800)),
      ),
      body: AnimatedBuilder(
        animation: _fold,
        builder: (_, _) {
          final v = Curves.easeInOutCubic.transform(_fold.value);
          if (v >= 0.5) return _FullHouse(progress: (v - 0.5) * 2, store: s);
          return Transform(
            alignment: Alignment.center,
            transform:
                Matrix4.identity()
                  ..setEntry(3, 2, 0.0012)
                  ..rotateY(v * pi),
            child: _board(s, lines),
          );
        },
      ),
    );
  }

  Widget _board(PulseStore s, int lines) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
      children: [
        // Header
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: PulseColors.card,
            borderRadius: BorderRadius.circular(OCornerRadius.l),
            boxShadow: PulseColors.floatShadow,
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('DAY 1 OF 7', style: OTextStyle.labelXSmall.copyWith(color: Colors.white70, letterSpacing: 1)),
                    const SizedBox(height: 4),
                    Text('9 small missions to bounce back', style: PText.h3(Colors.white)),
                    const SizedBox(height: 4),
                    Text(
                      s.donationConfirmed
                          ? 'NSS confirmed your donation • coupon unlocked'
                          : 'Awaiting NSS confirmation for your coupon',
                      style: PText.bodyX(Colors.white70),
                    ),
                  ],
                ),
              ),
              _HeaderRing(done: s.ticked.length),
            ],
          ),
        ),
        const SizedBox(height: 16),
        // Board
        LayoutBuilder(
          builder: (context, c) {
            const gap = 8.0;
            final tile = (c.maxWidth - gap * 2) / 3;
            return SizedBox(
              height: tile * 3 + gap * 2,
              child: Stack(
                children: [
                  for (var i = 0; i < 9; i++)
                    Positioned(
                      left: (i % 3) * (tile + gap),
                      top: (i ~/ 3) * (tile + gap),
                      width: tile,
                      height: tile,
                      child: _Tile(index: i, store: s, onTap: () => _onTile(i, s)),
                    ),
                  for (final e in _lineAnims.entries)
                    Positioned.fill(
                      child: IgnorePointer(
                        child: AnimatedBuilder(
                          animation: e.value,
                          builder:
                              (_, _) => CustomPaint(
                                painter: _LinePainter(
                                  e.key.split('-').map(int.parse).toList(),
                                  e.value.value,
                                  tile,
                                  gap,
                                ),
                              ),
                        ),
                      ),
                    ),
                ],
              ),
            );
          },
        ),
        const SizedBox(height: 16),
        Text('Line bonuses', style: PText.h3(OColor.gray800)),
        const SizedBox(height: 8),
        Row(
          children: [
            for (var i = 0; i < 3; i++) ...[
              Expanded(child: _Bonus(label: _bonuses[i].$1, icon: _bonuses[i].$2, unlocked: lines > i)),
              if (i < 2) const SizedBox(width: 8),
            ],
          ],
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: OColor.white,
            borderRadius: BorderRadius.circular(OCornerRadius.m),
            border: Border.all(color: OColor.gray200),
          ),
          child: Row(
            children: [
              Icon(FluentIcons.hand_left_24_regular, color: OColor.gray500, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Press and hold a self-check tile for a second to tick it. Bingo is optional: your donation already counts.',
                  style: PText.bodyX(OColor.gray600),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _onTile(int i, PulseStore s) {
    final t = PulseStore.tiles[i];
    if (s.isTicked(i) && t.id != 'meal') return;
    switch (t.id) {
      case 'water2l':
        showWaterSheet(context);
      case 'meal':
        showCouponSheet(context);
      case 'nominate':
        showNominateSheet(context);
      case 'share':
        showHeroShareSheet(context, onShared: () => s.tick('share'));
      case 'checkin':
        showCheckinSheet(context);
      default:
        break; // hold-to-tick tiles handle themselves
    }
  }
}

class _HeaderRing extends StatelessWidget {
  final int done;
  const _HeaderRing({required this.done});

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(end: done / 9),
      duration: const Duration(milliseconds: 700),
      curve: Curves.easeOutCubic,
      builder:
          (_, v, _) => SizedBox(
            width: 64,
            height: 64,
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 64,
                  height: 64,
                  child: CircularProgressIndicator(
                    value: v,
                    strokeWidth: 5,
                    strokeCap: StrokeCap.round,
                    color: Colors.white,
                    backgroundColor: Colors.white24,
                  ),
                ),
                Text(
                  '$done/9',
                  style: OTextStyle.labelMedium.copyWith(color: Colors.white, fontWeight: FontWeight.w700),
                ),
              ],
            ),
          ),
    );
  }
}

class _Tile extends StatefulWidget {
  final int index;
  final PulseStore store;
  final VoidCallback onTap;
  const _Tile({required this.index, required this.store, required this.onTap});

  @override
  State<_Tile> createState() => _TileState();
}

class _TileState extends State<_Tile> with SingleTickerProviderStateMixin {
  late final AnimationController _hold = AnimationController(vsync: this, duration: const Duration(milliseconds: 900));

  BingoTile get t => PulseStore.tiles[widget.index];
  bool get holdTile => const {'water500', 'rest', 'noGym', 'snack'}.contains(t.id);

  @override
  void initState() {
    super.initState();
    _hold.addStatusListener((st) {
      if (st == AnimationStatus.completed) {
        Haptics.light();
        widget.store.tick(t.id);
      }
    });
  }

  @override
  void dispose() {
    _hold.dispose();
    super.dispose();
  }

  String? _progressLabel(PulseStore s) {
    switch (t.id) {
      case 'water2l':
        return s.isTicked(widget.index) ? null : '${s.glasses}/4 glasses';
      case 'nominate':
        if (s.friends.isEmpty) return null;
        return '${s.friends.where((f) => f.registered).length}/2 joined';
      case 'meal':
        if (s.coupon == null) return s.donationConfirmed ? 'Tap to claim' : 'Unlocks soon';
        return s.coupon!.redeemed ? null : 'Coupon ready';
      default:
        return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.store;
    final done = s.isTicked(widget.index);
    final centre = t.id == 'meal';
    final progress = _progressLabel(s);
    final holdable = holdTile && !done;
    void release() {
      if (!_hold.isCompleted) _hold.reverse();
    }

    return Semantics(
      button: true,
      label: '${t.title}. ${progress ?? t.hint}',
      value: done ? 'Done' : 'Not done',
      hint: holdable ? 'Press and hold to tick' : null,
      onLongPress: holdable ? () => s.tick(t.id) : null,
      onTap: holdTile ? null : widget.onTap,
      excludeSemantics: true,
      child: Listener(
        onPointerDown: holdable ? (_) => _hold.forward(from: 0) : null,
        onPointerUp: holdable ? (_) => release() : null,
        onPointerCancel: holdable ? (_) => release() : null,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: holdTile ? null : widget.onTap,
          child: AnimatedContainer(
            duration: PulseMotion.standard,
            decoration: BoxDecoration(
              color: done ? PulseColors.blush : (centre ? PulseColors.goldSoft : OColor.white),
              borderRadius: BorderRadius.circular(OCornerRadius.m),
              border: Border.all(
                color: done ? PulseColors.crimson.withValues(alpha: 0.4) : (centre ? PulseColors.gold : OColor.gray200),
                width: centre ? 1.5 : 1,
              ),
            ),
            clipBehavior: Clip.antiAlias,
            child: Stack(
              children: [
                // Liquid fill while holding.
                AnimatedBuilder(
                  animation: _hold,
                  builder:
                      (_, _) => Align(
                        alignment: Alignment.bottomCenter,
                        child: FractionallySizedBox(
                          heightFactor: done ? 0 : _hold.value,
                          widthFactor: 1,
                          child: Container(color: OColor.blue100),
                        ),
                      ),
                ),
                Padding(
                  padding: const EdgeInsets.all(10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        t.icon,
                        size: 22,
                        color: done ? PulseColors.crimson : (centre ? OColor.yellow700 : OColor.gray600),
                      ),
                      const Spacer(),
                      Text(
                        t.title,
                        maxLines: 2,
                        style: OTextStyle.labelXSmall.copyWith(
                          color: OColor.gray800,
                          fontWeight: FontWeight.w700,
                          height: 1.2,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        progress ?? t.hint,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: OTextStyle.bodyXSmall.copyWith(
                          color: progress != null ? (centre ? OColor.yellow700 : OColor.blue500) : OColor.gray500,
                          fontSize: 10,
                          fontWeight: progress != null ? FontWeight.w600 : FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                ),
                // Stamp.
                Positioned(
                  right: 6,
                  top: 6,
                  child: AnimatedSwitcher(
                    duration: PulseMotion.emphasis,
                    transitionBuilder: (c, a) {
                      final cu = CurvedAnimation(parent: a, curve: Curves.easeOutBack);
                      return AnimatedBuilder(
                        animation: cu,
                        builder:
                            (_, child) => Transform.rotate(
                              angle: (1 - cu.value) * -0.14,
                              child: Transform.scale(
                                scale: 1.3 - 0.3 * cu.value,
                                child: Opacity(opacity: a.value, child: child),
                              ),
                            ),
                        child: c,
                      );
                    },
                    child:
                        done
                            ? Container(
                              key: const ValueKey('stamp'),
                              width: 30,
                              height: 30,
                              decoration: BoxDecoration(color: PulseColors.crimson, shape: BoxShape.circle),
                              child: const Icon(FluentIcons.checkmark_20_filled, color: Colors.white, size: 18),
                            )
                            : (centre
                                ? Heartbeat(
                                  key: const ValueKey('star'),
                                  child: Icon(FluentIcons.star_20_filled, color: PulseColors.gold, size: 20),
                                )
                                : const SizedBox.shrink(key: ValueKey('none'))),
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

class _LinePainter extends CustomPainter {
  final List<int> line;
  final double t;
  final double tile, gap;
  _LinePainter(this.line, this.t, this.tile, this.gap);

  Offset _c(int i) => Offset((i % 3) * (tile + gap) + tile / 2, (i ~/ 3) * (tile + gap) + tile / 2);

  @override
  void paint(Canvas canvas, Size size) {
    if (t <= 0) return;
    var a = _c(line.first);
    var b = _c(line.last);
    final d = (b - a);
    final u = d / d.distance;
    a = a - u * tile * 0.35;
    b = b + u * tile * 0.35;
    final end = Offset.lerp(a, b, Curves.easeOutCubic.transform(t))!;
    canvas.drawLine(
      a,
      end,
      Paint()
        ..color = const Color(0xFFDE1135).withValues(alpha: 0.75)
        ..strokeWidth = 6
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(covariant _LinePainter old) => old.t != t;
}

class _Bonus extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool unlocked;
  const _Bonus({required this.label, required this.icon, required this.unlocked});

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: PulseMotion.standard,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: unlocked ? PulseColors.goldSoft : OColor.white,
        borderRadius: BorderRadius.circular(OCornerRadius.m),
        border: Border.all(color: unlocked ? PulseColors.gold : OColor.gray200),
      ),
      child: Column(
        children: [
          Icon(
            unlocked ? icon : FluentIcons.lock_closed_20_regular,
            color: unlocked ? OColor.yellow700 : OColor.gray400,
            size: 22,
          ),
          const SizedBox(height: 4),
          Text(label, textAlign: TextAlign.center, style: PText.bodyX(unlocked ? OColor.gray800 : OColor.gray500)),
        ],
      ),
    );
  }
}

class _FullHouse extends StatelessWidget {
  final double progress;
  final PulseStore store;
  const _FullHouse({required this.progress, required this.store});

  @override
  Widget build(BuildContext context) {
    return Transform(
      alignment: Alignment.center,
      transform:
          Matrix4.identity()
            ..setEntry(3, 2, 0.0012)
            ..rotateY((1 - progress) * -pi / 2),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          // Sealed envelope
          AspectRatio(
            aspectRatio: 1.35,
            child: Container(
              decoration: BoxDecoration(
                gradient: PulseColors.card,
                borderRadius: BorderRadius.circular(OCornerRadius.l),
                boxShadow: PulseColors.floatShadow,
              ),
              child: Stack(
                children: [
                  Positioned.fill(child: CustomPaint(painter: _FlapPainter())),
                  Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Heartbeat(
                          child: Container(
                            width: 64,
                            height: 64,
                            decoration: BoxDecoration(
                              color: PulseColors.gold,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 3),
                            ),
                            child: const Icon(FluentIcons.heart_24_filled, color: Colors.white, size: 32),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text('Recovery complete', style: PText.h1(Colors.white).copyWith(fontWeight: FontWeight.w800)),
                        const SizedBox(height: 4),
                        Text('Full house, ${store.firstName}. You\'re a Superhero.', style: PText.body(Colors.white70)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          _Line(
            icon: FluentIcons.ribbon_star_24_filled,
            text: 'Hero badge and "Superhero" title added to your profile',
          ),
          _Line(icon: FluentIcons.ticket_diagonal_24_filled, text: "You're in this month's Hero raffle"),
          _Line(
            icon: FluentIcons.calendar_24_regular,
            text: 'Next eligible: ${store.nextEligible != null ? dayLabel(store.nextEligible!) : 'in 90 days'}',
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: SecondaryButton(
              label: 'Download NSS certificate',
              leadingIcon: FluentIcons.arrow_download_24_regular,
              onPressed:
                  () => ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Certificate downloaded (prototype)'),
                      behavior: SnackBarBehavior.floating,
                    ),
                  ),
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: PrimaryButton(
              label: 'Close event',
              onPressed: () {
                store.finishEvent();
                Navigator.of(context).popUntil((r) => r.isFirst);
                store.push(
                  'Thank you, ${store.firstName}',
                  'Your donation is saved in Blood Donation → My donations.',
                  FluentIcons.heart_24_filled,
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _FlapPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final p =
        Paint()
          ..color = Colors.white.withValues(alpha: 0.14)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2;
    canvas.drawPath(
      Path()
        ..moveTo(0, 0)
        ..lineTo(size.width / 2, size.height * 0.52)
        ..lineTo(size.width, 0),
      p,
    );
    canvas.drawLine(Offset(0, size.height), Offset(size.width * 0.38, size.height * 0.42), p);
    canvas.drawLine(Offset(size.width, size.height), Offset(size.width * 0.62, size.height * 0.42), p);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _Line extends StatelessWidget {
  final IconData icon;
  final String text;
  const _Line({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, color: OColor.green600, size: 20),
          const SizedBox(width: 10),
          Expanded(child: Text(text, style: PText.body(OColor.gray800))),
        ],
      ),
    );
  }
}
