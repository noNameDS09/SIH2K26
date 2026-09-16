import 'prices.dart';
import 'provenance.dart';

enum ListingStatus { draft, published }

ListingStatus _parseStatus(Object? v) =>
    v == 'published' ? ListingStatus.published : ListingStatus.draft;

/// A listing document. `fields` stays an open map by spec
/// (`06_DATA.md`: "Do not force one SQL-like schema") — craft-specific
/// keys (zari, pallu, weight_g, ...) live there untyped.
class Listing {
  const Listing({
    required this.id,
    this.status = ListingStatus.draft,
    this.originalUrl,
    this.studioUrl,
    this.bgPreset,
    this.deltaE,
    this.studioRejected = false,
    this.fields = const {},
    this.prices = const Prices(),
    this.provenance = const [],
    this.signature,
    this.qrUrl,
    this.publicUrl,
    this.signedAt,
    this.titleHi,
    this.titleEn,
    this.descHi,
    this.descEn,
    this.updatedAt,
  });

  final String id;
  final ListingStatus status;
  final String? originalUrl;
  final String? studioUrl;
  final String? bgPreset;
  final double? deltaE;
  final bool studioRejected;
  final Map<String, dynamic> fields;
  final Prices prices;
  final List<Provenance> provenance;
  final String? signature;
  final String? qrUrl;
  final String? publicUrl;
  final String? signedAt;
  final String? titleHi;
  final String? titleEn;
  final String? descHi;
  final String? descEn;
  final String? updatedAt;

  static Listing fromJson(Map<String, dynamic> json) => Listing(
        id: json['id'] as String,
        status: _parseStatus(json['status']),
        originalUrl: json['originalUrl'] as String?,
        studioUrl: json['studioUrl'] as String?,
        bgPreset: json['bgPreset'] as String?,
        deltaE: (json['deltaE'] as num?)?.toDouble(),
        studioRejected: json['studioRejected'] == true,
        fields: (json['fields'] as Map?)?.cast<String, dynamic>() ?? const {},
        prices: Prices.fromJson(json['prices'] as Map<String, dynamic>?),
        provenance: (json['provenance'] as List? ?? const [])
            .map(Provenance.tryParse)
            .whereType<Provenance>()
            .toList(),
        signature: json['signature'] as String?,
        // The persisted listing doc uses camelCase; the one-shot
        // `/sign` response uses snake_case and is never written back to
        // the doc (`publicUrl` in particular is not persisted at all —
        // capture it from that response directly, see
        // `mergeSignResponse`).
        qrUrl: json['qrUrl'] as String? ?? json['qr_url'] as String?,
        publicUrl: json['publicUrl'] as String? ?? json['public_url'] as String?,
        signedAt: json['signedAt'] as String? ?? json['signed_at'] as String?,
        titleHi: json['title_hi'] as String?,
        titleEn: json['title_en'] as String?,
        descHi: json['desc_hi'] as String?,
        descEn: json['desc_en'] as String?,
        updatedAt: json['updatedAt'] as String?,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'status': status == ListingStatus.published ? 'published' : 'draft',
        'originalUrl': originalUrl,
        'studioUrl': studioUrl,
        'bgPreset': bgPreset,
        'deltaE': deltaE,
        'studioRejected': studioRejected,
        'fields': fields,
        'title_hi': titleHi,
        'title_en': titleEn,
        'desc_hi': descHi,
        'desc_en': descEn,
        'signature': signature,
        'qrUrl': qrUrl,
        'publicUrl': publicUrl,
        'signedAt': signedAt,
        'prices': {
          if (prices.listed != null) 'listed': prices.listed,
          'override': prices.override,
        },
      };

  /// Merges a `POST /v1/listings/{id}/sign` response
  /// (`{listing_id, status, signature, qr_url, public_url, signed_at,
  /// source_label}`) into a client-side listing map. Needed because
  /// `publicUrl` is never persisted on the listing document server-side —
  /// this one response is the only place the app ever sees it.
  static Map<String, dynamic> mergeSignResponse(
    Map<String, dynamic> currentListing,
    Map<String, dynamic> signResponse,
  ) =>
      {
        ...currentListing,
        'status': signResponse['status'] ?? currentListing['status'],
        'signature': signResponse['signature'],
        'qrUrl': signResponse['qr_url'] ?? signResponse['qrUrl'],
        'publicUrl': signResponse['public_url'] ?? signResponse['publicUrl'],
        'signedAt': signResponse['signed_at'] ?? signResponse['signedAt'],
      };

  /// Missing slots per the Live cataloger schema (10_VOICE_AND_AGENTS.md)
  /// used to decide whether `/costing` is needed before pricing.
  static const costingSlots = ['hours', 'material_cost_inr', 'material_source', 'effort'];

  List<String> get missingCostingSlots =>
      costingSlots.where((k) => fields[k] == null).toList();

  Listing copyWith({
    ListingStatus? status,
    String? originalUrl,
    String? studioUrl,
    String? bgPreset,
    double? deltaE,
    bool? studioRejected,
    Map<String, dynamic>? fields,
    Prices? prices,
    String? signature,
    String? qrUrl,
    String? publicUrl,
    String? signedAt,
    String? titleHi,
    String? titleEn,
    String? descHi,
    String? descEn,
  }) =>
      Listing(
        id: id,
        status: status ?? this.status,
        originalUrl: originalUrl ?? this.originalUrl,
        studioUrl: studioUrl ?? this.studioUrl,
        bgPreset: bgPreset ?? this.bgPreset,
        deltaE: deltaE ?? this.deltaE,
        studioRejected: studioRejected ?? this.studioRejected,
        fields: fields ?? this.fields,
        prices: prices ?? this.prices,
        provenance: provenance,
        signature: signature ?? this.signature,
        qrUrl: qrUrl ?? this.qrUrl,
        publicUrl: publicUrl ?? this.publicUrl,
        signedAt: signedAt ?? this.signedAt,
        titleHi: titleHi ?? this.titleHi,
        titleEn: titleEn ?? this.titleEn,
        descHi: descHi ?? this.descHi,
        descEn: descEn ?? this.descEn,
        updatedAt: updatedAt,
      );
}
