import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/credit_account.dart';
import '../models/supplier_account.dart';
import '../services/database_service.dart';

class NayaPothaState {
  final List<CreditAccount> customers;
  final List<SupplierAccount> suppliers;
  final String activeTab; // 'Customer', 'Supplier'
  final String searchKeyword;

  NayaPothaState({
    this.customers = const [],
    this.suppliers = const [],
    this.activeTab = 'Customer',
    this.searchKeyword = '',
  });

  NayaPothaState copyWith({
    List<CreditAccount>? customers,
    List<SupplierAccount>? suppliers,
    String? activeTab,
    String? searchKeyword,
  }) {
    return NayaPothaState(
      customers: customers ?? this.customers,
      suppliers: suppliers ?? this.suppliers,
      activeTab: activeTab ?? this.activeTab,
      searchKeyword: searchKeyword ?? this.searchKeyword,
    );
  }
}

class NayaPothaViewModel extends StateNotifier<NayaPothaState> {
  final DatabaseService _dbService;

  NayaPothaViewModel(this._dbService) : super(NayaPothaState()) {
    loadLedger();
  }

  Future<void> loadLedger() async {
    final customers = await _dbService.getCreditAccounts();
    final suppliers = await _dbService.getSupplierAccounts();
    state = state.copyWith(customers: customers, suppliers: suppliers);
  }

  void changeTab(String tab) {
    state = state.copyWith(activeTab: tab);
  }

  void updateSearchKeyword(String keyword) {
    state = state.copyWith(searchKeyword: keyword.toLowerCase());
  }

  double get totalCustomerDebt {
    return state.customers.fold(0.0, (sum, acc) => sum + acc.balance);
  }

  int get overdueRemindersCount {
    // Treat any customer debt > 0 as a reminder candidate
    return state.customers.where((acc) => acc.balance > 0).length;
  }

  List<CreditAccount> get filteredCustomers {
    if (state.searchKeyword.isEmpty) return state.customers;
    return state.customers.where((acc) {
      return acc.name.toLowerCase().contains(state.searchKeyword) ||
          acc.phone.contains(state.searchKeyword);
    }).toList();
  }

  List<SupplierAccount> get filteredSuppliers {
    if (state.searchKeyword.isEmpty) return state.suppliers;
    return state.suppliers.where((acc) {
      return acc.name.toLowerCase().contains(state.searchKeyword) ||
          acc.phone.contains(state.searchKeyword);
    }).toList();
  }

  Future<void> addCustomerAccount(String name, String phone, double initialBalance) async {
    final newAccount = CreditAccount(
      name: name,
      phone: phone,
      balance: initialBalance,
      lastUpdated: DateTime.now(),
    );
    await _dbService.insertCreditAccount(newAccount);
    await loadLedger();
  }

  Future<void> addSupplierAccount(String name, String phone, double initialBalance, DateTime dueDate) async {
    final newAccount = SupplierAccount(
      name: name,
      phone: phone,
      balance: initialBalance,
      dueDate: dueDate,
      lastUpdated: DateTime.now(),
    );
    await _dbService.insertSupplierAccount(newAccount);
    await loadLedger();
  }

  Future<void> recordCustomerPayment(int id, double amount) async {
    final matches = state.customers.where((acc) => acc.id == id).toList();
    if (matches.isNotEmpty) {
      final account = matches.first;
      final newBalance = (account.balance - amount).clamp(0.0, double.infinity);
      await _dbService.updateCreditAccount(account.copyWith(
        balance: newBalance,
        lastUpdated: DateTime.now(),
      ));
      await loadLedger();
    }
  }

  Future<void> recordSupplierPayment(int id, double amount) async {
    final matches = state.suppliers.where((acc) => acc.id == id).toList();
    if (matches.isNotEmpty) {
      final account = matches.first;
      final newBalance = (account.balance - amount).clamp(0.0, double.infinity);
      await _dbService.updateSupplierAccount(account.copyWith(
        balance: newBalance,
        lastUpdated: DateTime.now(),
      ));
      await loadLedger();
    }
  }

  Future<void> deleteCustomer(int id) async {
    await _dbService.deleteCreditAccount(id);
    await loadLedger();
  }

  Future<void> deleteSupplier(int id) async {
    await _dbService.deleteSupplierAccount(id);
    await loadLedger();
  }

  // Pre-filled WhatsApp notification message content
  String getWhatsAppMessage(CreditAccount account, String shopName) {
    return 'Dear ${account.name},\n'
        'This is a friendly reminder that you have an outstanding credit balance of LKR ${account.balance.toStringAsFixed(0)} at $shopName.\n'
        'Please settle your payment at the counter or transfer to HNB Bank Account: 123-456-789. Thank you!';
  }
}

final nayaPothaProvider =
    StateNotifierProvider<NayaPothaViewModel, NayaPothaState>((ref) {
  return NayaPothaViewModel(DatabaseService.instance);
});
