class CreditAccount {
  final int? id;
  final String name;
  final String phone;
  final double balance;
  final DateTime lastUpdated;

  CreditAccount({
    this.id,
    required this.name,
    this.phone = '',
    required this.balance,
    required this.lastUpdated,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'phone': phone,
      'balance': balance,
      'lastUpdated': lastUpdated.toIso8601String(),
    };
  }

  factory CreditAccount.fromMap(Map<String, dynamic> map) {
    return CreditAccount(
      id: map['id'],
      name: map['name'] ?? '',
      phone: map['phone'] ?? '',
      balance: (map['balance'] as num?)?.toDouble() ?? 0.0,
      lastUpdated: DateTime.parse(map['lastUpdated'] ?? DateTime.now().toIso8601String()),
    );
  }

  CreditAccount copyWith({
    int? id,
    String? name,
    String? phone,
    double? balance,
    DateTime? lastUpdated,
  }) {
    return CreditAccount(
      id: id ?? this.id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      balance: balance ?? this.balance,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }
}
