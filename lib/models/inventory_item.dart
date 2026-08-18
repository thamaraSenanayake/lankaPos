class InventoryItem {
  final int? id;
  final String name;
  final double stock;
  final String unit;
  final double minStock;
  final double price;

  InventoryItem({
    this.id,
    required this.name,
    required this.stock,
    required this.unit,
    required this.minStock,
    required this.price,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'stock': stock,
      'unit': unit,
      'minStock': minStock,
      'price': price,
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
    );
  }

  InventoryItem copyWith({
    int? id,
    String? name,
    double? stock,
    String? unit,
    double? minStock,
    double? price,
  }) {
    return InventoryItem(
      id: id ?? this.id,
      name: name ?? this.name,
      stock: stock ?? this.stock,
      unit: unit ?? this.unit,
      minStock: minStock ?? this.minStock,
      price: price ?? this.price,
    );
  }
}
