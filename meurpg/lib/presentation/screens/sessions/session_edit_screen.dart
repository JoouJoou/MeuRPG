import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'session_model.dart';
import 'session_service.dart';

class SessionEditScreen extends StatefulWidget {
  final SessionModel session;

  const SessionEditScreen({super.key, required this.session});

  @override
  State<SessionEditScreen> createState() => _SessionEditScreenState();
}

class _SessionEditScreenState extends State<SessionEditScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _descController;
  DateTime? _selectedDate;
  final _service = SessionService();

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.session.title);
    _descController = TextEditingController(text: widget.session.description);
    _selectedDate = widget.session.date;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Editar Sessão'),
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
                decoration: const InputDecoration(labelText: 'Título'),
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
                label: const Text('Salvar Alterações'),
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
      initialDate: _selectedDate ?? DateTime.now(),
    );

    if (date != null) {
      final time = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(_selectedDate ?? DateTime.now()),
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
      final updatedSession = SessionModel(
        id: widget.session.id,
        title: _titleController.text.trim(),
        description: _descController.text.trim(),
        date: _selectedDate!,
        tableId: widget.session.tableId,
      );

      await _service.updateSession(updatedSession);

      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sessão atualizada com sucesso!')),
      );
    }
  }
}
