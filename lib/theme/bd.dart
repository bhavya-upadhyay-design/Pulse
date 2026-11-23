import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:onestop_ui/index.dart';

/// Blood-donation design tokens, copied from the Figma section "Screens"
/// (file "Others", node 1810:3556). OneStop surfaces keep using OColor /
/// OTextStyle from `onestop_ui`; these tokens are only for blood-donation UI.
///
/// Font: the Figma uses Uber Move / Uber Move Text, a proprietary face that
/// can't be bundled. We use OneStop's Geist at the same sizes and weights.
class BD {
  BD._();

  // Surfaces
  static const page = Color(0xFF1C1C1C); // Rectangle 112
  static const bar = Color(0xFF262626); // header behind "Blood Donation"
  static const card = Color(0xFF262626);
  static const border = Color(0xFF2F2F2F);
  static const inner = Color(0xFF393939); // skeleton bars in Learn cards

  // Text
  static const white = Colors.white;
  static const textSecondary = Color(0xFFA0A0A0); // #a0a0a0
  static const text700 = Color(0xFFCECFD2); // colors/text/text-secondary-(700)
  static const text600 = Color(0xFF94979C); // colors/text/text-tertiary-(600)
  static const bannerSub = Color(0xFFE0E0E0);
  static const navInactive = Color(0xFFD7D7D9);
  static const quickLabel = Color(0xFFB8B8B8);

  // Accents
  static const toggleOn = Color(0xFFFD445F);
  static const green = Color(0xFF2CB462); // date badge
  static const greenNav = Color(0xFF2DB062);
  static const greenCta = Color(0xFF148440); // "I'll go" outline
  static const greenBadgeBg = Color(0x332CB462); // rgba(44,180,98,0.2)
  static const navActiveBg = Color(0xFF2C4035);
  static const unitBar = Color(0xFF8C8C8C);
  static const crimsonBorder = Color(0xFFAA4657);
  static const heroPill = Color(0xFF8A3E4B);
  static const avatarBg = Color(0xFF22262F);
  static const avatarBorder = Color(0x1FFFFFFF);

  // Slide to say yes
  static const sliderTrack = Color(0x59FFFFFF); // rgba(255,255,255,0.35)
  static const sliderHalo = Color(0x80FFFFFF); // rgba(255,255,255,0.5)

  /// "New request widget" fill: a radial gradient from the top centre,
  /// 138,57,71 → 20,20,20, elliptical (≈221 × 279 px on a 346 × 411 card).
  static const requestGradient = RadialGradient(
    center: Alignment.topCenter,
    radius: 0.806,
    transform: EllipseTransform(0.79),
    colors: [
      Color.fromRGBO(138, 57, 71, 1),
      Color.fromRGBO(109, 48, 58, 1),
      Color.fromRGBO(79, 39, 46, 1),
      Color.fromRGBO(50, 29, 33, 1),
      Color.fromRGBO(20, 20, 20, 1),
    ],
    stops: [0, 0.25, 0.5, 0.75, 1],
  );

  // Motion
  static const fast = Duration(milliseconds: 160);
  static const medium = Duration(milliseconds: 260);
  static const slow = Duration(milliseconds: 420);
}

/// Squeezes a radial gradient horizontally about the top centre so it
/// becomes the ellipse the Figma gradient uses.
class EllipseTransform extends GradientTransform {
  final double sx;
  const EllipseTransform(this.sx);

  @override
  Matrix4? transform(Rect bounds, {TextDirection? textDirection}) {
    final cx = bounds.center.dx;
    final cy = bounds.top;
    return Matrix4.identity()
      ..translateByDouble(cx, cy, 0, 1)
      ..scaleByDouble(sx, 1, 1, 1)
      ..translateByDouble(-cx, -cy, 0, 1);
  }
}

/// Text styles. Uber Move Bold → w700, Medium → w500, Text Regular → w400.
class T {
  T._();
  static TextStyle _g(double size, FontWeight w, Color c, {double? height}) =>
      TextStyle(fontFamily: OTextStyle.fontFamily, fontSize: size, fontWeight: w, color: c, height: height);

  static TextStyle bold(double size, [Color c = BD.white]) => _g(size, FontWeight.w700, c);
  static TextStyle medium(double size, [Color c = BD.white]) => _g(size, FontWeight.w500, c);
  static TextStyle regular(double size, [Color c = BD.white, double? height]) => _g(size, FontWeight.w400, c, height: height);
}

/// 4 px grid helpers used by the Figma layouts.
const gap4 = SizedBox(width: 4, height: 4);
const gap8 = SizedBox(width: 8, height: 8);
const gap12 = SizedBox(width: 12, height: 12);
const gap16 = SizedBox(width: 16, height: 16);
const gap24 = SizedBox(width: 24, height: 24);

double degToRad(double d) => d * math.pi / 180;
