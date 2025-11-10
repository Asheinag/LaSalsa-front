import 'package:flutter/material.dart';

class QuickAddTaskBar extends StatefulWidget {
  // Callback-функция, которая "отдаст наверх" имя новой задачи
  final Function(String taskName) onTaskSubmitted;

  const QuickAddTaskBar({super.key, required this.onTaskSubmitted});

  @override
  State<QuickAddTaskBar> createState() => _QuickAddTaskBarState();
}

class _QuickAddTaskBarState extends State<QuickAddTaskBar> {
  final _textController = TextEditingController();

  void _submit() {
    final text = _textController.text.trim();
    if (text.isEmpty) {
      return; // Не отправляем пустую задачу
    }

    widget.onTaskSubmitted(text); // Вызываем callback
    _textController.clear(); // Очищаем поле ввода
    FocusScope.of(context).unfocus(); // Прячем клавиатуру
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Material используется для корректного отображения теней и цвета фона
    return Material(
      elevation: 8.0, // Небольшая тень сверху
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
        child: Row(
          children: [
            // Поле ввода будет занимать всё доступное место
            Expanded(
              child: TextField(
                controller: _textController,
                autofocus: true,
                decoration: const InputDecoration(
                  hintText: 'Новая задача...',
                  border: InputBorder.none, // Убираем рамку
                ),
                onSubmitted: (_) => _submit(),
              ),
            ),
            // Кнопка для отправки
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
