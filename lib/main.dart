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
    return FutureBuilder(
      future: _initApp(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.done) {
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
        return const MaterialApp(
          home: Scaffold(
            backgroundColor: Color(0xFF0D0D1C),
            body: Center(
              child: CircularProgressIndicator(color: Colors.cyanAccent),
            ),
          ),
        );
      },
    );
  }

  Future<void> _initApp() async {
    // Hive is already initialized above
    return;
  }
}