import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../state/models.dart';
import '../../theme/bd.dart';
import 'motion.dart';

/// Figma asset helper. Every file in assets/blood/ was downloaded from the
/// Figma section; nothing is redrawn.
Widget bdSvg(String name, {double? width, double? height, Color? tint}) => SvgPicture.asset(
  'assets/blood/$name.svg',
  width: width,
  height: height,
  colorFilter: tint == null ? null : ColorFilter.mode(tint, BlendMode.srcIn),
);

/// #262626 card, 16 radius (Frame 329 / Frame 346 …).
class BdCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets padding;
  final Color color;
  final double radius;
  final Border? border;
  const BdCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(12),
    this.color = BD.card,
    this.radius = 16,
    this.border,
  });

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: padding,
    decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(radius), border: border),
    child: child,
  );
}

/// Green date badge: 42 × 49, rgba(44,180,98,.2), 18 / 11 Medium #2cb462.
class DateBadge extends StatelessWidget {
  final DateTime date;
  final Color color;
  final Color bg;
  const DateBadge({super.key, required this.date, this.color = BD.green, this.bg = BD.greenBadgeBg});

  @override
  Widget build(BuildContext context) => Container(
    width: 42,
    height: 49,
    padding: const EdgeInsets.all(4),
    decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(6)),
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        SizedBox(height: 19, child: Text(date.day.toString().padLeft(2, '0'), style: T.medium(18, color).copyWith(height: 1))),
        const SizedBox(height: 2),
        Text(monthShort(date), style: T.medium(11, color)),
      ],
    ),
  );
}

/// Title + two 10 px lines next to a date badge (camp and donation rows).
class EventInfo extends StatelessWidget {
  final String title;
  final String line1;
  final String line2;
  final Color sub;
  const EventInfo({super.key, required this.title, required this.line1, required this.line2, this.sub = BD.textSecondary});

  @override
  Widget build(BuildContext context) => SizedBox(
    height: 49,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: T.bold(14), maxLines: 1, overflow: TextOverflow.ellipsis),
        Text(line1, style: T.regular(10, sub), maxLines: 1, overflow: TextOverflow.ellipsis),
        Text(line2, style: T.regular(10, sub), maxLines: 1, overflow: TextOverflow.ellipsis),
      ],
    ),
  );
}

/// "I'll go" pill: 68 × 26, 1 px #148440 outline, 12 Medium #148440.
/// Joined state fills green.
class GoPill extends StatelessWidget {
  final bool joined;
  final VoidCallback onTap;
  const GoPill({super.key, required this.joined, required this.onTap});

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    label: joined ? "You're going" : "I'll go",
    child: Pressable(
      onTap: onTap,
      child: AnimatedContainer(
        duration: BD.medium,
        curve: Curves.easeOutBack,
        width: joined ? 78 : 68,
        height: 26,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: joined ? BD.greenCta : Colors.transparent,
          border: Border.all(color: BD.greenCta),
          borderRadius: BorderRadius.circular(71),
        ),
        child: AnimatedSwitcher(
          duration: BD.fast,
          child:
              joined
                  ? Row(
                    key: const ValueKey('y'),
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(FluentIcons.checkmark_12_filled, size: 12, color: Colors.white),
                      const SizedBox(width: 4),
                      Text('Going', style: T.medium(12)),
                    ],
                  )
                  : Text("I'll go", key: const ValueKey('n'), style: T.medium(12, BD.greenCta)),
        ),
      ),
    ),
  );
}

/// Camp row (Frame 346): #262626, radius 16, padding 12.
class CampRow extends StatelessWidget {
  final Camp camp;
  final bool joined;
  final VoidCallback onToggle;
  final VoidCallback? onTap;
  const CampRow({super.key, required this.camp, required this.joined, required this.onToggle, this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: BdCard(
      child: Row(
        children: [
          DateBadge(date: camp.date),
          gap12,
          Expanded(child: EventInfo(title: camp.name, line1: camp.place, line2: camp.hours)),
          GoPill(joined: joined, onTap: onToggle),
        ],
      ),
    ),
  );
}

/// Toggle (_Toggle base): 36 × 20, on #fd445f, 16 px white knob.
class BdToggle extends StatelessWidget {
  final bool value;
  final ValueChanged<bool> onChanged;
  final String label;
  const BdToggle({super.key, required this.value, required this.onChanged, required this.label});

