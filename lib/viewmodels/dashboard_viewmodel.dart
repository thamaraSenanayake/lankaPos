import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/business_config.dart';
import '../models/sale.dart';
import '../models/inventory_item.dart';
import '../services/database_service.dart';
import 'inventory_viewmodel.dart';
import 'naya_potha_viewmodel.dart';
import 'business_health_viewmodel.dart';

class ProductItem {
  final String name;
  final double price;
  final String category;
  final String emoji;

  ProductItem({
    required this.name,
    required this.price,
    required this.category,
    required this.emoji,
  });
}

class DashboardState {
  final BusinessConfig? config;
  final List<SaleItem> cart;
  final List<Sale> salesHistory;
  final List<ProductItem> availableProducts;
  final String activeTab; // 'register', 'orders', 'reports' (inventory is separate)
  final List<Sale> activeKotQueue; 
  final bool isProcessingCheckout;
  final String orderType; // 'Retail', 'Dine-In', 'Takeaway', 'Delivery'
  final double cartDiscount; // overall percentage discount (0-100)
  final String searchKeyword;

  DashboardState({
    this.config,
    this.cart = const [],
    this.salesHistory = const [],
    this.availableProducts = const [],
    this.activeTab = 'register',
    this.activeKotQueue = const [],
    this.isProcessingCheckout = false,
    this.orderType = 'Retail',
    this.cartDiscount = 0.0,
    this.searchKeyword = '',
  });

  DashboardState copyWith({
    BusinessConfig? config,
    List<SaleItem>? cart,
    List<Sale>? salesHistory,
    List<ProductItem>? availableProducts,
    String? activeTab,
    List<Sale>? activeKotQueue,
    bool? isProcessingCheckout,
    String? orderType,
    double? cartDiscount,
    String? searchKeyword,
  }) {
    return DashboardState(
      config: config ?? this.config,
      cart: cart ?? this.cart,
      salesHistory: salesHistory ?? this.salesHistory,
      availableProducts: availableProducts ?? this.availableProducts,
      activeTab: activeTab ?? this.activeTab,
      activeKotQueue: activeKotQueue ?? this.activeKotQueue,
      isProcessingCheckout: isProcessingCheckout ?? this.isProcessingCheckout,
      orderType: orderType ?? this.orderType,
      cartDiscount: cartDiscount ?? this.cartDiscount,
      searchKeyword: searchKeyword ?? this.searchKeyword,
    );
  }
}

class DashboardViewModel extends StateNotifier<DashboardState> {
  final DatabaseService _dbService;
  final Ref _ref;

  DashboardViewModel(this._dbService, this._ref) : super(DashboardState()) {
    initDashboard();

    // Reactively listen to external inventory updates to keep products catalog sync'd
    _ref.listen<InventoryState>(inventoryProvider, (previous, next) {
      _syncProductsFromInventory(next.inventory);
    });
  }

  Future<void> initDashboard() async {
    final config = await _dbService.getBusinessConfig();
    if (config != null) {
      final sales = await _dbService.getSales();
      final inventory = await _dbService.getInventory();

      String defaultOrderType = 'Retail';
      if (config.businessType == 'Restaurant & Hotel' || config.businessType == 'Cafe & Bakery') {
        defaultOrderType = 'Dine-In';
      }

      state = state.copyWith(
        config: config,
        salesHistory: sales,
        availableProducts: _mapInventoryToProducts(inventory),
        orderType: defaultOrderType,
      );
    }
  }

  void _syncProductsFromInventory(List<InventoryItem> items) {
    state = state.copyWith(
      availableProducts: _mapInventoryToProducts(items),
    );
  }

  List<ProductItem> _mapInventoryToProducts(List<InventoryItem> items) {
    return items.map((item) {
      return ProductItem(
        name: item.name,
        price: item.price,
        category: item.category,
        emoji: _getEmojiForCategory(item.category, item.name),
      );
    }).toList();
  }

