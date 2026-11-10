import 'package:flutter/material.dart';
import '../../parent/screens/phone_auth_screen.dart';
import 'child_join_screen.dart';

class RoleSelectionScreen extends StatelessWidget {
  const RoleSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Выберите роль')),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              style: ElevatedButton.styleFrom(minimumSize: const Size.fromHeight(60)),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const PhoneAuthScreen()),
                );
              },
              child: const Text('РОДИТЕЛЬ', style: TextStyle(fontSize: 18)),
            ),
            const SizedBox(height: 20),
            OutlinedButton(
              style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(60)),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const ChildJoinScreen()),
                );
              },
              child: const Text('РЕБЁНОК', style: TextStyle(fontSize: 18)),
            ),
          ],
        ),
      ),
    );
  }
}