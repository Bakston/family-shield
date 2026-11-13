import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/app_theme.dart';
import '../../parent/screens/parent_panel_screen.dart';
import '../../child/screens/child_join_screen.dart';

// Глобальные дизайн-константы в стиле стекломорфизма
const Color parentGlassPanel = Color(0x33FFFFFF);
const Color parentTextPrimary = Colors.white;

/// Обёртка с фирменным фоном для стартовых экранов
class AppBackgroundWrapper extends StatelessWidget {
  final Widget child;
  final PreferredSizeWidget? appBar;

  const AppBackgroundWrapper({super.key, required this.child, this.appBar});

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
          appBar: appBar,
          body: SafeArea(child: child),
        ),
      ],
    );
  }
}

/// ЭКРАН 1: Главное меню с кнопкой "МОЯ СЕМЬЯ"
class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AppBackgroundWrapper(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Padding(
              padding: EdgeInsets.only(top: 16.0),
              child: Text(
                'FAMILY SHIELD',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: parentTextPrimary,
                  letterSpacing: 3,
                ),
              ),
            ),
            ElevatedButton.icon(
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
              icon: const Icon(Icons.family_restroom, size: 28, color: parentTextPrimary),
              label: const Text(
                'МОЯ СЕМЬЯ',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: parentTextPrimary,
                ),
              ),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const RoleSelectionScreen(),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

/// ЭКРАН 2: Выбор роли с кнопкой ВХОД над кнопками регистрации
class RoleSelectionScreen extends StatelessWidget {
  const RoleSelectionScreen({super.key});

  Future<void> _handleLoginTap(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    final savedUid = prefs.getString('saved_device_uid') ?? '';
    final savedPin = prefs.getString('saved_device_pin') ?? '';

    if (!context.mounted) return;

    if (savedUid.isNotEmpty && savedPin.isNotEmpty) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => PinLoginScreen(
            expectedUid: savedUid,
            expectedPin: savedPin,
          ),
        ),
      );
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const PasswordLoginScreen(),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppBackgroundWrapper(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text('Выбор режима', style: TextStyle(color: parentTextPrimary)),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24.0, 24.0, 24.0, 36.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Padding(
              padding: EdgeInsets.only(top: 16.0),
              child: Text(
                'Кто будет использовать это устройство?',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: parentTextPrimary,
                ),
              ),
            ),
            Column(
              children: [
                // Кнопка ВХОД над кнопками выбора роли
                ElevatedButton.icon(
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
                  icon: const Icon(Icons.login, size: 28, color: parentTextPrimary),
                  label: const Text(
                    'ВХОД',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: parentTextPrimary,
                    ),
                  ),
                  onPressed: () => _handleLoginTap(context),
                ),
                const SizedBox(height: 20),
                const Divider(color: Colors.white24),
                const SizedBox(height: 16),

                // Кнопка регистрации РОДИТЕЛЬ
                ElevatedButton.icon(
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
                  icon: const Icon(Icons.admin_panel_settings, size: 28, color: parentTextPrimary),
                  label: const Text(
                    'РОДИТЕЛЬ',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: parentTextPrimary,
                    ),
                  ),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const ParentRegistrationScreen(),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 16),

                // Кнопка регистрации РЕБЁНОК
                ElevatedButton.icon(
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
                  icon: const Icon(Icons.child_care, size: 28, color: parentTextPrimary),
                  label: const Text(
                    'РЕБЁНОК',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: parentTextPrimary,
                    ),
                  ),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const ChildJoinScreen(),
                      ),
                    );
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// ЭКРАН ВХОДА ПО ПИН-КОДУ (для знакомого устройства)
class PinLoginScreen extends StatefulWidget {
  final String expectedUid;
  final String expectedPin;

  const PinLoginScreen({
    super.key,
    required this.expectedUid,
    required this.expectedPin,
  });

  @override
  State<PinLoginScreen> createState() => _PinLoginScreenState();
}

class _PinLoginScreenState extends State<PinLoginScreen> {
  final TextEditingController _pinController = TextEditingController();
  bool _isChecking = false;

  @override
  void dispose() {
    _pinController.dispose();
    super.dispose();
  }

