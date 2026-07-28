import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/voting_provider.dart';
import 'screens/splash_screen.dart';
import 'theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const VotRiteApp());
}

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

class VotRiteApp extends StatefulWidget {
  const VotRiteApp({super.key});

  @override
  State<VotRiteApp> createState() => _VotRiteAppState();
}

class _VotRiteAppState extends State<VotRiteApp> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      final nav = navigatorKey.currentState;
      if (nav != null) {
        final provider = nav.context.read<VotingProvider>();
        provider.reset();
        nav.pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const SplashScreen()),
          (route) => false,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => VotingProvider(),
      child: Selector<VotingProvider, bool>(
        selector: (_, p) => p.accessibilityMode,
        builder: (context, isAccessible, _) {
          return MaterialApp(
            navigatorKey: navigatorKey,
            title: 'VotRite',
            debugShowCheckedModeBanner: false,
            theme: isAccessible
                ? VotRiteTheme.accessibilityTheme
                : VotRiteTheme.lightTheme,
            home: const SplashScreen(),
          );
        },
      ),
    );
  }
}
