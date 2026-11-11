import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'parent/screens/parent_panel_screen.dart';
import 'child/screens/role_selection_screen.dart';
import 'child/screens/child_panel_screen.dart';
import 'core/services/github_update_service.dart';

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
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const InitialSessionWrapper(),
      debugShowCheckedModeBanner: false,
    );
  }
}

/// Проверяет, привязан ли ребенок локально, иначе перенаправляет в AuthWrapper
class InitialSessionWrapper extends StatefulWidget {
  const InitialSessionWrapper({super.key});

  @override
  State<InitialSessionWrapper> createState() => _InitialSessionWrapperState();
}

class _InitialSessionWrapperState extends State<InitialSessionWrapper> {
  late final Future<Widget> _startScreenFuture;

  @override
  void initState() {
    super.initState();
    _startScreenFuture = _determineStartScreen();
  }

  Future<Widget> _determineStartScreen() async {
    final prefs = await SharedPreferences.getInstance();
    final savedChildId = prefs.getString('saved_child_id');

    if (savedChildId != null && savedChildId.isNotEmpty) {
      // Берем закэшированное имя, чтобы не зависеть от интернета
      String childName = prefs.getString('saved_child_name') ?? 'Ребёнок';

      try {
        final snapshot = await FirebaseDatabase.instance
            .ref('children/$savedChildId')
            .get()
            .timeout(const Duration(seconds: 5));

        if (snapshot.exists && snapshot.value != null) {
          final childData = Map<dynamic, dynamic>.from(snapshot.value as Map);
          childName = childData['name']?.toString() ?? childName;
          await prefs.setString('saved_child_name', childName);
        } else {
          // Если запись ребенка была явно удалена родителем из БД — сбрасываем привязку
          await prefs.remove('saved_child_id');
          await prefs.remove('saved_child_name');
          return const AuthWrapper();
        }
      } catch (_) {
        // При ошибке сети или таймауте все равно пускаем ребенка в его панель по локальной сессии
      }

      return ChildPanelScreen(childName: childName);
    }

    return const AuthWrapper();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Widget>(
      future: _startScreenFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        return snapshot.data ?? const AuthWrapper();
      },
    );
  }
}

/// Умный распределитель: проверяет сессию и наличие профиля в БД для родителей
class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  Future<bool> _isParentProfileReady(User user) async {
    final prefs = await SharedPreferences.getInstance();
    final cacheKey = 'parent_profile_ready_${user.uid}';

    // 1. Если профиль уже подтвержден локально — пускаем мгновенно
    if (prefs.getBool(cacheKey) == true) {
      return true;
    }

    // 2. Иначе проверяем в БД и кэшируем результат
    try {
      final snapshot = await FirebaseDatabase.instance
          .ref('users/${user.uid}')
          .get()
          .timeout(const Duration(seconds: 5));

      if (snapshot.exists && snapshot.value != null) {
        await prefs.setBool(cacheKey, true);
        return true;
      }
    } catch (_) {}

    return false;
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final user = snapshot.data;
        if (user == null) {
          return const WelcomeStartScreen();
        }

        return FutureBuilder<bool>(
          future: _isParentProfileReady(user),
          builder: (context, profileSnapshot) {
            if (profileSnapshot.connectionState == ConnectionState.waiting) {
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            }

            if (profileSnapshot.data == true) {
              return const ParentPanelScreen();
            } else {
              return const RoleSelectionScreen();
            }
          },
        );
      },
    );
  }
}

/// Стартовый экран с кнопкой "МОЯ СЕМЬЯ"
class WelcomeStartScreen extends StatelessWidget {
  const WelcomeStartScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.security, size: 100, color: Colors.blue),
              const SizedBox(height: 24),
              const Text(
                'Family Shield',
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 48),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size.fromHeight(50),
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                ),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const RoleSelectionScreen(),
                    ),
                  );
                },
                child: const Text('МОЯ СЕМЬЯ', style: TextStyle(fontSize: 18)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}