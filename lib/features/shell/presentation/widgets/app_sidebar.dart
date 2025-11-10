import 'package:flutter/material.dart';
import 'package:kabachok_lasalsa_front/features/inbox/presentation/screens/inbox_screen.dart';
import 'package:kabachok_lasalsa_front/features/today/presentation/screens/today_screen.dart';
import 'package:kabachok_lasalsa_front/features/chains/presentation/screens/chains_screen.dart';

class AppSidebar extends StatelessWidget {
  final Function(Widget) onScreenSelected;

  const AppSidebar({super.key, required this.onScreenSelected});

  @override
  Widget build(BuildContext context) {
    // Оборачиваем сайдбар в SizedBox, чтобы задать ему фиксированную ширину
    return SizedBox(
      width: 350, // Ширина сайдбара
      child: Drawer(
        // Drawer - стандартный виджет для таких панелей
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
        child: ListView(
          padding: EdgeInsets.zero,
          children: <Widget>[
            // "Шапка" сайдбара
            const DrawerHeader(
              decoration: BoxDecoration(color: Colors.blue), 
              child: Text(
                'Меню',
                style: TextStyle(color: Colors.white, fontSize: 24),
              ),
            ),
            // Пункт меню "Сегодня"
            ListTile(
              leading: const Icon(Icons.today),
              title: const Text('Сегодня'),
              onTap: () {
                // 2. При нажатии вызываем переданную функцию
                // и передаем в нее экземпляр нужного экрана
                onScreenSelected(const TodayScreen());
              },
            ),
            // Пункт меню "Входящие"
            ListTile(
              leading: const Icon(Icons.inbox),
              title: const Text('Входящие'),
              onTap: () {
                // 3. То же самое для экрана "Входящие"
                onScreenSelected(const InboxScreen());
              },
            ),
            ListTile(
              leading: const Icon(Icons.device_hub),
              title: const Text('Цепочки'),
              onTap: () {
                // 3. То же самое для экрана "Входящие"
                onScreenSelected(const ChainsScreen());
              },
            ),
            // Здесь в будущем будет список проектов...
          ],
        ),
      ),
    );
  }
}
