class InventoryItem {
  final int? id;
  final String name;
  final double stock;
  final String unit;
  final double minStock;
  final double price;
  final String barcode;
  final String category;
  final double costPrice;

  InventoryItem({
    this.id,
    required this.name,
    required this.stock,
    required this.unit,
    required this.minStock,
    required this.price,
    this.barcode = '',
    this.category = 'General',
    this.costPrice = 0.0,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'stock': stock,
      'unit': unit,
      'minStock': minStock,
      'price': price,
      'barcode': barcode,
      'category': category,
      'costPrice': costPrice,
    };
  }

  factory InventoryItem.fromMap(Map<String, dynamic> map) {
    return InventoryItem(
      id: map['id'],
      name: map['name'] ?? '',
      stock: (map['stock'] as num?)?.toDouble() ?? 0.0,
      unit: map['unit'] ?? 'pcs',
      minStock: (map['minStock'] as num?)?.toDouble() ?? 0.0,
      price: (map['price'] as num?)?.toDouble() ?? 0.0,
      barcode: map['barcode'] ?? '',
      category: map['category'] ?? 'General',
      costPrice: (map['costPrice'] as num?)?.toDouble() ?? 0.0,
    );
  }

  InventoryItem copyWith({
    int? id,
    String? name,
    double? stock,
    String? unit,
    double? minStock,
    double? price,
    String? barcode,
    String? category,
    double? costPrice,
  }) {
    return InventoryItem(
      id: id ?? this.id,
      name: name ?? this.name,
      stock: stock ?? this.stock,
      unit: unit ?? this.unit,
      minStock: minStock ?? this.minStock,
      price: price ?? this.price,
      barcode: barcode ?? this.barcode,
      category: category ?? this.category,
      costPrice: costPrice ?? this.costPrice,
    );
  }
}
