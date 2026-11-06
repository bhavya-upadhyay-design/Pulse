import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';
import 'package:onestop_ui/index.dart';
import 'package:provider/provider.dart';

import '../bingo/bingo_page.dart';
import '../request/decline_sheet.dart';
import '../state/pulse_store.dart';
import '../theme/pulse_tokens.dart';
import '../widgets/motion.dart';
import '../widgets/particles.dart';
import '../widgets/shapes.dart';

void openDonatedCelebration(BuildContext context) {
  context.read<PulseStore>().reportDonated();
  Navigator.of(context).push(
    PageRouteBuilder(
      transitionDuration: PulseMotion.morph,
      pageBuilder: (_, _, _) => const DonatedCelebrationPage(),
      transitionsBuilder: (_, a, _, c) => FadeTransition(opacity: a, child: c),
    ),
  );
}

void showMissedSheet(BuildContext context) {
  final s = context.read<PulseStore>();
  showPulseSheet(
    context,
    builder:
        (_) => ReasonSheet(
          title: "What happened, ${s.firstName}?",
          subtitle: 'No streak lost, nothing public. This just helps Sneha plan.',
          reasons: const [
            ReasonOption('Deferred at the blood bank (low Hb, BP etc.)', FluentIcons.stethoscope_24_regular),
            ReasonOption('Not feeling well', FluentIcons.emoji_sad_24_regular),
            ReasonOption('Exams / busy', FluentIcons.book_24_regular),
            ReasonOption('Missed the pickup', FluentIcons.vehicle_car_24_regular),
            ReasonOption('Other', FluentIcons.more_horizontal_24_regular),
          ],
          confirmTitle: 'Life happens',
          confirmBody: "You're still on the Lifeline list.",
          onPick: (r, _) => Future.delayed(const Duration(milliseconds: 1500), () => s.reportMissed(r)),
        ),
  );
}

/// Full-screen "you did it" moment. The only place full-screen confetti-like
/// motion is used outside Bingo's full house.
class DonatedCelebrationPage extends StatefulWidget {
  const DonatedCelebrationPage({super.key});

  @override
  State<DonatedCelebrationPage> createState() => _DonatedCelebrationPageState();
}

