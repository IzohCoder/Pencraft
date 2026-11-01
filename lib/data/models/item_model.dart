class ItemModel {
  const ItemModel({
    required this.id,
    required this.name,
    required this.description,
    required this.unit,
    required this.unitPriceMinor,
    this.taxRateBps,
    required this.currencyCode,
    required this.createdAt,
  });

  final int id;
  final String name;
  final String description;
  final String unit;
  final int unitPriceMinor;
  final int? taxRateBps;
  final String currencyCode;
  final int createdAt;
}
