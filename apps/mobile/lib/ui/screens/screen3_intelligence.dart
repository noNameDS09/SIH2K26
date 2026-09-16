import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../services/session_provider.dart';
import '../../services/api_service.dart';
import '../l10n/ks_strings.dart';
import '../routes/app_routes.dart';
import '../theme/ks_colors.dart';
import '../theme/ks_text_styles.dart';
import '../widgets/ks_app_header.dart';
import '../widgets/ks_stage_progress.dart';
import '../widgets/ks_trend_line_card.dart';
import '../../models/trend.dart';
import '../../models/listing.dart';

const _editableFields = [
  ('craft', 'Craft type'),
  ('material', 'Material'),
  ('technique', 'Technique'),
  ('colour', 'Colour'),
  ('occasion', 'Occasion'),
  ('gi', 'GI status'),
  ('hours', 'Hours of work'),
  ('material_cost_inr', 'Material cost (₹)'),
  ('material_source', 'Material source'),
  ('effort', 'Effort level'),
];

class Screen3Intelligence extends StatefulWidget {
  const Screen3Intelligence({super.key});

  @override
  State<Screen3Intelligence> createState() => _Screen3IntelligenceState();
}

class _Screen3IntelligenceState extends State<Screen3Intelligence> {
  final _controllers = <String, TextEditingController>{};
  final _titleEnCtrl = TextEditingController();
  final _titleHiCtrl = TextEditingController();
  final _descEnCtrl = TextEditingController();
  final _descHiCtrl = TextEditingController();

  bool _dirty = false;
  bool _saving = false;
  bool _speakingTts = false;
  String? _message;
  Trend? _trend;