  String _getEmojiForCategory(String category, String name) {
    final c = category.toLowerCase();
    final n = name.toLowerCase();
    if (n.contains('rice')) return '🌾';
    if (n.contains('sugar')) return '🍬';
    if (n.contains('milk')) return '🥛';
    if (n.contains('tea') || n.contains('coffee')) return '☕';
    if (n.contains('kottu') || n.contains('fried rice')) return '🍛';
    if (n.contains('hopper')) return '🥞';
    if (n.contains('bun') || n.contains('pastry') || n.contains('cracker') || n.contains('cookie') || n.contains('puff') || n.contains('bread')) return '🍪';
    if (c.contains('beverage') || c.contains('juice') || n.contains('beer')) return '🥤';
    if (c.contains('short') || c.contains('snack')) return '🥯';
    if (c.contains('dairy') || c.contains('cheese')) return '🧀';
    if (c.contains('salon') || n.contains('hair') || n.contains('trim')) return '✂️';
    if (c.contains('car') || n.contains('wash')) return '🚗';
    return '📦';
  }

  void updateSearchKeyword(String keyword) {
    state = state.copyWith(searchKeyword: keyword.toLowerCase());
  }

  List<ProductItem> get filteredProducts {
    final keyword = state.searchKeyword;
    if (keyword.isEmpty) return state.availableProducts;
    
    // Check if searched keyword is a scanned barcode matching in inventory
    final matchingBarcodeItems = _ref.read(inventoryProvider).inventory
        .where((item) => item.barcode == keyword).toList();
        
    if (matchingBarcodeItems.isNotEmpty) {
      final matchedNames = matchingBarcodeItems.map((e) => e.name).toSet();
      return state.availableProducts.where((p) => matchedNames.contains(p.name)).toList();
    }

    return state.availableProducts.where((p) {
      return p.name.toLowerCase().contains(keyword) ||
          p.category.toLowerCase().contains(keyword);
    }).toList();
  }

  void setOrderType(String type) {
    state = state.copyWith(orderType: type);
  }

  void addToCart(ProductItem product) {
    final existingIndex = state.cart.indexWhere((item) => item.name == product.name);
    if (existingIndex >= 0) {
      final updatedCart = List<SaleItem>.from(state.cart);
      final existingItem = updatedCart[existingIndex];
      updatedCart[existingIndex] = existingItem.copyWith(
        quantity: existingItem.quantity + 1,
      );
      state = state.copyWith(cart: updatedCart);
    } else {
      state = state.copyWith(
        cart: [...state.cart, SaleItem(name: product.name, price: product.price, quantity: 1, discount: 0.0)],
      );
    }
  }

  void addScannedBarcodeToCart(String barcode) {
    final matchingItems = _ref.read(inventoryProvider).inventory
        .where((item) => item.barcode == barcode).toList();
    if (matchingItems.isNotEmpty) {
      final item = matchingItems.first;
      final product = ProductItem(
        name: item.name,
        price: item.price,
        category: item.category,
        emoji: _getEmojiForCategory(item.category, item.name),
      );
      addToCart(product);
    }
  }

  void removeFromCart(String name) {
    state = state.copyWith(
      cart: state.cart.where((item) => item.name != name).toList(),
    );
  }

  void updateQuantity(String name, int change) {
    final updatedCart = state.cart.map((item) {
      if (item.name == name) {
        final newQuantity = item.quantity + change;
        return newQuantity > 0
            ? item.copyWith(quantity: newQuantity)
            : item;
      }
      return item;
    }).toList();
    state = state.copyWith(cart: updatedCart);
  }

  void updateItemDiscount(String name, double discount) {
    final updatedCart = state.cart.map((item) {
      if (item.name == name) {
        return item.copyWith(discount: discount.clamp(0.0, 100.0));
      }
      return item;
    }).toList();
    state = state.copyWith(cart: updatedCart);
  }

  void updateCartDiscount(double discount) {
    state = state.copyWith(cartDiscount: discount.clamp(0.0, 100.0));
  }

  void clearCart() {
    state = state.copyWith(cart: [], cartDiscount: 0.0);
  }

  void changeTab(String tab) {
    state = state.copyWith(activeTab: tab);
  }

  double get cartSubtotal {
    return state.cart.fold(0.0, (sum, item) => sum + item.total);
  }

  double get cartDiscountAmount {
    return cartSubtotal * (state.cartDiscount / 100);
  }

  double get cartTotal {
    return (cartSubtotal - cartDiscountAmount).clamp(0.0, double.infinity);
  }

