import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/business_config.dart';
import '../models/sale.dart';
import '../models/inventory_item.dart';
import '../services/database_service.dart';

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
  final List<InventoryItem> inventory;
  final List<ProductItem> availableProducts;
  final String activeTab; // 'register', 'orders', 'inventory', 'reports'
  final List<Sale> activeKotQueue; 
  final bool isProcessingCheckout;
  final String orderType; // 'Retail', 'Dine-In', 'Takeaway', 'Delivery'
  final double cartDiscount; // overall percentage discount (0-100)
  final String searchKeyword;

  DashboardState({
    this.config,
    this.cart = const [],
    this.salesHistory = const [],
    this.inventory = const [],
    this.availableProducts = const [],
    this.activeTab = 'register', // default to register screen
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
    List<InventoryItem>? inventory,
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
      inventory: inventory ?? this.inventory,
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

  DashboardViewModel(this._dbService) : super(DashboardState()) {
    initDashboard();
  }

  Future<void> initDashboard() async {
    final config = await _dbService.getBusinessConfig();
    if (config != null) {
      final products = _loadProductsForType(config.businessType);
      final sales = await _dbService.getSales();
      final inventory = await _dbService.getInventory();

      // Set default order type based on business type
      String defaultOrderType = 'Retail';
      if (config.businessType == 'Restaurant & Hotel' || config.businessType == 'Cafe & Bakery') {
        defaultOrderType = 'Dine-In';
      }

      state = state.copyWith(
        config: config,
        availableProducts: products,
        salesHistory: sales,
        inventory: inventory,
        orderType: defaultOrderType,
      );
    }
  }

  List<ProductItem> _loadProductsForType(String type) {
    switch (type) {
      case 'Cafe & Bakery':
        return [
          ProductItem(name: 'Egg Bun', price: 120.0, category: 'Short Eats', emoji: '🥯'),
          ProductItem(name: 'Fish Pastry', price: 140.0, category: 'Short Eats', emoji: '🥐'),
          ProductItem(name: 'Ulundu Vadai', price: 80.0, category: 'Short Eats', emoji: '🍩'),
          ProductItem(name: 'Milk Coffee', price: 150.0, category: 'Beverages', emoji: '☕'),
          ProductItem(name: 'Plain Tea', price: 60.0, category: 'Beverages', emoji: '🍵'),
          ProductItem(name: 'Chocolate Gateau Slice', price: 350.0, category: 'Cakes', emoji: '🍰'),
          ProductItem(name: 'Woodapple Juice', price: 200.0, category: 'Beverages', emoji: '🥤'),
        ];
      case 'Restaurant & Hotel':
        return [
          ProductItem(name: 'Chicken Kottu (L)', price: 850.0, category: 'Kottu', emoji: '🍛'),
          ProductItem(name: 'Egg Kottu', price: 650.0, category: 'Kottu', emoji: '🍛'),
          ProductItem(name: 'Cheese Kottu', price: 950.0, category: 'Kottu', emoji: '🧀'),
          ProductItem(name: 'Chicken Fried Rice', price: 800.0, category: 'Rice', emoji: '🍚'),
          ProductItem(name: 'Seni Sambal Egg Hopper', price: 120.0, category: 'Hoppers', emoji: '🍳'),
          ProductItem(name: 'Plain Hopper', price: 50.0, category: 'Hoppers', emoji: '🥞'),
          ProductItem(name: 'Ginger Beer (EGB)', price: 180.0, category: 'Beverages', emoji: '🍺'),
        ];
      case 'Service & Other':
        return [
          ProductItem(name: 'Standard Haircut', price: 700.0, category: 'Salon', emoji: '✂️'),
          ProductItem(name: 'Beard Trim & Style', price: 400.0, category: 'Salon', emoji: '🪒'),
          ProductItem(name: 'Full Vehicle Wash', price: 2500.0, category: 'Car Care', emoji: '🚗'),
          ProductItem(name: 'Interior Detailing', price: 1500.0, category: 'Car Care', emoji: '🧼'),
          ProductItem(name: 'General Consultation', price: 1000.0, category: 'Service', emoji: '📋'),
          ProductItem(name: 'Urgent Device Repair', price: 3000.0, category: 'Repair', emoji: '🛠️'),
        ];
      case 'Grocery & Retail':
      default:
        return [
          ProductItem(name: 'Keeri Samba Rice 1kg', price: 280.0, category: 'Provisions', emoji: '🌾'),
          ProductItem(name: 'White Sugar 1kg', price: 240.0, category: 'Provisions', emoji: '🍬'),
          ProductItem(name: 'Astra Margarine 250g', price: 550.0, category: 'Dairy', emoji: '🧈'),
          ProductItem(name: 'Anchor Milk Powder 400g', price: 1050.0, category: 'Dairy', emoji: '🥛'),
          ProductItem(name: 'Red Dhal 1kg', price: 320.0, category: 'Provisions', emoji: '🧆'),
          ProductItem(name: 'Dilmah Tea 100g', price: 450.0, category: 'Beverages', emoji: '☕'),
          ProductItem(name: 'Coconut Oil 1L', price: 680.0, category: 'Provisions', emoji: '🥥'),
          ProductItem(name: 'Munchee Super Lemon Puff', price: 150.0, category: 'Snacks', emoji: '🍪'),
        ];
    }
  }

  void updateSearchKeyword(String keyword) {
    state = state.copyWith(searchKeyword: keyword.toLowerCase());
  }

  List<ProductItem> get filteredProducts {
    if (state.searchKeyword.isEmpty) return state.availableProducts;
    return state.availableProducts.where((p) {
      return p.name.toLowerCase().contains(state.searchKeyword) ||
          p.category.toLowerCase().contains(state.searchKeyword);
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

      // Reload inventory values from database to represent deducted stocks
      final updatedInventory = await _dbService.getInventory();

      state = state.copyWith(
        cart: [],
        cartDiscount: 0.0,
        salesHistory: updatedHistory,
        activeKotQueue: updatedKotQueue,
        inventory: updatedInventory,
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

  Future<void> restockInventoryItem(int itemId, double addQty) async {
    final updatedList = await Future.wait(state.inventory.map((item) async {
      if (item.id == itemId) {
        final updatedItem = item.copyWith(stock: item.stock + addQty);
        await _dbService.updateInventoryItem(updatedItem);
        return updatedItem;
      }
      return item;
    }));
    state = state.copyWith(inventory: updatedList);
  }

  Future<void> setInventoryStockDirect(int itemId, double directQty) async {
    final updatedList = await Future.wait(state.inventory.map((item) async {
      if (item.id == itemId) {
        final updatedItem = item.copyWith(stock: directQty.clamp(0.0, 9999.0));
        await _dbService.updateInventoryItem(updatedItem);
        return updatedItem;
      }
      return item;
    }));
    state = state.copyWith(inventory: updatedList);
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
  }
}

final dashboardProvider =
    StateNotifierProvider<DashboardViewModel, DashboardState>((ref) {
  return DashboardViewModel(DatabaseService.instance);
});
