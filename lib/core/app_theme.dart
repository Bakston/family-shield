import 'package:flutter/material.dart';

class AppTheme {
  // ====================================================
  // 1. МАЛЬЧИКОВАЯ ВЕРСИЯ («Кибер-Неон»)
  // ====================================================
  static const Color boyBackground = Color(0xFF0A0E17);
  static const Color boyGlassPanel = Color(0x99121A2B); // 60% opacity
  static const Color boyPrimaryAccent = Color(0xFF00F0FF); // Неоновый голубой
  static const Color boySecondaryAccent = Color(0xFF3B82F6);
  static const Color boyTextPrimary = Color(0xFFFFFFFF);
  static const Color boyTextSecondary = Color(0xFF8A99AD);

  // ====================================================
  // 2. ДЕВОЧКОВАЯ ВЕРСИЯ («Кибер-Розовый»)
  // ====================================================
  static const Color girlBackground = Color(0xFF100A14);
  static const Color girlGlassPanel = Color(0x991B1221); // 60% opacity
  static const Color girlPrimaryAccent = Color(0xFFFF2A85); // Неоновый розовый / фуксия
  static const Color girlSecondaryAccent = Color(0xFFB83280);
  static const Color girlTextPrimary = Color(0xFFFFF5F7);
  static const Color girlTextSecondary = Color(0xFFA08C9D);

  // ====================================================
  // 3. РОДИТЕЛЬСКАЯ / НЕЙТРАЛЬНАЯ ВЕРСИЯ («Светлый дашборд»)
  // ====================================================
  static const Color parentBackground = Color(0xFFF5F4F0);
  static const Color parentGlassPanel = Color(0x99E8ECE9); // 60% opacity
  static const Color parentPrimaryAccent = Color(0xFF36454F);
  static const Color parentSecondaryAccent = Color(0xFF85B5AB);
  static const Color parentTextPrimary = Color(0xFF2C353D);
  static const Color parentTextSecondary = Color(0xFF707C85);

  // Общие статусные цвета (подходят для всех)
  static const Color successColor = Color(0xFF10B981); // Изумрудный (выполнено)
  static const Color warningColor = Color(0xFFF59E0B); // Янтарный (лимит)
  static const Color errorColor = Color(0xFFEF4444);   // Красный (исчерпано)

  /// Метод для получения палитры на основе роли и пола
  static AppPalette getPalette(String role, {String gender = 'boy'}) {
    if (role == 'parent') {
      return AppPalette(
        background: parentBackground,
        glassPanel: parentGlassPanel,
        primaryAccent: parentPrimaryAccent,
        secondaryAccent: parentSecondaryAccent,
        textPrimary: parentTextPrimary,
        textSecondary: parentTextSecondary,
      );
    } else {
      if (gender == 'girl') {
        return AppPalette(
          background: girlBackground,
          glassPanel: girlGlassPanel,
          primaryAccent: girlPrimaryAccent,
          secondaryAccent: girlSecondaryAccent,
          textPrimary: girlTextPrimary,
          textSecondary: girlTextSecondary,
        );
      } else {
        return AppPalette(
          background: boyBackground,
          glassPanel: boyGlassPanel,
          primaryAccent: boyPrimaryAccent,
          secondaryAccent: boySecondaryAccent,
          textPrimary: boyTextPrimary,
          textSecondary: boyTextSecondary,
        );
      }
    }
  }
}

/// Класс-контейнер для текущей активной палитры
class AppPalette {
  final Color background;
  final Color glassPanel;
  final Color primaryAccent;
  final Color secondaryAccent;
  final Color textPrimary;
  final Color textSecondary;

  AppPalette({
    required this.background,
    required this.glassPanel,
    required this.primaryAccent,
    required this.secondaryAccent,
    required this.textPrimary,
    required this.textSecondary,
  });
}