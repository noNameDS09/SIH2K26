class Sale {
  const Sale({
    required this.id,
    required this.listingId,
    this.craft,
    required this.amount,
    required this.confirmedAt,
  });

  final String id;
  final String listingId;
  final String? craft;
  final int amount;
  final String confirmedAt;

  static Sale? tryParse(Map<String, dynamic>? json) {
    if (json == null) return null;
    final id = json['id'];
    final listingId = json['listingId'];
    final amount = json['amount'];
    final confirmedAt = json['confirmedAt'];
    if (id is! String || listingId is! String || amount is! num || confirmedAt is! String) {
      return null;
    }
    return Sale(
      id: id,
      listingId: listingId,
      craft: json['craft'] as String?,
      amount: amount.toInt(),
      confirmedAt: confirmedAt,
    );
  }
}
