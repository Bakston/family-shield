import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../core/services/database_service.dart';
import 'parent_panel_screen.dart';

class ParentRegistrationScreen extends StatefulWidget {
  final String phone;
  const ParentRegistrationScreen({super.key, required this.phone});

  @override
  State<ParentRegistrationScreen> createState() => _ParentRegistrationScreenState();
}

class _ParentRegistrationScreenState extends State<ParentRegistrationScreen> {
  final _nameController = TextEditingController();
  String _familyRole = 'Мама'; 
  DateTime? _birthDate;

  final DatabaseService _databaseService = DatabaseService();

  Future<void> _selectBirthDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime(1990, 1, 1),
      firstDate: DateTime(1950),
      lastDate: DateTime.now(),
    );
    if (!context.mounted) return;
    if (picked != null && picked != _birthDate) {
      setState(() {
        _birthDate = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Заполнение профиля')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Имя',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              initialValue: _familyRole,
              items: const [
                DropdownMenuItem(value: 'Мама', child: Text('Мама')),
                DropdownMenuItem(value: 'Папа', child: Text('Папа')),
              ],
              onChanged: (val) => setState(() => _familyRole = val!),
              decoration: const InputDecoration(
                labelText: 'Кто вы в семье?',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            
            // Выбор даты рождения
            InkWell(
              onTap: () => _selectBirthDate(context),
              child: InputDecorator(
                decoration: const InputDecoration(
                  labelText: 'Дата рождения',
                  border: OutlineInputBorder(),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _birthDate == null
                          ? 'Выберите дату рождения'
                          : '${_birthDate!.day}.${_birthDate!.month}.${_birthDate!.year}',
                      style: TextStyle(
                        color: _birthDate == null ? Colors.grey[600] : Colors.black,
                      ),
                    ),
                    const Icon(Icons.calendar_today),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 32),
            ElevatedButton(
              style: ElevatedButton.styleFrom(minimumSize: const Size.fromHeight(50)),
              onPressed: () async {
                final user = FirebaseAuth.instance.currentUser;
                if (user != null) {
                  await _databaseService.saveParentProfile(
                    uid: user.uid,
                    phone: widget.phone,
                    name: _nameController.text,
                    familyRole: _familyRole,
                    birthDate: _birthDate?.toIso8601String(),
                  );
                }

                if (!context.mounted) return;

                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (context) => const ParentPanelScreen()),
                  (route) => false,
                );
              },
              child: const Text('СОХРАНИТЬ И ВОЙТИ'),
            ),
          ],
        ),
      ),
    );
  }
}