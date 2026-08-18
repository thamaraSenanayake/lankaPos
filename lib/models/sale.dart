class SaleItem {
  final int? id;
  final String name;
  final double price;
  final int quantity;
  final double discount; // Discount percentage (e.g., 10.0 for 10%)

  SaleItem({
    this.id,
    required this.name,
    required this.price,
    required this.quantity,
    this.discount = 0.0,
  });

  double get unitDiscountedPrice => price * (1 - discount / 100);
  double get total => unitDiscountedPrice * quantity;

  Map<String, dynamic> toMap(int saleId) {
    return {
      'saleId': saleId,
      'name': name,
      'price': price,
      'quantity': quantity,
      'discount': discount,
    };
  }

  factory SaleItem.fromMap(Map<String, dynamic> map) {
    return SaleItem(
      id: map['id'],
      name: map['name'] ?? '',
      price: (map['price'] as num?)?.toDouble() ?? 0.0,
      quantity: map['quantity'] ?? 1,
      discount: (map['discount'] as num?)?.toDouble() ?? 0.0,
    );
  }

  SaleItem copyWith({
    int? id,
    String? name,
    double? price,
    int? quantity,
    double? discount,
  }) {
    return SaleItem(
      id: id ?? this.id,
      name: name ?? this.name,
      price: price ?? this.price,
      quantity: quantity ?? this.quantity,
      discount: discount ?? this.discount,
    );
  }
}

class Sale {
  final int? id;
  final DateTime timestamp;
  final List<SaleItem> items;
  final double totalAmount;
  final String paymentMethod;
  final String? customerName;
  final String orderType; // Retail, Dine-In, Takeaway, Delivery
  final double discountAmount; // Overall discount amount applied at checkout

  Sale({
    this.id,
    required this.timestamp,
    required this.items,
    required this.totalAmount,
    required this.paymentMethod,
    this.customerName,
    this.orderType = 'Retail',
    this.discountAmount = 0.0,
  });

  factory Sale.fromMap(Map<String, dynamic> map, List<SaleItem> items) {
    return Sale(
      id: map['id'],
      timestamp: DateTime.parse(map['timestamp']),
      items: items,
      totalAmount: (map['totalAmount'] as num?)?.toDouble() ?? 0.0,
      paymentMethod: map['paymentMethod'] ?? 'Cash',
      customerName: map['customerName'],
      orderType: map['orderType'] ?? 'Retail',
      discountAmount: (map['discountAmount'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'timestamp': timestamp.toIso8601String(),
      'totalAmount': totalAmount,
      'paymentMethod': paymentMethod,
      'customerName': customerName,
      'orderType': orderType,
      'discountAmount': discountAmount,
    };
  }
}