  @override
  void initState() {
    super.initState();
    for (final (key, _) in _editableFields) {
      _controllers[key] = TextEditingController();
    }
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadFromProvider());
    ApiService.trends().then((t) {
      if (mounted) setState(() => _trend = t);
    });
  }

  void _loadFromProvider() {
    final provider = context.read<SessionProvider>();
    final listing = provider.listing ?? {};

    _titleEnCtrl.text = (listing['title_en'] as String?) ?? '';
    _titleHiCtrl.text = (listing['title_hi'] as String?) ?? '';
    _descEnCtrl.text = (listing['desc_en'] as String?) ?? (listing['description'] as String?) ?? '';
    _descHiCtrl.text = (listing['desc_hi'] as String?) ?? '';

    final fields = listing['fields'];
    if (fields is Map) {
      for (final (key, _) in _editableFields) {
        final raw = fields[key];
        _controllers[key]?.text =
            raw is List ? raw.join(', ') : (raw?.toString() ?? '');
      }
    }
    setState(() => _dirty = false);
  }

  @override
  void dispose() {
    _titleEnCtrl.dispose();
    _titleHiCtrl.dispose();
    _descEnCtrl.dispose();
    _descHiCtrl.dispose();
    for (final ctrl in _controllers.values) ctrl.dispose();
    super.dispose();
  }

  void _markDirty() {
    if (!_dirty) setState(() { _dirty = true; _message = null; });
  }

  int get _completedCount {
    var count = 0;
    if (_titleEnCtrl.text.trim().isNotEmpty) count++;
    if (_titleHiCtrl.text.trim().isNotEmpty) count++;
    if (_descEnCtrl.text.trim().isNotEmpty) count++;
    if (_descHiCtrl.text.trim().isNotEmpty) count++;
    for (final (key, _) in _editableFields) {
      if (_controllers[key]!.text.trim().isNotEmpty) count++;
    }
    return count;
  }

  int get _totalCount => 4 + _editableFields.length;

  Future<void> _saveDraft() async {
    if (!_dirty || _saving) return;
    setState(() { _saving = true; _message = null; });

    final provider = context.read<SessionProvider>();
    final id = provider.listing?['id'] as String?;
    if (id == null) {
      setState(() { _saving = false; _message = 'No listing to save.'; });
      return;
    }

    final nextFields = <String, dynamic>{};
    for (final (key, _) in _editableFields) {
      final raw = _controllers[key]!.text.trim();
      if (key == 'colour') {
        nextFields[key] = raw.isNotEmpty
            ? raw.split(',').map((s) => s.trim()).where((s) => s.isNotEmpty).toList()
            : [];
      } else if (key == 'hours' || key == 'material_cost_inr') {
        nextFields[key] = raw.isNotEmpty ? num.tryParse(raw) : null;
      } else {
        nextFields[key] = raw.isNotEmpty ? raw : null;
      }
    }

    try {
      final updated = await ApiService.patchListing(id, {
        'fields': nextFields,
        'title_en': _titleEnCtrl.text.trim(),
        'title_hi': _titleHiCtrl.text.trim(),
        'desc_en': _descEnCtrl.text.trim(),
        'desc_hi': _descHiCtrl.text.trim(),
      });
      if (updated != null) provider.updateListing(updated.toJson());
      if (mounted) setState(() { _dirty = false; _saving = false; _message = 'Draft changes saved.'; });
    } catch (_) {
      if (mounted) setState(() { _saving = false; _message = 'Could not save draft.'; });
    }
  }

  Future<void> _listenAudio() async {
    if (_speakingTts) return;
    setState(() => _speakingTts = true);
    final provider = context.read<SessionProvider>();
    final langCode = _sarvamCode(context);
    final listing = provider.listing ?? {};
    final text = (listing['title_hi'] as String?) ??
        (listing['title_en'] as String?) ??
        'आपकी सूची तैयार है';
    try {
      await provider.speakText(text, langCode: langCode);
    } catch (_) {}
    if (mounted) setState(() => _speakingTts = false);
  }

  /// Costing slots the Live cataloger did not fill (`10_VOICE_AND_AGENTS.md`
  /// costing questions) — gates the route to `/costing` before `/pricing`.
  List<String> _missingCostingSlots(SessionProvider provider) {
    final fields = provider.listing?['fields'];
    if (fields is! Map) return Listing.costingSlots;
    return Listing.costingSlots.where((k) => fields[k] == null).toList();
  }

  String _nextRoute(SessionProvider provider) =>
      _missingCostingSlots(provider).isEmpty ? AppRoutes.pricing : AppRoutes.costing;

  String _sarvamCode(BuildContext context) => KsStrings.sarvamLangCode(context);

  @override
  Widget build(BuildContext context) {
    return Consumer<SessionProvider>(
      builder: (context, provider, _) {
        final listing = provider.listing;
        final photoUrl = listing?['studio_url'] as String? ??
            listing?['original_url'] as String? ??
            listing?['photo_url'] as String?;

        return Scaffold(
          backgroundColor: KsColors.background,
          body: Column(
            children: [
              KsAppHeader(
                title: 'Review',
                onBack: () => context.go(AppRoutes.live),
              ),
              if (provider.isLoading)
                Expanded(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const CircularProgressIndicator(color: KsColors.terracotta, strokeWidth: 2),
                        const SizedBox(height: 16),
                        Text(provider.statusMessage ?? 'Processing…',
                            style: KsTextStyles.body(color: KsColors.terracotta, size: 13)),
                      ],
                    ),
                  ),
                )
              else
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 16),
                        const KsStageProgress(stage: 3, label: 'REVIEW'),
                        const SizedBox(height: 20),

                        // Page intro
                        Text('Check every product detail', style: KsTextStyles.h2),
                        const SizedBox(height: 6),
                        Text(
                          'Nothing saves while you type. Use the save action when the draft is accurate.',
                          style: KsTextStyles.body(color: KsColors.textSecondary, size: 12),
                        ),
                        const SizedBox(height: 16),

                        // Completion count
                        _CompletionBar(
                          completed: _completedCount,
                          total: _totalCount,
                        ),
                        const SizedBox(height: 16),

                        KsTrendLineCard(trend: _trend),
                        const SizedBox(height: 20),

                        // Listen to listing TTS
                        _AudioListenRow(
                          speaking: _speakingTts,
                          onTap: _listenAudio,
                        ),
                        const SizedBox(height: 20),

                        // Product image preview (if available)
                        if (photoUrl != null) ...[
                          _ProductImagePreview(url: photoUrl),
                          const SizedBox(height: 20),
                        ],

                        // Bilingual public card
                        _SectionCard(
                          label: 'BILINGUAL PUBLIC CARD',
                          child: Column(
                            children: [
                              _EditField(
                                label: 'English title',
                                controller: _titleEnCtrl,
                                onChanged: (_) => _markDirty(),
                              ),
                              const SizedBox(height: 12),
                              _EditField(
                                label: 'Hindi title',
                                controller: _titleHiCtrl,
                                onChanged: (_) => _markDirty(),
                              ),
                              const SizedBox(height: 12),
                              _EditField(
                                label: 'English description',
                                controller: _descEnCtrl,
                                maxLines: 3,
                                onChanged: (_) => _markDirty(),
                              ),
                              const SizedBox(height: 12),
                              _EditField(
                                label: 'Hindi description',
                                controller: _descHiCtrl,
                                maxLines: 3,
                                onChanged: (_) => _markDirty(),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Product and costing fields
                        _SectionCard(
                          label: 'PRODUCT AND COSTING FIELDS',
                          child: Column(
                            children: [
                              for (var i = 0; i < _editableFields.length; i++) ...[
                                if (i > 0) const SizedBox(height: 12),
                                _EditField(
                                  label: _editableFields[i].$2,
                                  controller: _controllers[_editableFields[i].$1]!,
                                  keyboardType: (_editableFields[i].$1 == 'hours' ||
                                          _editableFields[i].$1 == 'material_cost_inr')
                                      ? TextInputType.number
                                      : TextInputType.text,
                                  onChanged: (_) => _markDirty(),
                                ),
                              ],
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Status / message
                        if (_message != null) ...[
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                            decoration: BoxDecoration(
                              color: _message!.contains('saved') ? KsColors.paleGreen : KsColors.peach3,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(_message!,
                                style: KsTextStyles.body(
                                    color: _message!.contains('saved') ? KsColors.deepGreen : KsColors.terracotta,
                                    size: 12)),
                          ),
                          const SizedBox(height: 16),
                        ],

                        // Save draft button
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: _dirty && !_saving ? _saveDraft : null,
                            icon: _saving
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(strokeWidth: 2, color: KsColors.terracotta),
                                  )
                                : const Icon(Icons.check, size: 18, color: KsColors.terracotta),
                            label: Text(
                              _saving ? 'Saving changes…' : 'Save draft changes',
                              style: KsTextStyles.body(
                                  color: _dirty ? KsColors.terracotta : KsColors.textSecondary, size: 13),
                            ),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              side: BorderSide(
                                  color: _dirty ? KsColors.terracotta : KsColors.border),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),

                        // Continue to pricing
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () => context.go(AppRoutes.live),
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                  side: const BorderSide(color: KsColors.border),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                                child: Text('Add more by voice',
                                    style: KsTextStyles.body(color: KsColors.textSecondary, size: 13)),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              flex: 2,
                              child: ElevatedButton.icon(
                                onPressed: _dirty || _saving
                                    ? null
                                    : () => context.go(_nextRoute(provider)),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: KsColors.terracotta,
                                  foregroundColor: KsColors.white,
                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                                icon: const Icon(Icons.arrow_forward, size: 18),
                                label: Text(
                                  _missingCostingSlots(provider).isEmpty
                                      ? 'Continue to pricing'
                                      : 'A few more costing details',
                                  style: KsTextStyles.cta(size: 14),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 40),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _CompletionBar extends StatelessWidget {
  final int completed;
  final int total;
  const _CompletionBar({required this.completed, required this.total});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: KsColors.surface1,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('Catalog details',
                  style: KsTextStyles.body(color: KsColors.textSecondary, size: 12)),
              const Spacer(),
              Text('$completed of $total completed',
                  style: KsTextStyles.bodyMedium(size: 12, color: KsColors.terracotta)),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: total > 0 ? completed / total : 0,
              backgroundColor: KsColors.peach3,
              color: KsColors.terracotta,
              minHeight: 6,
            ),
          ),
        ],
      ),
    );
  }
}

class _AudioListenRow extends StatelessWidget {
  final bool speaking;
  final VoidCallback onTap;
  const _AudioListenRow({required this.speaking, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: KsColors.peach3,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: KsColors.terracotta.withAlpha(60)),
        ),
        child: Row(
          children: [
            Icon(
              speaking ? Icons.pause_circle_filled : Icons.play_circle_filled,
              color: KsColors.terracotta,
              size: 24,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    speaking ? 'Reading your listing…' : 'Listen to your listing',
                    style: KsTextStyles.bodyMedium(size: 13),
                  ),
                  Text(
                    'AI reads the draft title in your language',
                    style: KsTextStyles.body(color: KsColors.textSecondary, size: 11),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProductImagePreview extends StatelessWidget {
  final String url;
  const _ProductImagePreview({required this.url});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 180,
      decoration: BoxDecoration(
        color: KsColors.surface1,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: KsColors.border),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(11),
        child: url.startsWith('http')
            ? Image.network(url, fit: BoxFit.cover, errorBuilder: (_, __, ___) => _emptyMedia())
            : _emptyMedia(),
      ),
    );
  }

  Widget _emptyMedia() => Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.image_outlined, size: 32, color: KsColors.textSecondary),
          const SizedBox(height: 8),
          Text('No product photo stored',
              style: KsTextStyles.body(color: KsColors.textSecondary, size: 12)),
        ],
      );
}

class _SectionCard extends StatelessWidget {
  final String label;
  final Widget child;
  const _SectionCard({required this.label, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: KsColors.surface1,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: KsColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: KsTextStyles.label(color: KsColors.brown3, size: 9)),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}

class _EditField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final int maxLines;
  final TextInputType keyboardType;
  final ValueChanged<String>? onChanged;

  const _EditField({
    required this.label,
    required this.controller,
    this.maxLines = 1,
    this.keyboardType = TextInputType.text,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: KsTextStyles.label(color: KsColors.brown3, size: 9)),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          maxLines: maxLines,
          keyboardType: keyboardType,
          onChanged: onChanged,
          style: KsTextStyles.body(color: KsColors.ink, size: 13),
          decoration: InputDecoration(
            filled: true,
            fillColor: KsColors.white,
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
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
              borderSide: const BorderSide(color: KsColors.terracotta, width: 1.5),
            ),
          ),
        ),
      ],
    );
  }
}
