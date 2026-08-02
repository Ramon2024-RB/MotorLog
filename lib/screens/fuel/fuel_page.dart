import 'package:flutter/material.dart';

class FuelPage extends StatelessWidget {
  const FuelPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tankvorgänge'),
      ),
      body: const Center(
        child: Text(
          'Noch keine Tankvorgänge vorhanden',
          style: TextStyle(fontSize: 17),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {},
        icon: const Icon(Icons.add),
        label: const Text('Tanken'),
      ),
    );
  }
}