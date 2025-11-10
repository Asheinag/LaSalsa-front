import 'package:flutter/material.dart';

class ChainsScreen extends StatelessWidget {
  const ChainsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Цепочки задач'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: const Center(
        child: Text('Здесь будет граф всех связаных задач'),
      ),
    );
  }
}