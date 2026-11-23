import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../state/models.dart';
import '../../state/pulse_store.dart';
import '../../theme/bd.dart';
import '../widgets/common.dart';
import '../widgets/motion.dart';
import 'actions.dart';
import 'bingo.dart';

void openDonatedCelebration(BuildContext context) {
  context.read<PulseStore>().reportDonated();
  Navigator.of(context).push(
    PageRouteBuilder(
      transitionDuration: const Duration(milliseconds: 420),
      pageBuilder: (_, _, _) => const DonatedPage(),
      transitionsBuilder: (_, a, _, c) => FadeTransition(opacity: a, child: c),
    ),
  );
}

void showMissedSheet(BuildContext context) {
  final s = context.read<PulseStore>();
  showBdSheet(
    context,
    builder:
        (_) => ReasonSheet(
          title: 'What happened, ${s.firstName}?',
          subtitle: 'No streak lost, nothing public. This just helps Sneha plan.',
          reasons: const [
            ReasonOption('Deferred at the blood bank (low Hb, BP)', FluentIcons.stethoscope_20_regular),
            ReasonOption('Not feeling well', FluentIcons.emoji_sad_20_regular),
            ReasonOption('Exams / busy', FluentIcons.book_20_regular),
            ReasonOption('Missed the pickup', FluentIcons.vehicle_car_20_regular),
            ReasonOption('Other', FluentIcons.more_horizontal_20_regular),
          ],
          doneTitle: 'Life happens',
          doneBody: "You're still on the Lifeline list.",
          onPick: (r, _) => s.reportMissed(r),
        ),
  );
}

/// Full-screen "you did it" moment, in the request widget's colours.
class DonatedPage extends StatefulWidget {
  const DonatedPage({super.key});
  @override
  State<DonatedPage> createState() => _DonatedPageState();
}

class _DonatedPageState extends State<DonatedPage> with TickerProviderStateMixin {
  late final AnimationController _type = AnimationController(vsync: this, duration: const Duration(milliseconds: 1300));
  late final AnimationController _badge = AnimationController(vsync: this, duration: const Duration(milliseconds: 900));

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      playBurst(context, confetti: true, origin: Offset(MediaQuery.sizeOf(context).width / 2, MediaQuery.sizeOf(context).height * 0.4));
      Haptics.success();
    });
    Future.delayed(const Duration(milliseconds: 200), () => mounted ? _badge.forward() : null);
    Future.delayed(const Duration(milliseconds: 700), () => mounted ? _type.forward() : null);
  }

  @override
  void dispose() {
    _type.dispose();
    _badge.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = context.watch<PulseStore>();
    final line = '${s.firstName}, you just gave ${s.request?.requester.split(' ').first ?? 'someone'}’s family a chance.';
    final bottom = MediaQuery.viewPaddingOf(context).bottom;
    return Scaffold(
      backgroundColor: BD.page,
      body: Container(
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment(0, -0.35),
            radius: 0.9,
            colors: [Color.fromRGBO(138, 57, 71, 1), Color.fromRGBO(50, 29, 33, 1), Color.fromRGBO(20, 20, 20, 1)],
            stops: [0, 0.55, 1],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              children: [
                Align(
                  alignment: Alignment.topRight,
                  child: IconButton(
                    tooltip: 'Close',
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(FluentIcons.dismiss_24_regular, color: Colors.white),
                  ),
                ),
                const Spacer(),
                AnimatedBuilder(
                  animation: _badge,
                  builder:
                      (_, child) => Transform.scale(
                        scale: 0.3 + 0.7 * Curves.elasticOut.transform(_badge.value),
                        child: Opacity(opacity: _badge.value.clamp(0.0, 1.0), child: child),
                      ),
                  child: Container(
                    width: 132,
                    height: 132,
                    decoration: BoxDecoration(
                      color: BD.heroPill,
                      shape: BoxShape.circle,
                      border: Border.all(color: const Color(0x33FFFFFF)),
                      boxShadow: [BoxShadow(color: BD.toggleOn.withValues(alpha: 0.35), blurRadius: 40)],
                    ),
                    alignment: Alignment.center,
                    child: Heartbeat(child: Image.asset('assets/blood/hero_badge.png', width: 56, height: 76)),
                  ),
                ),
                const SizedBox(height: 28),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                  decoration: BoxDecoration(color: BD.heroPill, borderRadius: BorderRadius.circular(108)),
                  child: Text('Hero #${s.heroesThisMonth + (s.donationConfirmed ? 0 : 1)} this month', style: T.bold(14)),
                ),
                gap16,
                AnimatedBuilder(
                  animation: _type,
                  builder:
                      (_, _) => Text(
                        line.substring(0, (line.length * _type.value).round()),
                        textAlign: TextAlign.center,
                        style: T.bold(24).copyWith(height: 1.3),
                      ),
                ),
                gap12,
                EnterIn(
                  delay: const Duration(milliseconds: 1600),
                  child: Text('One donation can help save up to 3 lives.', textAlign: TextAlign.center, style: T.regular(14, BD.text700)),
                ),
                const Spacer(),
                EnterIn(
                  delay: const Duration(milliseconds: 1900),
                  child: Column(
                    children: [
                      BdButton(
                        label: 'Start Recovery Bingo',
                        icon: FluentIcons.grid_20_filled,
                        onTap: () => Navigator.of(context).pushReplacement(BingoPage.route()),
                      ),
                      gap8,
                      BdButton(
                        label: 'Share my Hero card',
                        outline: true,
                        color: Colors.white,
                        icon: FluentIcons.share_20_regular,
                        onTap: () => showHeroShare(context),
                      ),
                      gap12,
                      Text("9 small recovery missions. Let's start with water.", style: T.regular(12, BD.textSecondary)),
                      SizedBox(height: 12 + bottom),
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

/// Story-sized share card; no patient details.
void showHeroShare(BuildContext context, {VoidCallback? onShared}) {
  final s = context.read<PulseStore>();
  showBdSheet(
    context,
    builder:
        (ctx) => Padding(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Your Hero card', style: T.bold(16)),
              gap16,
              AspectRatio(
                aspectRatio: 9 / 12,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: BD.requestGradient,
                    color: BD.page,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: BD.border),
                  ),
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text('One', style: T.bold(20, const Color(0xFFCDCDD1))),
                          Text('.', style: T.bold(20, BD.green)),
                          const Spacer(),
                          Image.asset('assets/blood/hero_badge.png', width: 25, height: 34),
                        ],
                      ),
                      const Spacer(),
                      const DropMedallion(),
                      gap16,
                      Text('${s.firstName} is a\nLifeline Hero', style: T.bold(28).copyWith(height: 1.15)),
                      gap8,
                      Text('${s.bloodGroup ?? 'O+'} • ${dayLabel(DateTime.now())} • ${s.hostel} Hostel', style: T.regular(12, BD.text700)),
                      gap16,
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(color: BD.card, borderRadius: BorderRadius.circular(16)),
                        child: Text('Be the next one. OneStop → Quick Access → Blood donation.', style: T.regular(12, BD.textSecondary)),
                      ),
                    ],
                  ),
                ),
              ),
              gap16,
              BdButton(
                label: 'Share to story',
                icon: FluentIcons.share_20_regular,
                onTap: () {
                  Navigator.of(ctx).pop();
                  onShared?.call();
                  ScaffoldMessenger.maybeOf(context)?.showSnackBar(bdSnack('Shared! (prototype)'));
                },
              ),
            ],
          ),
        ),
  );
}
