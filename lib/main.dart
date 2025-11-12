// lib/main.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'presentation/screens/coins_list_screen.dart';
import 'data/repositories/coin_repository.dart';
import 'core/theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Hive.initFlutter();

  await _openBoxSafely('favorites');
  await _openBoxSafely('settings');
  await _openBoxSafely('dio_cache');

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => CoinRepository()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

Future<void> _openBoxSafely(String name) async {
  try {
    await Hive.openBox(name);
  } catch (e) {
    print('Corrupted box $name, deleting...');
    await Hive.deleteBoxFromDisk(name);
    await Hive.openBox(name);
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    return MaterialApp(
      title: 'Krypton',
      theme: themeProvider.theme,
      home: const CoinsListScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}