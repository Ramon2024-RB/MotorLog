import 'package:flutter/material.dart';

import 'screens/dashboard/dashboard_page.dart';

void main() {
  runApp(const MotorLogApp());
}

class MotorLogApp extends StatelessWidget {
  const MotorLogApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'MotorLog',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF176B5B),
          brightness: Brightness.light,
        ),
        useMaterial3: true,
      ),
      home: const DashboardPage(),
    );
  }
}