import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../parent/screens/parent_panel_screen.dart';
import '../../child/screens/child_panel_screen.dart';
import 'welcome_screen.dart';

class InitialSessionWrapper extends StatefulWidget {
  const InitialSessionWrapper({super.key});

  @override
  State<InitialSessionWrapper> createState() => _InitialSessionWrapperState();
}

class _InitialSessionWrapperState extends State<InitialSessionWrapper> {
  bool _isLoading = true;
  String? _userType;
  String? _userUid;
  String? _childId;

  @override
  void initState() {
    super.initState();
    _checkSession();
  }

  Future<void> _checkSession() async {
    final prefs = await SharedPreferences.getInstance();
    final userType = prefs.getString('user_type');
    final userUid = prefs.getString('user_uid');
    final childId = prefs.getString('child_id');

    if (!mounted) return;
    setState(() {
      _userType = userType;
      _userUid = userUid;
      _childId = childId;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    // Если устройство настроено как Родитель
    if (_userType == 'parent' && _userUid != null && _userUid!.isNotEmpty) {
      return const ParentPanelScreen();
    }

    // Если устройство настроено как Ребёнок
    if (_userType == 'child' && _childId != null && _childId!.isNotEmpty) {
      return const ChildPanelScreen();
    }

    // Если сессии нет — показываем главное меню с кнопкой "МОЯ СЕМЬЯ"
    return const WelcomeScreen();
  }
}