import 'package:flutter/material.dart';
import 'ui/outward/outward_distribution_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Kala Setu',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF9A5B32),
        ),
        useMaterial3: true,
      ),
      home: const OutwardDistributionScreen(),
    );
  }
}