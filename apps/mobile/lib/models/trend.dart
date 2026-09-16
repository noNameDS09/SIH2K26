import 'provenance.dart';

/// `public_trends/current` per `06_DATA.md`. `seed: true` and low `n` must
/// always be shown together — never present a seeded number as observed.
class Trend {
  const Trend({
    this.craft,
    this.cluster,
    this.rising = const [],
    this.n = 0,
    this.seed = false,
    this.updatedAt,
    this.provenance,
    this.series = const [],
  });

  final String? craft;
  final String? cluster;
  final List<String> rising;
  final int n;
  final bool seed;
  final String? updatedAt;
  final Provenance? provenance;

  /// Sparkline points, if the backend supplies a short history.
  final List<double> series;

  static Trend? tryParse(Map<String, dynamic>? json) {
    if (json == null) return null;
    return Trend(
      craft: json['craft'] as String?,
      cluster: json['cluster'] as String?,
      rising: (json['rising'] as List? ?? const []).cast<String>(),
      n: (json['n'] as num?)?.toInt() ?? 0,
      seed: json['seed'] == true,
      updatedAt: json['updatedAt'] as String?,
      provenance: Provenance.tryParse(json['provenance']),
      series: (json['series'] as List? ?? const [])
          .map((e) => (e as num).toDouble())
          .toList(),
    );
  }
}
