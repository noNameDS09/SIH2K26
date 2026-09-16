
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../services/session_provider.dart';

class StudioScreen extends StatefulWidget {
  const StudioScreen({super.key});
  @override
  State<StudioScreen> createState() => _StudioScreenState();
}

class _StudioScreenState extends State<StudioScreen> {
  String _preset = "linen";
  bool _showOriginal = false;

  @override
  Widget build(BuildContext context) {
    final provider = context.read<SessionProvider>();
    final hasOriginal = provider.capturedImageBytes != null;
    final hasEnhanced = provider.enhancedImageBytes != null;
    final imageToShow = _showOriginal ? provider.capturedImageBytes : provider.enhancedImageBytes;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("STAGE 2 — STUDIO ENHANCEMENT", style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF9F3C07))),
              const SizedBox(height: 12),
              Text("Preset: $_preset", style: TextStyle(fontSize: 10, color: Color(0xFF705F58))),
              const SizedBox(height: 8),
              Expanded(
                child: Container(
                  decoration: BoxDecoration(border: Border.all(color: Color(0xFFD9C9C0)), borderRadius: BorderRadius.circular(12)),
                  child: imageToShow != null
                    ? Image.memory(imageToShow, fit: BoxFit.contain)
                    : Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                        Icon(hasEnhanced ? Icons.check_circle_rounded : Icons.image_rounded, size: 48, color: Color(0xFF476430)),
                        SizedBox(height: 12),
                        Text(hasEnhanced ? "Enhanced image (preset: $_preset)" : "No enhanced image yet"),
                      ])),
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: ["linen", "white", "slate", "jute", "wood", "beige"].map((preset) => ChoiceChip(
                  label: Text(preset),
                  selected: _preset == preset,
                  selectedColor: Color(0xFF9F3C07),
                  labelStyle: TextStyle(color: _preset == preset ? Colors.white : Colors.black),
                  onSelected: (selected) => setState(() => _preset = preset),
                )).toList(),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: FilledButton(
                      onPressed: () => setState(() => _showOriginal = !_showOriginal),
                      child: Text(_showOriginal ? "Show Enhanced" : "Show Original"),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => context.go("/live"),
                      child: const Text("Continue to Cataloger"),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
