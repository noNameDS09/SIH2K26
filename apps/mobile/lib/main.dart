import 'package:flutter/material.dart';

import 'ui/language_screen.dart';

void main() {
  runApp(const KalaSetuApp());
}

class KalaSetuApp extends StatelessWidget {
  const KalaSetuApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'KalaSetu',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFF97316),
          brightness: Brightness.light,
        ),
      ),
      home: const LanguageScreen(),
    );
  }
}