class _DonatedCelebrationPageState extends State<DonatedCelebrationPage> with TickerProviderStateMixin {
  late final AnimationController _type = AnimationController(vsync: this, duration: const Duration(milliseconds: 1400));
  late final AnimationController _badge = AnimationController(vsync: this, duration: const Duration(milliseconds: 900));

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      playBurst(context, BurstKind.dropsToHearts);
      Haptics.success();
    });
    Future.delayed(const Duration(milliseconds: 700), () => mounted ? _type.forward() : null);
    Future.delayed(const Duration(milliseconds: 1500), () {
      if (!mounted) return;
      _badge.forward();
      Haptics.medium();
    });
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
    final patient = s.request?.patientName ?? 'someone';
    final line = '${s.firstName}, you just gave $patient a chance.';
    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [OColor.white, PulseColors.blush],
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
                    onPressed: () => Navigator.of(context).pop(),
                    icon: Icon(FluentIcons.dismiss_24_regular, color: OColor.gray600),
                  ),
                ),
                const Spacer(),
                // Badge lands with a spring.
                AnimatedBuilder(
                  animation: _badge,
                  builder: (_, child) {
                    final v = Curves.elasticOut.transform(_badge.value);
                    return Transform.scale(
                      scale: 0.2 + 0.8 * v,
                      child: Opacity(opacity: _badge.value.clamp(0, 1), child: child),
                    );
                  },
                  child: _HeroBadge(group: s.bloodGroup ?? 'B+'),
                ),
                const SizedBox(height: 28),
                AnimatedBuilder(
                  animation: _type,
                  builder: (_, _) {
                    final n = (line.length * _type.value).round();
                    return Text(
                      line.substring(0, n),
                      textAlign: TextAlign.center,
                      style: PText.h1(OColor.gray800).copyWith(fontSize: 26, fontWeight: FontWeight.w700),
                    );
                  },
                ),
                const SizedBox(height: 10),
                EnterIn(
                  delay: const Duration(milliseconds: 1900),
                  child: Text(
                    'Hero #${s.heroNumber} this month. Up to 3 lives touched.',
                    style: PText.body(OColor.gray600),
                    textAlign: TextAlign.center,
                  ),
                ),
                const Spacer(),
                EnterIn(
                  delay: const Duration(milliseconds: 2200),
                  child: Column(
                    children: [
                      SizedBox(
                        width: double.infinity,
                        child: PrimaryButton(
                          label: 'Start Recovery Bingo',
                          tarilingIcon: FluentIcons.arrow_right_24_regular,
                          onPressed: () => Navigator.of(context).pushReplacement(BingoPage.route()),
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextButton.icon(
                        onPressed: () => showHeroShareSheet(context),
                        icon: Icon(FluentIcons.share_24_regular, color: OColor.green600, size: 18),
                        label: Text(
                          'Share my Hero card',
                          style: OTextStyle.labelMedium.copyWith(color: OColor.green600),
                        ),
                      ),
                      Text(
                        'Your recovery has 9 small missions. Let\'s start with water.',
                        style: PText.bodyX(OColor.gray500),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
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

class _HeroBadge extends StatelessWidget {
  final String group;
  const _HeroBadge({required this.group});

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        Breath(
          builder:
              (_, b) => Container(
                width: 170 + 16 * b,
                height: 170 + 16 * b,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: PulseColors.crimson.withValues(alpha: 0.08 + 0.05 * b),
                ),
              ),
        ),
        Container(
          width: 140,
          height: 140,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: PulseColors.card,
            border: Border.all(color: PulseColors.gold, width: 5),
            boxShadow: PulseColors.floatShadow,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(FluentIcons.heart_24_filled, color: Colors.white, size: 44),
              Text(
                'HERO',
                style: OTextStyle.labelSmall.copyWith(
                  color: Colors.white,
                  letterSpacing: 3,
                  fontWeight: FontWeight.w800,
                ),
              ),
              Text(group, style: OTextStyle.labelXSmall.copyWith(color: Colors.white70)),
            ],
          ),
        ),
      ],
    );
  }
}

/// Instagram-story-sized share card. No patient details.
void showHeroShareSheet(BuildContext context, {VoidCallback? onShared}) {
  final s = context.read<PulseStore>();
  showPulseSheet(
    context,
    builder:
        (ctx) => Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Your Hero card', style: PText.h2(OColor.gray800)),
              const SizedBox(height: 12),
              AspectRatio(
                aspectRatio: 9 / 13,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: PulseColors.card,
                    borderRadius: BorderRadius.circular(OCornerRadius.l),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Stack(
                    children: [
                      Positioned(
                        left: 0,
                        right: 0,
                        top: 120,
                        child: Opacity(opacity: 0.15, child: EcgLine(color: Colors.white, height: 80)),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  'One',
                                  style: OTextStyle.headingMedium.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                Text('.', style: OTextStyle.headingMedium.copyWith(color: PulseColors.gold)),
                                const Spacer(),
                                PChip(text: 'PULSE', bg: Colors.white24, fg: Colors.white),
                              ],
                            ),
                            const Spacer(),
                            const Icon(FluentIcons.heart_24_filled, color: Colors.white, size: 40),
                            const SizedBox(height: 8),
                            Text(
                              '${s.firstName} is a\nLifeline Hero',
                              style: PText.h1(Colors.white).copyWith(fontSize: 30, fontWeight: FontWeight.w800),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '${s.bloodGroup ?? 'B+'} • ${dayLabel(DateTime.now())} • ${s.hostel} Hostel',
                              style: PText.body(Colors.white70),
                            ),
                            const SizedBox(height: 16),
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(OCornerRadius.m),
                              ),
                              child: Text(
                                'Be the next one. Set your blood group in OneStop → Blood Donation.',
                                style: PText.bodyX(Colors.white),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: PrimaryButton(
                  label: 'Share to story',
                  leadingIcon: FluentIcons.share_24_regular,
                  onPressed: () {
                    Navigator.of(ctx).pop();
                    onShared?.call();
                    ScaffoldMessenger.maybeOf(context)?.showSnackBar(
                      const SnackBar(content: Text('Shared! (prototype)'), behavior: SnackBarBehavior.floating),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
  );
}
