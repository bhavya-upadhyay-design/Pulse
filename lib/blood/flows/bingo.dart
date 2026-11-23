import 'dart:math';

import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../state/models.dart';
import '../../state/pulse_store.dart';
import '../../theme/bd.dart';
import '../blood_shell.dart';
import '../widgets/common.dart';
import '../widgets/motion.dart';
import 'actions.dart';
import 'outcome.dart';

/// Recovery Bingo: a 3×3 card of recovery missions after donating.
/// Centre tile = iron-rich mess meal coupon.
class BingoPage extends StatefulWidget {
  const BingoPage({super.key});

  static Route route() => PageRouteBuilder(
    transitionDuration: const Duration(milliseconds: 380),
    pageBuilder: (_, _, _) => const BingoPage(),
    transitionsBuilder:
        (_, a, _, c) => FadeTransition(
          opacity: a,
          child: SlideTransition(
            position: Tween(begin: const Offset(0, 0.04), end: Offset.zero).animate(CurvedAnimation(parent: a, curve: Curves.easeOutCubic)),
            child: c,
          ),
        ),
  );

  @override
  State<BingoPage> createState() => _BingoPageState();
}

class _BingoPageState extends State<BingoPage> with TickerProviderStateMixin {
  final Set<String> _seen = {};
  final Map<String, AnimationController> _lines = {};
  bool _init = false;
  bool _houseShown = false;
  late final AnimationController _fold = AnimationController(vsync: this, duration: const Duration(milliseconds: 900));

  static const _bonuses = [
    ('Badge frame', FluentIcons.image_border_20_filled),
    ('Hero raffle entry', FluentIcons.ticket_diagonal_20_filled),
    ('Superhero title', FluentIcons.star_emphasis_20_filled),
  ];

  @override
  void dispose() {
    for (final c in _lines.values) {
      c.dispose();
    }
    _fold.dispose();
    super.dispose();
  }

