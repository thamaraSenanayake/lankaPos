class Expense {
  final int? id;
  final String category;
  final double amount;
  final String note;
  final String photoPath;
  final DateTime timestamp;

  Expense({
    this.id,
    required this.category,
    required this.amount,
    this.note = '',
    this.photoPath = '',
    required this.timestamp,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'category': category,
      'amount': amount,
      'note': note,
      'photoPath': photoPath,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  factory Expense.fromMap(Map<String, dynamic> map) {
    return Expense(
      id: map['id'],
      category: map['category'] ?? '',
      amount: (map['amount'] as num?)?.toDouble() ?? 0.0,
      note: map['note'] ?? '',
      photoPath: map['photoPath'] ?? '',
      timestamp: DateTime.parse(map['timestamp'] ?? DateTime.now().toIso8601String()),
    );
  }

  Expense copyWith({
    int? id,
    String? category,
    double? amount,
    String? note,
    String? photoPath,
    DateTime? timestamp,
  }) {
    return Expense(
      id: id ?? this.id,
      category: category ?? this.category,
      amount: amount ?? this.amount,
      note: note ?? this.note,
      photoPath: photoPath ?? this.photoPath,
      timestamp: timestamp ?? this.timestamp,
    );
  }
}
