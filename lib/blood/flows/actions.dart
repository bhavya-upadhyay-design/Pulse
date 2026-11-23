import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../state/models.dart';
import '../../state/pulse_store.dart';
import '../../theme/bd.dart';
import '../widgets/common.dart';
import '../widgets/motion.dart';
import 'request_details_page.dart';

/// Accepting from anywhere: store update, haptic, heart burst.
void acceptRequest(BuildContext context, {Offset? origin}) {
  final s = context.read<PulseStore>();
  if (s.phase != AskPhase.open) return;
  s.accept();
  Haptics.success();
  final size = MediaQuery.sizeOf(context);
  playBurst(context, origin: origin ?? Offset(size.width / 2, size.height * 0.35));
}

void openRequestDetails(BuildContext context) {
  Navigator.of(context).push(RequestDetailsPage.route());
}

class ReasonOption {
  final String label;
  final IconData icon;
  const ReasonOption(this.label, this.icon);
}

const declineReasons = [
  ReasonOption('Not feeling well', FluentIcons.emoji_sad_20_regular),
  ReasonOption('Exams / busy', FluentIcons.book_20_regular),
  ReasonOption('Donated recently', FluentIcons.drop_20_regular),
  ReasonOption('Travelling', FluentIcons.airplane_20_regular),
  ReasonOption('Other', FluentIcons.more_horizontal_20_regular),
];

void openDecline(BuildContext context) {
  final s = context.read<PulseStore>();
  showBdSheet(
    context,
    builder:
        (_) => ReasonSheet(
          title: 'No worries, ${s.firstName}',
          subtitle: "Tell us why in one tap. We'll pass this to the next donor right away.",
          reasons: declineReasons,
          doneTitle: 'Thanks for telling us quickly',
          doneBody: "We've passed this to the next donor.",
          onPick: (r, d) => s.decline(r, donatedOn: d),
        ),
  );
}

/// One-tap reason picker in the blood-donation style.
class ReasonSheet extends StatefulWidget {
  final String title;
  final String subtitle;
  final List<ReasonOption> reasons;
  final String doneTitle;
  final String doneBody;
  final void Function(String reason, DateTime? donatedOn) onPick;
  const ReasonSheet({
    super.key,
    required this.title,
    required this.subtitle,
    required this.reasons,
    required this.doneTitle,
    required this.doneBody,
    required this.onPick,
  });

  @override
  State<ReasonSheet> createState() => _ReasonSheetState();
}

class _ReasonSheetState extends State<ReasonSheet> {
  bool _done = false;
  bool _askDate = false;
  DateTime? _month;

  void _finish(String r, DateTime? d) {
    setState(() => _done = true);
    Haptics.light();
    Future.delayed(const Duration(milliseconds: 1400), () {
      if (!mounted) return;
      Navigator.of(context).pop();
      widget.onPick(r, d);
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedSize(
      duration: BD.medium,
      curve: Curves.easeOutCubic,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 20),
        child: AnimatedSwitcher(
          duration: BD.medium,
          child:
              _done
                  ? Column(
                    key: const ValueKey('done'),
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const DropMedallion(),
                      gap16,
                      Text(widget.doneTitle, style: T.bold(16), textAlign: TextAlign.center),
                      gap8,
                      Text(widget.doneBody, style: T.regular(12, BD.textSecondary), textAlign: TextAlign.center),
                      gap16,
                    ],
                  )
                  : _askDate
                  ? _dates()
                  : Column(
                    key: const ValueKey('list'),
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(widget.title, style: T.bold(16)),
                      gap8,
                      Text(widget.subtitle, style: T.regular(12, BD.textSecondary)),
                      gap16,
                      for (final r in widget.reasons)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Pressable(
                            onTap: () => r.label == 'Donated recently' ? setState(() => _askDate = true) : _finish(r.label, null),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                              decoration: BoxDecoration(
                                color: BD.page,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: BD.border),
                              ),
                              child: Row(
                                children: [
                                  Icon(r.icon, color: BD.textSecondary, size: 20),
                                  gap12,
                                  Expanded(child: Text(r.label, style: T.medium(14))),
                                  const Icon(FluentIcons.chevron_right_20_regular, color: BD.textSecondary, size: 18),
                                ],
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
        ),
      ),
    );
  }

  Widget _dates() {
    final now = DateTime.now();
    final months = List.generate(6, (i) => DateTime(now.year, now.month - i));
    return Column(
      key: const ValueKey('date'),
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('When did you last donate?', style: T.bold(16)),
        gap8,
        Text("We'll update your eligibility so we don't ask too early.", style: T.regular(12, BD.textSecondary)),
        gap16,
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final m in months)
              ChipPill(text: '${monthShort(m)} ${m.year}', selected: _month == m, onTap: () => setState(() => _month = m)),
          ],
        ),
        gap24,
        BdButton(label: 'Update and decline', onTap: _month == null ? null : () => _finish('Donated recently', _month)),
      ],
    );
  }
}

/// Selectable pill used in sheets and onboarding.
class ChipPill extends StatelessWidget {
  final String text;
  final bool selected;
  final VoidCallback onTap;
  final double? width;
  const ChipPill({super.key, required this.text, required this.selected, required this.onTap, this.width});

  @override
  Widget build(BuildContext context) => Pressable(
    onTap: onTap,
    child: AnimatedContainer(
      duration: BD.fast,
      width: width,
      height: 36,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: selected ? BD.toggleOn : BD.page,
        borderRadius: BorderRadius.circular(71),
        border: Border.all(color: selected ? BD.toggleOn : BD.border),
      ),
      child: Text(text, style: T.medium(13, selected ? Colors.white : BD.text700)),
    ),
  );
}

/// Call / WhatsApp sheet for the POC or NSS coordinator.
void showContactSheet(BuildContext context, Contact c, {String? line}) {
  showBdSheet(
    context,
    builder:
        (ctx) => Padding(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  InitialsDot(initials: c.initials, size: 48),
                  gap12,
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(child: Text(c.name, style: T.bold(16))),
                            const SizedBox(width: 6),
                            const Icon(FluentIcons.checkmark_starburst_16_filled, color: BD.green, size: 16),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text('${c.role} • Verified by NSS IITG', style: T.regular(12, BD.textSecondary)),
                      ],
                    ),
                  ),
                ],
              ),
              if (line != null) ...[gap16, Text(line, style: T.regular(13, BD.text700, 1.4))],
              gap24,
              Row(
                children: [
                  Expanded(child: BdButton(label: 'Call', icon: FluentIcons.call_20_filled, onTap: () => _demo(ctx, 'Calling ${c.phone}'))),
                  gap8,
                  Expanded(
                    child: BdButton(
                      label: 'WhatsApp',
                      outline: true,
                      icon: FluentIcons.chat_20_regular,
                      onTap: () => _demo(ctx, 'Opening WhatsApp'),
                    ),
                  ),
                ],
              ),
              gap12,
              Center(child: SelectableText(c.phone, style: T.regular(12, BD.textSecondary))),
            ],
          ),
        ),
  );
}

void _demo(BuildContext context, String msg) {
  Navigator.of(context).pop();
  ScaffoldMessenger.maybeOf(context)?.showSnackBar(bdSnack('$msg (prototype)'));
}

SnackBar bdSnack(String text) => SnackBar(
  behavior: SnackBarBehavior.floating,
  backgroundColor: const Color(0xFF323232),
  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
  content: Text(text, style: T.medium(13)),
);
