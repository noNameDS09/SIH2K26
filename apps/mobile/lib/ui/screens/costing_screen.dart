import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../services/api_service.dart';
import '../../services/session_provider.dart';
import '../l10n/locale_provider.dart';
import '../theme/ks_colors.dart';
import '../theme/ks_text_styles.dart';
import '../widgets/ks_app_header.dart';
import '../widgets/ks_cards.dart';
import '../widgets/ks_stage_progress.dart';

/// Stage 3 — collects the costing slots the Live cataloger didn't get
/// (`10_VOICE_AND_AGENTS.md`: hours, material_cost_inr, material_source,
/// effort). Only reached when `Listing.missingCostingSlots` is non-empty;
/// returns to `/pricing` once saved. "Don't know" stores `null`, never a
/// guess, per the cataloger's own rule.
class CostingScreen extends StatefulWidget {
  const CostingScreen({super.key});

  @override
  State<CostingScreen> createState() => _CostingScreenState();
}

const _materialSources = ['own', 'shop', 'trader'];
const _effortLevels = ['simple', 'normal', 'skilled'];

class _CostingScreenState extends State<CostingScreen> {
  final _hoursCtrl = TextEditingController();
  final _costCtrl = TextEditingController();
  String? _materialSource;
  String? _effort;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final fields = context.read<SessionProvider>().listing?['fields'];
    if (fields is Map) {
      _hoursCtrl.text = fields['hours']?.toString() ?? '';
      _costCtrl.text = fields['material_cost_inr']?.toString() ?? '';
      _materialSource = fields['material_source'] as String?;
      _effort = fields['effort'] as String?;
    }
  }

  @override
  void dispose() {
    _hoursCtrl.dispose();
    _costCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final provider = context.read<SessionProvider>();
    final id = provider.listingId ?? (provider.listing?['id'] as String?);
    if (id == null) return;
    setState(() => _saving = true);
    final fields = <String, dynamic>{
      'hours': _hoursCtrl.text.trim().isEmpty ? null : num.tryParse(_hoursCtrl.text.trim()),
      'material_cost_inr':
          _costCtrl.text.trim().isEmpty ? null : num.tryParse(_costCtrl.text.trim()),
      'material_source': _materialSource,
      'effort': _effort,
    };
    final updated = await ApiService.patchListing(id, {'fields': fields});
    if (updated != null) provider.updateListing(updated.toJson());
    if (!mounted) return;
    setState(() => _saving = false);
    context.go('/pricing');
  }

  @override
  Widget build(BuildContext context) {
    final locale = context.watch<LocaleProvider>().locale.languageCode.toUpperCase();
    return Scaffold(
      backgroundColor: KsColors.background,
      appBar: KsAppHeader(
        title: 'Costing',
        onBack: () => context.pop(),
        languageChip: locale,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const KsStageProgress(stage: 3, label: 'COSTING'),
              const SizedBox(height: 16),
              Text('A couple more details to price this fairly',
                  style: KsTextStyles.h3),
              const SizedBox(height: 4),
              Text("Say \"don't know\" if you're not sure — we won't guess.",
                  style: KsTextStyles.caption),
              const SizedBox(height: 20),
              KsCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Hours to make one piece', style: KsTextStyles.bodyMedium()),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _hoursCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(hintText: 'e.g. 6'),
                    ),
                    const SizedBox(height: 16),
                    Text('Material cost (₹)', style: KsTextStyles.bodyMedium()),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _costCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(hintText: "e.g. 400, or leave blank if don't know"),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              KsCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Where did the material come from?', style: KsTextStyles.bodyMedium()),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: _materialSources
                          .map((s) => ChoiceChip(
                                label: Text(s),
                                selected: _materialSource == s,
                                onSelected: (_) => setState(() => _materialSource = s),
                              ))
                          .toList(),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              KsCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('How skilled is this work?', style: KsTextStyles.bodyMedium()),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: _effortLevels
                          .map((s) => ChoiceChip(
                                label: Text(s),
                                selected: _effort == s,
                                onSelected: (_) => setState(() => _effort = s),
                              ))
                          .toList(),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _saving ? null : _save,
                  child: Text(_saving ? 'Saving…' : 'Continue to pricing'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
