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

  // SAFE OPEN + FORCE DELETE CORRUPTED BOXES
  await _safeOpenBox('favorites');
  await _safeOpenBox('settings');
  await _safeOpenBox('dio_cache');

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

Future<void> _safeOpenBox(String name) async {
  try {
    await Hive.openBox(name);
  } on HiveError catch (e) {
    print('Corrupted $name: $e → Deleting...');
    await Hive.deleteBoxFromDisk(name);
    await Hive.openBox(name);
  } catch (e) {
    print('Failed to open $name: $e → Forcing delete...');
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