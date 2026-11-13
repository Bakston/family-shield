import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/app_theme.dart';
import '../../features/auth/initial_session_wrapper.dart';
import '../../features/widgets/user_avatar_widget.dart';

const Color parentGlassPanel = Color(0x33FFFFFF);
const Color parentTextPrimary = Colors.white;

class ParentProfileScreen extends StatefulWidget {
  const ParentProfileScreen({super.key});

  @override
  State<ParentProfileScreen> createState() => _ParentProfileScreenState();
}

class _ParentProfileScreenState extends State<ParentProfileScreen> {
  String _uid = '';
  String _name = '';
  String _role = 'Папа';
  String _birthDate = '';
  String _login = '';
  String _password = '';
  String _savedDbPassword = '';
  String _pin = '';
  String _avatarHash = '';

  bool _isLoading = true;
  bool _isSaving = false;

  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _loadProfileData();
  }

  Future<void> _loadProfileData() async {
    final prefs = await SharedPreferences.getInstance();
    final uid = prefs.getString('user_uid') ?? '';

    String name = prefs.getString('user_name') ?? '';
    String role = prefs.getString('user_role') ?? 'Папа';
    String birthDate = prefs.getString('user_birth_date') ?? '';
    String avatarHash = prefs.getString('user_avatar_hash') ?? '';
    String login = '';
    String password = '';
    String pin = prefs.getString('saved_device_pin') ?? '';

    if (uid.isNotEmpty) {
      try {
        final snapshot =
            await FirebaseDatabase.instance.ref('users/$uid').get();
        if (snapshot.exists && snapshot.value != null) {
          final data = Map<dynamic, dynamic>.from(snapshot.value as Map);
          name = data['name']?.toString() ?? name;
          role = data['familyRole']?.toString() ?? role;
          birthDate = data['birthDate']?.toString() ?? birthDate;
          login = data['login']?.toString() ?? '';
          password = data['password']?.toString() ?? '';
          avatarHash = data['avatarHash']?.toString() ?? avatarHash;
          if (data['pin'] != null && data['pin'].toString().isNotEmpty) {
            pin = data['pin'].toString();
          }
        }
      } catch (e) {
        debugPrint('Ошибка загрузки профиля из БД: $e');
      }
    }

    if (!mounted) return;
    setState(() {
      _uid = uid;
      _name = name;
      _role = role;
      _birthDate = birthDate;
      _login = login;
      _password = password;
      _savedDbPassword = password;
      _pin = pin;
      _avatarHash = avatarHash;
      _isLoading = false;
    });
  }

  /// Выбор и кодирование аватарки в Base64-хэш
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

  /// Нижнее меню выбора источника аватарки
  void _showAvatarOptions() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder:
          (sheetContext) => SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Фото профиля',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  ListTile(
                    leading: const Icon(
                      Icons.photo_library,
                      color: Colors.blue,
                    ),
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
                      leading: const Icon(
                        Icons.delete_outline,
                        color: Colors.red,
                      ),
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

  Future<void> _saveProfile() async {
    if (_uid.isEmpty) return;
    setState(() => _isSaving = true);

    try {
      await FirebaseDatabase.instance.ref('users/$_uid').update({
        'name': _name.trim(),
        'familyRole': _role,
        'birthDate': _birthDate,
        'login': _login.trim(),
        'password': _password.trim(),
        'pin': _pin.trim(),
        'avatarHash': _avatarHash,
      });

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user_name', _name.trim());
      await prefs.setString('user_role', _role);
      await prefs.setString('user_birth_date', _birthDate);
      await prefs.setString('user_avatar_hash', _avatarHash);
      await prefs.setString('saved_device_uid', _uid);

      if (_pin.trim().isNotEmpty) {
        await prefs.setString('saved_device_pin', _pin.trim());
      } else {
        await prefs.remove('saved_device_pin');
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Данные профиля успешно сохранены')),
      );
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Ошибка сохранения: $e')));
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  /// Диалог удаления профиля с подтверждением по паролю аккаунта
  void _confirmDeleteProfileWithPassword() {
    final confirmController = TextEditingController();
    final bool hasPassword = _savedDbPassword.isNotEmpty;

    showDialog(
      context: context,
      builder:
          (dialogContext) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: const Row(
              children: [
                Icon(Icons.warning_amber_rounded, color: Colors.red),
                SizedBox(width: 8),
                Expanded(child: Text('Удаление профиля')),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  hasPassword
                      ? 'Это действие необратимо удалит ваш аккаунт из базы данных. Для подтверждения введите пароль от аккаунта:'
                      : 'Пароль аккаунта ещё не задан. Для подтверждения удаления введите слово УДАЛИТЬ:',
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: confirmController,
                  obscureText: hasPassword,
                  decoration: InputDecoration(
                    labelText:
                        hasPassword ? 'Пароль аккаунта' : 'Введите УДАЛИТЬ',
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
                onPressed: () {
                  final entered = confirmController.text.trim();
                  if (hasPassword) {
                    if (entered != _savedDbPassword) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Неверный пароль!')),
                      );
                      return;
                    }
                  } else {
                    if (entered.toUpperCase() != 'УДАЛИТЬ') {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Введите слово УДАЛИТЬ для подтверждения',
                          ),
                        ),
                      );
                      return;
                    }
                  }

                  Navigator.pop(dialogContext);
                  _performDeleteProfile();
                },
                child: const Text('Удалить навсегда'),
              ),
            ],
          ),
    );
  }

  Future<void> _performDeleteProfile() async {
    final prefs = await SharedPreferences.getInstance();

    if (_uid.isNotEmpty) {
      try {
        final db = FirebaseDatabase.instance.ref();
        final userSnapshot = await db.child('users/$_uid').get();
        if (userSnapshot.exists && userSnapshot.value != null) {
          final userData = Map<dynamic, dynamic>.from(
            userSnapshot.value as Map,
          );
          final linkedParentUid = userData['linkedParent'];
          if (linkedParentUid != null) {
            await db.child('users/$linkedParentUid/linkedParent').remove();
          }
        }

        await db.child('users/$_uid').remove();
      } catch (e) {
        debugPrint('Ошибка при удалении профиля из БД: $e');
      }

      await prefs.remove('parent_profile_ready_$_uid');
    }

    await prefs.remove('user_type');
    await prefs.remove('user_uid');
    await prefs.remove('user_name');
    await prefs.remove('user_role');
    await prefs.remove('user_birth_date');
    await prefs.remove('user_avatar_hash');
    await prefs.remove('saved_device_uid');
    await prefs.remove('saved_device_pin');

    if (!mounted) return;

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const InitialSessionWrapper()),
      (route) => false,
    );
  }

  void _editTextField({
    required String title,
    required String currentValue,
    required Function(String) onApply,
    bool isPin = false,
    bool obscure = false,
  }) {
    final controller = TextEditingController(text: currentValue);
    showDialog(
      context: context,
      builder:
          (dialogContext) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: Text(title),
            content: TextField(
              controller: controller,
              obscureText: obscure,
              keyboardType: isPin ? TextInputType.number : TextInputType.text,
              inputFormatters:
                  isPin
                      ? [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(4),
                      ]
                      : null,
              decoration: InputDecoration(
                hintText:
                    isPin ? '4 цифры (например, 1234)' : 'Введите значение',
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
                  final val = controller.text.trim();
                  if (isPin && val.isNotEmpty && val.length != 4) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('ПИН-код должен состоять из 4 цифр'),
                      ),
                    );
                    return;
                  }
                  setState(() => onApply(val));
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
      builder:
          (dialogContext) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: const Text('Роль в семье'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children:
                  ['Мама', 'Папа'].map((roleOption) {
                    return ListTile(
                      title: Text(roleOption),
                      trailing:
                          _role == roleOption
                              ? const Icon(Icons.check, color: Colors.blue)
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
      initialDate: DateTime(now.year - 30, 1, 1),
      firstDate: DateTime(1940),
      lastDate: DateTime(now.year - 14),
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
          child: Container(color: Colors.black.withValues(alpha: 0.45)),
        ),
        Scaffold(
          backgroundColor: Colors.transparent,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            automaticallyImplyLeading: false,
            title: const Text(
              'Профиль',
              style: TextStyle(
                color: parentTextPrimary,
                fontSize: 26,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          body:
              _isLoading
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
                                      color: Colors.white.withValues(
                                        alpha: 0.95,
                                      ),
                                      borderRadius: BorderRadius.circular(24),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withValues(
                                            alpha: 0.2,
                                          ),
                                          blurRadius: 15,
                                          offset: const Offset(0, 8),
                                        ),
                                      ],
                                    ),
                                    child: Column(
                                      children: [
                                        Text(
                                          _name.isNotEmpty ? _name : 'Родитель',
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
                                          value:
                                              _name.isNotEmpty
                                                  ? _name
                                                  : 'Не указано',
                                          onTap:
                                              () => _editTextField(
                                                title: 'Изменить имя',
                                                currentValue: _name,
                                                onApply: (v) => _name = v,
                                              ),
                                        ),

                                        _buildProfileRow(
                                          icon: Icons.family_restroom,
                                          title: 'Роль в семье',
                                          value: _role,
                                          onTap: _editRole,
                                        ),

                                        _buildProfileRow(
                                          icon: Icons.cake_outlined,
                                          title: 'Дата рождения',
                                          value:
                                              _birthDate.isNotEmpty
                                                  ? _birthDate
                                                  : 'Не указана',
                                          onTap: _editBirthDate,
                                        ),

                                        const Divider(),

                                        _buildProfileRow(
                                          icon: Icons.alternate_email,
                                          title: 'Логин',
                                          value:
                                              _login.isNotEmpty
                                                  ? _login
                                                  : 'Нажмите, чтобы задать',
                                          highlightEmpty: _login.isEmpty,
                                          onTap:
                                              () => _editTextField(
                                                title: 'Задать логин',
                                                currentValue: _login,
                                                onApply: (v) => _login = v,
                                              ),
                                        ),

                                        _buildProfileRow(
                                          icon: Icons.lock_outline,
                                          title: 'Пароль',
                                          value:
                                              _password.isNotEmpty
                                                  ? '•' * _password.length
                                                  : 'Нажмите, чтобы задать',
                                          highlightEmpty: _password.isEmpty,
                                          onTap:
                                              () => _editTextField(
                                                title: 'Задать пароль',
                                                currentValue: _password,
                                                obscure: true,
                                                onApply: (v) => _password = v,
                                              ),
                                        ),

                                        _buildProfileRow(
                                          icon: Icons.pin_outlined,
                                          title: 'ПИН-код (4 цифры)',
                                          value:
                                              _pin.isNotEmpty
                                                  ? '•••• (установлен)'
                                                  : 'Для быстрого входа',
                                          highlightEmpty: _pin.isEmpty,
                                          onTap:
                                              () => _editTextField(
                                                title: 'Быстрый ПИН-код',
                                                currentValue: _pin,
                                                isPin: true,
                                                onApply: (v) => _pin = v,
                                              ),
                                        ),
                                      ],
                                    ),
                                  ),

                                  // Кликабельный круглый аватар с иконкой камеры
                                  GestureDetector(
                                    onTap: _showAvatarOptions,
                                    child: Stack(
                                      alignment: Alignment.bottomRight,
                                      children: [
                                        UserAvatarWidget(
                                          avatarBase64: _avatarHash,
                                          radius: 48,
                                          fallbackIcon: Icons.person,
                                          fallbackBackgroundColor:
                                              Colors.blue.shade700,
                                          fallbackIconColor: Colors.white,
                                          borderWidth: 4,
                                          borderColor: Colors.white,
                                        ),
                                        Container(
                                          padding: const EdgeInsets.all(6),
                                          decoration: BoxDecoration(
                                            color: Colors.blue.shade800,
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

                          // Ряд кнопок: Назад + СОХРАНИТЬ
                          Row(
                            children: [
                              InkWell(
                                onTap: () => Navigator.pop(context),
                                borderRadius: BorderRadius.circular(30),
                                child: Container(
                                  width: 56,
                                  height: 56,
                                  decoration: BoxDecoration(
                                    color: parentGlassPanel,
                                    borderRadius: BorderRadius.circular(30),
                                    border: Border.all(
                                      color: Colors.white.withValues(
                                        alpha: 0.35,
                                      ),
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
                                    minimumSize: const Size.fromHeight(60),
                                    backgroundColor: parentGlassPanel,
                                    foregroundColor: parentTextPrimary,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(30),
                                      side: BorderSide(
                                        color: Colors.white.withValues(
                                          alpha: 0.3,
                                        ),
                                        width: 1.5,
                                      ),
                                    ),
                                  ),
                                  onPressed: _isSaving ? null : _saveProfile,
                                  child:
                                      _isSaving
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

                          // Отдельная кнопка УДАЛИТЬ ПРОФИЛЬ
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                minimumSize: const Size.fromHeight(60),
                                backgroundColor: parentGlassPanel,
                                foregroundColor: parentTextPrimary,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(30),
                                  side: BorderSide(
                                    color: Colors.white.withValues(alpha: 0.3),
                                    width: 1.5,
                                  ),
                                ),
                              ),
                              icon: const Icon(
                                Icons.delete_forever,
                                color: Colors.redAccent,
                              ),
                              label: const Text(
                                'УДАЛИТЬ ПРОФИЛЬ',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.8,
                                ),
                              ),
                              onPressed: _confirmDeleteProfileWithPassword,
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