  Future<bool> checkout({required String paymentMethod, String? customerName}) async {
    if (state.cart.isEmpty) return false;
    state = state.copyWith(isProcessingCheckout: true);

    final finalTotal = cartTotal;
    final finalDiscountAmount = cartDiscountAmount;

    final newSale = Sale(
      timestamp: DateTime.now(),
      items: List<SaleItem>.from(state.cart),
      totalAmount: finalTotal,
      paymentMethod: paymentMethod,
      customerName: customerName,
      orderType: state.orderType,
      discountAmount: finalDiscountAmount,
    );

    try {
      final saleId = await _dbService.insertSale(newSale);
      final savedSale = Sale(
        id: saleId,
        timestamp: newSale.timestamp,
        items: newSale.items,
        totalAmount: newSale.totalAmount,
        paymentMethod: newSale.paymentMethod,
        customerName: newSale.customerName,
        orderType: newSale.orderType,
        discountAmount: newSale.discountAmount,
      );

      final updatedHistory = [savedSale, ...state.salesHistory];
      final updatedKotQueue = state.config?.kotEnabled == true && state.orderType == 'Dine-In'
          ? [...state.activeKotQueue, savedSale]
          : state.activeKotQueue;

      // Reload inventory values reactive state
      await _ref.read(inventoryProvider.notifier).loadInventory();

      state = state.copyWith(
        cart: [],
        cartDiscount: 0.0,
        salesHistory: updatedHistory,
        activeKotQueue: updatedKotQueue,
        isProcessingCheckout: false,
      );
      return true;
    } catch (_) {
      state = state.copyWith(isProcessingCheckout: false);
      return false;
    }
  }

  void completeKotOrder(int saleId) {
    state = state.copyWith(
      activeKotQueue: state.activeKotQueue.where((sale) => sale.id != saleId).toList(),
    );
  }

  // --- Reports Calculation Helper ---
  double get totalIncomeAllTime {
    return state.salesHistory.fold(0.0, (sum, sale) => sum + sale.totalAmount);
  }

  double get totalIncomeToday {
    final today = DateTime.now();
    return state.salesHistory
        .where((sale) =>
            sale.timestamp.year == today.year &&
            sale.timestamp.month == today.month &&
            sale.timestamp.day == today.day)
        .fold(0.0, (sum, sale) => sum + sale.totalAmount);
  }

  int get salesCountToday {
    final today = DateTime.now();
    return state.salesHistory
        .where((sale) =>
            sale.timestamp.year == today.year &&
            sale.timestamp.month == today.month &&
            sale.timestamp.day == today.day)
        .length;
  }

  Map<String, double> get paymentMethodBreakdown {
    final Map<String, double> breakdown = {
      'Cash': 0.0,
      'Card': 0.0,
      'LANKAQR': 0.0,
      'Naya Potha': 0.0,
    };
    for (var sale in state.salesHistory) {
      final method = sale.paymentMethod;
      breakdown[method] = (breakdown[method] ?? 0.0) + sale.totalAmount;
    }
    return breakdown;
  }

  List<MapEntry<String, int>> get topSellingProducts {
    final Map<String, int> counts = {};
    for (var sale in state.salesHistory) {
      for (var item in sale.items) {
        counts[item.name] = (counts[item.name] ?? 0) + item.quantity;
      }
    }
    final sorted = counts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return sorted.take(5).toList();
  }

  double get totalOutstandingNayaCredit {
    return state.salesHistory
        .where((sale) => sale.paymentMethod == 'Naya Potha')
        .fold(0.0, (sum, sale) => sum + sale.totalAmount);
  }

  Future<void> clearAllData() async {
    await _dbService.clearDatabase();
    state = DashboardState();
    await _ref.read(inventoryProvider.notifier).loadInventory();
    _ref.read(nayaPothaProvider.notifier).loadLedger();
    _ref.read(businessHealthProvider.notifier).loadHealth();
  }

  Future<void> updateConfig(BusinessConfig newConfig) async {
    await _dbService.saveBusinessConfig(newConfig);
    state = state.copyWith(config: newConfig);
  }
}

final dashboardProvider =
    StateNotifierProvider<DashboardViewModel, DashboardState>((ref) {
  return DashboardViewModel(DatabaseService.instance, ref);
});
