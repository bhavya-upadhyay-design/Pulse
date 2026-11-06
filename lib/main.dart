import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';
import 'package:onestop_ui/index.dart';
import 'package:provider/provider.dart';

import 'onboarding/lifeline_onboarding.dart';
import 'shell/home_shell.dart';
import 'state/pulse_store.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  final store = PulseStore();
  // `?scene=request` or `#request` (hosted pages only pass the hash).
  final frag = Uri.base.fragment;
  applyScene(store, Uri.base.queryParameters['scene'] ?? (frag.isEmpty ? null : frag));
  // `?a11y=1` turns the semantics tree on (screen readers / UI tests on web).
  if (Uri.base.queryParameters['a11y'] == '1') SemanticsBinding.instance.ensureSemantics();
  runApp(ChangeNotifierProvider.value(value: store, child: const PulseApp()));
}

/// Jump straight to a state for reviews and demos, e.g. `?scene=request`.
/// Scenes: onboarding (default), home, request, critical, event, outcome,
/// bingo.
void applyScene(PulseStore s, String? scene) {
  if (scene == null || scene == 'onboarding') return;
  s.seedProfile();
  switch (scene) {
    case 'request':
      s.adminRaiseRequest();
    case 'critical':
      s.adminRaiseRequest(critical: true);
    case 'event':
      s.adminRaiseRequest();
      s.accept();
      s.acceptedAt = null;
      s.adminSchedule();
    case 'outcome':
      s.adminRaiseRequest();
      s.accept();
      s.acceptedAt = null;
      s.adminPassSlot();
    case 'bingo':
      s.adminRaiseRequest();
      s.accept();
      s.acceptedAt = null;
      s.adminPassSlot();
      s.reportDonated();
      s.adminConfirmDonation();
  }
  s.pushes.value = null;
}

class PulseApp extends StatelessWidget {
  const PulseApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'OneStop • Pulse',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        fontFamily: OTextStyle.fontFamily,
        scaffoldBackgroundColor: OColor.gray100,
        colorScheme: ColorScheme.fromSeed(seedColor: OColor.green600, primary: OColor.green600),
        appBarTheme: const AppBarTheme(systemOverlayStyle: SystemUiOverlayStyle.dark),
        snackBarTheme: SnackBarThemeData(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(OCornerRadius.m)),
        ),
      ),
      builder: (context, child) => _PhoneFrame(child: child!),
      home: const _Root(),
    );
  }
}

class _Root extends StatelessWidget {
  const _Root();

  @override
  Widget build(BuildContext context) {
    final seen = context.select<PulseStore, bool>((s) => s.onboardingSeen);
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 420),
      child:
          seen
              ? const HomeShell(key: ValueKey('shell'))
              : LifelineOnboarding(key: const ValueKey('onb'), onDone: () {}),
    );
  }
}

/// On wide screens (web demo), centre the app in a phone-sized frame.
class _PhoneFrame extends StatelessWidget {
  final Widget child;
  const _PhoneFrame({required this.child});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    if (size.width <= 520) return child;
    const w = 400.0;
    final h = (size.height - 48).clamp(640.0, 880.0);
    return ColoredBox(
      color: const Color(0xFF232329),
      child: Center(
        child: Container(
          width: w,
          height: h,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(36),
            border: Border.all(color: Colors.black, width: 8),
            boxShadow: const [BoxShadow(color: Colors.black54, blurRadius: 40)],
          ),
          clipBehavior: Clip.antiAlias,
          child: MediaQuery(data: MediaQuery.of(context).copyWith(size: Size(w - 16, h - 16)), child: child),
        ),
      ),
    );
  }
}
