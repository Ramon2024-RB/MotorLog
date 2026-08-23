import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'core/database/app_database.dart';
import 'core/router/app_router.dart';
import 'services/notification_service.dart';
import 'services/theme_provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://mqcrseazmfytecaxdfdu.supabase.co',
    publishableKey: 'sb_publishable__8OlcDRdF1t-u2H_l-UskQ_bOkcMw3M',
  );

  await AppDatabase.instance.initializeForCurrentUser();

  await NotificationService.instance.initialize();
  await NotificationService.instance.requestPermissions();

  runApp(const MotorLogRoot());
}

class MotorLogRoot extends StatefulWidget {
  const MotorLogRoot({super.key});

  @override
  State<MotorLogRoot> createState() => _MotorLogRootState();
}

class _MotorLogRootState extends State<MotorLogRoot> {
  late final StreamSubscription<AuthState> _authSubscription;

  String? _userId;

  @override
  void initState() {
    super.initState();

    _userId = Supabase.instance.client.auth.currentUser?.id;

    _authSubscription = Supabase.instance.client.auth.onAuthStateChange.listen((
      data,
    ) {
      final newUserId = data.session?.user.id;

      if (newUserId == _userId) {
        return;
      }

      setState(() {
        _userId = newUserId;
      });
    });
  }

  @override
  void dispose() {
    _authSubscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ProviderScope(key: ValueKey(_userId), child: const MotorLogApp());
  }
}

class MotorLogApp extends ConsumerWidget {
  const MotorLogApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeAsync = ref.watch(themeProvider);

    final themeMode = themeAsync.value ?? ThemeMode.system;

    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      title: 'MotorLog',
      routerConfig: appRouter,
      themeMode: themeMode,

      // -----------------------------------------------------------------------
      // HELLES DESIGN
      // -----------------------------------------------------------------------
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF176B5B),
          brightness: Brightness.light,
        ),
        useMaterial3: true,
      ),

      // -----------------------------------------------------------------------
      // DUNKLES DESIGN
      // -----------------------------------------------------------------------
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF176B5B),
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
    );
  }
}
