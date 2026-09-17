
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../services/session_provider.dart';
import '../../services/api_service.dart';
import '../theme/ks_colors.dart';
import '../theme/ks_text_styles.dart';
import '../widgets/ks_app_header.dart';
import '../widgets/ks_progress_bar.dart';
import '../routes/app_routes.dart';



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
  bool _loading = true;
  String? _error;

  static const _editableFields = [
    {'key': 'craft', 'label': 'Craft', 'type': 'text', 'icon': Icons.brush_outlined},
    {'key': 'material', 'label': 'Material', 'type': 'text', 'icon': Icons.category_outlined},
    {'key': 'technique', 'label': 'Technique', 'type': 'text', 'icon': Icons.handyman_outlined},
    {'key': 'colour', 'label': 'Colour', 'type': 'text', 'icon': Icons.palette_outlined},
    {'key': 'occasion', 'label': 'Occasion', 'type': 'text', 'icon': Icons.festival_outlined},
    {'key': 'gi', 'label': 'GI status', 'type': 'text', 'icon': Icons.verified_outlined},
    {'key': 'hours', 'label': 'Hours of work', 'type': 'number', 'icon': Icons.timer_outlined},
    {'key': 'material_cost_inr', 'label': 'Material cost (₹)', 'type': 'number', 'icon': Icons.currency_rupee_outlined},
    {'key': 'material_source', 'label': 'Material source', 'type': 'text', 'icon': Icons.place_outlined},
    {'key': 'effort', 'label': 'Effort', 'type': 'text', 'icon': Icons.hardware_outlined},
  ];

  @override
  void initState() {
    super.initState();
    for (var f in _editableFields) {
      _controllers[f['key'] as String] = TextEditingController();
    }
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadData());
  }

  Future<void> _loadData() async {
    final provider = context.read<SessionProvider>();
    final id = provider.listingId;
    if (id == null || id.isEmpty) {
      if (mounted) setState(() { _loading = false; _error = 'No product draft found. Start by capturing a product.'; });
      return;
    }
    try {
      var fetched = await ApiService.getListing(id);
      
      // If the listing has no title and very few fields, trigger the AI prediction (LLM)
      final currentFields = (fetched['fields'] as Map<String, dynamic>?) ?? {};
      final hasTitle = (fetched['title_en'] as String?)?.isNotEmpty == true || (fetched['title_hi'] as String?)?.isNotEmpty == true;
      if (!hasTitle && currentFields.length < 3) {
        if (mounted) setState(() { _loading = true; });
        // Force the backend to generate the listing copy using Gemini LLM
        final generated = await ApiService.generateListingCopy(id);
        if (generated.isNotEmpty) {
          fetched = generated;
        }
      }

      if (!mounted) return;
      provider.listing = fetched;
      _titleEnCtrl.text = (fetched['title_en'] as String?) ?? '';
      _titleHiCtrl.text = (fetched['title_hi'] as String?) ?? '';
      _descEnCtrl.text = (fetched['desc_en'] as String?) ?? (fetched['description'] as String?) ?? '';
      _descHiCtrl.text = (fetched['desc_hi'] as String?) ?? '';
      
      final fields = (fetched['fields'] as Map<String, dynamic>?) ?? {};
      for (var f in _editableFields) {
        final key = f['key'] as String;
        final val = fields[key];
        if (val is List) {
          _controllers[key]!.text = val.join(', ');
        } else {
          _controllers[key]!.text = val?.toString() ?? '';
        }
      }
      setState(() => _loading = false);
    } catch (e) {
      if (mounted) setState(() { _loading = false; _error = 'Could not load product draft.'; });
    }
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
    if (_isSaving) return;

    setState(() => _isSaving = true);
    
    final currentFields = provider.listing?['fields'] as Map<String, dynamic>? ?? {};
    final nextFields = Map<String, dynamic>.from(currentFields);
    
    for (var f in _editableFields) {
      final key = f['key'] as String;
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
          SnackBar(content: Text('Error saving draft: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _markDirty() {
    if (!_isDirty) setState(() => _isDirty = true);
  }

  Widget _buildTextField(String label, TextEditingController controller, {int maxLines = 1, TextInputType? keyboardType, IconData? icon}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (icon != null) ...[Icon(icon, size: 16, color: KsColors.terracotta), const SizedBox(width: 6)],
              Text(label, style: KsTextStyles.label(color: KsColors.ink, size: 14)),
            ],
          ),
          const SizedBox(height: 8),
          TextField(
            controller: controller,
            maxLines: maxLines,
            keyboardType: keyboardType,
            style: KsTextStyles.body(color: KsColors.ink).copyWith(fontSize: 16),
            onChanged: (_) => _markDirty(),
            decoration: InputDecoration(
              filled: true,
              fillColor: KsColors.surfaceWarm,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: KsColors.border),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: KsColors.border),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: KsColors.terracotta, width: 2),
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

    return Scaffold(
      backgroundColor: KsColors.background,
      extendBodyBehindAppBar: true,
      appBar: KsAppHeader(
        title: 'Step 4 · Review',
        onBack: () => context.pop(),
      ),
      body: Stack(
        children: [
          SafeArea(child: _buildBody(provider)),
        ],
      ),
    );
  }

  Widget _buildBody(SessionProvider provider) {
    // Loading state
    if (_loading) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(color: KsColors.terracotta, strokeWidth: 3.0),
            SizedBox(height: 24),
            Text('AI is analyzing your product…', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: KsColors.ink)),
            SizedBox(height: 8),
            Text('Generating details in English and Hindi', style: TextStyle(fontSize: 14, color: KsColors.textSecondary)),
          ],
        ),
      );
    }

    // Error / empty state
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.description_outlined, size: 48, color: KsColors.textMuted),
              const SizedBox(height: 16),
              Text('No draft to review', style: KsTextStyles.section),
              const SizedBox(height: 8),
              Text(_error!, textAlign: TextAlign.center, style: KsTextStyles.body()),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: () => context.go(AppRoutes.capture),
                style: FilledButton.styleFrom(backgroundColor: KsColors.terracotta),
                child: const Text('Start a product'),
              ),
            ],
          ),
        ),
      );
    }

    final currentTitle = _titleEnCtrl.text.isNotEmpty 
      ? _titleEnCtrl.text 
      : _titleHiCtrl.text.isNotEmpty ? _titleHiCtrl.text : "Untitled product";
      
    final currentDesc = _descEnCtrl.text.isNotEmpty
      ? _descEnCtrl.text
      : _descHiCtrl.text.isNotEmpty ? _descHiCtrl.text : "The confirmed product story will appear here.";

    return SingleChildScrollView(
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
              Expanded(child: Text('Check every product detail', style: KsTextStyles.editorial(size: 22))),
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
          Text('Review every field, then save and continue to pricing.', style: KsTextStyles.body()),
          const SizedBox(height: 24),

          // Draft Preview Card
          ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.8), width: 1.5),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (provider.listingId != null)
                      ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Image.network(
                          '${ApiService.baseUrl}/v1/listings/${provider.listingId}/media/studio.jpg',
                          headers: ApiService.authHeaders,
                          height: 200,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          errorBuilder: (ctx, err, trace) => Container(
                            height: 200,
                            color: KsColors.surfaceMuted,
                            child: const Icon(Icons.image_outlined, size: 48, color: KsColors.textMuted),
                          ),
                        ),
                      ),
                    const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(color: KsColors.peach3, borderRadius: BorderRadius.circular(4)),
                  child: Text('Draft preview', style: KsTextStyles.label(color: KsColors.terracotta, size: 10)),
                ),
                const SizedBox(height: 8),
                Text(currentTitle, style: KsTextStyles.section),
                const SizedBox(height: 6),
                Text(currentDesc, style: KsTextStyles.body(), maxLines: 3, overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
            ),
          ),
          const SizedBox(height: 24),

          // Form Section
          ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.8), width: 1.5),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                // Progress
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Catalog details', style: KsTextStyles.bodyMedium()),
                    Text('$_completeCount of ${_editableFields.length} completed', style: KsTextStyles.label()),
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
                Row(
                  children: [
                    const Icon(Icons.translate, size: 20, color: KsColors.terracotta),
                    const SizedBox(width: 8),
                    Text('Public details', style: KsTextStyles.section.copyWith(fontSize: 18)),
                  ],
                ),
                const SizedBox(height: 20),
                _buildTextField('English title', _titleEnCtrl, icon: Icons.title),
                _buildTextField('Hindi title', _titleHiCtrl, icon: Icons.title),
                _buildTextField('English description', _descEnCtrl, maxLines: 4, icon: Icons.notes),
                _buildTextField('Hindi description', _descHiCtrl, maxLines: 4, icon: Icons.notes),
                
                const SizedBox(height: 32),
                
                // Product and costing fields
                Row(
                  children: [
                    const Icon(Icons.assignment_outlined, size: 20, color: KsColors.terracotta),
                    const SizedBox(width: 8),
                    Text('Product & Costing', style: KsTextStyles.section.copyWith(fontSize: 18)),
                  ],
                ),
                const SizedBox(height: 20),
                ..._editableFields.map((f) => _buildTextField(
                  f['label'] as String, 
                  _controllers[f['key']]!,
                  keyboardType: f['type'] == 'number' ? TextInputType.number : TextInputType.text,
                  icon: f['icon'] as IconData?,
                )),

                const SizedBox(height: 16),
                
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: (!_isDirty || _isSaving) ? null : _saveDraft,
                    icon: _isSaving ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Icon(Icons.check),
                    label: Text(_isSaving ? 'Saving changes…' : 'Save draft changes'),
                    style: FilledButton.styleFrom(
                      backgroundColor: KsColors.terracotta,
                      disabledBackgroundColor: KsColors.terracotta.withValues(alpha: 0.5),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                ),
              ],
            ),
          ),
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
              onPressed: (_isDirty || _isSaving) ? null : () => context.push('/pricing'),
              icon: const Icon(Icons.arrow_forward),
              label: const Text('Continue to pricing'),
              style: FilledButton.styleFrom(
                backgroundColor: KsColors.terracotta,
                disabledBackgroundColor: KsColors.terracotta.withValues(alpha: 0.5),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }
}
