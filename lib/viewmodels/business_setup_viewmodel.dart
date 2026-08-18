import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/business_config.dart';
import '../services/database_service.dart';

class BusinessSetupViewModel extends StateNotifier<BusinessConfig> {
  final DatabaseService _dbService;

  BusinessSetupViewModel(this._dbService)
      : super(BusinessConfig(
          shopName: '',
          address: '',
          phoneNumber: '',
          businessType: 'Grocery & Retail',
          receiptLanguage: 'Dual (Sinhala + English)',
          nayaPothaEnabled: true,
          kotEnabled: false,
          lankaQrEnabled: true,
        ));

  void updateShopName(String name) {
    state = state.copyWith(shopName: name);
  }

  void updateAddress(String address) {
    state = state.copyWith(address: address);
  }

  void updatePhoneNumber(String phone) {
    state = state.copyWith(phoneNumber: phone);
  }

  void updateBusinessType(String type) {
    state = state.copyWith(businessType: type);
    // Auto-adjust default feature toggles based on business type
    if (type == 'Restaurant & Hotel') {
      state = state.copyWith(kotEnabled: true, nayaPothaEnabled: false);
    } else if (type == 'Grocery & Retail') {
      state = state.copyWith(nayaPothaEnabled: true, kotEnabled: false);
    } else if (type == 'Cafe & Bakery') {
      state = state.copyWith(kotEnabled: true, nayaPothaEnabled: false);
    } else {
      state = state.copyWith(kotEnabled: false, nayaPothaEnabled: false);
    }
  }

  void updateReceiptLanguage(String language) {
    state = state.copyWith(receiptLanguage: language);
  }

  void toggleNayaPotha(bool value) {
    state = state.copyWith(nayaPothaEnabled: value);
  }

  void toggleKot(bool value) {
    state = state.copyWith(kotEnabled: value);
  }

  void toggleLankaQr(bool value) {
    state = state.copyWith(lankaQrEnabled: value);
  }

  Future<bool> saveSetup() async {
    if (state.shopName.trim().isEmpty ||
        state.address.trim().isEmpty ||
        state.phoneNumber.trim().isEmpty) {
      return false;
    }
    try {
      await _dbService.saveBusinessConfig(state);
      return true;
    } catch (_) {
      return false;
    }
  }
}

final businessSetupProvider =
    StateNotifierProvider<BusinessSetupViewModel, BusinessConfig>((ref) {
  return BusinessSetupViewModel(DatabaseService.instance);
});
