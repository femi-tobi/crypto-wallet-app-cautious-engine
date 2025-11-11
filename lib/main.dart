import 'dart:io';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';

import 'core/utils/theme.dart';
import 'data/repositories/coin_repository.dart';
import 'presentation/screens/coins_list_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  await Hive.openBox('favorites');
  runApp(const KryptonApp());
}

class KryptonApp extends StatelessWidget {
  const KryptonApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => CoinRepository()..fetchCoins(),
      child: MaterialApp(
        title: 'Krypton',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.darkTheme,
        home: const CoinsListScreen(),
      ),
    );
  }
}