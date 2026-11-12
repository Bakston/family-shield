import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';

import 'core/app_theme.dart';
import 'core/services/github_update_service.dart';
import 'features/auth/initial_session_wrapper.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  await Firebase.initializeApp();
  runApp(const FamilyShieldApp());
}

class FamilyShieldApp extends StatefulWidget {
  const FamilyShieldApp({super.key});

  @override
  State<FamilyShieldApp> createState() => _FamilyShieldAppState();
}

class _FamilyShieldAppState extends State<FamilyShieldApp> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final context = navigatorKey.currentContext;
      if (context != null) {
        GithubUpdateService.checkForUpdates(context, silent: true);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Family Shield',
      navigatorKey: navigatorKey,
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        fontFamily: 'Inter',
        scaffoldBackgroundColor: AppTheme.parentBackground,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppTheme.parentPrimaryAccent,
          primary: AppTheme.parentPrimaryAccent,
          secondary: AppTheme.parentSecondaryAccent,
          surface: AppTheme.parentGlassPanel,
        ),
        textTheme: const TextTheme(
          bodyLarge: TextStyle(color: AppTheme.parentTextPrimary),
          bodyMedium: TextStyle(color: AppTheme.parentTextSecondary),
        ),
      ),
      home: const InitialSessionWrapper(),
    );
  }
}