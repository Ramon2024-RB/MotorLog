import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'core/router/app_router.dart';
import 'services/notification_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://mqcrseazmfytecaxdfdu.supabase.co',
    publishableKey: 'sb_publishable__8OlcDRdF1t-u2H_l-UskQ_bOkcMw3M',
  );

  await NotificationService.instance.initialize();
  await NotificationService.instance.requestPermissions();

  runApp(const ProviderScope(child: MotorLogApp()));
}

class MotorLogApp extends StatelessWidget {
  const MotorLogApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      title: 'MotorLog',
      routerConfig: appRouter,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF176B5B)),
        useMaterial3: true,
      ),
    );
  }
}
