import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class PricingScreen extends StatelessWidget {
  const PricingScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          const Icon(Icons.mic_rounded, size: 48, color: Color(0xFF9F3C07)),
          const SizedBox(height: 16),
          Text("STAGE 5 — PRICING", style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 24),
          FilledButton(onPressed: () => context.go("/approval"), child: const Text("Continue")),
        ])),
      ),
    );
  }
}
