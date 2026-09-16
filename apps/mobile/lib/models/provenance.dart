/// Provenance shape mandated by `agent-coding-guide/06_DATA.md` and
/// `00_AGENT_RULES.md`: every AI value must carry `{source, confidence, ts}`.
/// A `null` [Provenance] on a rendered AI value is a bug surface, not a
/// state to hide — the UI shows a distinct "no provenance" chip for it.
class Provenance {
  const Provenance({
    required this.source,
    this.version,
    required this.confidence,
    required this.ts,
  });

  final String source;
  final String? version;
  final double confidence;
  final String ts;

  static Provenance? tryParse(Object? json) {
    if (json is! Map) return null;
    final source = json['source'];
    final confidence = json['confidence'];
    final ts = json['ts'];
    if (source is! String || confidence is! num || ts is! String) return null;
    return Provenance(
      source: source,
      version: json['version'] as String?,
      confidence: confidence.toDouble(),
      ts: ts,
    );
  }

  Map<String, dynamic> toJson() => {
        'source': source,
        if (version != null) 'version': version,
        'confidence': confidence,
        'ts': ts,
      };
}

/// A value paired with its (possibly missing) provenance.
class Traced<T> {
  const Traced(this.value, this.provenance);

  final T value;
  final Provenance? provenance;

  static Traced<int>? tryParseInt(Object? json) {
    if (json is! Map) return null;
    final value = json['value'];
    if (value is! num) return null;
    return Traced<int>(value.toInt(), Provenance.tryParse(json['provenance']));
  }
}