  Future<void> _verifyPin() async {
    final enteredPin = _pinController.text.trim();
    if (enteredPin != widget.expectedPin) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Неверный ПИН-код')),
      );
      return;
    }

    setState(() => _isChecking = true);

    try {
      final snapshot = await FirebaseDatabase.instance
          .ref('users/${widget.expectedUid}')
          .get();

      if (!snapshot.exists || snapshot.value == null) {
        throw Exception('Профиль не найден в базе данных');
      }

      final data = Map<dynamic, dynamic>.from(snapshot.value as Map);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user_type', 'parent');
      await prefs.setString('user_uid', widget.expectedUid);
      await prefs.setString('user_name', data['name']?.toString() ?? 'Родитель');
      await prefs.setString('user_role', data['familyRole']?.toString() ?? 'Родитель');
      await prefs.setString('user_birth_date', data['birthDate']?.toString() ?? '');

      if (!mounted) return;
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const ParentPanelScreen()),
        (route) => false,
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isChecking = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка входа: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppBackgroundWrapper(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text('Быстрый вход', style: TextStyle(color: parentTextPrimary)),
      ),
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Card(
            elevation: 8,
            color: Colors.white.withValues(alpha: 0.92),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Icon(Icons.lock_open, size: 48, color: Colors.blue),
                  const SizedBox(height: 12),
                  const Text(
                    'Введите ПИН-код',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    controller: _pinController,
                    obscureText: true,
                    textAlign: TextAlign.center,
                    keyboardType: TextInputType.number,
                    style: const TextStyle(fontSize: 24, letterSpacing: 12),
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(4),
                    ],
                    decoration: InputDecoration(
                      hintText: '••••',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size.fromHeight(56),
                      backgroundColor: Colors.blue.shade700,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                    onPressed: _isChecking ? null : _verifyPin,
                    child: _isChecking
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text(
                            'ВОЙТИ',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                  ),
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const PasswordLoginScreen(),
                        ),
                      );
                    },
                    child: const Text('Войти по логину и паролю'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// ЭКРАН АВТОРИЗАЦИИ ПО ЛОГИНУ И ПАРОЛЮ (для нового устройства)
class PasswordLoginScreen extends StatefulWidget {
  const PasswordLoginScreen({super.key});

  @override
  State<PasswordLoginScreen> createState() => _PasswordLoginScreenState();
}

class _PasswordLoginScreenState extends State<PasswordLoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _loginController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _loginController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _loginWithCredentials() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final enteredLogin = _loginController.text.trim();
      final enteredPassword = _passwordController.text.trim();

      final snapshot = await FirebaseDatabase.instance.ref('users').get();
      if (!snapshot.exists || snapshot.value == null) {
        throw Exception('Пользователи не найдены');
      }

      final usersMap = Map<dynamic, dynamic>.from(snapshot.value as Map);
      String? foundUid;
      Map<dynamic, dynamic>? foundUserData;

      usersMap.forEach((key, value) {
        final userData = Map<dynamic, dynamic>.from(value);
        if (userData['login']?.toString() == enteredLogin &&
            userData['password']?.toString() == enteredPassword) {
          foundUid = key.toString();
          foundUserData = userData;
        }
      });

      if (foundUid == null || foundUserData == null) {
        throw Exception('Неверный логин или пароль');
      }

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user_type', 'parent');
      await prefs.setString('user_uid', foundUid!);
      await prefs.setString('saved_device_uid', foundUid!);
      await prefs.setString(
        'user_name',
        foundUserData!['name']?.toString() ?? 'Родитель',
      );
      await prefs.setString(
        'user_role',
        foundUserData!['familyRole']?.toString() ?? 'Родитель',
      );
      await prefs.setString(
        'user_birth_date',
        foundUserData!['birthDate']?.toString() ?? '',
      );

      final userPin = foundUserData!['pin']?.toString() ?? '';
      if (userPin.isNotEmpty) {
        await prefs.setString('saved_device_pin', userPin);
      }

      if (!mounted) return;
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const ParentPanelScreen()),
        (route) => false,
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceAll('Exception: ', ''))),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppBackgroundWrapper(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text('Авторизация', style: TextStyle(color: parentTextPrimary)),
      ),
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Card(
            elevation: 8,
            color: Colors.white.withValues(alpha: 0.92),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      'Вход в аккаунт',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 20),
                    TextFormField(
                      controller: _loginController,
                      decoration: InputDecoration(
                        labelText: 'Логин',
                        prefixIcon: const Icon(Icons.person),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                      validator: (v) =>
                          (v == null || v.trim().isEmpty) ? 'Введите логин' : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _passwordController,
                      obscureText: true,
                      decoration: InputDecoration(
                        labelText: 'Пароль',
                        prefixIcon: const Icon(Icons.lock),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                      validator: (v) =>
                          (v == null || v.trim().isEmpty) ? 'Введите пароль' : null,
                    ),
                    const SizedBox(height: 28),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size.fromHeight(56),
                        backgroundColor: Colors.blue.shade700,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                      onPressed: _isLoading ? null : _loginWithCredentials,
                      child: _isLoading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text(
                              'ВОЙТИ',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// ЭКРАН 3: Анкета Родителя (Имя, Роль: Мама/Папа, Дата рождения, кнопка СОЗДАТЬ)
class ParentRegistrationScreen extends StatefulWidget {
  const ParentRegistrationScreen({super.key});

  @override
  State<ParentRegistrationScreen> createState() =>
      _ParentRegistrationScreenState();
}

class _ParentRegistrationScreenState extends State<ParentRegistrationScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  String _selectedRole = 'Папа';
  DateTime? _selectedBirthDate;
  bool _isSaving = false;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _pickBirthDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedBirthDate ?? DateTime(now.year - 30, 1, 1),
      firstDate: DateTime(1940),
      lastDate: DateTime(now.year - 14),
    );

    if (picked != null && mounted) {
      setState(() {
        _selectedBirthDate = picked;
      });
    }
  }

  String _formatDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    return '$day.$month.${date.year}';
  }

  Future<void> _createParentProfile() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedBirthDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Пожалуйста, укажите дату рождения')),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final newRef = FirebaseDatabase.instance.ref('users').push();
      final String generatedUid =
          newRef.key ?? 'parent_${DateTime.now().millisecondsSinceEpoch}';

      final String name = _nameController.text.trim();
      final String birthDateStr = _formatDate(_selectedBirthDate!);

      await newRef.set({
        'uid': generatedUid,
        'name': name,
        'familyRole': _selectedRole,
        'birthDate': birthDateStr,
        'createdAt': ServerValue.timestamp,
      });

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user_type', 'parent');
      await prefs.setString('user_uid', generatedUid);
      await prefs.setString('saved_device_uid', generatedUid);
      await prefs.setString('user_name', name);
      await prefs.setString('user_role', _selectedRole);
      await prefs.setString('user_birth_date', birthDateStr);
      await prefs.setBool('parent_profile_ready_$generatedUid', true);

      if (!mounted) return;

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const ParentPanelScreen()),
        (route) => false,
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка создания профиля: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppBackgroundWrapper(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text(
          'Анкета родителя',
          style: TextStyle(color: parentTextPrimary),
        ),
      ),
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(5.0),
          child: Card(
            elevation: 8,
            color: Colors.white.withValues(alpha: 0.92),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(30),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      'Создание профиля',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 20),

                    TextFormField(
                      controller: _nameController,
                      decoration: InputDecoration(
                        labelText: 'Ваше имя',
                        prefixIcon: const Icon(Icons.person),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Введите имя';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    DropdownButtonFormField<String>(
                      initialValue: _selectedRole,
                      decoration: InputDecoration(
                        labelText: 'Роль в семье',
                        prefixIcon: const Icon(Icons.supervisor_account),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                      items: const [
                        DropdownMenuItem(value: 'Мама', child: Text('Мама')),
                        DropdownMenuItem(value: 'Папа', child: Text('Папа')),
                      ],
                      onChanged: (value) {
                        if (value != null) {
                          setState(() => _selectedRole = value);
                        }
                      },
                    ),
                    const SizedBox(height: 16),

                    InkWell(
                      onTap: _pickBirthDate,
                      borderRadius: BorderRadius.circular(30),
                      child: InputDecorator(
                        decoration: InputDecoration(
                          labelText: 'Дата рождения',
                          prefixIcon: const Icon(Icons.cake),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                        ),
                        child: Text(
                          _selectedBirthDate == null
                              ? 'Календарь'
                              : _formatDate(_selectedBirthDate!),
                          style: TextStyle(
                            fontSize: 16,
                            color: _selectedBirthDate == null
                                ? Colors.grey.shade600
                                : Colors.black87,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 28),

                    ElevatedButton(
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
                      onPressed: _isSaving ? null : _createParentProfile,
                      child: _isSaving
                          ? const SizedBox(
                              height: 24,
                              width: 24,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: parentTextPrimary,
                              ),
                            )
                          : const Text(
                              'СОЗДАТЬ',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: parentTextPrimary,
                              ),
                            ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}