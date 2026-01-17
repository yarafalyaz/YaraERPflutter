import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'config/theme.dart';
import 'providers/auth_provider.dart';
import 'screens/login_screen.dart';
import 'screens/main_screen.dart';

import 'package:intl/date_symbol_data_local.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('id_ID', null);
  
  runApp(
    ChangeNotifierProvider(
      create: (context) => AuthProvider()..init(),
      child: const YaraERPApp(),
    ),
  );
}

class YaraERPApp extends StatelessWidget {
  const YaraERPApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Yara ERP',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      home: const AuthWrapper(),
      routes: {
        '/login': (context) => const LoginScreen(),
        '/dashboard': (context) => const MainScreen(),
      },
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    // Show splash while checking auth status
    if (auth.token == null && auth.isLoading == false) {
      // Check if we have a stored token
      return const LoginScreen();
    }

    return auth.isAuthenticated
        ? const MainScreen()
        : const LoginScreen();
  }
}

