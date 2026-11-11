import 'package:flutter/material.dart';
import '../../core/services/github_update_service.dart';
import '../../features/widgets/app_version_widget.dart';

class ChildPanelScreen extends StatelessWidget {
  final String childName;

  const ChildPanelScreen({
    super.key,
    this.childName = 'Ребёнок',
  });

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Панель Ребёнка'),
          automaticallyImplyLeading: false,
          actions: [
            IconButton(
              icon: const Icon(Icons.system_update),
              tooltip: 'Проверить обновления',
              onPressed: () {
                GithubUpdateService.checkForUpdates(context, silent: false);
              },
            ),
          ],
        ),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              children: [
                const Spacer(),
                const Icon(Icons.verified_user, size: 80, color: Colors.green),
                const SizedBox(height: 24),
                Text(
                  'Привет, $childName!',
                  style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                const Text(
                  'Устройство успешно привязано к семье.\nЗащита активна.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16, color: Colors.grey),
                ),
                const Spacer(),
                const AppVersionWidget(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}