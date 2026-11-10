import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'child_qr_display_screen.dart'; // Экран с QR-кодом, создадим его следующим

class AddChildScreen extends StatefulWidget {
  const AddChildScreen({super.key});

  @override
  State<AddChildScreen> createState() => _AddChildScreenState();
}

class _AddChildScreenState extends State<AddChildScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  
  String _selectedRole = 'Сын'; // По умолчанию
  DateTime? _birthDate;
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  /// Выбор даты рождения
  Future<void> _selectBirthDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().subtract(const Duration(days: 365 * 10)), // По умолчанию 10 лет назад
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
        const SnackBar(content: Text('Пожалуйста, выберите дату рождения ребёнка')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final parentUid = FirebaseAuth.instance.currentUser!.uid;
      
      // Создаем уникальный узел для ребенка в базе данных
      final childrenRef = FirebaseDatabase.instance.ref('children').push();
      final childId = childrenRef.key!;

      final childData = {
        'childId': childId,
        'parentUid': parentUid,
        'name': _nameController.text.trim(),
        'familyRole': _selectedRole, // Сын или Дочь
        'birthDate': _birthDate!.toIso8601String(),
        'phone': _phoneController.text.trim(),
        'isLinked': false, // Станет true после того, как ребенок отсканирует QR
        'createdAt': ServerValue.timestamp,
      };

      // Записываем данные ребенка
      await childrenRef.set(childData);

      if (!mounted) return;

      // Переходим на экран отображения QR-кода, передавая туда ID ребенка
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => ChildQrDisplayScreen(
            childId: childId,
            childName: _nameController.text.trim(),
          ),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка при сохранении: $e')),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Добавление ребёнка')),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              const Text(
                'Заполните данные ребёнка для привязки устройства',
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
              const SizedBox(height: 24),
              
              // Имя ребёнка
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Имя ребёнка',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.person),
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
                decoration: const InputDecoration(
                  labelText: 'Роль в семье',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.family_restroom),
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
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Дата рождения',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.calendar_today),
                  ),
                  child: Text(
                    _birthDate == null
                        ? 'Выберите дату'
                        : '${_birthDate!.day}.${_birthDate!.month}.${_birthDate!.year}',
                    style: TextStyle(
                      fontSize: 16,
                      color: _birthDate == null ? Colors.grey : Colors.black,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Номер телефона (опционально)
              TextFormField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: 'Номер телефона (необязательно)',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.phone),
                ),
              ),
              const SizedBox(height: 40),

              // Кнопка продолжения (Генерация QR)
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size.fromHeight(55),
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                ),
                onPressed: _isLoading ? null : _submitChildForm,
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                        'ПРИВЯЗАТЬ УСТРОЙСТВО',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}