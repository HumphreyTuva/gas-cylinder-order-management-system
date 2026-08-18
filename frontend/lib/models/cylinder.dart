class CylinderType {
  final String id;
  final String name;
  final double sizeKg;
  final double purchasePrice;
  final double refillPrice;
  final String description;
  final bool isActive;
  final int stockQuantity;

  CylinderType({
    required this.id,
    required this.name,
    required this.sizeKg,
    required this.purchasePrice,
    required this.refillPrice,
    required this.description,
    required this.isActive,
    required this.stockQuantity,
  });

  factory CylinderType.fromJson(Map<String, dynamic> json) {
    return CylinderType(
      id: json['id'].toString(),
      name: json['name'] ?? '',
      sizeKg: double.tryParse(json['size_kg'].toString()) ?? 0,
      purchasePrice: double.tryParse(json['purchase_price'].toString()) ?? 0,
      refillPrice: double.tryParse(json['refill_price'].toString()) ?? 0,
      description: json['description'] ?? '',
      isActive: json['is_active'] ?? true,
      stockQuantity: json['stock_quantity'] ?? 0,
    );
  }
}
