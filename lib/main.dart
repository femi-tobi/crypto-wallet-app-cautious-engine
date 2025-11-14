// lib/main.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart';

import 'presentation/screens/coins_list_screen.dart';
import 'data/repositories/coin_repository.dart';
import 'core/theme/app_theme.dart';

final GlobalKey<ScaffoldMessengerState> snackBarKey = GlobalKey<ScaffoldMessengerState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final docsDir = await getApplicationDocumentsDirectory();
  final oldDir = Directory('${docsDir.path}/../app_flutter');
  
  // Selectively delete old files, but preserve coins cache
  if (await oldDir.exists()) {
    try {
      final entries = oldDir.listSync();
      for (var entry in entries) {
        // Don't delete coins.hive or coins.hive.lock
        if (entry is File) {
          final filename = entry.path.split('/').last;
          if (!filename.startsWith('coins')) {
            await entry.delete();
          }
        } else if (entry is Directory) {
          await entry.delete(recursive: true);
        }
      }
    } catch (e) {
      debugPrint('Error cleaning old directory: $e');
    }
  }

  await Hive.initFlutter(docsDir.path);
  await Hive.openBox('favorites');
  await Hive.openBox('settings');
  await Hive.openBox('coins'); // Open coins box here so it persists

  runApp(const MyAppWrapper());
}

class MyAppWrapper extends StatelessWidget {
  const MyAppWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => CoinRepository()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
      ],
      child: const MyApp(),
    );
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return MaterialApp(
      title: 'Crypto Wallet',
      theme: lightTheme,
      darkTheme: darkTheme,
      themeMode: themeProvider.isDark ? ThemeMode.dark : ThemeMode.light,
      home: const CoinsListScreen(),
      debugShowCheckedModeBanner: false,
      scaffoldMessengerKey: snackBarKey,
    );
  }
}