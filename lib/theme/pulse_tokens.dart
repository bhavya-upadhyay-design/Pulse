import 'package:flutter/material.dart';
import 'package:onestop_ui/index.dart';

/// Pulse design tokens.
///
/// Everything not listed here comes straight from OneStop's design system
/// (`onestop_ui`): Geist type scale (OTextStyle), OColor neutrals and greens,
/// OSpacing and OCornerRadius. Pulse only adds a crimson "card language"
/// built on OneStop's existing red scale, used on blood-donation surfaces.
class PulseColors {
  PulseColors._();

  /// The ask. red500.
  static Color get crimson => OColor.red500;

  /// Gradient end, pressed, final-15-minutes strip. red700.
  static Color get deep => OColor.red700;

  /// Chips on white, Home tint wash. red100.
  static Color get blush => OColor.red100;

  /// Rewards, tickets, Hero badge. yellow400.
  static Color get gold => OColor.yellow400;
  static Color get goldSoft => OColor.yellow100;

  static const Color onCrimson = Colors.white;

  static const LinearGradient card = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFEF3354), Color(0xFFAF0D2A)],
  );

  static const LinearGradient success = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF1AB056), Color(0xFF085E2A)],
  );

  static List<BoxShadow> get floatShadow => [
    BoxShadow(color: const Color(0xFFDE1135).withValues(alpha: 0.24), blurRadius: 24, offset: const Offset(0, 8)),
  ];
}

/// Motion tokens (see spec: Motion and animation).
class PulseMotion {
  PulseMotion._();
  static const micro = Duration(milliseconds: 120);
  static const standard = Duration(milliseconds: 240);
  static const emphasis = Duration(milliseconds: 420);
  static const morph = Duration(milliseconds: 500);
  static const celebrate = Duration(milliseconds: 1600);
  static const heartbeat = Duration(milliseconds: 1100);
  static const breath = Duration(milliseconds: 3000);

  static const Curve standardCurve = Curves.easeInOutCubic;
  static const Curve springCurve = Curves.easeOutBack;
}

/// Shorthand text styles on top of OTextStyle (Geist).
class PText {
  PText._();
  static TextStyle h1(Color c) => OTextStyle.headingLarge.copyWith(color: c, height: 1.2);
  static TextStyle h2(Color c) => OTextStyle.headingMedium.copyWith(color: c, height: 1.25);
  static TextStyle h3(Color c) => OTextStyle.headingSmall.copyWith(color: c);
  static TextStyle label(Color c) => OTextStyle.labelSmall.copyWith(color: c);
  static TextStyle labelX(Color c) => OTextStyle.labelXSmall.copyWith(color: c);
  static TextStyle body(Color c) => OTextStyle.bodySmall.copyWith(color: c, height: 1.4);
  static TextStyle bodyX(Color c) => OTextStyle.bodyXSmall.copyWith(color: c, height: 1.35);
  static TextStyle counter(Color c) =>
      OTextStyle.displayXSmall.copyWith(color: c, fontFeatures: const [FontFeature.tabularFigures()]);
  static TextStyle mono(Color c, double size) => OTextStyle.labelMedium.copyWith(
    color: c,
    fontSize: size,
    fontWeight: FontWeight.w700,
    fontFeatures: const [FontFeature.tabularFigures()],
  );
}
