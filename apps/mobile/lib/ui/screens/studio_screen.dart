
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';


class StudioScreen extends StatelessWidget {
  const StudioScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFEF8F4),
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.image_rounded, size: 48, color: Color(0xFF9F3C07)),
              const SizedBox(height: 16),
              Text('STAGE 2 — STUDIO ENHANCEMENT', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              Text('Image enhancement with 6 background presets.', style: Theme.of(context).textTheme.bodyMedium),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: () => context.go('/live'),
                child: const Text('Continue to Live Cataloger'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
