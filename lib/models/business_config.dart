class BusinessConfig {
  final String shopName;
  final String address;
  final String phoneNumber;
  final String businessType;
  final String receiptLanguage;
  final bool nayaPothaEnabled;
  final bool kotEnabled;
  final bool lankaQrEnabled;
  final String footerMessage;
  final bool cashierLockEnabled;
  final String cashierPin;

  BusinessConfig({
    required this.shopName,
    required this.address,
    required this.phoneNumber,
    required this.businessType,
    required this.receiptLanguage,
    required this.nayaPothaEnabled,
    required this.kotEnabled,
    required this.lankaQrEnabled,
    this.footerMessage = 'Thank You Come Again!',
    this.cashierLockEnabled = false,
    this.cashierPin = '1234',
  });

  Map<String, dynamic> toMap() {
    return {
      'shopName': shopName,
      'address': address,
      'phoneNumber': phoneNumber,
      'businessType': businessType,
      'receiptLanguage': receiptLanguage,
      'nayaPothaEnabled': nayaPothaEnabled ? 1 : 0,
      'kotEnabled': kotEnabled ? 1 : 0,
      'lankaQrEnabled': lankaQrEnabled ? 1 : 0,
      'footerMessage': footerMessage,
      'cashierLockEnabled': cashierLockEnabled ? 1 : 0,
      'cashierPin': cashierPin,
    };
  }

  factory BusinessConfig.fromMap(Map<String, dynamic> map) {
    return BusinessConfig(
      shopName: map['shopName'] ?? '',
      address: map['address'] ?? '',
      phoneNumber: map['phoneNumber'] ?? '',
      businessType: map['businessType'] ?? 'Grocery & Retail',
      receiptLanguage: map['receiptLanguage'] ?? 'English',
      nayaPothaEnabled: (map['nayaPothaEnabled'] ?? 0) == 1,
      kotEnabled: (map['kotEnabled'] ?? 0) == 1,
      lankaQrEnabled: (map['lankaQrEnabled'] ?? 0) == 1,
      footerMessage: map['footerMessage'] ?? 'Thank You Come Again!',
      cashierLockEnabled: (map['cashierLockEnabled'] ?? 0) == 1,
      cashierPin: map['cashierPin'] ?? '1234',
    );
  }

  BusinessConfig copyWith({
    String? shopName,
    String? address,
    String? phoneNumber,
    String? businessType,
    String? receiptLanguage,
    bool? nayaPothaEnabled,
    bool? kotEnabled,
    bool? lankaQrEnabled,
    String? footerMessage,
    bool? cashierLockEnabled,
    String? cashierPin,
  }) {
    return BusinessConfig(
      shopName: shopName ?? this.shopName,
      address: address ?? this.address,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      businessType: businessType ?? this.businessType,
      receiptLanguage: receiptLanguage ?? this.receiptLanguage,
      nayaPothaEnabled: nayaPothaEnabled ?? this.nayaPothaEnabled,
      kotEnabled: kotEnabled ?? this.kotEnabled,
      lankaQrEnabled: lankaQrEnabled ?? this.lankaQrEnabled,
      footerMessage: footerMessage ?? this.footerMessage,
      cashierLockEnabled: cashierLockEnabled ?? this.cashierLockEnabled,
      cashierPin: cashierPin ?? this.cashierPin,
    );
  }
}
