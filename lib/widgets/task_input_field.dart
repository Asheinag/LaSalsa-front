import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class TaskInputField extends StatelessWidget {
  final TextEditingController controller;
  final Function(String, DateTime?) onAdd;
  final DateTime? selectedDate;
  final VoidCallback onSelectDate;

  const TaskInputField({
    super.key,
    required this.controller,
    required this.onAdd,
    this.selectedDate,
    required this.onSelectDate,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              decoration: const InputDecoration(
                hintText: 'Введите новую задачу',
              ),
              onSubmitted: (_) => onAdd(controller.text.trim(), selectedDate),
            ),
          ),
          const SizedBox(width: 8),
          InkWell(
            key: const Key(
              'taskInput.calendar',
            ), // ← добавим ключ для стабильных тестов
            onTap: onSelectDate,
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: selectedDate == null
                  ? const Icon(Icons.calendar_today)
                  : Text(
                      DateFormat('yyyy-MM-dd').format(selectedDate!),
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => onAdd(controller.text.trim(), selectedDate),
          ),
        ],
      ),
    );
  }
}
