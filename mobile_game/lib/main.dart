import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/router.dart';
import 'app/theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const ProviderScope(child: DungeonMindApp()));
}

class DungeonMindApp extends ConsumerWidget {
  const DungeonMindApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: 'DungeonMind',
      theme: dungeonTheme,
      routerConfig: router,
      debugShowCheckedModeBanner: false,
    );
  }
}
