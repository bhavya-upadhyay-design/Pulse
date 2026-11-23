import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';

import '../../theme/bd.dart';
import '../blood_shell.dart';
import '../widgets/common.dart';
import '../widgets/motion.dart';

class LearnTopic {
  final String title;
  final String card; // card image rendered from the Figma
  final List<(IconData, String, String)> points; // icon, headline, body
  const LearnTopic(this.title, this.card, this.points);
}

/// "Learn in 30 secs" cards. Card art comes from the Figma section.
const learnTopics = [
  LearnTopic('Myths vs facts on blood donation', 'assets/blood/learn_myths.png', [
    (FluentIcons.warning_20_regular, 'Myth: it reduces immunity', 'Your immune system is not affected. White cells recover within days.'),
    (FluentIcons.shield_checkmark_20_regular, 'Fact: it can be good for your heart', 'Regular donors tend to have healthier iron levels.'),
    (
      FluentIcons.warning_20_regular,
      'Myth: it makes you weak for weeks',
      'Most people feel normal within hours. Plasma is replaced within a day.',
    ),
    (
      FluentIcons.shield_checkmark_20_regular,
      'Fact: it takes about 10 minutes',
      'The whole visit, with check-up and rest, is about an hour.',
    ),
  ]),
  LearnTopic('Who can donate blood?', 'assets/blood/learn_who.png', [
    (FluentIcons.person_20_regular, '18 to 65 years old', 'Healthy on the day of donation.'),
    (FluentIcons.scales_20_regular, 'At least 45 kg', 'Haemoglobin of 12.5 g/dL or more; checked on the spot.'),
    (FluentIcons.calendar_20_regular, 'About 3 months since your last donation', '90 days for men and 120 for women is the usual gap.'),
    (
      FluentIcons.dismiss_circle_20_regular,
      'Wait if you',
      'are on antibiotics, had a tattoo or piercing in the last 6 months, or feel unwell.',
    ),
  ]),
  LearnTopic('Benefits of blood donation', 'assets/blood/learn_benefits.png', [
    (FluentIcons.stethoscope_20_regular, 'A free mini health check', 'Hb, blood pressure, pulse and weight every time.'),
    (FluentIcons.heart_pulse_20_regular, 'Helps up to 3 people', 'One unit is split into red cells, plasma and platelets.'),
    (FluentIcons.ribbon_star_20_regular, 'Hero badge and NSS certificate', 'Plus an iron-rich meal from your mess.'),
  ]),
  LearnTopic('Do’s and don’ts post donation', 'assets/blood/learn_dos.png', [
    (FluentIcons.drink_bottle_20_regular, 'Drink 2 L of water today', 'Start with 500 ml in the first hour.'),
    (FluentIcons.food_apple_20_regular, 'Eat iron-rich food', 'Spinach, rajma, jaggery, dates and peanuts.'),
    (FluentIcons.sport_20_regular, 'Skip heavy exercise for 24 h', 'No gym or long climbs today.'),
    (FluentIcons.heart_20_regular, 'Keep the bandage on for 4–5 h', 'If it bleeds, press and raise your arm.'),
  ]),
  LearnTopic('All blood types explained', 'assets/blood/learn_types.png', [
    (FluentIcons.drop_20_regular, 'O− gives to everyone', 'The universal red-cell donor. Always in demand.'),
    (FluentIcons.drop_20_regular, 'AB+ receives from everyone', 'And AB plasma can be given to anyone.'),
    (FluentIcons.drop_20_regular, 'Rh − is rarer', 'Only a small share of people in India are Rh negative.'),
  ]),
];

void openLearn(BuildContext context, LearnTopic t) {
  Navigator.of(context).push(
    PageRouteBuilder(
      transitionDuration: const Duration(milliseconds: 360),
      pageBuilder: (_, _, _) => _LearnPage(topic: t),
      transitionsBuilder:
          (_, a, _, c) => FadeTransition(
            opacity: a,
            child: ScaleTransition(
              scale: Tween(begin: 0.96, end: 1.0).animate(CurvedAnimation(parent: a, curve: Curves.easeOutCubic)),
              child: c,
            ),
          ),
    ),
  );
}

class _LearnPage extends StatelessWidget {
  final LearnTopic topic;
  const _LearnPage({required this.topic});

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.viewPaddingOf(context).bottom;
    return Scaffold(
      backgroundColor: BD.page,
      body: Column(
        children: [
          const BdAppBar(title: 'Learn in 30 secs'),
          Expanded(
            child: ListView(
              padding: EdgeInsets.fromLTRB(12, 16, 12, 24 + bottom),
              children: [
                Center(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: Image.asset(topic.card, width: 240, height: 212, fit: BoxFit.cover),
                  ),
                ),
                gap24,
                for (var i = 0; i < topic.points.length; i++)
                  EnterIn(
                    delay: Duration(milliseconds: 120 + 80 * i),
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: BdCard(
                        padding: const EdgeInsets.all(14),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(color: BD.greenBadgeBg, borderRadius: BorderRadius.circular(6)),
                              child: Icon(
                                topic.points[i].$1,
                                color: topic.points[i].$1 == FluentIcons.warning_20_regular ? BD.toggleOn : BD.green,
                                size: 18,
                              ),
                            ),
                            gap12,
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(topic.points[i].$2, style: T.bold(14)),
                                  gap4,
                                  Text(topic.points[i].$3, style: T.regular(12, BD.textSecondary, 1.4)),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                gap8,
                Text(
                  'General guidance. The blood bank confirms eligibility on the day.',
                  textAlign: TextAlign.center,
                  style: T.regular(11, BD.text600),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
