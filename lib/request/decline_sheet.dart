import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';
import 'package:onestop_ui/index.dart';
import 'package:provider/provider.dart';

import '../state/pulse_store.dart';
import '../theme/pulse_tokens.dart';
import '../widgets/motion.dart';

/// OneStop-style bottom sheet frame: white, 16 radius, grab handle.
Future<T?> showPulseSheet<T>(BuildContext context, {required WidgetBuilder builder}) {
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black.withValues(alpha: 0.45),
    builder:
        (ctx) => Container(
          decoration: BoxDecoration(
            color: OColor.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(OCornerRadius.l)),
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
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(color: OColor.gray300, borderRadius: BorderRadius.circular(2)),
                  ),
                ),
                Flexible(child: builder(ctx)),
              ],
            ),
          ),
        ),
  );
}

class ReasonOption {
  final String label;
  final IconData icon;
  const ReasonOption(this.label, this.icon);
}

const declineReasons = [
  ReasonOption('Not feeling well', FluentIcons.emoji_sad_24_regular),
  ReasonOption('Exams / busy', FluentIcons.book_24_regular),
  ReasonOption('Donated recently', FluentIcons.drop_24_regular),
  ReasonOption('Travelling', FluentIcons.airplane_24_regular),
  ReasonOption('Other', FluentIcons.more_horizontal_24_regular),
];

/// Reason picker. One tap per reason. Returns the reason, or null.
class ReasonSheet extends StatefulWidget {
  final String title;
  final String subtitle;
  final List<ReasonOption> reasons;
  final String confirmTitle;
  final String confirmBody;
  final void Function(String reason, DateTime? donatedOn) onPick;
  const ReasonSheet({
    super.key,
    required this.title,
    required this.subtitle,
    required this.reasons,
    required this.confirmTitle,
    required this.confirmBody,
    required this.onPick,
  });

  @override
  State<ReasonSheet> createState() => _ReasonSheetState();
}

class _ReasonSheetState extends State<ReasonSheet> {
  String? _picked;
  bool _askDate = false;
  DateTime _month = DateTime(DateTime.now().year, DateTime.now().month);
  bool _done = false;

  void _finish(String reason, DateTime? date) {
    widget.onPick(reason, date);
    setState(() => _done = true);
    Haptics.light();
    Future.delayed(const Duration(milliseconds: 1600), () {
      if (mounted) Navigator.of(context).pop(reason);
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedSize(
      duration: PulseMotion.standard,
      curve: PulseMotion.standardCurve,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
        child: AnimatedSwitcher(
          duration: PulseMotion.standard,
          child: _done ? _confirm() : (_askDate ? _datePick() : _list()),
        ),
      ),
    );
  }

  Widget _confirm() {
    return Column(
      key: const ValueKey('done'),
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(height: 8),
        EnterIn(
          child: Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(color: OColor.green100, shape: BoxShape.circle),
            child: Icon(FluentIcons.heart_24_filled, color: OColor.green600, size: 28),
          ),
        ),
        const SizedBox(height: 12),
        Text(widget.confirmTitle, style: PText.h3(OColor.gray800), textAlign: TextAlign.center),
        const SizedBox(height: 6),
        Text(widget.confirmBody, style: PText.body(OColor.gray600), textAlign: TextAlign.center),
        const SizedBox(height: 12),
      ],
    );
  }

  Widget _list() {
    return Column(
      key: const ValueKey('list'),
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(widget.title, style: PText.h2(OColor.gray800)),
        const SizedBox(height: 4),
        Text(widget.subtitle, style: PText.body(OColor.gray600)),
        const SizedBox(height: 16),
        for (final r in widget.reasons)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Pressable(
              onTap: () {
                setState(() => _picked = r.label);
                if (r.label == 'Donated recently') {
                  setState(() => _askDate = true);
                } else {
                  _finish(r.label, null);
                }
              },
              child: AnimatedContainer(
                duration: PulseMotion.micro,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                decoration: BoxDecoration(
                  color: _picked == r.label ? OColor.gray100 : OColor.white,
                  borderRadius: BorderRadius.circular(OCornerRadius.m),
                  border: Border.all(color: OColor.gray200),
                ),
                child: Row(
                  children: [
                    Icon(r.icon, color: OColor.gray600, size: 22),
                    const SizedBox(width: 12),
                    Expanded(child: Text(r.label, style: OTextStyle.labelMedium.copyWith(color: OColor.gray800))),
                    Icon(FluentIcons.chevron_right_20_regular, color: OColor.gray400, size: 18),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _datePick() {
    final now = DateTime.now();
    final months = List.generate(6, (i) => DateTime(now.year, now.month - i));
    return Column(
      key: const ValueKey('date'),
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('When did you last donate?', style: PText.h2(OColor.gray800)),
        const SizedBox(height: 4),
        Text("We'll update your eligibility so we don't ask too early.", style: PText.body(OColor.gray600)),
        const SizedBox(height: 16),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final m in months)
              ChoiceChip(
                label: Text(monthYear(m)),
                selected: _month == m,
                onSelected: (_) => setState(() => _month = m),
                selectedColor: OColor.green100,
                labelStyle: OTextStyle.labelSmall.copyWith(color: _month == m ? OColor.green600 : OColor.gray800),
                side: BorderSide(color: _month == m ? OColor.green600 : OColor.gray200),
                showCheckmark: false,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(OCornerRadius.xl)),
              ),
          ],
        ),
        const SizedBox(height: 20),
        SizedBox(
          width: double.infinity,
          child: PrimaryButton(label: 'Update & decline', onPressed: () => _finish('Donated recently', _month)),
        ),
      ],
    );
  }
}

