import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/app_theme.dart';
import '../../features/widgets/user_avatar_widget.dart';

const Color parentGlassPanel = Color(0x33FFFFFF);
const Color parentTextPrimary = Colors.white;

class ChildProfileEditScreen extends StatefulWidget {
  final String childId;

  const ChildProfileEditScreen({
    super.key,
    required this.childId,
  });

  @override
  State<ChildProfileEditScreen> createState() => _ChildProfileEditScreenState();
}

class _ChildProfileEditScreenState extends State<ChildProfileEditScreen> {
  String _name = '';
  String _role = 'Сын';
  String _birthDate = '';
  String _login = '';
  String _password = '';
  String _avatarHash = '';

  bool _isLoading = true;
  bool _isSaving = false;

  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _loadChildData();
  }

  Future<void> _loadChildData() async {
    try {
      final snapshot = await FirebaseDatabase.instance
          .ref('children/${widget.childId}')
          .get();

      if (snapshot.exists && snapshot.value != null) {
        final data = Map<dynamic, dynamic>.from(snapshot.value as Map);
        if (!mounted) return;
        setState(() {
          _name = data['name']?.toString() ?? '';
          _role = data['familyRole']?.toString() ?? 'Сын';
          _birthDate = data['birthDate']?.toString() ?? '';
          _login = data['login']?.toString() ?? '';
          _password = data['password']?.toString() ?? '';
          _avatarHash = data['avatarHash']?.toString() ?? '';
          _isLoading = false;
        });
        return;
      }
    } catch (e) {
      debugPrint('Ошибка загрузки профиля ребёнка: $e');
    }

    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _pickAvatar(ImageSource source) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: source,
        maxWidth: 200,
        maxHeight: 200,
        imageQuality: 70,
      );

      if (image == null) return;

      final bytes = await image.readAsBytes();
      final String base64String = base64Encode(bytes);

      if (!mounted) return;
      setState(() {
        _avatarHash = base64String;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Не удалось выбрать изображение: $e')),
      );
    }
  }

  void _showAvatarOptions() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Фото профиля ребёнка',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              ListTile(
                leading: const Icon(Icons.photo_library, color: Colors.blue),
                title: const Text('Выбрать из галереи'),
                onTap: () {
                  Navigator.pop(sheetContext);
                  _pickAvatar(ImageSource.gallery);
                },
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt, color: Colors.green),
                title: const Text('Сделать фото'),
                onTap: () {
                  Navigator.pop(sheetContext);
                  _pickAvatar(ImageSource.camera);
                },
              ),
              if (_avatarHash.isNotEmpty)
                ListTile(
                  leading: const Icon(Icons.delete_outline, color: Colors.red),
                  title: const Text(
                    'Удалить фото',
                    style: TextStyle(color: Colors.red),
                  ),
                  onTap: () {
                    Navigator.pop(sheetContext);
                    setState(() => _avatarHash = '');
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _saveChildProfile() async {
    if (_name.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Имя ребёнка не может быть пустым')),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      await FirebaseDatabase.instance
          .ref('children/${widget.childId}')
          .update({
        'name': _name.trim(),
        'familyRole': _role,
        'birthDate': _birthDate,
        'login': _login.trim(),
        'password': _password.trim(),
        'avatarHash': _avatarHash,
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Профиль ребёнка успешно обновлён')),
      );
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка сохранения: $e')),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _confirmDeleteChild() {
    final confirmController = TextEditingController();

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.red),
            SizedBox(width: 8),
            Expanded(child: Text('Удаление профиля ребёнка')),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Профиль «$_name» и вся история привязки будут удалены из семьи. Для подтверждения введите слово УДАЛИТЬ:',
            ),
            const SizedBox(height: 16),
            TextField(
              controller: confirmController,
              decoration: InputDecoration(
                labelText: 'Введите УДАЛИТЬ',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Отмена'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              if (confirmController.text.trim().toUpperCase() != 'УДАЛИТЬ') {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Введите слово УДАЛИТЬ для подтверждения'),
                  ),
                );
                return;
              }

              Navigator.pop(dialogContext);
              await _performDeleteChild();
            },
            child: const Text('Удалить навсегда'),
          ),
        ],
      ),
    );
  }

  Future<void> _performDeleteChild() async {
    try {
      await FirebaseDatabase.instance
          .ref('children/${widget.childId}')
          .remove();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Профиль ребёнка удалён')),
      );
      // Возвращаемся на панель родителя (закрываем и профиль, и экран деталей ребёнка)
      Navigator.of(context).popUntil((route) => route.isFirst);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка при удалении: $e')),
      );
    }
  }

  void _editTextField({
    required String title,
    required String currentValue,
    required Function(String) onApply,
    bool obscure = false,
  }) {
    final controller = TextEditingController(text: currentValue);
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(title),
        content: TextField(
          controller: controller,
          obscureText: obscure,
          decoration: InputDecoration(
            hintText: 'Введите значение',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Отмена'),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() => onApply(controller.text.trim()));
              Navigator.pop(dialogContext);
            },
            child: const Text('Готово'),
          ),
        ],
      ),
    );
  }

  void _editRole() {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Роль в семье'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: ['Сын', 'Дочь'].map((roleOption) {
            return ListTile(
              title: Text(roleOption),
              trailing: _role == roleOption
                  ? const Icon(Icons.check, color: Colors.purple)
                  : null,
              onTap: () {
                setState(() => _role = roleOption);
                Navigator.pop(dialogContext);
              },
            );
          }).toList(),
        ),
      ),
    );
  }

  Future<void> _editBirthDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime(now.year - 10, 1, 1),
      firstDate: DateTime(2000),
      lastDate: now,
    );
    if (picked != null && mounted) {
      final d = picked.day.toString().padLeft(2, '0');
      final m = picked.month.toString().padLeft(2, '0');
      setState(() => _birthDate = '$d.$m.${picked.year}');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(
          child: Image.asset(
            AppTheme.parentBackgroundAsset,
            fit: BoxFit.cover,
          ),
        ),
        Positioned.fill(
          child: Container(
            color: Colors.black.withValues(alpha: 0.45),
          ),
        ),
        Scaffold(
          backgroundColor: Colors.transparent,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            automaticallyImplyLeading: false,
            title: const Text(
              'Профиль ребёнка',
              style: TextStyle(
                color: parentTextPrimary,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          body: _isLoading
              ? const Center(
                  child: CircularProgressIndicator(color: parentTextPrimary),
                )
              : SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                    child: Column(
                      children: [
                        Expanded(
                          child: SingleChildScrollView(
                            child: Stack(
                              alignment: Alignment.topCenter,
                              children: [
                                Container(
                                  margin: const EdgeInsets.only(top: 48),
                                  padding: const EdgeInsets.fromLTRB(
                                    16,
                                    60,
                                    16,
                                    16,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.95),
                                    borderRadius: BorderRadius.circular(24),
                                    boxShadow: [
                                      BoxShadow(
                                        color:
                                            Colors.black.withValues(alpha: 0.2),
                                        blurRadius: 15,
                                        offset: const Offset(0, 8),
                                      ),
                                    ],
                                  ),
                                  child: Column(
                                    children: [
                                      Text(
                                        _name.isNotEmpty ? _name : 'Ребёнок',
                                        style: const TextStyle(
                                          fontSize: 22,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.black87,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        _login.isNotEmpty
                                            ? '$_role • $_login'
                                            : '$_role • Логин не задан',
                                        style: TextStyle(
                                          fontSize: 13,
                                          color: Colors.grey.shade600,
                                        ),
                                      ),
                                      const SizedBox(height: 16),
                                      const Divider(),

                                      _buildProfileRow(
                                        icon: Icons.person_outline,
                                        title: 'Имя',
                                        value: _name.isNotEmpty
                                            ? _name
                                            : 'Не указано',
                                        onTap: () => _editTextField(
                                          title: 'Изменить имя ребёнка',
                                          currentValue: _name,
                                          onApply: (v) => _name = v,
                                        ),
                                      ),

                                      _buildProfileRow(
                                        icon: Icons.child_care,
                                        title: 'Роль в семье',
                                        value: _role,
                                        onTap: _editRole,
                                      ),

                                      _buildProfileRow(
                                        icon: Icons.cake_outlined,
                                        title: 'Дата рождения',
                                        value: _birthDate.isNotEmpty
                                            ? _birthDate
                                            : 'Не указана',
                                        onTap: _editBirthDate,
                                      ),

                                      const Divider(),

                                      _buildProfileRow(
                                        icon: Icons.alternate_email,
                                        title: 'Логин (для лаунчера)',
                                        value: _login.isNotEmpty
                                            ? _login
                                            : 'Нажмите, чтобы задать',
                                        highlightEmpty: _login.isEmpty,
                                        onTap: () => _editTextField(
                                          title: 'Задать логин ребёнка',
                                          currentValue: _login,
                                          onApply: (v) => _login = v,
                                        ),
                                      ),

                                      _buildProfileRow(
                                        icon: Icons.lock_outline,
                                        title: 'Пароль',
                                        value: _password.isNotEmpty
                                            ? '•' * _password.length
                                            : 'Нажмите, чтобы задать',
                                        highlightEmpty: _password.isEmpty,
                                        onTap: () => _editTextField(
                                          title: 'Задать пароль ребёнка',
                                          currentValue: _password,
                                          obscure: true,
                                          onApply: (v) => _password = v,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                                // Круглый аватар ребёнка с кнопкой камеры
                                GestureDetector(
                                  onTap: _showAvatarOptions,
                                  child: Stack(
                                    alignment: Alignment.bottomRight,
                                    children: [
                                      UserAvatarWidget(
                                        avatarBase64: _avatarHash,
                                        radius: 48,
                                        fallbackIcon: Icons.child_care,
                                        fallbackBackgroundColor:
                                            Colors.purple.shade600,
                                        fallbackIconColor: Colors.white,
                                        borderWidth: 4,
                                        borderColor: Colors.white,
                                      ),
                                      Container(
                                        padding: const EdgeInsets.all(6),
                                        decoration: BoxDecoration(
                                          color: Colors.purple.shade800,
                                          shape: BoxShape.circle,
                                          border: Border.all(
                                            color: Colors.white,
                                            width: 2,
                                          ),
                                        ),
                                        child: const Icon(
                                          Icons.camera_alt,
                                          size: 16,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Нижние кнопки: Назад + СОХРАНИТЬ
                        Row(
                          children: [
                            InkWell(
                              onTap: () => Navigator.pop(context),
                              borderRadius: BorderRadius.circular(16),
                              child: Container(
                                width: 56,
                                height: 56,
                                decoration: BoxDecoration(
                                  color: parentGlassPanel,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: Colors.white.withValues(alpha: 0.35),
                                    width: 1.5,
                                  ),
                                ),
                                child: const Icon(
                                  Icons.arrow_back,
                                  color: parentTextPrimary,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  minimumSize: const Size.fromHeight(56),
                                  backgroundColor: Colors.blue.shade700,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                ),
                                onPressed: _isSaving ? null : _saveChildProfile,
                                child: _isSaving
                                    ? const SizedBox(
                                        width: 24,
                                        height: 24,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Colors.white,
                                        ),
                                      )
                                    : const Text(
                                        'СОХРАНИТЬ',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          letterSpacing: 1,
                                        ),
                                      ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),

                        // Кнопка удаления профиля ребёнка
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              minimumSize: const Size.fromHeight(48),
                              backgroundColor:
                                  Colors.red.shade900.withValues(alpha: 0.55),
                              foregroundColor: Colors.white,
                              side: BorderSide(
                                color: Colors.redAccent.withValues(alpha: 0.7),
                                width: 1.5,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            icon: const Icon(
                              Icons.delete_forever,
                              color: Colors.redAccent,
                            ),
                            label: const Text(
                              'УДАЛИТЬ ПРОФИЛЬ РЕБЁНКА',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.8,
                              ),
                            ),
                            onPressed: _confirmDeleteChild,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
        ),
      ],
    );
  }

  Widget _buildProfileRow({
    required IconData icon,
    required String title,
    required String value,
    required VoidCallback onTap,
    bool highlightEmpty = false,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      leading: Icon(icon, color: Colors.blueGrey.shade700),
      title: Text(
        title,
        style: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w500,
          color: Colors.black87,
        ),
      ),
      subtitle: Text(
        value,
        style: TextStyle(
          fontSize: 13,
          color: highlightEmpty ? Colors.orange.shade800 : Colors.grey.shade600,
        ),
      ),
      trailing: const Icon(Icons.chevron_right, color: Colors.grey),
      onTap: onTap,
    );
  }
}