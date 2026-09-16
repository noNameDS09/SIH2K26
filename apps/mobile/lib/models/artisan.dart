/// Five-bar Trade Record. Spec rule (`00_AGENT_RULES.md`): never call this
/// a "credit score" anywhere in UI strings; bars only unlock, never penalise.
/// Real field name from `compute_trade_record()`
/// (`apps/api/.../adapters/firebase.py`) is `community`, not `cluster`.
class TradeRecord {
  const TradeRecord({
    this.identity = 0,
    this.listings = 0,
    this.sales = 0,
    this.consistency = 0,
    this.community = 0,
  });

  final int identity;
  final int listings;
  final int sales;
  final int consistency;
  final int community;

  static TradeRecord fromJson(Map<String, dynamic>? json) {
    if (json == null) return const TradeRecord();
    int bar(String k) => ((json[k] as num?) ?? 0).clamp(0, 5).toInt();
    return TradeRecord(
      identity: bar('identity'),
      listings: bar('listings'),
      sales: bar('sales'),
      consistency: bar('consistency'),
      community: bar('community'),
    );
  }

  List<int> get bars => [identity, listings, sales, consistency, community];
}

class Artisan {
  const Artisan({
    required this.uid,
    this.name,
    this.phone,
    this.lang,
    this.cluster,
    this.pehchan,
    this.consentAt,
    this.tradeRecord = const TradeRecord(),
  });

  final String uid;
  final String? name;
  final String? phone;
  final String? lang;
  final String? cluster;

  /// `pehchan` is stored server-side as a map (e.g. `{"id": "..."}"`), not
  /// a bare string.
  final String? pehchan;
  final String? consentAt;
  final TradeRecord tradeRecord;

  static Artisan? tryParse(Map<String, dynamic>? json) {
    if (json == null) return null;
    final uid = json['uid'];
    if (uid is! String) return null;
    final pehchanRaw = json['pehchan'];
    return Artisan(
      uid: uid,
      name: json['name'] as String?,
      phone: json['phone'] as String?,
      lang: json['lang'] as String?,
      cluster: json['cluster'] as String?,
      pehchan: pehchanRaw is Map ? pehchanRaw['id'] as String? : pehchanRaw as String?,
      consentAt: json['consentAt'] as String?,
      tradeRecord: TradeRecord.fromJson(json['tradeRecord'] as Map<String, dynamic>?),
    );
  }
}
