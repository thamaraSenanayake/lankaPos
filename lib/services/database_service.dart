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
    await populateDefaultInventory(businessType);
    await populateDefaultNaya();
    await populateDefaultSales(businessType);
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

  Future<void> populateDefaultInventory(String businessType) async {
    final db = await database;
    await db.delete('product_ingredients');
    await db.delete('inventory');

    if (businessType == 'Cafe & Bakery') {
      // Raw Ingredients
      final flourId = await db.insert('inventory', InventoryItem(
        name: "Baker's Flour",
        stock: 50.0,
        unit: 'kg',
        minStock: 10.0,
        price: 220.0,
        costPrice: 175.0,
        barcode: '880001',
        category: 'Raw Materials',
        stockType: 'Ingredients',
      ).toMap());

      final eggsId = await db.insert('inventory', InventoryItem(
        name: 'Fresh Farm Eggs',
        stock: 150.0,
        unit: 'pcs',
        minStock: 25.0,
        price: 45.0,
        costPrice: 38.0,
        barcode: '880002',
        category: 'Raw Materials',
        stockType: 'Ingredients',
      ).toMap());

      final milkId = await db.insert('inventory', InventoryItem(
        name: "Fresh Cow's Milk",
        stock: 30.0,
        unit: 'L',
        minStock: 5.0,
        price: 380.0,
        costPrice: 300.0,
        barcode: '880003',
        category: 'Raw Materials',
        stockType: 'Ingredients',
      ).toMap());

      final sugarId = await db.insert('inventory', InventoryItem(
        name: 'Fine White Sugar',
        stock: 40.0,
        unit: 'kg',
        minStock: 10.0,
        price: 240.0,
        costPrice: 200.0,
        barcode: '880004',
        category: 'Raw Materials',
        stockType: 'Ingredients',
      ).toMap());

      final coffeeId = await db.insert('inventory', InventoryItem(
        name: 'Roasted Coffee Powder',
        stock: 10.0,
        unit: 'kg',
        minStock: 2.0,
        price: 2400.0,
        costPrice: 1800.0,
        barcode: '880005',
        category: 'Raw Materials',
        stockType: 'Ingredients',
      ).toMap());

      final teaId = await db.insert('inventory', InventoryItem(
        name: 'Ceylon BOPF Tea',
        stock: 12.0,
        unit: 'kg',
        minStock: 2.0,
        price: 1600.0,
        costPrice: 1200.0,
        barcode: '880006',
        category: 'Raw Materials',
        stockType: 'Ingredients',
      ).toMap());

      // Sellable Products with Linked Ingredients
      final eggBunId = await db.insert('inventory', InventoryItem(
        name: 'Egg Bun',
        stock: 50.0,
        unit: 'pcs',
        minStock: 10.0,
        price: 120.0,
        costPrice: 80.0,
        barcode: '4792000201',
        category: 'Short Eats',
        stockType: 'Products',
      ).toMap());

      final coffeeCupId = await db.insert('inventory', InventoryItem(
        name: 'Milk Coffee',
        stock: 100.0,
        unit: 'cups',
        minStock: 20.0,
        price: 150.0,
        costPrice: 90.0,
        barcode: '4792000204',
        category: 'Beverages',
        stockType: 'Products',
      ).toMap());

      final teaCupId = await db.insert('inventory', InventoryItem(
        name: 'Plain Tea',
        stock: 120.0,
        unit: 'cups',
        minStock: 20.0,
        price: 60.0,
        costPrice: 30.0,
        barcode: '4792000205',
        category: 'Beverages',
        stockType: 'Products',
      ).toMap());

      // Link recipes into product_ingredients
      await db.insert('product_ingredients', {'productId': eggBunId, 'ingredientId': flourId, 'quantity': 0.1});
      await db.insert('product_ingredients', {'productId': eggBunId, 'ingredientId': eggsId, 'quantity': 1.0});

      await db.insert('product_ingredients', {'productId': coffeeCupId, 'ingredientId': coffeeId, 'quantity': 0.015});
      await db.insert('product_ingredients', {'productId': coffeeCupId, 'ingredientId': milkId, 'quantity': 0.12});
      await db.insert('product_ingredients', {'productId': coffeeCupId, 'ingredientId': sugarId, 'quantity': 0.015});

      await db.insert('product_ingredients', {'productId': teaCupId, 'ingredientId': teaId, 'quantity': 0.01});
      await db.insert('product_ingredients', {'productId': teaCupId, 'ingredientId': sugarId, 'quantity': 0.015});

      // General Bakery Items
      final bakeryItems = [
        InventoryItem(name: 'Fish Pastry', stock: 40.0, unit: 'pcs', minStock: 10.0, price: 140.0, costPrice: 95.0, barcode: '4792000202', category: 'Short Eats', stockType: 'General'),
        InventoryItem(name: 'Ulundu Vadai', stock: 60.0, unit: 'pcs', minStock: 15.0, price: 80.0, costPrice: 50.0, barcode: '4792000203', category: 'Short Eats', stockType: 'General'),
        InventoryItem(name: 'Chicken Roll', stock: 35.0, unit: 'pcs', minStock: 10.0, price: 150.0, costPrice: 100.0, barcode: '4792000208', category: 'Short Eats', stockType: 'General'),
        InventoryItem(name: 'Kimbula Banis', stock: 45.0, unit: 'pcs', minStock: 10.0, price: 90.0, costPrice: 60.0, barcode: '4792000209', category: 'Short Eats', stockType: 'General'),
        InventoryItem(name: 'Chocolate Gateau Slice', stock: 18.0, unit: 'pcs', minStock: 5.0, price: 350.0, costPrice: 240.0, barcode: '4792000206', category: 'Snacks', stockType: 'General'),
        InventoryItem(name: 'Woodapple Juice', stock: 30.0, unit: 'glasses', minStock: 8.0, price: 200.0, costPrice: 140.0, barcode: '4792000207', category: 'Beverages', stockType: 'General'),
      ];
      for (var item in bakeryItems) {
        await db.insert('inventory', item.toMap());
      }
    } else if (businessType == 'Restaurant & Hotel') {
      // Raw Ingredients
      final rotiId = await db.insert('inventory', InventoryItem(
        name: 'Chopped Godamba Roti',
        stock: 30.0,
        unit: 'kg',
        minStock: 5.0,
        price: 450.0,
        costPrice: 300.0,
        barcode: '890001',
        category: 'Raw Materials',
        stockType: 'Ingredients',
      ).toMap());

      final eggsId = await db.insert('inventory', InventoryItem(
        name: 'Fresh Farm Eggs',
        stock: 140.0,
        unit: 'pcs',
        minStock: 20.0,
        price: 45.0,
        costPrice: 38.0,
        barcode: '890002',
        category: 'Raw Materials',
        stockType: 'Ingredients',
      ).toMap());

      final chickenId = await db.insert('inventory', InventoryItem(
        name: 'Curry Chicken Pieces',
        stock: 20.0,
        unit: 'kg',
        minStock: 4.0,
        price: 1300.0,
        costPrice: 950.0,
        barcode: '890003',
        category: 'Raw Materials',
        stockType: 'Ingredients',
      ).toMap());

      final cheeseId = await db.insert('inventory', InventoryItem(
        name: 'Cheddar Cheese Block',
        stock: 10.0,
        unit: 'kg',
        minStock: 2.0,
        price: 2800.0,
        costPrice: 2100.0,
        barcode: '890005',
        category: 'Raw Materials',
        stockType: 'Ingredients',
      ).toMap());

      final riceId = await db.insert('inventory', InventoryItem(
        name: 'Basmati Rice',
        stock: 40.0,
        unit: 'kg',
        minStock: 10.0,
        price: 650.0,
        costPrice: 480.0,
        barcode: '890006',
        category: 'Raw Materials',
        stockType: 'Ingredients',
      ).toMap());

      // Sellable Products
      final chkKottuId = await db.insert('inventory', InventoryItem(
        name: 'Chicken Kottu (L)',
        stock: 40.0,
        unit: 'plates',
        minStock: 5.0,
        price: 950.0,
        costPrice: 650.0,
        barcode: '4793000301',
        category: 'Kottu',
        stockType: 'Products',
      ).toMap());

      final cheeseKottuId = await db.insert('inventory', InventoryItem(
        name: 'Cheese Kottu',
        stock: 25.0,
        unit: 'plates',
        minStock: 5.0,
        price: 1150.0,
        costPrice: 800.0,
        barcode: '4793000303',
        category: 'Kottu',
        stockType: 'Products',
      ).toMap());

      final eggKottuId = await db.insert('inventory', InventoryItem(
        name: 'Egg Kottu',
        stock: 35.0,
        unit: 'plates',
        minStock: 5.0,
        price: 700.0,
        costPrice: 480.0,
        barcode: '4793000302',
        category: 'Kottu',
        stockType: 'Products',
      ).toMap());

      final friedRiceId = await db.insert('inventory', InventoryItem(
        name: 'Chicken Fried Rice',
        stock: 45.0,
        unit: 'plates',
        minStock: 8.0,
        price: 850.0,
        costPrice: 580.0,
        barcode: '4793000304',
        category: 'Rice',
        stockType: 'Products',
      ).toMap());

      // Link recipes
      await db.insert('product_ingredients', {'productId': chkKottuId, 'ingredientId': rotiId, 'quantity': 0.3});
      await db.insert('product_ingredients', {'productId': chkKottuId, 'ingredientId': chickenId, 'quantity': 0.15});
      await db.insert('product_ingredients', {'productId': chkKottuId, 'ingredientId': eggsId, 'quantity': 1.0});

      await db.insert('product_ingredients', {'productId': cheeseKottuId, 'ingredientId': rotiId, 'quantity': 0.3});
      await db.insert('product_ingredients', {'productId': cheeseKottuId, 'ingredientId': cheeseId, 'quantity': 0.08});
      await db.insert('product_ingredients', {'productId': cheeseKottuId, 'ingredientId': eggsId, 'quantity': 1.0});

      await db.insert('product_ingredients', {'productId': eggKottuId, 'ingredientId': rotiId, 'quantity': 0.3});
      await db.insert('product_ingredients', {'productId': eggKottuId, 'ingredientId': eggsId, 'quantity': 2.0});

      await db.insert('product_ingredients', {'productId': friedRiceId, 'ingredientId': riceId, 'quantity': 0.25});
      await db.insert('product_ingredients', {'productId': friedRiceId, 'ingredientId': chickenId, 'quantity': 0.1});
      await db.insert('product_ingredients', {'productId': friedRiceId, 'ingredientId': eggsId, 'quantity': 1.0});

      // Other Restaurant Items
      final restaurantItems = [
        InventoryItem(name: 'Seni Sambal Egg Hopper', stock: 80.0, unit: 'pcs', minStock: 15.0, price: 130.0, costPrice: 85.0, barcode: '4793000305', category: 'Hoppers', stockType: 'General'),
        InventoryItem(name: 'Plain Hopper', stock: 150.0, unit: 'pcs', minStock: 25.0, price: 50.0, costPrice: 25.0, barcode: '4793000306', category: 'Hoppers', stockType: 'General'),
        InventoryItem(name: 'Devilled Chicken Portion', stock: 25.0, unit: 'plates', minStock: 5.0, price: 750.0, costPrice: 520.0, barcode: '4793000308', category: 'Side Dishes', stockType: 'General'),
        InventoryItem(name: 'Ginger Beer (EGB)', stock: 60.0, unit: 'bottles', minStock: 12.0, price: 180.0, costPrice: 130.0, barcode: '4793000307', category: 'Beverages', stockType: 'General'),
        InventoryItem(name: 'Fresh Lime Soda', stock: 40.0, unit: 'glasses', minStock: 10.0, price: 220.0, costPrice: 100.0, barcode: '4793000309', category: 'Beverages', stockType: 'General'),
      ];
      for (var item in restaurantItems) {
        await db.insert('inventory', item.toMap());
      }
    } else if (businessType == 'Service & Other') {
      final serviceItems = [
        InventoryItem(name: 'Standard Haircut', stock: 999.0, unit: 'sessions', minStock: 0.0, price: 800.0, costPrice: 150.0, barcode: '4794000401', category: 'Salon', stockType: 'General'),
        InventoryItem(name: 'Beard Trim & Styling', stock: 999.0, unit: 'sessions', minStock: 0.0, price: 450.0, costPrice: 80.0, barcode: '4794000402', category: 'Salon', stockType: 'General'),
        InventoryItem(name: 'Full Vehicle Wash & Vacuum', stock: 100.0, unit: 'cars', minStock: 10.0, price: 2800.0, costPrice: 850.0, barcode: '4794000403', category: 'Car Care', stockType: 'General'),
        InventoryItem(name: 'Interior Body Polish', stock: 50.0, unit: 'cars', minStock: 5.0, price: 3500.0, costPrice: 1200.0, barcode: '4794000404', category: 'Car Care', stockType: 'General'),
        InventoryItem(name: 'Urgent Smartphone Screen Repair', stock: 40.0, unit: 'repairs', minStock: 5.0, price: 4500.0, costPrice: 2200.0, barcode: '4794000406', category: 'Repairs', stockType: 'General'),
        InventoryItem(name: 'IT Support Consultation', stock: 999.0, unit: 'hours', minStock: 0.0, price: 1500.0, costPrice: 0.0, barcode: '4794000405', category: 'Services', stockType: 'General'),
      ];
      for (var item in serviceItems) {
        await db.insert('inventory', item.toMap());
      }
    } else {
      // Grocery & Retail
      final groceryItems = [
        InventoryItem(name: 'Keeri Samba Rice 5kg', stock: 45.0, unit: 'Bags', minStock: 10.0, price: 1450.0, costPrice: 1200.0, barcode: '47920010012', category: 'Groceries', stockType: 'General'),
        InventoryItem(name: 'Anchor Milk Powder 400g', stock: 28.0, unit: 'Boxes', minStock: 8.0, price: 1150.0, costPrice: 1020.0, barcode: '94100010022', category: 'Dairy', stockType: 'General'),
        InventoryItem(name: 'Munchee Super Cream Cracker 190g', stock: 60.0, unit: 'Packs', minStock: 15.0, price: 250.0, costPrice: 210.0, barcode: '47910020001', category: 'Snacks', stockType: 'General'),
        InventoryItem(name: 'Munchee Lemon Puff 200g', stock: 40.0, unit: 'Packs', minStock: 10.0, price: 260.0, costPrice: 220.0, barcode: '47910020002', category: 'Snacks', stockType: 'General'),
        InventoryItem(name: 'Astra Margarine 250g', stock: 35.0, unit: 'tubs', minStock: 8.0, price: 550.0, costPrice: 480.0, barcode: '4791000103', category: 'Dairy', stockType: 'General'),
        InventoryItem(name: 'White Sugar 1kg', stock: 150.0, unit: 'kg', minStock: 25.0, price: 240.0, costPrice: 210.0, barcode: '4791000102', category: 'Groceries', stockType: 'General'),
        InventoryItem(name: 'Red Dhal (Parippu) 1kg', stock: 120.0, unit: 'kg', minStock: 20.0, price: 320.0, costPrice: 280.0, barcode: '4791000104', category: 'Groceries', stockType: 'General'),
        InventoryItem(name: 'Dilmah Premium Ceylon Tea 100g', stock: 55.0, unit: 'boxes', minStock: 10.0, price: 450.0, costPrice: 380.0, barcode: '4791000105', category: 'Beverages', stockType: 'General'),
        InventoryItem(name: 'Pure Coconut Oil 1L', stock: 40.0, unit: 'bottles', minStock: 12.0, price: 680.0, costPrice: 590.0, barcode: '4791000106', category: 'Groceries', stockType: 'General'),
        InventoryItem(name: 'Maliban Gold Marie 80g', stock: 80.0, unit: 'Packs', minStock: 20.0, price: 120.0, costPrice: 95.0, barcode: '47910020003', category: 'Snacks', stockType: 'General'),
        InventoryItem(name: 'Sunlight Lemon Soap 115g', stock: 90.0, unit: 'bars', minStock: 15.0, price: 160.0, costPrice: 130.0, barcode: '4791000107', category: 'Household', stockType: 'General'),
        InventoryItem(name: 'MD Mixed Fruit Jam 300g', stock: 25.0, unit: 'jars', minStock: 5.0, price: 420.0, costPrice: 350.0, barcode: '4791000108', category: 'Groceries', stockType: 'General'),
      ];
      for (var item in groceryItems) {
        await db.insert('inventory', item.toMap());
      }
    }
  }

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

  Future<void> populateDefaultNaya() async {
    final db = await database;
    await db.delete('credit_accounts');
    await db.delete('supplier_ledger');
    await db.delete('expenses');

    final debtors = [
      CreditAccount(
        name: 'Nimal Perera',
        phone: '0771234567',
        balance: 12400.0,
        lastUpdated: DateTime.now().subtract(const Duration(days: 2)),
      ),
      CreditAccount(
        name: 'Saman Kumara',
        phone: '0719876543',
        balance: 3200.0,
        lastUpdated: DateTime.now(),
      ),
      CreditAccount(
        name: 'Pathum Bandara',
        phone: '0725556666',
        balance: 4500.0,
        lastUpdated: DateTime.now().subtract(const Duration(days: 3)),
      ),
      CreditAccount(
        name: 'Kasun Jayawardena',
        phone: '0768889900',
        balance: 7850.0,
        lastUpdated: DateTime.now().subtract(const Duration(days: 1)),
      ),
      CreditAccount(
        name: 'Anura Silva',
        phone: '0783334444',
        balance: 1650.0,
        lastUpdated: DateTime.now(),
      ),
    ];

    for (var debtor in debtors) {
      await db.insert('credit_accounts', debtor.toMap());
    }

    final suppliers = [
      SupplierAccount(
        name: 'Cargills Ceylon PLC',
        phone: '0112345678',
        balance: 35000.0,
        dueDate: DateTime.now().add(const Duration(days: 3)),
        lastUpdated: DateTime.now().subtract(const Duration(days: 1)),
      ),
      SupplierAccount(
        name: 'Unilever Ceylon Ltd',
        phone: '0119876543',
        balance: 18500.0,
        dueDate: DateTime.now().add(const Duration(days: 7)),
        lastUpdated: DateTime.now().subtract(const Duration(days: 2)),
      ),
      SupplierAccount(
        name: 'Maliban Biscuit Manufactories',
        phone: '0114567890',
        balance: 14200.0,
        dueDate: DateTime.now().add(const Duration(days: 5)),
        lastUpdated: DateTime.now().subtract(const Duration(days: 3)),
      ),
      SupplierAccount(
        name: 'Local Wholesale Distributors',
        phone: '0779998888',
        balance: 5000.0,
        dueDate: DateTime.now().add(const Duration(days: 1)),
        lastUpdated: DateTime.now(),
      ),
    ];

    for (var supplier in suppliers) {
      await db.insert('supplier_ledger', supplier.toMap());
    }

    final now = DateTime.now();
    final expensesList = [
      Expense(
        category: 'Rent',
        amount: 35000.0,
        note: 'Monthly shop space rental payment',
        timestamp: DateTime(now.year, now.month, 1, 9, 0),
      ),
      Expense(
        category: 'Bills',
        amount: 14200.0,
        note: 'CEB Electricity commercial bill payment',
        timestamp: DateTime(now.year, now.month, 5, 11, 30),
      ),
      Expense(
        category: 'Bills',
        amount: 2800.0,
        note: 'National Water Board commercial bill',
        timestamp: DateTime(now.year, now.month, 6, 14, 15),
      ),
      Expense(
        category: 'Wages',
        amount: 28000.0,
        note: 'Cashier assistant monthly salary',
        timestamp: DateTime(now.year, now.month, 10, 17, 0),
      ),
      Expense(
        category: 'Supplies',
        amount: 4500.0,
        note: 'Kraft paper bags, receipt paper rolls & packaging',
        timestamp: DateTime(now.year, now.month, 12, 10, 0),
      ),
    ];

    for (var exp in expensesList) {
      await db.insert('expenses', exp.toMap());
    }
  }

  Future<void> populateDefaultSales(String businessType) async {
    final db = await database;
    await db.delete('sale_items');
    await db.delete('sales');

    final now = DateTime.now();
    List<Map<String, dynamic>> salesData = [];

    if (businessType == 'Cafe & Bakery') {
      salesData = [
        {
          'timestamp': DateTime(now.year, now.month, now.day, 8, 30).toIso8601String(),
          'totalAmount': 540.0,
          'paymentMethod': 'Cash',
          'orderType': 'Dine-In',
          'customerName': null,
          'items': [
            {'name': 'Milk Coffee', 'price': 150.0, 'quantity': 2, 'discount': 0.0},
            {'name': 'Egg Bun', 'price': 120.0, 'quantity': 2, 'discount': 0.0},
          ],
        },
        {
          'timestamp': DateTime(now.year, now.month, now.day, 10, 15).toIso8601String(),
          'totalAmount': 550.0,
          'paymentMethod': 'LANKAQR',
          'orderType': 'Takeaway',
          'customerName': null,
          'items': [
            {'name': 'Chocolate Gateau Slice', 'price': 350.0, 'quantity': 1, 'discount': 0.0},
            {'name': 'Woodapple Juice', 'price': 200.0, 'quantity': 1, 'discount': 0.0},
          ],
        },
        {
          'timestamp': DateTime(now.year, now.month, now.day, 13, 20).toIso8601String(),
          'totalAmount': 700.0,
          'paymentMethod': 'Cash',
          'orderType': 'Dine-In',
          'customerName': null,
          'items': [
            {'name': 'Fish Pastry', 'price': 140.0, 'quantity': 3, 'discount': 0.0},
            {'name': 'Ulundu Vadai', 'price': 80.0, 'quantity': 2, 'discount': 0.0},
            {'name': 'Plain Tea', 'price': 60.0, 'quantity': 2, 'discount': 0.0},
          ],
        },
        {
          'timestamp': DateTime(now.year, now.month, now.day, 15, 45).toIso8601String(),
          'totalAmount': 600.0,
          'paymentMethod': 'Card',
          'orderType': 'Dine-In',
          'customerName': null,
          'items': [
            {'name': 'Chicken Roll', 'price': 150.0, 'quantity': 2, 'discount': 0.0},
            {'name': 'Milk Coffee', 'price': 150.0, 'quantity': 2, 'discount': 0.0},
          ],
        },
        {
          'timestamp': now.subtract(const Duration(days: 1, hours: 3)).toIso8601String(),
          'totalAmount': 720.0,
          'paymentMethod': 'Cash',
          'orderType': 'Takeaway',
          'customerName': null,
          'items': [
            {'name': 'Egg Bun', 'price': 120.0, 'quantity': 4, 'discount': 0.0},
            {'name': 'Plain Tea', 'price': 60.0, 'quantity': 4, 'discount': 0.0},
          ],
        },
        {
          'timestamp': now.subtract(const Duration(days: 1, hours: 6)).toIso8601String(),
          'totalAmount': 1260.0,
          'paymentMethod': 'Naya Potha',
          'orderType': 'Dine-In',
          'customerName': 'Nimal Perera',
          'items': [
            {'name': 'Chocolate Gateau Slice', 'price': 350.0, 'quantity': 2, 'discount': 0.0},
            {'name': 'Fish Pastry', 'price': 140.0, 'quantity': 4, 'discount': 0.0},
          ],
        },
        {
          'timestamp': now.subtract(const Duration(days: 2, hours: 2)).toIso8601String(),
          'totalAmount': 1100.0,
          'paymentMethod': 'LANKAQR',
          'orderType': 'Takeaway',
          'customerName': null,
          'items': [
            {'name': 'Fish Pastry', 'price': 140.0, 'quantity': 5, 'discount': 0.0},
            {'name': 'Ulundu Vadai', 'price': 80.0, 'quantity': 5, 'discount': 0.0},
          ],
        },
      ];
    } else if (businessType == 'Restaurant & Hotel') {
      salesData = [
        {
          'timestamp': DateTime(now.year, now.month, now.day, 12, 30).toIso8601String(),
          'totalAmount': 2060.0,
          'paymentMethod': 'Cash',
          'orderType': 'Dine-In',
          'customerName': null,
          'items': [
            {'name': 'Chicken Fried Rice', 'price': 850.0, 'quantity': 2, 'discount': 0.0},
            {'name': 'Ginger Beer (EGB)', 'price': 180.0, 'quantity': 2, 'discount': 0.0},
          ],
        },
        {
          'timestamp': DateTime(now.year, now.month, now.day, 13, 45).toIso8601String(),
          'totalAmount': 1170.0,
          'paymentMethod': 'LANKAQR',
          'orderType': 'Takeaway',
          'customerName': null,
          'items': [
            {'name': 'Chicken Kottu (L)', 'price': 950.0, 'quantity': 1, 'discount': 0.0},
            {'name': 'Fresh Lime Soda', 'price': 220.0, 'quantity': 1, 'discount': 0.0},
          ],
        },
        {
          'timestamp': DateTime(now.year, now.month, now.day, 15, 15).toIso8601String(),
          'totalAmount': 3410.0,
          'paymentMethod': 'Card',
          'orderType': 'Dine-In',
          'customerName': null,
          'items': [
            {'name': 'Cheese Kottu', 'price': 1150.0, 'quantity': 2, 'discount': 0.0},
            {'name': 'Devilled Chicken Portion', 'price': 750.0, 'quantity': 1, 'discount': 0.0},
            {'name': 'Ginger Beer (EGB)', 'price': 180.0, 'quantity': 2, 'discount': 0.0},
          ],
        },
        {
          'timestamp': now.subtract(const Duration(days: 1, hours: 2)).toIso8601String(),
          'totalAmount': 2640.0,
          'paymentMethod': 'Cash',
          'orderType': 'Dine-In',
          'customerName': null,
          'items': [
            {'name': 'Egg Kottu', 'price': 700.0, 'quantity': 3, 'discount': 0.0},
            {'name': 'Ginger Beer (EGB)', 'price': 180.0, 'quantity': 3, 'discount': 0.0},
          ],
        },
        {
          'timestamp': now.subtract(const Duration(days: 1, hours: 5)).toIso8601String(),
          'totalAmount': 2420.0,
          'paymentMethod': 'Naya Potha',
          'orderType': 'Dine-In',
          'customerName': 'Saman Kumara',
          'items': [
            {'name': 'Chicken Kottu (L)', 'price': 950.0, 'quantity': 2, 'discount': 0.0},
            {'name': 'Seni Sambal Egg Hopper', 'price': 130.0, 'quantity': 4, 'discount': 0.0},
          ],
        },
        {
          'timestamp': now.subtract(const Duration(days: 2, hours: 4)).toIso8601String(),
          'totalAmount': 1020.0,
          'paymentMethod': 'LANKAQR',
          'orderType': 'Takeaway',
          'customerName': null,
          'items': [
            {'name': 'Plain Hopper', 'price': 50.0, 'quantity': 10, 'discount': 0.0},
            {'name': 'Seni Sambal Egg Hopper', 'price': 130.0, 'quantity': 4, 'discount': 0.0},
          ],
        },
      ];
    } else if (businessType == 'Service & Other') {
      salesData = [
        {
          'timestamp': DateTime(now.year, now.month, now.day, 10, 0).toIso8601String(),
          'totalAmount': 1250.0,
          'paymentMethod': 'Cash',
          'orderType': 'Retail',
          'customerName': null,
          'items': [
            {'name': 'Standard Haircut', 'price': 800.0, 'quantity': 1, 'discount': 0.0},
            {'name': 'Beard Trim & Styling', 'price': 450.0, 'quantity': 1, 'discount': 0.0},
          ],
        },
        {
          'timestamp': DateTime(now.year, now.month, now.day, 13, 30).toIso8601String(),
          'totalAmount': 2800.0,
          'paymentMethod': 'LANKAQR',
          'orderType': 'Retail',
          'customerName': null,
          'items': [
            {'name': 'Full Vehicle Wash & Vacuum', 'price': 2800.0, 'quantity': 1, 'discount': 0.0},
          ],
        },
        {
          'timestamp': DateTime(now.year, now.month, now.day, 16, 0).toIso8601String(),
          'totalAmount': 4500.0,
          'paymentMethod': 'Card',
          'orderType': 'Retail',
          'customerName': null,
          'items': [
            {'name': 'Urgent Smartphone Screen Repair', 'price': 4500.0, 'quantity': 1, 'discount': 0.0},
          ],
        },
        {
          'timestamp': now.subtract(const Duration(days: 1, hours: 3)).toIso8601String(),
          'totalAmount': 3500.0,
          'paymentMethod': 'Cash',
          'orderType': 'Retail',
          'customerName': null,
          'items': [
            {'name': 'Interior Body Polish', 'price': 3500.0, 'quantity': 1, 'discount': 0.0},
          ],
        },
        {
          'timestamp': now.subtract(const Duration(days: 2, hours: 4)).toIso8601String(),
          'totalAmount': 1500.0,
          'paymentMethod': 'Naya Potha',
          'orderType': 'Retail',
          'customerName': 'Pathum Bandara',
          'items': [
            {'name': 'IT Support Consultation', 'price': 1500.0, 'quantity': 1, 'discount': 0.0},
          ],
        },
      ];
    } else {
      // Grocery & Retail
      salesData = [
        {
          'timestamp': DateTime(now.year, now.month, now.day, 9, 30).toIso8601String(),
          'totalAmount': 2010.0,
          'paymentMethod': 'Cash',
          'orderType': 'Retail',
          'customerName': null,
          'items': [
            {'name': 'Keeri Samba Rice 5kg', 'price': 1450.0, 'quantity': 1, 'discount': 0.0},
            {'name': 'White Sugar 1kg', 'price': 240.0, 'quantity': 1, 'discount': 0.0},
            {'name': 'Red Dhal (Parippu) 1kg', 'price': 320.0, 'quantity': 1, 'discount': 0.0},
          ],
        },
        {
          'timestamp': DateTime(now.year, now.month, now.day, 11, 45).toIso8601String(),
          'totalAmount': 2100.0,
          'paymentMethod': 'LANKAQR',
          'orderType': 'Retail',
          'customerName': null,
          'items': [
            {'name': 'Anchor Milk Powder 400g', 'price': 1150.0, 'quantity': 1, 'discount': 0.0},
            {'name': 'Munchee Super Cream Cracker 190g', 'price': 250.0, 'quantity': 2, 'discount': 0.0},
            {'name': 'Dilmah Premium Ceylon Tea 100g', 'price': 450.0, 'quantity': 1, 'discount': 0.0},
          ],
        },
        {
          'timestamp': DateTime(now.year, now.month, now.day, 15, 15).toIso8601String(),
          'totalAmount': 1550.0,
          'paymentMethod': 'Card',
          'orderType': 'Retail',
          'customerName': null,
          'items': [
            {'name': 'Pure Coconut Oil 1L', 'price': 680.0, 'quantity': 1, 'discount': 0.0},
            {'name': 'Astra Margarine 250g', 'price': 550.0, 'quantity': 1, 'discount': 0.0},
            {'name': 'Sunlight Lemon Soap 115g', 'price': 160.0, 'quantity': 2, 'discount': 0.0},
          ],
        },
        {
          'timestamp': DateTime(now.year, now.month, now.day, 17, 0).toIso8601String(),
          'totalAmount': 920.0,
          'paymentMethod': 'Cash',
          'orderType': 'Retail',
          'customerName': null,
          'items': [
            {'name': 'MD Mixed Fruit Jam 300g', 'price': 420.0, 'quantity': 1, 'discount': 0.0},
            {'name': 'Maliban Gold Marie 80g', 'price': 120.0, 'quantity': 2, 'discount': 0.0},
            {'name': 'Munchee Lemon Puff 200g', 'price': 260.0, 'quantity': 1, 'discount': 0.0},
          ],
        },
        {
          'timestamp': now.subtract(const Duration(days: 1, hours: 2)).toIso8601String(),
          'totalAmount': 3380.0,
          'paymentMethod': 'Cash',
          'orderType': 'Retail',
          'customerName': null,
          'items': [
            {'name': 'Keeri Samba Rice 5kg', 'price': 1450.0, 'quantity': 2, 'discount': 0.0},
            {'name': 'White Sugar 1kg', 'price': 240.0, 'quantity': 2, 'discount': 0.0},
          ],
        },
        {
          'timestamp': now.subtract(const Duration(days: 1, hours: 5)).toIso8601String(),
          'totalAmount': 2750.0,
          'paymentMethod': 'Naya Potha',
          'orderType': 'Retail',
          'customerName': 'Nimal Perera',
          'items': [
            {'name': 'Anchor Milk Powder 400g', 'price': 1150.0, 'quantity': 2, 'discount': 0.0},
            {'name': 'Dilmah Premium Ceylon Tea 100g', 'price': 450.0, 'quantity': 1, 'discount': 0.0},
          ],
        },
        {
          'timestamp': now.subtract(const Duration(days: 2, hours: 3)).toIso8601String(),
          'totalAmount': 2000.0,
          'paymentMethod': 'LANKAQR',
          'orderType': 'Retail',
          'customerName': null,
          'items': [
            {'name': 'Pure Coconut Oil 1L', 'price': 680.0, 'quantity': 2, 'discount': 0.0},
            {'name': 'Red Dhal (Parippu) 1kg', 'price': 320.0, 'quantity': 2, 'discount': 0.0},
          ],
        },
      ];
    }

    for (var saleMap in salesData) {
      final items = saleMap['items'] as List<Map<String, dynamic>>;
      final saleId = await db.insert('sales', {
        'timestamp': saleMap['timestamp'],
        'totalAmount': saleMap['totalAmount'],
        'paymentMethod': saleMap['paymentMethod'],
        'customerName': saleMap['customerName'],
        'orderType': saleMap['orderType'],
        'discountAmount': 0.0,
      });

      for (var item in items) {
        await db.insert('sale_items', {
          'saleId': saleId,
          'name': item['name'],
          'price': item['price'],
          'quantity': item['quantity'],
          'discount': item['discount'],
        });
      }
    }
  }

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
