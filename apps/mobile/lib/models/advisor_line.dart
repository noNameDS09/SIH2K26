import 'provenance.dart';
import 'trend.dart';

/// Agent B output. A `null` value IS the spec'd "silence" state
/// (`10_VOICE_AND_AGENTS.md`: "If no rule fires, empty. Do not fill with
/// generic tips.") — callers must render nothing, not a placeholder.
///
/// Real shape from `GET /v1/advisor`
/// (`apps/api/.../engines/advisor.py:advise_artisan`):
/// `{sentence, empty, rule_id, listing_id, lang, trade_record, provenance}`.
class AdvisorLine {
  const AdvisorLine({required this.text, required this.ruleId, this.provenance});

  final String text;
  final String ruleId;
  final Provenance? provenance;

  static AdvisorLine? tryParse(Map<String, dynamic>? json) {
    if (json == null) return null;
    if (json['empty'] == true) return null;
    final text = json['sentence'];
    if (text is! String || text.isEmpty) return null;
    return AdvisorLine(
      text: text,
      ruleId: json['rule_id'] as String? ?? 'unknown',
      provenance: Provenance.tryParse(json['provenance']),
    );
  }

  /// From one raw `insight.generated` event record
  /// (`{payload: {rule_id, sentence}, ts, ...}`), as returned in
  /// `GET /v1/insights`'s `history` list.
  static AdvisorLine? tryParseEvent(Map<String, dynamic>? json) {
    if (json == null) return null;
    final payload = json['payload'];
    if (payload is! Map) return null;
    final text = payload['sentence'];
    if (text is! String || text.isEmpty) return null;
    final ts = json['ts'] as String?;
    return AdvisorLine(
      text: text,
      ruleId: payload['rule_id'] as String? ?? 'unknown',
      provenance: ts == null
          ? null
          : Provenance(source: 'advisor-rules.v1', confidence: 0.9, ts: ts),
    );
  }
}

/// `GET /v1/insights` bundles Agent B's current line, its history, and the
/// cluster trend in one response — no need for three separate calls.
class InsightsBundle {
  const InsightsBundle({this.advisor, this.history = const [], this.trend});

  final AdvisorLine? advisor;
  final List<AdvisorLine> history;
  final Trend? trend;

  static InsightsBundle fromJson(Map<String, dynamic> json) => InsightsBundle(
        advisor: AdvisorLine.tryParse(json['advisor'] as Map<String, dynamic>?),
        history: (json['history'] as List? ?? const [])
            .whereType<Map>()
            .map((e) => AdvisorLine.tryParseEvent(e.cast<String, dynamic>()))
            .whereType<AdvisorLine>()
            .toList(),
        trend: Trend.tryParse(json['trends'] as Map<String, dynamic>?),
      );
}