  @override
  Widget build(BuildContext context) => Semantics(
    toggled: value,
    label: label,
    child: GestureDetector(
      onTap: () {
        Haptics.light();
        onChanged(!value);
      },
      child: AnimatedContainer(
        duration: BD.fast,
        width: 36,
        height: 20,
        padding: const EdgeInsets.all(2),
        decoration: BoxDecoration(color: value ? BD.toggleOn : const Color(0xFF414141), borderRadius: BorderRadius.circular(9999)),
        child: AnimatedAlign(
          duration: BD.fast,
          curve: Curves.easeOut,
          alignment: value ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(width: 16, height: 16, decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle)),
        ),
      ),
    ),
  );
}

/// Round "drop" medallion used at the top of the request widget:
/// 52 px, 1 px rgba(255,255,255,.2) border, drop_flame icon.
class DropMedallion extends StatelessWidget {
  final double size;
  const DropMedallion({super.key, this.size = 52});

  @override
  Widget build(BuildContext context) => Container(
    width: size,
    height: size,
    alignment: Alignment.center,
    decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: const Color(0x33FFFFFF))),
    child: bdSvg('drop_flame', width: 21.875 * size / 52, height: 25.94 * size / 52),
  );
}

/// Units progress: three 2 px bars, 6 px gap. Grey until a unit is covered.
class UnitsBar extends StatelessWidget {
  final int units;
  final int confirmed;
  const UnitsBar({super.key, required this.units, required this.confirmed});

  @override
  Widget build(BuildContext context) => Row(
    children: [
      for (var i = 0; i < units; i++) ...[
        if (i > 0) const SizedBox(width: 6),
        Expanded(
          child: Container(
            height: 2,
            color: BD.unitBar,
            alignment: Alignment.centerLeft,
            child: AnimatedFractionallySizedBox(
              duration: BD.slow,
              curve: Curves.easeOutCubic,
              widthFactor: i < confirmed ? 1 : 0,
              child: Container(color: BD.green),
            ),
          ),
        ),
      ],
    ],
  );
}

/// Bottom sheet in the blood-donation style: #262626, 24 radius top, handle.
Future<T?> showBdSheet<T>(BuildContext context, {required WidgetBuilder builder}) {
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black.withValues(alpha: 0.6),
    builder:
        (ctx) => Container(
          decoration: const BoxDecoration(
            color: BD.card,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            border: Border(top: BorderSide(color: BD.border)),
          ),
          padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(ctx).bottom),
          child: SafeArea(
            top: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 8),
                Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(color: const Color(0xFF414141), borderRadius: BorderRadius.circular(2)),
                  ),
                ),
                Flexible(child: builder(ctx)),
              ],
            ),
          ),
        ),
  );
}

/// Full-width green pill CTA (filled) / outline variant, Figma green #148440.
class BdButton extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;
  final bool outline;
  final IconData? icon;
  final Color color;
  const BdButton({super.key, required this.label, required this.onTap, this.outline = false, this.icon, this.color = BD.greenCta});

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    final fg = outline ? color : Colors.white;
    return Opacity(
      opacity: enabled ? 1 : 0.4,
      child: Pressable(
        onTap: onTap,
        child: Container(
          height: 44,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: outline ? Colors.transparent : color,
            border: Border.all(color: color),
            borderRadius: BorderRadius.circular(71),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[Icon(icon, size: 18, color: fg), const SizedBox(width: 8)],
              Text(label, style: T.medium(14, fg)),
            ],
          ),
        ),
      ),
    );
  }
}

/// Section title: 18 Medium white ("Your Donations", "Upcoming donation camps").
class SectionTitle extends StatelessWidget {
  final String text;
  const SectionTitle(this.text, {super.key});
  @override
  Widget build(BuildContext context) => Text(text, style: T.medium(18));
}

/// Initials avatar from the "All donors" feed (32 px, #22262f, 0.5 px border).
class InitialsDot extends StatelessWidget {
  final String initials;
  final double size;
  final bool highlight;
  const InitialsDot({super.key, required this.initials, this.size = 32, this.highlight = false});

  @override
  Widget build(BuildContext context) => Container(
    width: size,
    height: size,
    alignment: Alignment.center,
    decoration: BoxDecoration(
      color: highlight ? BD.heroPill : BD.avatarBg,
      shape: BoxShape.circle,
      border: Border.all(color: BD.avatarBorder, width: 0.5),
    ),
    child: Text(
      initials,
      style: TextStyle(
        fontFamily: T.bold(14).fontFamily,
        fontSize: size * 0.4375,
        fontWeight: FontWeight.w600,
        color: highlight ? Colors.white : BD.text600,
      ),
    ),
  );
}