  void _sync(PulseStore s) {
    for (final l in s.completedLines) {
      final k = l.join('-');
      if (_seen.contains(k)) continue;
      _seen.add(k);
      final c = AnimationController(vsync: this, duration: const Duration(milliseconds: 320), value: _init ? 0 : 1);
      _lines[k] = c;
      if (_init) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          c.forward();
          if (s.bingoDone) return;
          playBurst(context);
          Haptics.medium();
          final n = _seen.length;
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(bdSnack(n <= 3 ? 'BINGO! ${_bonuses[n - 1].$1} unlocked' : 'BINGO! Another line'));
        });
      }
    }
    if (!_init) {
      _init = true;
      _houseShown = s.bingoDone;
      if (s.bingoDone) _fold.value = 1;
    } else if (s.bingoDone && !_houseShown) {
      _houseShown = true;
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        await Future.delayed(const Duration(milliseconds: 500));
        if (!mounted) return;
        _fold.forward();
        await Future.delayed(const Duration(milliseconds: 700));
        if (!mounted) return;
        playBurst(context, confetti: true);
        Haptics.success();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = context.watch<PulseStore>();
    _sync(s);
    return Scaffold(
      backgroundColor: BD.page,
      body: Column(
        children: [
          const BdAppBar(title: 'Recovery Bingo'),
          Expanded(
            child: AnimatedBuilder(
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
                  child: _board(s),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _board(PulseStore s) {
    final bottom = MediaQuery.viewPaddingOf(context).bottom;
    final lines = s.completedLines.length;
    return ListView(
      padding: EdgeInsets.fromLTRB(12, 16, 12, 24 + bottom),
      children: [
        Container(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 20),
          decoration: BoxDecoration(
            gradient: BD.requestGradient,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: BD.border),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('DAY 1 OF 7', style: T.medium(10, BD.textSecondary).copyWith(letterSpacing: 1)),
                    gap4,
                    Text('9 small missions to bounce back', style: T.bold(16)),
                    gap4,
                    Text(
                      s.donationConfirmed ? 'Donation confirmed • meal coupon unlocked' : 'Awaiting NSS confirmation for your meal',
                      style: T.regular(12, BD.textSecondary),
                    ),
                  ],
                ),
              ),
              SizedBox(
                width: 56,
                height: 56,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      width: 56,
                      height: 56,
                      child: TweenAnimationBuilder<double>(
                        tween: Tween(end: s.ticked.length / 9),
                        duration: BD.slow,
                        builder:
                            (_, v, _) => CircularProgressIndicator(
                              value: v,
                              strokeWidth: 4,
                              strokeCap: StrokeCap.round,
                              color: BD.toggleOn,
                              backgroundColor: const Color(0x33FFFFFF),
                            ),
                      ),
                    ),
                    Text('${s.ticked.length}/9', style: T.bold(14)),
                  ],
                ),
              ),
            ],
          ),
        ),
        gap16,
        LayoutBuilder(
          builder: (context, c) {
            const g = 8.0;
            final t = (c.maxWidth - 2 * g) / 3;
            return SizedBox(
              height: 3 * t + 2 * g,
              child: Stack(
                children: [
                  for (var i = 0; i < 9; i++)
                    Positioned(
                      left: (i % 3) * (t + g),
                      top: (i ~/ 3) * (t + g),
                      width: t,
                      height: t,
                      child: _Tile(index: i, store: s, onTap: () => _onTile(i, s)),
                    ),
                  for (final e in _lines.entries)
                    Positioned.fill(
                      child: IgnorePointer(
                        child: AnimatedBuilder(
                          animation: e.value,
                          builder:
                              (_, _) => CustomPaint(painter: _LinePainter(e.key.split('-').map(int.parse).toList(), e.value.value, t, g)),
                        ),
                      ),
                    ),
                ],
              ),
            );
          },
        ),
        gap24,
        const SectionTitle('Line bonuses'),
        const SizedBox(height: 17),
        Row(
          children: [
            for (var i = 0; i < 3; i++) ...[
              if (i > 0) gap8,
              Expanded(
                child: AnimatedContainer(
                  duration: BD.medium,
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 6),
                  decoration: BoxDecoration(
                    color: BD.card,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: lines > i ? BD.crimsonBorder : BD.border),
                  ),
                  child: Column(
                    children: [
                      Icon(
                        lines > i ? _bonuses[i].$2 : FluentIcons.lock_closed_20_regular,
                        color: lines > i ? BD.toggleOn : BD.textSecondary,
                        size: 20,
                      ),
                      gap4,
                      Text(_bonuses[i].$1, textAlign: TextAlign.center, style: T.medium(11, lines > i ? Colors.white : BD.textSecondary)),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
        gap16,
        Text(
          'Press and hold a self-check tile for a second to tick it. Bingo is optional: your donation already counts.',
          textAlign: TextAlign.center,
          style: T.regular(12, BD.textSecondary),
        ),
      ],
    );
  }

  void _onTile(int i, PulseStore s) {
    final id = PulseStore.tiles[i].id;
    if (s.isTicked(i) && id != 'meal') return;
    switch (id) {
      case 'water2l':
        showBdSheet(context, builder: (_) => const _WaterSheet());
      case 'meal':
        showBdSheet(context, builder: (_) => const _CouponSheet());
      case 'nominate':
        showBdSheet(context, builder: (_) => const _NominateSheet());
      case 'share':
        showHeroShare(context, onShared: () => s.tick('share'));
      case 'checkin':
        showBdSheet(context, builder: (_) => const _CheckinSheet());
    }
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

  String? _progress(PulseStore s) => switch (t.id) {
    'water2l' => s.isTicked(widget.index) ? null : '${s.glasses}/4 glasses',
    'nominate' => s.friends.isEmpty ? null : '${s.friends.where((f) => f.registered).length}/2 joined',
    'meal' => s.coupon == null ? (s.donationConfirmed ? 'Tap to claim' : 'Unlocks soon') : (s.coupon!.redeemed ? null : 'Coupon ready'),
    _ => null,
  };

  @override
  Widget build(BuildContext context) {
    final s = widget.store;
    final done = s.isTicked(widget.index);
    final centre = t.id == 'meal';
    final hold = holdTile && !done;
    final p = _progress(s);
    return Semantics(
      button: true,
      label: '${t.title}. ${p ?? t.hint}',
      value: done ? 'Done' : 'Not done',
      hint: hold ? 'Press and hold to tick' : null,
      onLongPress: hold ? () => s.tick(t.id) : null,
      onTap: holdTile ? null : widget.onTap,
      excludeSemantics: true,
      child: Listener(
        onPointerDown: hold ? (_) => _hold.forward(from: 0) : null,
        onPointerUp: hold ? (_) => _hold.isCompleted ? null : _hold.reverse() : null,
        onPointerCancel: hold ? (_) => _hold.isCompleted ? null : _hold.reverse() : null,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: holdTile ? null : widget.onTap,
          child: AnimatedContainer(
            duration: BD.medium,
            decoration: BoxDecoration(
              color: BD.card,
              gradient: done ? BD.requestGradient : null,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: done ? BD.crimsonBorder : (centre ? BD.greenCta : BD.border)),
            ),
            clipBehavior: Clip.antiAlias,
            child: Stack(
              children: [
                AnimatedBuilder(
                  animation: _hold,
                  builder:
                      (_, _) => Align(
                        alignment: Alignment.bottomCenter,
                        child: FractionallySizedBox(
                          heightFactor: done ? 0 : _hold.value,
                          widthFactor: 1,
                          child: Container(color: BD.greenBadgeBg),
                        ),
                      ),
                ),
                Padding(
                  padding: const EdgeInsets.all(10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(t.icon, size: 20, color: done ? BD.toggleOn : (centre ? BD.green : BD.textSecondary)),
                      const Spacer(),
                      Text(t.title, maxLines: 2, style: T.bold(12).copyWith(height: 1.2)),
                      const SizedBox(height: 2),
                      Text(
                        p ?? t.hint,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: T.regular(10, p != null ? BD.green : BD.textSecondary),
                      ),
                    ],
                  ),
                ),
                Positioned(
                  right: 6,
                  top: 6,
                  child: AnimatedSwitcher(
                    duration: BD.slow,
                    transitionBuilder: (c, a) => ScaleTransition(scale: CurvedAnimation(parent: a, curve: Curves.easeOutBack), child: c),
                    child:
                        done
                            ? Container(
                              key: const ValueKey('y'),
                              width: 24,
                              height: 24,
                              decoration: const BoxDecoration(color: BD.green, shape: BoxShape.circle),
                              child: const Icon(FluentIcons.checkmark_16_filled, color: Colors.white, size: 14),
                            )
                            : const SizedBox.shrink(key: ValueKey('n')),
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
  final List<int> l;
  final double t, tile, g;
  _LinePainter(this.l, this.t, this.tile, this.g);

  Offset _c(int i) => Offset((i % 3) * (tile + g) + tile / 2, (i ~/ 3) * (tile + g) + tile / 2);

  @override
  void paint(Canvas canvas, Size size) {
    if (t <= 0) return;
    var a = _c(l.first), b = _c(l.last);
    final u = (b - a) / (b - a).distance;
    a -= u * tile * 0.35;
    b += u * tile * 0.35;
    canvas.drawLine(
      a,
      Offset.lerp(a, b, Curves.easeOutCubic.transform(t))!,
      Paint()
        ..color = BD.toggleOn.withValues(alpha: 0.45)
        ..strokeWidth = 4
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(covariant _LinePainter o) => o.t != t;
}

class _FullHouse extends StatelessWidget {
  final double progress;
  final PulseStore store;
  const _FullHouse({required this.progress, required this.store});

  @override
  Widget build(BuildContext context) {
    final s = store;
    return Transform(
      alignment: Alignment.center,
      transform:
          Matrix4.identity()
            ..setEntry(3, 2, 0.0012)
            ..rotateY((1 - progress) * -pi / 2),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(12, 16, 12, 24),
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(16, 32, 16, 24),
            decoration: BoxDecoration(
              gradient: BD.requestGradient,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: BD.border),
            ),
            child: Column(
              children: [
                Heartbeat(child: Image.asset('assets/blood/hero_badge.png', width: 50, height: 68)),
                gap16,
                Text('Recovery complete', style: T.bold(22)),
                gap8,
                Text("Full house, ${s.firstName}. You're a Superhero.", style: T.regular(14, BD.text700)),
              ],
            ),
          ),
          gap16,
          BdCard(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _row(FluentIcons.ribbon_star_20_filled, 'Hero badge and Superhero title added to your profile'),
                _row(FluentIcons.ticket_diagonal_20_filled, "You're in this month's Hero raffle"),
                _row(
                  FluentIcons.calendar_20_regular,
                  'Next eligible: ${s.nextEligible != null ? dayLabel(s.nextEligible!) : 'in 90 days'}',
                ),
              ],
            ),
          ),
          gap16,
          BdButton(
            label: 'Download NSS certificate',
            outline: true,
            icon: FluentIcons.arrow_download_20_regular,
            onTap: () => ScaffoldMessenger.of(context).showSnackBar(bdSnack('Certificate saved (prototype)')),
          ),
          gap8,
          BdButton(
            label: 'Close event',
            onTap: () {
              s.finishEvent();
              Navigator.of(context).pop();
              s.push('Thank you, ${s.firstName}', 'Your donation is saved under My Donations.');
            },
          ),
        ],
      ),
    );
  }

  Widget _row(IconData i, String t) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 6),
    child: Row(children: [Icon(i, color: BD.green, size: 20), gap12, Expanded(child: Text(t, style: T.medium(13)))]),
  );
}

// ───────────── Sheets ─────────────
class _WaterSheet extends StatelessWidget {
  const _WaterSheet();

  @override
  Widget build(BuildContext context) {
    final s = context.watch<PulseStore>();
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('Drink 2 L today', style: T.bold(16)),
          gap8,
          Text('Tap a glass each time you finish 500 ml.', style: T.regular(12, BD.textSecondary)),
          gap24,
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              for (var i = 0; i < 4; i++)
                Semantics(
                  button: true,
                  label: 'Glass ${i + 1}',
                  value: i < s.glasses ? 'Full' : 'Empty',
                  onTap: i == s.glasses ? s.addGlass : null,
                  excludeSemantics: true,
                  child: Pressable(
                    onTap: i == s.glasses ? s.addGlass : null,
                    child: Container(
                      width: 52,
                      height: 76,
                      decoration: BoxDecoration(
                        color: BD.page,
                        border: Border.all(color: i == s.glasses ? BD.green : BD.border, width: 2),
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(4), bottom: Radius.circular(14)),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: Stack(
                        children: [
                          Align(
                            alignment: Alignment.bottomCenter,
                            child: TweenAnimationBuilder<double>(
                              tween: Tween(end: i < s.glasses ? 0.85 : 0),
                              duration: const Duration(milliseconds: 600),
                              curve: Curves.easeOutBack,
                              builder:
                                  (_, v, _) => FractionallySizedBox(
                                    heightFactor: v.clamp(0.0, 1.0),
                                    widthFactor: 1,
                                    child: Container(color: const Color(0xFF3887FF)),
                                  ),
                            ),
                          ),
                          if (i == s.glasses) const Center(child: Icon(FluentIcons.add_20_filled, color: BD.green, size: 18)),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
          gap16,
          Text(
            s.glasses >= 4 ? 'Hydrated! Tile ticked.' : '${(s.glasses * 0.5).toStringAsFixed(1)} L of 2 L',
            style: T.medium(13, s.glasses >= 4 ? BD.green : BD.text700),
          ),
        ],
      ),
    );
  }
}

class _CouponSheet extends StatelessWidget {
  const _CouponSheet();

  @override
  Widget build(BuildContext context) {
    final s = context.watch<PulseStore>();
    final c = s.coupon;
    if (!s.donationConfirmed) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(16, 24, 16, 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(FluentIcons.lock_closed_24_regular, color: BD.textSecondary, size: 32),
            gap12,
            Text('Your meal unlocks soon', style: T.bold(16)),
            gap8,
            Text(
              'Sneha confirms your donation with the blood bank, usually within a couple of hours. Your coupon appears here right after.',
              textAlign: TextAlign.center,
              style: T.regular(12, BD.textSecondary),
            ),
          ],
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
      child: AnimatedSwitcher(
        duration: BD.slow,
        child:
            c == null
                ? Column(
                  key: const ValueKey('gen'),
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Heartbeat(child: const Icon(FluentIcons.food_24_filled, color: BD.green, size: 36)),
                    gap12,
                    Text('Your iron-rich meal is on us', style: T.bold(16)),
                    gap8,
                    Text('A one-time coupon for ${s.mess}, valid for 48 hours.', style: T.regular(12, BD.textSecondary)),
                    gap24,
                    BdButton(label: 'Generate coupon', icon: FluentIcons.ticket_diagonal_20_regular, onTap: s.generateCoupon),
                  ],
                )
                : Column(
                  key: const ValueKey('ticket'),
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    EnterIn(
                      dy: 24,
                      child: Container(
                        decoration: BoxDecoration(
                          color: BD.page,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: BD.greenCta),
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: Column(
                          children: [
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(16),
                              color: BD.greenBadgeBg,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('HERO MEAL • ${c.mess.toUpperCase()}', style: T.medium(10, BD.green).copyWith(letterSpacing: 1)),
                                  gap4,
                                  Text(c.dish, style: T.bold(14)),
                                  gap4,
                                  Text('Valid for lunch or dinner till ${dayLabel(c.validUntil)}', style: T.regular(12, BD.text700)),
                                ],
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(16),
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(6),
                                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8)),
                                    child: Opacity(
                                      opacity: c.redeemed ? 0.3 : 1,
                                      child: QrImageView(data: c.code, size: 96, padding: EdgeInsets.zero),
                                    ),
                                  ),
                                  gap16,
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text('Show at the mess counter', style: T.regular(11, BD.textSecondary)),
                                        gap8,
                                        SelectableText(c.code, style: T.bold(16)),
                                        gap8,
                                        Text(
                                          c.redeemed ? 'Redeemed • tile ticked' : 'One-time use',
                                          style: T.medium(12, c.redeemed ? BD.green : BD.toggleOn),
                                        ),
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
                    gap16,
                    if (!c.redeemed)
                      BdButton(
                        label: 'Simulate mess scan (demo)',
                        outline: true,
                        icon: FluentIcons.qr_code_20_regular,
                        onTap: () {
                          Haptics.success();
                          s.redeemCoupon();
                          Future.delayed(const Duration(milliseconds: 800), () {
                            if (context.mounted) Navigator.of(context).pop();
                          });
                        },
                      ),
                  ],
                ),
      ),
    );
  }
}

class _NominateSheet extends StatefulWidget {
  const _NominateSheet();
  @override
  State<_NominateSheet> createState() => _NominateSheetState();
}

class _NominateSheetState extends State<_NominateSheet> {
  static const _people = [
    ('Kunal Verma', '220104033', 'KV'),
    ('Ananya Das', '220104051', 'AD'),
    ('Rishabh Jain', '220106019', 'RJ'),
    ('Pooja Nair', '220103008', 'PN'),
  ];
  final Set<int> _picked = {};

  @override
  Widget build(BuildContext context) {
    final s = context.watch<PulseStore>();
    if (s.friends.isNotEmpty) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Your nominations', style: T.bold(16)),
            gap8,
            Text('The tile ticks when both have set their blood group.', style: T.regular(12, BD.textSecondary)),
            gap16,
            for (final f in s.friends)
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Row(
                  children: [
                    InitialsDot(initials: f.name.split(' ').map((e) => e[0]).join()),
                    gap12,
                    Expanded(child: Text(f.name, style: T.medium(14, BD.text700))),
                    AnimatedSwitcher(
                      duration: BD.slow,
                      child: Text(
                        f.registered ? 'Joined' : 'Invite sent',
                        key: ValueKey(f.registered),
                        style: T.medium(12, f.registered ? BD.green : BD.textSecondary),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Nominate 2 friends', style: T.bold(16)),
          gap8,
          Text('They get a soft invite: "${s.firstName} thinks you\'d make a great Lifeline."', style: T.regular(12, BD.textSecondary)),
          gap16,
          for (var i = 0; i < _people.length; i++)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Pressable(
                onTap:
                    () => setState(() {
                      if (_picked.contains(i)) {
                        _picked.remove(i);
                      } else if (_picked.length < 2) {
                        _picked.add(i);
                      }
                    }),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: BD.page,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: _picked.contains(i) ? BD.greenCta : BD.border),
                  ),
                  child: Row(
                    children: [
                      InitialsDot(initials: _people[i].$3),
                      gap12,
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(_people[i].$1, style: T.medium(14, BD.text700)),
                            Text('Roll ${_people[i].$2}', style: T.regular(12, BD.text600)),
                          ],
                        ),
                      ),
                      Icon(
                        _picked.contains(i) ? FluentIcons.checkmark_circle_20_filled : FluentIcons.circle_20_regular,
                        color: _picked.contains(i) ? BD.green : BD.textSecondary,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          gap16,
          BdButton(
            label: _picked.length == 2 ? 'Send 2 invites' : 'Pick ${2 - _picked.length} more',
            onTap:
                _picked.length == 2
                    ? () {
                      final st = context.read<PulseStore>();
                      st.nominate([for (final i in _picked) Friend(_people[i].$2, _people[i].$1)]);
                      Haptics.success();
                      Future.delayed(const Duration(seconds: 4), st.adminFriendRegisters);
                      Future.delayed(const Duration(seconds: 8), st.adminFriendRegisters);
                    }
                    : null,
          ),
        ],
      ),
    );
  }
}

class _CheckinSheet extends StatefulWidget {
  const _CheckinSheet();
  @override
  State<_CheckinSheet> createState() => _CheckinSheetState();
}

class _CheckinSheetState extends State<_CheckinSheet> {
  int? _feel;
  bool? _weak;
  static const _faces = [
    (FluentIcons.emoji_sad_24_regular, 'Tired'),
    (FluentIcons.emoji_meh_24_regular, 'Okay'),
    (FluentIcons.emoji_smile_slight_24_regular, 'Good'),
    (FluentIcons.emoji_laugh_24_regular, 'Great'),
  ];

  @override
  Widget build(BuildContext context) {
    final s = context.read<PulseStore>();
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('Day-7 check-in', style: T.bold(16)),
              gap8,
              Text('(unlocked early for the demo)', style: T.regular(11, BD.textSecondary)),
            ],
          ),
          gap16,
          Text('How are you feeling this week?', style: T.medium(13)),
          gap12,
          Row(
            children: [
              for (var i = 0; i < 4; i++) ...[
                if (i > 0) gap8,
                Expanded(
                  child: Pressable(
                    onTap: () => setState(() => _feel = i),
                    child: AnimatedContainer(
                      duration: BD.fast,
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: _feel == i ? BD.greenBadgeBg : BD.page,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: _feel == i ? BD.greenCta : BD.border),
                      ),
                      child: Column(
                        children: [
                          Icon(_faces[i].$1, color: _feel == i ? BD.green : BD.textSecondary, size: 26),
                          gap4,
                          Text(_faces[i].$2, style: T.medium(11, BD.text700)),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
          gap16,
          Text('Any dizziness or weakness?', style: T.medium(13)),
          gap12,
          Row(
            children: [
              ChipPill(text: 'No', selected: _weak == false, onTap: () => setState(() => _weak = false)),
              gap8,
              ChipPill(text: 'Yes', selected: _weak == true, onTap: () => setState(() => _weak = true)),
            ],
          ),
          if (_weak == true) ...[
            gap12,
            Text('Please visit the Medical Section at the campus hospital. We have let Sneha know too.', style: T.regular(12, BD.toggleOn)),
          ],
          gap24,
          BdButton(
            label: 'Submit check-in',
            onTap:
                _feel != null && _weak != null
                    ? () {
                      s.tick('checkin');
                      Navigator.of(context).pop();
                    }
                    : null,
          ),
        ],
      ),
    );
  }
}
