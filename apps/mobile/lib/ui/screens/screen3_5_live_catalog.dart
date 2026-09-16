import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/session_provider.dart';
import '../theme/ks_colors.dart';
import '../theme/ks_text_styles.dart';

class LiveCatalogPage extends StatelessWidget {
  const LiveCatalogPage({super.key});
  @override
  Widget build(BuildContext context) {
    final session = context.watch<SessionProvider>();
    final currentSlot = session.currentQuestion ?? 'Starting interview...';
    final phase = session.isDone ? 'Complete' : (session.session.isNotEmpty ? 'Interviewing' : 'Ready');

    return Scaffold(
      backgroundColor: KsColors.background,
      appBar: AppBar(
        title: Text('Live Catalog', style: KsTextStyles.section),
        backgroundColor: KsColors.surface,
        elevation: 0,
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => Navigator.pop(context)),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Voice Catalog Session', style: KsTextStyles.section),
            const SizedBox(height: 4),
            Text('Phase: $phase', style: KsTextStyles.body(color: KsColors.textSecondary)),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: KsColors.surfaceWarm,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Current slot', style: KsTextStyles.label()),
                  const SizedBox(height: 4),
                  Text(currentSlot, style: KsTextStyles.bodyMedium()),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: session.isDone
                  ? Center(child: Text('Catalog complete. Continue to Price.', style: KsTextStyles.editorial()))
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text('Speak your answer. The assistant listens and confirms.', style: KsTextStyles.body()),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            icon: const Icon(Icons.mic),
                            label: const Text('Record Answer'),
                            onPressed: () => session.startRecording(),
                          ),
                        ),
                        if (session.isRecording)
                          Container(
                            margin: const EdgeInsets.only(top: 12),
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: KsColors.greenSoft,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text('Listening... Speak clearly.', style: KsTextStyles.body(size: 11, color: KsColors.greenDark)),
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
