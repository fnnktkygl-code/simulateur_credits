import 'package:flutter/material.dart';
import 'theme/app_theme.dart';
import 'screens/home_screen.dart';

void main() => runApp(const SimulateurApp());

class SimulateurApp extends StatelessWidget {
  const SimulateurApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Simulateur de Crédits',
      debugShowCheckedModeBanner: false,
      theme: SimTheme.theme,
      home: const HomeScreen(),
    );
  }
}
