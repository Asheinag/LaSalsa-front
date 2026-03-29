import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class QuickAddTaskBar extends StatefulWidget {
  final Function(String, DateTime?) onTaskSubmitted;
  final String? initialValue;
  final DateTime? initialDate;

  const QuickAddTaskBar({
    super.key,
    required this.onTaskSubmitted,
    this.initialValue,
    this.initialDate,
  });

  @override
  State<QuickAddTaskBar> createState() => _QuickAddTaskBarState();
}

class _QuickAddTaskBarState extends State<QuickAddTaskBar> {
  late final TextEditingController _textController;
  late final FocusNode _focusNode;
  DateTime? _selectedDate;

  @override
  void initState() {
    super.initState();
    _textController = TextEditingController(text: widget.initialValue);
    _focusNode = FocusNode();
    _selectedDate = widget.initialDate;
  }

  void _submit() {
    final text = _textController.text.trim();
    if (text.isEmpty) {
      return;
    }

    widget.onTaskSubmitted(text, _selectedDate);
    _textController.clear();
    _focusNode.requestFocus();
  }

  @override
  void dispose() {
    _textController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  void _clearDate() {
    setState(() {
      _selectedDate = null;
    });
  }

  Widget _buildDateWidget() {
    if (_selectedDate == null) {
      return IconButton(
        icon: const Icon(Icons.calendar_today_outlined),
        onPressed: _selectDate,
        tooltip: 'Выбрать дату',
      );
    } else {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextButton(
            onPressed: _selectDate,
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              visualDensity: VisualDensity.compact,
            ),
            child: Text(DateFormat('dd.MM').format(_selectedDate!)),
          ),
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: _clearDate,
            tooltip: 'Очистить дату',
            iconSize: 16,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 8.0,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 4, 8, 4),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _textController,
                focusNode: _focusNode,
                autofocus: true,
                decoration: const InputDecoration(
                  hintText: 'Новая задача...',
                  border: InputBorder.none,
                ),
                onSubmitted: (_) => _submit(),
              ),
            ),
            _buildDateWidget(),
            const SizedBox(width: 8),
            IconButton(
              icon: const Icon(Icons.add_circle_outline),
              onPressed: _submit,
              tooltip: 'Добавить задачу',
            ),
          ],
        ),
      ),
    );
  }
}
