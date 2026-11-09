import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:open_filex/open_filex.dart';

class GithubUpdateService {
  static const String owner = 'Bakston';
  static const String repo = 'family-shield';
  static const String currentVersion = '1.0.2';
  static const String githubToken = ''; // Оставьте пустым, если репозиторий публичный

  /// Проверка обновлений с GitHub Releases.
  static Future<void> checkForUpdates(BuildContext context, {bool silent = true}) async {
    final url = Uri.parse('https://api.github.com/repos/$owner/$repo/releases/latest');
    
    final headers = <String, String>{
      'Accept': 'application/vnd.github+json',
      if (githubToken.isNotEmpty) 'Authorization': 'Bearer $githubToken',
    };

    try {
      final response = await http.get(url, headers: headers);
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        String latestTag = data['tag_name'] ?? '';
        
        List assets = data['assets'] ?? [];
        String? downloadUrl;
        for (var asset in assets) {
          String name = asset['name'] ?? '';
          if (name.endsWith('.apk')) {
            downloadUrl = asset['browser_download_url'];
            break;
          }
        }

        String cleanLatest = latestTag.replaceAll(RegExp(r'[^0-9.]'), '');

        if (cleanLatest.isNotEmpty && cleanLatest != currentVersion && downloadUrl != null) {
          if (context.mounted) {
            _showUpdateDialog(context, cleanLatest, downloadUrl);
          }
        } else {
          if (!silent && context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('У вас установлена самая свежая версия!')),
            );
          }
        }
      } else {
        if (!silent && context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Не удалось проверить обновление')),
          );
        }
      }
    } catch (e) {
      if (!silent && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Ошибка соединения с сетью')),
        );
      }
    }
  }

  static void _showUpdateDialog(BuildContext context, String version, String downloadUrl) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Доступно обновление'),
        content: Text('Вышла новая версия приложения ($version). Скачать и установить прямо сейчас?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Позже'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context); // Закрываем диалог
              _downloadAndInstall(context, downloadUrl); // Запускаем скачивание
            },
            child: const Text('Обновить'),
          ),
        ],
      ),
    );
  }

  /// Скачивание APK во временную память и запуск установки
  static Future<void> _downloadAndInstall(BuildContext context, String downloadUrl) async {
    // Показываем диалог загрузки с прогресс-индикатором
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const AlertDialog(
        content: Row(
          children: [
            CircularProgressIndicator(),
            SizedBox(width: 20),
            Text('Загрузка обновления...'),
          ],
        ),
      ),
    );

    try {
      final uri = Uri.parse(downloadUrl);
      final headers = <String, String>{
        if (githubToken.isNotEmpty) 'Authorization': 'Bearer $githubToken',
      };

      final response = await http.get(uri, headers: headers);

      if (response.statusCode == 200) {
        // Получаем временную папку телефона
        final dir = await getTemporaryDirectory();
        final filePath = '${dir.path}/update.apk';
        final file = File(filePath);
        
        // Записываем байты скачанного файла
        await file.writeAsBytes(response.bodyBytes);

        // Закрываем диалог загрузки
        if (context.mounted) Navigator.pop(context);

        // Открываем файл через системный установщик
        final result = await OpenFilex.open(filePath);
        
        if (result.type != ResultType.done && context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Не удалось запустить установку: ${result.message}')),
          );
        }
      } else {
        if (context.mounted) {
          Navigator.pop(context); // Закрываем диалог
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Ошибка при скачивании файла обновления')),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.pop(context); // Закрываем диалог
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка: $e')),
        );
      }
    }
  }
}