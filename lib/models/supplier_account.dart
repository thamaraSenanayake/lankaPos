class SupplierAccount {
  final int? id;
  final String name;
  final String phone;
  final double balance;
  final DateTime dueDate;
  final DateTime lastUpdated;

  SupplierAccount({
    this.id,
    required this.name,
    this.phone = '',
    required this.balance,
    required this.dueDate,
    required this.lastUpdated,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'phone': phone,
      'balance': balance,
      'dueDate': dueDate.toIso8601String(),
      'lastUpdated': lastUpdated.toIso8601String(),
    };
  }

  factory SupplierAccount.fromMap(Map<String, dynamic> map) {
    return SupplierAccount(
      id: map['id'],
      name: map['name'] ?? '',
      phone: map['phone'] ?? '',
      balance: (map['balance'] as num?)?.toDouble() ?? 0.0,
      dueDate: DateTime.parse(map['dueDate'] ?? DateTime.now().toIso8601String()),
      lastUpdated: DateTime.parse(map['lastUpdated'] ?? DateTime.now().toIso8601String()),
    );
  }

  SupplierAccount copyWith({
    int? id,
    String? name,
    String? phone,
    double? balance,
    DateTime? dueDate,
    DateTime? lastUpdated,
  }) {
    return SupplierAccount(
      id: id ?? this.id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      balance: balance ?? this.balance,
      dueDate: dueDate ?? this.dueDate,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }
}
