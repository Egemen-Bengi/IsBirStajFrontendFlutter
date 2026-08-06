import 'package:flutter/material.dart';
import 'package:is_bir_staj_app/screens/scanner_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const EnvanterApp());
}

class EnvanterApp extends StatelessWidget {
  const EnvanterApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Envanter Sistemi',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const TextScannerScreen(),
    );
  }
}