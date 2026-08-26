import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/business_config.dart';
import '../models/sale.dart';
import '../models/inventory_item.dart';
import '../models/credit_account.dart';
import '../models/supplier_account.dart';
import '../models/expense.dart';

class DatabaseService {
  static final DatabaseService instance = DatabaseService._init();
  static Database? _database;

  DatabaseService._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('lankapos.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 8,
      onCreate: _createDB,
      onUpgrade: _upgradeDB,
    );
  }

  Future<void> _createDB(Database db, int version) async {
    // Create Business Config Table (Version 6 upgrade)
    await db.execute('''
      CREATE TABLE business_config (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        shopName TEXT NOT NULL,
        address TEXT NOT NULL,
        phoneNumber TEXT NOT NULL,
        businessType TEXT NOT NULL,
        receiptLanguage TEXT NOT NULL,
        nayaPothaEnabled INTEGER NOT NULL,
        kotEnabled INTEGER NOT NULL,
        lankaQrEnabled INTEGER NOT NULL,
        footerMessage TEXT NOT NULL DEFAULT 'Thank You Come Again!',
        cashierLockEnabled INTEGER NOT NULL DEFAULT 0,
        cashierPin TEXT NOT NULL DEFAULT '1234'
      )
    ''');

    // Create Sales Table
    await db.execute('''
      CREATE TABLE sales (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        timestamp TEXT NOT NULL,
        totalAmount REAL NOT NULL,
        paymentMethod TEXT NOT NULL,
        customerName TEXT,
        orderType TEXT NOT NULL DEFAULT 'Retail',
        discountAmount REAL NOT NULL DEFAULT 0.0
      )
    ''');

    // Create Sale Items Table
    await db.execute('''
      CREATE TABLE sale_items (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        saleId INTEGER NOT NULL,
        name TEXT NOT NULL,
        price REAL NOT NULL,
        quantity INTEGER NOT NULL,
        discount REAL NOT NULL DEFAULT 0.0,
        FOREIGN KEY (saleId) REFERENCES sales (id) ON DELETE CASCADE
      )
    ''');

    // Create Inventory Table
    await db.execute('''
      CREATE TABLE inventory (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        stock REAL NOT NULL,
        unit TEXT NOT NULL,
        minStock REAL NOT NULL,
        price REAL NOT NULL,
        barcode TEXT NOT NULL DEFAULT '',
        category TEXT NOT NULL DEFAULT 'General',
        costPrice REAL NOT NULL DEFAULT 0.0,
        stockType TEXT NOT NULL DEFAULT 'General'
      )
    ''');

    // Create Credit Accounts Table
    await db.execute('''
      CREATE TABLE credit_accounts (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL UNIQUE,
        phone TEXT NOT NULL DEFAULT '',
        balance REAL NOT NULL DEFAULT 0.0,
        lastUpdated TEXT NOT NULL
      )
    ''');

    // Create Supplier Ledger Table
    await db.execute('''
      CREATE TABLE supplier_ledger (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL UNIQUE,
        phone TEXT NOT NULL DEFAULT '',
        balance REAL NOT NULL DEFAULT 0.0,
        dueDate TEXT NOT NULL,
        lastUpdated TEXT NOT NULL
      )
    ''');

    // Create Expenses Table
    await db.execute('''
      CREATE TABLE expenses (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        category TEXT NOT NULL,
        amount REAL NOT NULL,
        note TEXT NOT NULL DEFAULT '',
        photoPath TEXT NOT NULL DEFAULT '',
        timestamp TEXT NOT NULL
      )
    ''');

    // Create Product Ingredients Table (Version 8)
    await db.execute('''
      CREATE TABLE product_ingredients (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        productId INTEGER NOT NULL,
        ingredientId INTEGER NOT NULL,
        quantity REAL NOT NULL,
        FOREIGN KEY (productId) REFERENCES inventory (id) ON DELETE CASCADE,
        FOREIGN KEY (ingredientId) REFERENCES inventory (id) ON DELETE CASCADE
      )
    ''');
  }

  Future<void> _upgradeDB(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 6) {
      await db.execute('DROP TABLE IF EXISTS sale_items');
      await db.execute('DROP TABLE IF EXISTS sales');
      await db.execute('DROP TABLE IF EXISTS business_config');
      await db.execute('DROP TABLE IF EXISTS inventory');
      await db.execute('DROP TABLE IF EXISTS credit_accounts');
      await db.execute('DROP TABLE IF EXISTS supplier_ledger');
      await db.execute('DROP TABLE IF EXISTS expenses');
      await _createDB(db, newVersion);
    }
    if (oldVersion < 7) {
      await db.execute('DROP TABLE IF EXISTS recipes');
      await db.execute('''
        CREATE TABLE recipes (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          productId INTEGER NOT NULL,
          ingredientId INTEGER NOT NULL,
          quantity REAL NOT NULL,
          FOREIGN KEY (productId) REFERENCES inventory (id) ON DELETE CASCADE,
          FOREIGN KEY (ingredientId) REFERENCES inventory (id) ON DELETE CASCADE
        )
      ''');
    }
    if (oldVersion < 8) {
      await db.execute('DROP TABLE IF EXISTS recipes');
      await db.execute('DROP TABLE IF EXISTS product_ingredients');
      try {
        await db.execute("ALTER TABLE inventory ADD COLUMN stockType TEXT NOT NULL DEFAULT 'General'");
      } catch (_) {}
      await db.execute('''
        CREATE TABLE product_ingredients (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          productId INTEGER NOT NULL,
          ingredientId INTEGER NOT NULL,
          quantity REAL NOT NULL,
          FOREIGN KEY (productId) REFERENCES inventory (id) ON DELETE CASCADE,
          FOREIGN KEY (ingredientId) REFERENCES inventory (id) ON DELETE CASCADE
        )
      ''');
    }
  }

  // --- Business Config operations ---
  Future<int> saveBusinessConfig(BusinessConfig config) async {
    final db = await database;
    await db.delete('business_config');
    return await db.insert('business_config', config.toMap());
  }

  Future<void> initializeDefaultData(String businessType) async {
    // await populateDefaultInventory(businessType);
    // await populateDefaultNaya();
  }

  Future<BusinessConfig?> getBusinessConfig() async {
    final db = await database;
    final maps = await db.query('business_config');
    if (maps.isNotEmpty) {
      return BusinessConfig.fromMap(maps.first);
    }
    return null;
  }

  Future<int> deleteBusinessConfig() async {
    final db = await database;
    return await db.delete('business_config');
  }

  // --- Inventory operations ---
  Future<List<InventoryItem>> getInventory() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('inventory');
    return maps.map((map) => InventoryItem.fromMap(map)).toList();
  }

  Future<int> insertInventoryItem(InventoryItem item) async {
    final db = await database;
    return await db.insert('inventory', item.toMap());
  }

  Future<int> updateInventoryItem(InventoryItem item) async {
    final db = await database;
    return await db.update(
      'inventory',
      item.toMap(),
      where: 'id = ?',
      whereArgs: [item.id],
    );
  }

  Future<int> deleteInventoryItem(int id) async {
    final db = await database;
    return await db.delete(
      'inventory',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> deductStock(String name, double quantity) async {
    final db = await database;
    final maps = await db.query('inventory', where: 'name = ?', whereArgs: [name]);
    if (maps.isNotEmpty) {
      final item = InventoryItem.fromMap(maps.first);
      final newStock = (item.stock - quantity).clamp(0.0, 9999.0);
      await db.update(
        'inventory',
        item.copyWith(stock: newStock).toMap(),
        where: 'name = ?',
        whereArgs: [name],
      );
    }
  }

  // Future<void> populateDefaultInventory(String businessType) async {
  //   final db = await database;
  //   await db.delete('inventory');

  //   final List<InventoryItem> defaults = [];

  //   if (businessType == 'Cafe & Bakery') {
  //     defaults.addAll([
  //       InventoryItem(name: 'Egg Bun', stock: 50, unit: 'pcs', minStock: 10, price: 120.0, costPrice: 90.0, barcode: '4792000201', category: 'Short Eats'),
  //       InventoryItem(name: 'Fish Pastry', stock: 40, unit: 'pcs', minStock: 10, price: 140.0, costPrice: 110.0, barcode: '4792000202', category: 'Short Eats'),
  //       InventoryItem(name: 'Ulundu Vadai', stock: 60, unit: 'pcs', minStock: 15, price: 80.0, costPrice: 50.0, barcode: '4792000203', category: 'Short Eats'),
  //       InventoryItem(name: 'Milk Coffee', stock: 100, unit: 'cups', minStock: 20, price: 150.0, costPrice: 90.0, barcode: '4792000204', category: 'Beverages'),
  //       InventoryItem(name: 'Plain Tea', stock: 120, unit: 'cups', minStock: 20, price: 60.0, costPrice: 30.0, barcode: '4792000205', category: 'Beverages'),
  //       InventoryItem(name: 'Chocolate Gateau Slice', stock: 15, unit: 'pcs', minStock: 5, price: 350.0, costPrice: 280.0, barcode: '4792000206', category: 'Snacks'),
  //       InventoryItem(name: 'Woodapple Juice', stock: 30, unit: 'pcs', minStock: 8, price: 200.0, costPrice: 140.0, barcode: '4792000207', category: 'Beverages'),
  //     ]);
  //   } else if (businessType == 'Restaurant & Hotel') {
  //     defaults.addAll([
  //       InventoryItem(name: 'Chicken Kottu (L)', stock: 35, unit: 'plates', minStock: 5, price: 850.0, costPrice: 650.0, barcode: '4793000301', category: 'Kottu'),
  //       InventoryItem(name: 'Egg Kottu', stock: 40, unit: 'plates', minStock: 5, price: 650.0, costPrice: 480.0, barcode: '4793000302', category: 'Kottu'),
  //       InventoryItem(name: 'Cheese Kottu', stock: 20, unit: 'plates', minStock: 5, price: 950.0, costPrice: 700.0, barcode: '4793000303', category: 'Kottu'),
  //       InventoryItem(name: 'Chicken Fried Rice', stock: 50, unit: 'plates', minStock: 8, price: 800.0, costPrice: 600.0, barcode: '4793000304', category: 'Rice'),
  //       InventoryItem(name: 'Seni Sambal Egg Hopper', stock: 80, unit: 'pcs', minStock: 15, price: 120.0, costPrice: 80.0, barcode: '4793000305', category: 'Hoppers'),
  //       InventoryItem(name: 'Plain Hopper', stock: 150, unit: 'pcs', minStock: 25, price: 50.0, costPrice: 25.0, barcode: '4793000306', category: 'Hoppers'),
  //       InventoryItem(name: 'Ginger Beer (EGB)', stock: 60, unit: 'bottles', minStock: 12, price: 180.0, costPrice: 130.0, barcode: '4793000307', category: 'Beverages'),
  //     ]);
  //   } else if (businessType == 'Service & Other') {
  //     defaults.addAll([
  //       InventoryItem(name: 'Standard Haircut', stock: 999, unit: 'sessions', minStock: 0, price: 700.0, costPrice: 150.0, barcode: '4794000401', category: 'Salon'),
  //       InventoryItem(name: 'Beard Trim & Style', stock: 999, unit: 'sessions', minStock: 0, price: 400.0, costPrice: 100.0, barcode: '4794000402', category: 'Salon'),
  //       InventoryItem(name: 'Full Vehicle Wash', stock: 100, unit: 'cars', minStock: 10, price: 2500.0, costPrice: 800.0, barcode: '4794000403', category: 'Car Care'),
  //       InventoryItem(name: 'Interior Detailing', stock: 50, unit: 'cars', minStock: 5, price: 1500.0, costPrice: 500.0, barcode: '4794000404', category: 'Car Care'),
  //       InventoryItem(name: 'General Consultation', stock: 999, unit: 'sessions', minStock: 0, price: 1000.0, costPrice: 0.0, barcode: '4794000405', category: 'General'),
  //       InventoryItem(name: 'Urgent Device Repair', stock: 100, unit: 'repairs', minStock: 5, price: 3000.0, costPrice: 1200.0, barcode: '4794000406', category: 'General'),
  //     ]);
  //   } else {
  //     defaults.addAll([
  //       InventoryItem(name: 'Keeri Samba Rice 5kg', stock: 45, unit: 'Bags', minStock: 10, price: 1200.0, costPrice: 1050.0, barcode: '47920010012', category: 'Groceries'),
  //       InventoryItem(name: 'Anchor Milk Powder 400g', stock: 3, unit: 'Boxes', minStock: 5, price: 1150.0, costPrice: 1020.0, barcode: '94100010022', category: 'Dairy'),
  //       InventoryItem(name: 'Munchee Super Cream Cracker 190g', stock: 18, unit: 'Packs', minStock: 8, price: 250.0, costPrice: 210.0, barcode: '47910020001', category: 'Snacks'),
  //       InventoryItem(name: 'Astra Margarine 250g', stock: 15, unit: 'tubs', minStock: 5, price: 550.0, costPrice: 480.0, barcode: '4791000103', category: 'Dairy'),
  //       InventoryItem(name: 'White Sugar 1kg', stock: 200, unit: 'kg', minStock: 30, price: 240.0, costPrice: 210.0, barcode: '4791000102', category: 'Groceries'),
  //       InventoryItem(name: 'Red Dhal 1kg', stock: 120, unit: 'kg', minStock: 20, price: 320.0, costPrice: 280.0, barcode: '4791000104', category: 'Groceries'),
  //       InventoryItem(name: 'Dilmah Tea 100g', stock: 60, unit: 'boxes', minStock: 10, price: 450.0, costPrice: 380.0, barcode: '4791000105', category: 'Beverages'),
  //       InventoryItem(name: 'Coconut Oil 1L', stock: 75, unit: 'bottles', minStock: 12, price: 680.0, costPrice: 590.0, barcode: '4791000106', category: 'Groceries'),
  //     ]);
  //   }

  //   for (var item in defaults) {
  //     await db.insert('inventory', item.toMap());
  //   }
  // }

  // --- Credit Accounts (Debtors) operations ---
  Future<List<CreditAccount>> getCreditAccounts() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('credit_accounts', orderBy: 'balance DESC');
    return maps.map((map) => CreditAccount.fromMap(map)).toList();
  }

  Future<int> insertCreditAccount(CreditAccount account) async {
    final db = await database;
    return await db.insert('credit_accounts', account.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<int> updateCreditAccount(CreditAccount account) async {
    final db = await database;
    return await db.update(
      'credit_accounts',
      account.toMap(),
      where: 'id = ?',
      whereArgs: [account.id],
    );
  }

  Future<int> deleteCreditAccount(int id) async {
    final db = await database;
    return await db.delete('credit_accounts', where: 'id = ?', whereArgs: [id]);
  }

  // --- Supplier Ledger operations ---
  Future<List<SupplierAccount>> getSupplierAccounts() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('supplier_ledger', orderBy: 'balance DESC');
    return maps.map((map) => SupplierAccount.fromMap(map)).toList();
  }

  Future<int> insertSupplierAccount(SupplierAccount account) async {
    final db = await database;
    return await db.insert('supplier_ledger', account.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<int> updateSupplierAccount(SupplierAccount account) async {
    final db = await database;
    return await db.update(
      'supplier_ledger',
      account.toMap(),
      where: 'id = ?',
      whereArgs: [account.id],
    );
  }

  Future<int> deleteSupplierAccount(int id) async {
    final db = await database;
    return await db.delete('supplier_ledger', where: 'id = ?', whereArgs: [id]);
  }

  // --- Expenses operations ---
  Future<List<Expense>> getExpenses() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('expenses', orderBy: 'timestamp DESC');
    return maps.map((map) => Expense.fromMap(map)).toList();
  }

  Future<int> insertExpense(Expense expense) async {
    final db = await database;
    return await db.insert('expenses', expense.toMap());
  }

  Future<int> deleteExpense(int id) async {
    final db = await database;
    return await db.delete('expenses', where: 'id = ?', whereArgs: [id]);
  }

  // Future<void> populateDefaultNaya() async {
  //   final db = await database;
  //   await db.delete('credit_accounts');
  //   await db.delete('supplier_ledger');
  //   await db.delete('expenses');

  //   final debtors = [
  //     CreditAccount(name: 'Nimal Perera', phone: '0771234567', balance: 12400.0, lastUpdated: DateTime.now().subtract(const Duration(days: 2))),
  //     CreditAccount(name: 'Saman Kumara', phone: '0719876543', balance: 3200.0, lastUpdated: DateTime.now()),
  //     CreditAccount(name: 'Pathum Bandara', phone: '0725556666', balance: 4500.0, lastUpdated: DateTime.now().subtract(const Duration(days: 3))),
  //   ];

  //   for (var debtor in debtors) {
  //     await db.insert('credit_accounts', debtor.toMap());
  //   }

  //   final suppliers = [
  //     SupplierAccount(name: 'Cargills Foods', phone: '0112345678', balance: 35000.0, dueDate: DateTime.now().add(const Duration(days: 3)), lastUpdated: DateTime.now().subtract(const Duration(days: 1))),
  //     SupplierAccount(name: 'Unilever Ceylon', phone: '0119876543', balance: 18500.0, dueDate: DateTime.now().add(const Duration(days: 7)), lastUpdated: DateTime.now().subtract(const Duration(days: 2))),
  //     SupplierAccount(name: 'Local Veggie Wholesale', phone: '0779998888', balance: 5000.0, dueDate: DateTime.now().add(const Duration(days: 1)), lastUpdated: DateTime.now()),
  //   ];

  //   for (var supplier in suppliers) {
  //     await db.insert('supplier_ledger', supplier.toMap());
  //   }

  //   final expensesList = [
  //     Expense(category: 'Rent', amount: 30000.0, note: 'Shop rent for August', timestamp: DateTime(DateTime.now().year, DateTime.now().month, 1)),
  //     Expense(category: 'Bills', amount: 12000.0, note: 'CEB Electricity bill payment', timestamp: DateTime(DateTime.now().year, DateTime.now().month, 5)),
  //     Expense(category: 'Wages', amount: 25000.0, note: 'Assistant helper cashier salary', timestamp: DateTime(DateTime.now().year, DateTime.now().month, 10)),
  //   ];

  //   for (var exp in expensesList) {
  //     await db.insert('expenses', exp.toMap());
  //   }
  // }

  // --- Sales operations ---
  Future<int> insertSale(Sale sale) async {
    final db = await database;
    return await db.transaction((txn) async {
      final saleId = await txn.insert('sales', sale.toMap());

      for (var item in sale.items) {
        await txn.insert('sale_items', item.toMap(saleId));
        
        // Check if this product has linked ingredients
        final List<Map<String, dynamic>> ingredientItems = await txn.rawQuery('''
          SELECT ingredientId, quantity FROM product_ingredients WHERE productId = (
            SELECT id FROM inventory WHERE name = ? LIMIT 1
          )
        ''', [item.name]);

        if (ingredientItems.isNotEmpty) {
          // If linked ingredients are found, deduct them instead
          for (var recipeItem in ingredientItems) {
            final double quantityToDeduct = item.quantity * (recipeItem['quantity'] as num).toDouble();
            await txn.execute(
              'UPDATE inventory SET stock = MAX(0, stock - ?) WHERE id = ?',
              [quantityToDeduct, recipeItem['ingredientId']],
            );
          }
        } else {
          // Default fallback: deduct the sellable product's own stock
          await txn.execute(
            'UPDATE inventory SET stock = MAX(0, stock - ?) WHERE name = ?',
            [item.quantity, item.name],
          );
        }
      }

      if (sale.paymentMethod == 'Naya Potha' && sale.customerName != null) {
        final cName = sale.customerName!.trim();
        final List<Map<String, dynamic>> matches = await txn.query(
          'credit_accounts',
          where: 'name = ?',
          whereArgs: [cName],
        );

        if (matches.isNotEmpty) {
          final account = CreditAccount.fromMap(matches.first);
          await txn.update(
            'credit_accounts',
            account.copyWith(
              balance: account.balance + sale.totalAmount,
              lastUpdated: DateTime.now(),
            ).toMap(),
            where: 'name = ?',
            whereArgs: [cName],
          );
        } else {
          await txn.insert(
            'credit_accounts',
            CreditAccount(
              name: cName,
              phone: '0770000000',
              balance: sale.totalAmount,
              lastUpdated: DateTime.now(),
            ).toMap(),
          );
        }
      }

      return saleId;
    });
  }

  Future<List<Sale>> getSales() async {
    final db = await database;
    final List<Map<String, dynamic>> saleMaps = await db.query('sales', orderBy: 'id DESC');
    
    final List<Sale> sales = [];
    for (var saleMap in saleMaps) {
      final saleId = saleMap['id'] as int;
      final List<Map<String, dynamic>> itemMaps = await db.query(
        'sale_items',
        where: 'saleId = ?',
        whereArgs: [saleId],
      );

      final items = itemMaps.map((m) => SaleItem.fromMap(m)).toList();
      sales.add(Sale.fromMap(saleMap, items));
    }
    return sales;
  }

  // --- Product Ingredients Operations (Version 8) ---
  Future<List<Map<String, dynamic>>> getProductIngredients(int productId) async {
    final db = await database;
    return await db.rawQuery('''
      SELECT r.id, r.productId, r.ingredientId, r.quantity, i.name, i.unit, i.stock
      FROM product_ingredients r
      JOIN inventory i ON r.ingredientId = i.id
      WHERE r.productId = ?
    ''', [productId]);
  }

  Future<void> saveProductIngredients(int productId, List<Map<String, dynamic>> ingredients) async {
    final db = await database;
    await db.transaction((txn) async {
      await txn.delete('product_ingredients', where: 'productId = ?', whereArgs: [productId]);
      for (var ing in ingredients) {
        await txn.insert('product_ingredients', {
          'productId': productId,
          'ingredientId': ing['ingredientId'],
          'quantity': ing['quantity'],
        });
      }
    });
  }

  Future<void> clearDatabase() async {
    final db = await database;
    await db.delete('business_config');
    await db.delete('sale_items');
    await db.delete('sales');
    await db.delete('inventory');
    await db.delete('credit_accounts');
    await db.delete('supplier_ledger');
    await db.delete('expenses');
    await db.delete('product_ingredients');
  }
}
