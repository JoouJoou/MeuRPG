import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'session_model.dart';
import 'session_service.dart';
import '/models/user_model.dart';

class SessionCreateScreen extends StatefulWidget {
  final UserModel user;
  final String tableId;

  const SessionCreateScreen({
    super.key,
    required this.user,
    required this.tableId,
  });

  @override
  State<SessionCreateScreen> createState() => _SessionCreateScreenState();
}

class _SessionCreateScreenState extends State<SessionCreateScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  DateTime? _selectedDate;

  final _service = SessionService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Criar Sessão'),
        backgroundColor: Colors.red.shade700,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Título da Sessão',
                ),
                validator:
                    (value) => value!.isEmpty ? 'Informe o título' : null,
              ),
              TextFormField(
                controller: _descController,
                decoration: const InputDecoration(labelText: 'Descrição'),
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Text(
                    _selectedDate == null
                        ? 'Selecione a data'
                        : DateFormat(
                          'dd/MM/yyyy – HH:mm',
                        ).format(_selectedDate!),
                  ),
                  const Spacer(),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.calendar_today),
                    label: const Text('Escolher'),
                    onPressed: _pickDateTime,
                  ),
                ],
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                icon: const Icon(Icons.save),
                label: const Text('Salvar Sessão'),
                onPressed: _submitForm,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pickDateTime() async {
    final date = await showDatePicker(
      context: context,
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
      initialDate: DateTime.now(),
    );

    if (date != null) {
      final time = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.now(),
      );

      if (time != null) {
        setState(() {
          _selectedDate = DateTime(
            date.year,
            date.month,
            date.day,
            time.hour,
            time.minute,
          );
        });
      }
    }
  }

  Future<void> _submitForm() async {
    if (_formKey.currentState!.validate() && _selectedDate != null) {
      final session = SessionModel(
        id: '', // será gerado no service
        title: _titleController.text.trim(),
        description: _descController.text.trim(),
        date: _selectedDate!,
        tableId: widget.tableId,
      );

      await _service.createSession(session);

      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sessão criada com sucesso!')),
      );
    }
  }
}
