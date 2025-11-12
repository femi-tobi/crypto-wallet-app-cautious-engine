import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'presentation/screens/coins_list_screen.dart';
import 'data/repositories/coin_repository.dart';
import 'core/theme/app_theme.dart'; // ADD THIS

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  await Hive.openBox('favorites');
  await Hive.openBox('settings'); // For settings persistence
  await Hive.openBox('dio_cache');

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