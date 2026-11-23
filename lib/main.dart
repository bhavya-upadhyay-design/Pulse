import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'package:get_storage/get_storage.dart';
import 'package:onestop_ui/index.dart';
import 'package:provider/provider.dart';

import 'blood/blood_shell.dart';
import 'blood/flows/bingo.dart';
import 'blood/flows/sheets.dart';
import 'onestop/home.dart';
import 'state/pulse_store.dart';

Future<void> main() async {
  // The app reads `#scene` itself; Flutter must not treat hash changes as routes.
  setUrlStrategy(null);
  WidgetsFlutterBinding.ensureInitialized();
  // OneStop's dark theme (the Figma screens are all dark mode).
  try {
    await GetStorage.init();
    await ThemeStore.instance.setTheme(Brightness.dark);
  } catch (_) {
    // Storage can be blocked (private window); the theme falls back below.
    if (ThemeStore.instance.isLightMode) await ThemeStore.instance.toggleTheme(notify: false).catchError((_) {});
  }
  final store = PulseStore();
  // `?scene=request` or `#request` (hosted pages only pass the hash).
  final frag = Uri.base.fragment;
  final scene = Uri.base.queryParameters['scene'] ?? (frag.isEmpty ? null : frag);
  applyScene(store, scene);
  // `?a11y=1` turns the semantics tree on (screen readers / UI tests on web).
  if (Uri.base.queryParameters['a11y'] == '1') SemanticsBinding.instance.ensureSemantics();
  runApp(ChangeNotifierProvider.value(value: store, child: PulseApp(scene: scene)));
}

/// Demo scenes: onboarding (default), home, request, critical, event,
/// outcome, bingo, blood (My Donations), explore, herowall.
void applyScene(PulseStore s, String? scene) {
  if (scene == null || scene == 'onboarding') return;
  s.seedProfile();
  switch (scene) {
    case 'request' || 'blood':
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
  final String? scene;
  const PulseApp({super.key, this.scene});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'OneStop • Pulse',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        fontFamily: OTextStyle.fontFamily,
        scaffoldBackgroundColor: OColor.gray100,
        colorScheme: ColorScheme.fromSeed(seedColor: OColor.green600, brightness: Brightness.dark, primary: OColor.green600),
        appBarTheme: const AppBarTheme(systemOverlayStyle: SystemUiOverlayStyle.light),
      ),
      builder: (context, child) => _PhoneFrame(child: child!),
      home: _Root(scene: scene),
    );
  }
}

class _Root extends StatefulWidget {
  final String? scene;
  const _Root({this.scene});
  @override
  State<_Root> createState() => _RootState();
}

class _RootState extends State<_Root> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final nav = Navigator.of(context);
      switch (widget.scene) {
        case 'blood':
          nav.push(BloodShell.route());
        case 'explore':
          nav.push(BloodShell.route(tab: 1));
        case 'herowall':
          nav.push(BloodShell.route(tab: 2));
        case 'bingo':
          nav.push(BingoPage.route());
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final seen = context.select<PulseStore, bool>((s) => s.onboardingSeen);
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 420),
      child: seen ? const OneStopHome(key: ValueKey('home')) : const BecomeLifeline(key: ValueKey('onb')),
    );
  }
}

/// On wide screens (web demo), centre the app in a 360 × 780 phone frame,
/// the size of the Figma frames.
class _PhoneFrame extends StatelessWidget {
  final Widget child;
  const _PhoneFrame({required this.child});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    if (size.width <= 520) return child;
    const w = 376.0;
    final h = (size.height - 40).clamp(640.0, 812.0);
    return ColoredBox(
      color: const Color(0xFF0E0E0E),
      child: Center(
        child: Container(
          width: w,
          height: h,
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(40), border: Border.all(color: const Color(0xFF2A2A2A), width: 8)),
          clipBehavior: Clip.antiAlias,
          child: MediaQuery(data: MediaQuery.of(context).copyWith(size: Size(w - 16, h - 16)), child: child),
        ),
      ),
    );
  }
}
