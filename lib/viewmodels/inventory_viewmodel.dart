import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/inventory_item.dart';
import '../services/database_service.dart';

class InventoryState {
  final List<InventoryItem> inventory;
  final String selectedCategoryFilter;
  final bool lowStockOnlyFilter;
  final String searchKeyword;

  InventoryState({
    this.inventory = const [],
    this.selectedCategoryFilter = 'All Categories',
    this.lowStockOnlyFilter = false,
    this.searchKeyword = '',
  });

  InventoryState copyWith({
    List<InventoryItem>? inventory,
    String? selectedCategoryFilter,
    bool? lowStockOnlyFilter,
    String? searchKeyword,
  }) {
    return InventoryState(
      inventory: inventory ?? this.inventory,
      selectedCategoryFilter: selectedCategoryFilter ?? this.selectedCategoryFilter,
      lowStockOnlyFilter: lowStockOnlyFilter ?? this.lowStockOnlyFilter,
      searchKeyword: searchKeyword ?? this.searchKeyword,
    );
  }
}

class InventoryViewModel extends StateNotifier<InventoryState> {
  final DatabaseService _dbService;

  InventoryViewModel(this._dbService) : super(InventoryState()) {
    loadInventory();
  }

  Future<void> loadInventory() async {
    final list = await _dbService.getInventory();
    state = state.copyWith(inventory: list);
  }

  void updateCategoryFilter(String category) {
    state = state.copyWith(selectedCategoryFilter: category);
  }

  void toggleLowStockFilter(bool value) {
    state = state.copyWith(lowStockOnlyFilter: value);
  }

  void updateSearchKeyword(String keyword) {
    state = state.copyWith(searchKeyword: keyword.toLowerCase());
  }

  int get lowStockCount {
    return state.inventory.where((item) => item.stock <= item.minStock).length;
  }

  List<String> get allCategoriesList {
    final categories = state.inventory.map((item) => item.category).toSet().toList();
    categories.sort();
    return ['All Categories', ...categories];
  }

  List<InventoryItem> get filteredInventory {
    List<InventoryItem> list = state.inventory;

    // Search filter
    if (state.searchKeyword.isNotEmpty) {
      list = list.where((item) {
        return item.name.toLowerCase().contains(state.searchKeyword) ||
            item.barcode.contains(state.searchKeyword);
      }).toList();
    }

    // Category filter
    if (state.selectedCategoryFilter != 'All Categories') {
      list = list.where((item) => item.category == state.selectedCategoryFilter).toList();
    }

    // Low stock filter
    if (state.lowStockOnlyFilter) {
      list = list.where((item) => item.stock <= item.minStock).toList();
    }

    return list;
  }

  Future<void> addProduct(InventoryItem item) async {
    await _dbService.insertInventoryItem(item);
    await loadInventory();
  }

  Future<void> editProduct(InventoryItem item) async {
    await _dbService.updateInventoryItem(item);
    await loadInventory();
  }

  Future<void> deleteProduct(int id) async {
    await _dbService.deleteInventoryItem(id);
    await loadInventory();
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

  String exportCsvData() {
    final buffer = StringBuffer();
    buffer.writeln('ID,Barcode,Name,Category,Stock,Unit,MinStock,CostPrice,SellingPrice');
    for (var item in state.inventory) {
      buffer.writeln('${item.id},${item.barcode},"${item.name}",${item.category},${item.stock},${item.unit},${item.minStock},${item.costPrice},${item.price}');
    }
    return buffer.toString();
  }

  Future<bool> importCsvData(String csvText) async {
    try {
      final lines = csvText.split('\n');
      if (lines.length <= 1) return false;

      for (int i = 1; i < lines.length; i++) {
        final line = lines[i].trim();
        if (line.isEmpty) continue;
        
        final parts = line.split(',');
        if (parts.length < 9) continue;

        final barcode = parts[1];
        final name = parts[2].replaceAll('"', '');
        final category = parts[3];
        final stock = double.tryParse(parts[4]) ?? 0.0;
        final unit = parts[5];
        final minStock = double.tryParse(parts[6]) ?? 0.0;
        final costPrice = double.tryParse(parts[7]) ?? 0.0;
        final price = double.tryParse(parts[8]) ?? 0.0;

        final matches = state.inventory.where((item) => item.barcode == barcode || item.name == name).toList();
        if (matches.isNotEmpty) {
          final matched = matches.first;
          await _dbService.updateInventoryItem(matched.copyWith(
            stock: stock,
            price: price,
            costPrice: costPrice,
            category: category,
            minStock: minStock,
            unit: unit,
          ));
        } else {
          await _dbService.insertInventoryItem(InventoryItem(
            name: name,
            stock: stock,
            unit: unit,
            minStock: minStock,
            price: price,
            costPrice: costPrice,
            barcode: barcode,
            category: category,
          ));
        }
      }

      await loadInventory();
      return true;
    } catch (_) {
      return false;
    }
  }
}

final inventoryProvider =
    StateNotifierProvider<InventoryViewModel, InventoryState>((ref) {
  return InventoryViewModel(DatabaseService.instance);
});
