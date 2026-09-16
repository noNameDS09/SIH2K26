import 'provenance.dart';

/// Three-band price per `agent-coding-guide/13_API.md`.
/// `floor <= recommended <= aspirational`; `listed` is the artisan's
/// final choice (defaults to `recommended` until overridden).
class Prices {
  const Prices({
    this.floor,
    this.recommended,
    this.aspirational,
    this.listed,
    this.override = false,
    this.breakdown = const {},
  });

  final Traced<int>? floor;
  final Traced<int>? recommended;
  final Traced<int>? aspirational;
  final int? listed;
  final bool override;
  final Map<String, dynamic> breakdown;

  bool get hasBands => floor != null && recommended != null && aspirational != null;

  static Prices fromJson(Map<String, dynamic>? json) {
    if (json == null) return const Prices();
    return Prices(
      floor: Traced.tryParseInt(json['floor']),
      recommended: Traced.tryParseInt(json['recommended']),
      aspirational: Traced.tryParseInt(json['aspirational']),
      // Real `compute_prices()` wraps `listed` as {value, provenance} too,
      // but the app's own override (PATCH prices.listed) may send a raw int.
      listed: json['listed'] is Map
          ? ((json['listed'] as Map)['value'] as num?)?.toInt()
          : (json['listed'] as num?)?.toInt(),
      override: json['override'] == true,
      breakdown: (json['breakdown'] as Map?)?.cast<String, dynamic>() ?? const {},
    );
  }

  Prices copyWith({int? listed, bool? override}) => Prices(
        floor: floor,
        recommended: recommended,
        aspirational: aspirational,
        listed: listed ?? this.listed,
        override: override ?? this.override,
        breakdown: breakdown,
      );
}