void showDeclineSheet(BuildContext context) {
  final store = context.read<PulseStore>();
  showPulseSheet(
    context,
    builder:
        (_) => ReasonSheet(
          title: 'No worries, ${store.firstName}',
          subtitle: "Tell us why in one tap. We'll pass this to the next donor right away.",
          reasons: declineReasons,
          confirmTitle: 'Thanks for telling us quickly',
          confirmBody: "We've passed this to the next donor.",
          onPick: (r, d) => store.decline(r, donatedOn: d),
        ),
  );
}

/// Call / WhatsApp sheet for the POC or NSS coordinator.
void showContactSheet(
  BuildContext context, {
  required String name,
  required String role,
  required String phone,
  required String initials,
  required Color tint,
  String? line,
}) {
  showPulseSheet(
    context,
    builder:
        (ctx) => Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(shape: BoxShape.circle, color: tint.withValues(alpha: 0.16)),
                    alignment: Alignment.center,
                    child: Text(
                      initials,
                      style: OTextStyle.labelLarge.copyWith(color: tint, fontWeight: FontWeight.w700),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(child: Text(name, style: PText.h3(OColor.gray800))),
                            const SizedBox(width: 4),
                            Icon(FluentIcons.checkmark_starburst_16_filled, size: 16, color: OColor.blue500),
                          ],
                        ),
                        Text(role, style: PText.bodyX(OColor.gray600)),
                        Text('Verified by NSS IITG', style: PText.bodyX(OColor.blue500)),
                      ],
                    ),
                  ),
                ],
              ),
              if (line != null) ...[const SizedBox(height: 12), Text(line, style: PText.body(OColor.gray700))],
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _ContactBtn(
                      icon: FluentIcons.call_24_filled,
                      label: 'Call',
                      onTap: () => _demoAction(ctx, 'Calling $phone'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _ContactBtn(
                      icon: FluentIcons.chat_24_filled,
                      label: 'WhatsApp',
                      onTap: () => _demoAction(ctx, 'Opening WhatsApp chat with $name'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Center(child: Text(phone, style: PText.bodyX(OColor.gray500))),
            ],
          ),
        ),
  );
}

void _demoAction(BuildContext context, String msg) {
  Navigator.of(context).pop();
  ScaffoldMessenger.maybeOf(
    context,
  )?.showSnackBar(SnackBar(content: Text('$msg (prototype)'), behavior: SnackBarBehavior.floating));
}

class _ContactBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _ContactBtn({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(color: OColor.green100, borderRadius: BorderRadius.circular(OCornerRadius.l)),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: OColor.green600, size: 20),
            const SizedBox(width: 8),
            Text(label, style: OTextStyle.labelMedium.copyWith(color: OColor.green600)),
          ],
        ),
      ),
    );
  }
}
