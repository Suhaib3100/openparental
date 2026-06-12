import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'screens/home_screen.dart';
import 'screens/login_screen.dart';
import 'state/providers.dart';

void main() {
  runApp(const ProviderScope(child: MoniiParentApp()));
}

class MoniiParentApp extends StatelessWidget {
  const MoniiParentApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'monii',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorSchemeSeed: const Color(0xFF3B82F6),
        useMaterial3: true,
      ),
      home: const RootView(),
    );
  }
}

class RootView extends ConsumerWidget {
  const RootView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authProvider);
    if (auth.loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    return auth.loggedIn ? const HomeScreen() : const LoginScreen();
  }
}
