import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'child_qr_display_screen.dart';

// Глобальные дизайн-константы
const Color parentGlassPanel = Color(0x33FFFFFF);
const Color parentTextPrimary = Colors.white;

class AddChildScreen extends StatefulWidget {
  const AddChildScreen({super.key});

  @override
  State<AddChildScreen> createState() => _AddChildScreenState();
}

class _AddChildScreenState extends State<AddChildScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();

  String _selectedRole = 'Сын'; // По умолчанию
  DateTime? _birthDate;
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  /// Выбор даты рождения
  Future<void> _selectBirthDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().subtract(
        const Duration(days: 365 * 10),
      ), // 10 лет назад
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        _birthDate = picked;
      });
    }
  }

  /// Сохранение данных ребенка в БД и переход к генерации QR-кода
  Future<void> _submitChildForm() async {
    if (!_formKey.currentState!.validate()) return;
    if (_birthDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Пожалуйста, выберите дату рождения ребёнка'),
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      final parentUid = prefs.getString('user_uid');

      if (parentUid == null || parentUid.isEmpty) {
        throw Exception('Не найден UID родителя в локальной сессии');
      }

      // Создаем уникальный узел для ребенка в базе данных
      final childrenRef = FirebaseDatabase.instance.ref('children').push();
      final childId = childrenRef.key!;

      final childData = {
        'childId': childId,
        'parentUid': parentUid,
        'name': _nameController.text.trim(),
        'familyRole': _selectedRole, // Сын или Дочь
        'birthDate': _birthDate!.toIso8601String(),
        'isLinked': false, // Станет true после того, как ребенок отсканирует QR
        'createdAt': ServerValue.timestamp,
      };

      // Записываем данные ребенка
      await childrenRef.set(childData);

      if (!mounted) return;

      // Переходим на экран отображения QR-кода
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder:
              (context) => ChildQrDisplayScreen(
                childId: childId,
                childName: _nameController.text.trim(),
              ),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Ошибка при сохранении: $e')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // 1. Фирменный фоновый рисунок
        Positioned.fill(
          child: Image.asset(
            'assets/images/background_0002_001.jpg',
            fit: BoxFit.cover,
          ),
        ),
        // 2. Затемняющая вуаль
        Positioned.fill(
          child: Container(color: Colors.black.withValues(alpha: 0.45)),
        ),
        // 3. Основной контент экрана
        Scaffold(
          backgroundColor: Colors.transparent,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            iconTheme: const IconThemeData(color: parentTextPrimary),
            title: const Text(
              'Добавление ребёнка',
              style: TextStyle(
                color: parentTextPrimary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          body: Padding(
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
                  child: ListView(
                    shrinkWrap: true,
                    children: [
                      const Text(
                        'Заполните данные ребёнка для привязки устройства',
                        style: TextStyle(fontSize: 15, color: Colors.black54),
                      ),
                      const SizedBox(height: 24),

                      // Имя ребёнка
                      TextFormField(
                        controller: _nameController,
                        decoration: InputDecoration(
                          labelText: 'Имя ребёнка',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                          prefixIcon: const Icon(Icons.person),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Введите имя ребёнка';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 20),

                      // Выбор роли (Сын / Дочь)
                      DropdownButtonFormField<String>(
                        initialValue: _selectedRole,
                        decoration: InputDecoration(
                          labelText: 'Роль в семье',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                          prefixIcon: const Icon(Icons.family_restroom),
                        ),
                        items: const [
                          DropdownMenuItem(value: 'Сын', child: Text('Сын')),
                          DropdownMenuItem(value: 'Дочь', child: Text('Дочь')),
                        ],
                        onChanged: (value) {
                          if (value != null) {
                            setState(() => _selectedRole = value);
                          }
                        },
                      ),
                      const SizedBox(height: 20),

                      // Выбор даты рождения
                      InkWell(
                        onTap: () => _selectBirthDate(context),
                        borderRadius: BorderRadius.circular(30),
                        child: InputDecorator(
                          decoration: InputDecoration(
                            labelText: 'Дата рождения',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                            prefixIcon: const Icon(Icons.calendar_today),
                          ),
                          child: Text(
                            _birthDate == null
                                ? 'Календарь'
                                : '${_birthDate!.day}.${_birthDate!.month}.${_birthDate!.year}',
                            style: TextStyle(
                              fontSize: 16,
                              color:
                                  _birthDate == null
                                      ? Colors.grey.shade600
                                      : Colors.black87,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 32),

                      // Кнопка продолжения (Генерация QR) с капсульным скруглением
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
                        onPressed: _isLoading ? null : _submitChildForm,
                        child:
                            _isLoading
                                ? const SizedBox(
                                  height: 24,
                                  width: 24,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                                : const Text(
                                  'ДОБАВИТЬ РЕБЁНКА',
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
      ],
    );
  }
}
