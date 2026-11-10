import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';

import 'parent/screens/parent_panel_screen.dart';
import 'child/screens/role_selection_screen.dart';
import 'core/services/github_update_service.dart';

// Глобальный ключ для доступа к контексту приложения
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Фиксируем портретную ориентацию приложения
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
    // Глобальная тихая проверка обновлений при старте приложения
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
      navigatorKey: navigatorKey, // Передаем ключ в MaterialApp
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const AuthWrapper(),
      debugShowCheckedModeBanner: false,
    );
  }
}

/// Умный распределитель: проверяет сессию и наличие профиля в БД
class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        
        final user = snapshot.data;
        if (user == null) {
          return const WelcomeStartScreen();
        } else {
          return FutureBuilder<DataSnapshot>(
            future: FirebaseDatabase.instance.ref('users/${user.uid}').get(),
            builder: (context, dbSnapshot) {
              if (dbSnapshot.connectionState == ConnectionState.waiting) {
                return const Scaffold(body: Center(child: CircularProgressIndicator()));
              }
              
              if (dbSnapshot.hasData && dbSnapshot.data!.exists) {
                return const ParentPanelScreen();
              } else {
                return const RoleSelectionScreen();
              }
            },
          );
        }
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
              const Text('Family Shield', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
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
                    MaterialPageRoute(builder: (context) => const RoleSelectionScreen()),
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