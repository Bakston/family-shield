import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:open_filex/open_filex.dart';
import 'package:package_info_plus/package_info_plus.dart';

class GithubUpdateService {
  static const String owner = 'Bakston';
  static const String repo = 'family-shield';
  static const String githubToken = ''; // Оставьте пустым для публичного репозитория

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
        String latestTag = data['tag_name'] ?? ''; // Например, "1.0.5" или "v1.0.5"
        
        List assets = data['assets'] ?? [];
        String? downloadUrl;
        for (var asset in assets) {
          String name = asset['name'] ?? '';
          if (name.endsWith('.apk')) {
            downloadUrl = asset['browser_download_url'];
            break;
          }
        }

        // Получаем текущую версию приложения из pubspec.yaml автоматически
        final packageInfo = await PackageInfo.fromPlatform();
        String currentVer = packageInfo.version; // Например, "1.0.4"

        // Очищаем теги до формата major.minor.patch
        String cleanLatest = latestTag.replaceAll(RegExp(r'[^0-9.]'), '').split('.').take(3).join('.');
        String cleanCurrent = currentVer.replaceAll(RegExp(r'[^0-9.]'), '').split('.').take(3).join('.');

        if (cleanLatest.isNotEmpty && cleanLatest != cleanCurrent && downloadUrl != null) {
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
              Navigator.pop(context);
              _downloadAndInstall(context, downloadUrl);
            },
            child: const Text('Обновить'),
          ),
        ],
      ),
    );
  }

  static Future<void> _downloadAndInstall(BuildContext context, String downloadUrl) async {
    int progress = 0;
    StateSetter? setStateDialog;

    // Показываем диалог с динамическим обновлением прогресса
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          setStateDialog = setState;
          return AlertDialog(
            title: const Text('Загрузка обновления'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                LinearProgressIndicator(value: progress > 0 ? progress / 100 : null),
                const SizedBox(height: 20),
                Text(
                  progress > 0 ? 'Загружено: $progress%' : 'Подключение...',
                  style: const TextStyle(fontSize: 15),
                ),
              ],
            ),
          );
        },
      ),
    );

    try {
      final uri = Uri.parse(downloadUrl);
      final client = http.Client();
      final request = http.Request('GET', uri);
      if (githubToken.isNotEmpty) {
        request.headers['Authorization'] = 'Bearer $githubToken';
      }

      final streamedResponse = await client.send(request);

      if (streamedResponse.statusCode == 200) {
        final contentLength = streamedResponse.contentLength ?? 0;
        int receivedBytes = 0;

        final dir = await getTemporaryDirectory();
        final filePath = '${dir.path}/update.apk';
        final file = File(filePath);
        final sink = file.openWrite();

        await for (var chunk in streamedResponse.stream) {
          receivedBytes += chunk.length;
          sink.add(chunk);

          if (contentLength > 0) {
            final newProgress = ((receivedBytes / contentLength) * 100).toInt();
            if (newProgress != progress) {
              progress = newProgress;
              // Обновляем состояние внутри диалога без закрытия
              setStateDialog?.call(() {});
            }
          }
        }

        await sink.flush();
        await sink.close();
        client.close();

        if (context.mounted) Navigator.pop(context); // Закрываем диалог загрузки

        // Запускаем установку скачанного APK
        final result = await OpenFilex.open(filePath);
        
        if (result.type != ResultType.done && context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Не удалось запустить установку: ${result.message}')),
          );
        }
      } else {
        client.close();
        if (context.mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Ошибка при скачивании файла обновления')),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка: $e')),
        );
      }
    }
  }
}