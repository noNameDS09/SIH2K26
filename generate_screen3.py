import os

code = """import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../services/session_provider.dart';
import '../../services/api_service.dart';
import '../theme/ks_colors.dart';
import '../theme/ks_text_styles.dart';
import '../widgets/ks_app_header.dart';
import '../widgets/ks_progress_bar.dart';
import '../l10n/ks_strings.dart';
import '../widgets/ks_bottom_nav.dart';

class Screen3Intelligence extends StatefulWidget {
  const Screen3Intelligence({super.key});

  @override
  State<Screen3Intelligence> createState() => _Screen3IntelligenceState();
}

class _Screen3IntelligenceState extends State<Screen3Intelligence> {
  final Map<String, TextEditingController> _controllers = {};
  
  final TextEditingController _titleEnCtrl = TextEditingController();
  final TextEditingController _titleHiCtrl = TextEditingController();
  final TextEditingController _descEnCtrl = TextEditingController();
  final TextEditingController _descHiCtrl = TextEditingController();

  bool _isDirty = false;
  bool _isSaving = false;

  static const _editableFields = [
    {'key': 'craft', 'label': 'Craft', 'type': 'text'},
    {'key': 'material', 'label': 'Material', 'type': 'text'},
    {'key': 'technique', 'label': 'Technique', 'type': 'text'},
    {'key': 'colour', 'label': 'Colour', 'type': 'text'},
    {'key': 'occasion', 'label': 'Occasion', 'type': 'text'},
    {'key': 'gi', 'label': 'GI status', 'type': 'text'},
    {'key': 'hours', 'label': 'Hours of work', 'type': 'number'},
    {'key': 'material_cost_inr', 'label': 'Material cost (₹)', 'type': 'number'},
    {'key': 'material_source', 'label': 'Material source', 'type': 'text'},
    {'key': 'effort', 'label': 'Effort', 'type': 'text'},
  ];

  @override
  void initState() {
    super.initState();
    for (var f in _editableFields) {
      _controllers[f['key']!] = TextEditingController();
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  void _loadData() {
    final provider = context.read<SessionProvider>();
    final listing = provider.listing;
    if (listing == null) return;
    
    _titleEnCtrl.text = listing['title_en'] ?? '';
    _titleHiCtrl.text = listing['title_hi'] ?? '';
    _descEnCtrl.text = listing['desc_en'] ?? listing['description'] ?? '';
    _descHiCtrl.text = listing['desc_hi'] ?? '';

    final fields = listing['fields'] as Map<String, dynamic>? ?? {};
    for (var f in _editableFields) {
      final key = f['key']!;
      final val = fields[key];
      if (val is List) {
        _controllers[key]!.text = val.join(', ');
      } else {
        _controllers[key]!.text = val?.toString() ?? '';
      }
    }
    
    // Add listener to mark dirty
    void markDirty() {
      if (!_isDirty) setState(() => _isDirty = true);
    }
    _titleEnCtrl.addListener(markDirty);
    _titleHiCtrl.addListener(markDirty);
    _descEnCtrl.addListener(markDirty);
    _descHiCtrl.addListener(markDirty);
    for (var c in _controllers.values) {
      c.addListener(markDirty);
    }
    setState(() => _isDirty = false);
  }

  @override
  void dispose() {
    _titleEnCtrl.dispose();
    _titleHiCtrl.dispose();
    _descEnCtrl.dispose();
    _descHiCtrl.dispose();
    for (var c in _controllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  int get _completeCount {
    int count = 0;
    for (var c in _controllers.values) {
      if (c.text.trim().isNotEmpty) count++;
    }
    return count;
  }

  Future<void> _saveDraft() async {
    final provider = context.read<SessionProvider>();
    final listing = provider.listing;
    if (listing == null || _isSaving) return;

    setState(() => _isSaving = true);
    
    final currentFields = listing['fields'] as Map<String, dynamic>? ?? {};
    final nextFields = Map<String, dynamic>.from(currentFields);
    
    for (var f in _editableFields) {
      final key = f['key']!;
      final raw = _controllers[key]!.text.trim();
      
      if (key == 'colour') {
        nextFields[key] = raw.isNotEmpty ? raw.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList() : [];
      } else if (f['type'] == 'number') {
        nextFields[key] = raw.isNotEmpty ? num.tryParse(raw) : null;
      } else {
        nextFields[key] = raw.isNotEmpty ? raw : null;
      }
    }

    try {
      if (provider.listingId != null) {
        final updated = await ApiService.patchListing(provider.listingId!, {
          'fields': nextFields,
          'title_en': _titleEnCtrl.text.trim(),
          'title_hi': _titleHiCtrl.text.trim(),
          'desc_en': _descEnCtrl.text.trim(),
          'desc_hi': _descHiCtrl.text.trim(),
        });
        provider.listing = updated;
      }
      if (mounted) {
        setState(() => _isDirty = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Draft changes saved.'), backgroundColor: KsColors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving draft: \$e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Widget _buildTextField(String label, TextEditingController controller, {int maxLines = 1, TextInputType? keyboardType}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: KsTextStyles.label()),
          const SizedBox(height: 6),
          TextField(
            controller: controller,
            maxLines: maxLines,
            keyboardType: keyboardType,
            style: KsTextStyles.body(),
            decoration: InputDecoration(
              filled: true,
              fillColor: KsColors.surfaceWarm,
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide.none,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<SessionProvider>();
    final listing = provider.listing;
    final ks = KsStrings.of(context);
    final imageBytes = provider.enhancedImageBytes ?? provider.capturedImageBytes;
    
    final currentTitle = _titleEnCtrl.text.isNotEmpty 
      ? _titleEnCtrl.text 
      : _titleHiCtrl.text.isNotEmpty ? _titleHiCtrl.text : "Untitled product";
      
    final currentDesc = _descEnCtrl.text.isNotEmpty
      ? _descEnCtrl.text
      : _descHiCtrl.text.isNotEmpty ? _descHiCtrl.text : "The confirmed product story will appear here.";

    return Scaffold(
      backgroundColor: KsColors.background,
      appBar: KsAppHeader(
        title: 'Step 4 · Review',
        onBack: () => context.go('/live'), // Adjust route as necessary based on your nav
      ),
      body: listing == null
          ? const Center(child: CircularProgressIndicator(color: KsColors.terracotta))
          : SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 16),
                  const KsProgressBar(totalSteps: 7, currentStep: 4, label: 'STAGE 4 — CRAFT INTELLIGENCE'),
                  const SizedBox(height: 24),
                  
                  // Intro section
                  Row(
                    children: [
                      Expanded(child: Text('Check every product detail', style: KsTextStyles.editorial(size: 24))),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: _isDirty ? KsColors.peach3 : KsColors.paleGreen,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(_isDirty ? 'Unsaved changes' : 'Draft saved', 
                          style: KsTextStyles.label(color: _isDirty ? KsColors.terracotta : KsColors.deepGreen, size: 10)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text('Nothing saves while you type. Use the explicit save action when the draft is accurate.', style: KsTextStyles.body()),
                  const SizedBox(height: 24),

                  // Draft Preview Card
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: KsColors.surface1,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (imageBytes != null)
                          ClipRRect(
                            borderRadius: BorderRadius.circular(11),
                            child: Image.memory(imageBytes, height: 160, width: double.infinity, fit: BoxFit.cover),
                          ),
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(color: KsColors.peach3, borderRadius: BorderRadius.circular(4)),
                          child: Text('Draft preview', style: KsTextStyles.label(color: KsColors.terracotta, size: 10)),
                        ),
                        const SizedBox(height: 8),
                        Text(currentTitle, style: KsTextStyles.section),
                        const SizedBox(height: 6),
                        Text(currentDesc, style: KsTextStyles.body()),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            const Icon(Icons.history_edu, size: 16, color: KsColors.brown3),
                            const SizedBox(width: 6),
                            Text('Draft source', style: KsTextStyles.label(color: KsColors.brown3)),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Form Section
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: KsColors.peach3),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Progress
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Catalog details', style: KsTextStyles.bodyMedium()),
                            Text('\$_completeCount of ${_editableFields.length} completed', style: KsTextStyles.label()),
                          ],
                        ),
                        const SizedBox(height: 8),
                        LinearProgressIndicator(
                          value: _completeCount / _editableFields.length,
                          backgroundColor: KsColors.surfaceWarm,
                          color: KsColors.terracotta,
                          minHeight: 6,
                          borderRadius: BorderRadius.circular(3),
                        ),
                        const SizedBox(height: 24),

                        // Bilingual public card
                        Text('Bilingual public card', style: KsTextStyles.section),
                        const SizedBox(height: 16),
                        _buildTextField('English title', _titleEnCtrl),
                        _buildTextField('Hindi title', _titleHiCtrl),
                        _buildTextField('English description', _descEnCtrl, maxLines: 4),
                        _buildTextField('Hindi description', _descHiCtrl, maxLines: 4),
                        
                        const SizedBox(height: 24),
                        
                        // Product and costing fields
                        Text('Product and costing fields', style: KsTextStyles.section),
                        const SizedBox(height: 16),
                        ..._editableFields.map((f) => _buildTextField(
                          f['label']!, 
                          _controllers[f['key']]!,
                          keyboardType: f['type'] == 'number' ? TextInputType.number : TextInputType.text
                        )),

                        const SizedBox(height: 16),
                        
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton.icon(
                            onPressed: (!_isDirty || _isSaving) ? null : _saveDraft,
                            icon: _isSaving ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Icon(Icons.check),
                            label: Text(_isSaving ? 'Saving changes...' : 'Save draft changes'),
                            style: FilledButton.styleFrom(
                              backgroundColor: KsColors.terracotta,
                              disabledBackgroundColor: KsColors.terracotta.withOpacity(0.5),
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Actions
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: () => context.go('/live'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        side: const BorderSide(color: KsColors.terracotta),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      child: Text('Add more by voice', style: KsTextStyles.bodyMedium(color: KsColors.terracotta)),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: (_isDirty || _isSaving) ? null : () => context.go('/pricing'),
                      icon: const Icon(Icons.arrow_forward),
                      label: const Text('Continue to pricing'),
                      style: FilledButton.styleFrom(
                        backgroundColor: KsColors.terracotta,
                        disabledBackgroundColor: KsColors.terracotta.withOpacity(0.5),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
    );
  }
}
"""

with open('apps/mobile/lib/ui/screens/screen3_intelligence.dart', 'w') as f:
    f.write(code)
