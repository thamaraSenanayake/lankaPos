import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/business_config.dart';
import '../models/sale.dart';
import '../models/inventory_item.dart';

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
      version: 2,
      onCreate: _createDB,
      onUpgrade: _upgradeDB,
    );
  }

  Future<void> _createDB(Database db, int version) async {
    // Create Business Config Table
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
        lankaQrEnabled INTEGER NOT NULL
      )
    ''');

    // Create Sales Table (Version 2 with orderType and discountAmount)
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

    // Create Sale Items Table (Version 2 with discount support)
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
        price REAL NOT NULL
      )
    ''');
  }

  Future<void> _upgradeDB(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      // For simple local development upgrade, let's drop the tables and recreate them.
      await db.execute('DROP TABLE IF EXISTS sale_items');
      await db.execute('DROP TABLE IF EXISTS sales');
      await db.execute('DROP TABLE IF EXISTS business_config');
      await db.execute('DROP TABLE IF EXISTS inventory');
      await _createDB(db, newVersion);
    }
  }

  // --- Business Config operations ---
  Future<int> saveBusinessConfig(BusinessConfig config) async {
    final db = await database;
    await db.delete('business_config');
    final id = await db.insert('business_config', config.toMap());
    
    // Auto populate inventory matching business type on fresh configuration
    await populateDefaultInventory(config.businessType);
    return id;
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
    await db.delete('inventory'); // Clear previous inventory populate

    final List<InventoryItem> defaults = [];

    if (businessType == 'Cafe & Bakery') {
      defaults.addAll([
        InventoryItem(name: 'Egg Bun', stock: 50, unit: 'pcs', minStock: 10, price: 120.0),
        InventoryItem(name: 'Fish Pastry', stock: 40, unit: 'pcs', minStock: 10, price: 140.0),
        InventoryItem(name: 'Ulundu Vadai', stock: 60, unit: 'pcs', minStock: 15, price: 80.0),
        InventoryItem(name: 'Milk Coffee', stock: 100, unit: 'cups', minStock: 20, price: 150.0),
        InventoryItem(name: 'Plain Tea', stock: 120, unit: 'cups', minStock: 20, price: 60.0),
        InventoryItem(name: 'Chocolate Gateau Slice', stock: 15, unit: 'pcs', minStock: 5, price: 350.0),
        InventoryItem(name: 'Woodapple Juice', stock: 30, unit: 'pcs', minStock: 8, price: 200.0),
      ]);
    } else if (businessType == 'Restaurant & Hotel') {
      defaults.addAll([
        InventoryItem(name: 'Chicken Kottu (L)', stock: 35, unit: 'plates', minStock: 5, price: 850.0),
        InventoryItem(name: 'Egg Kottu', stock: 40, unit: 'plates', minStock: 5, price: 650.0),
        InventoryItem(name: 'Cheese Kottu', stock: 20, unit: 'plates', minStock: 5, price: 950.0),
        InventoryItem(name: 'Chicken Fried Rice', stock: 50, unit: 'plates', minStock: 8, price: 800.0),
        InventoryItem(name: 'Seni Sambal Egg Hopper', stock: 80, unit: 'pcs', minStock: 15, price: 120.0),
        InventoryItem(name: 'Plain Hopper', stock: 150, unit: 'pcs', minStock: 25, price: 50.0),
        InventoryItem(name: 'Ginger Beer (EGB)', stock: 60, unit: 'bottles', minStock: 12, price: 180.0),
      ]);
    } else if (businessType == 'Service & Other') {
      // Services don't rely heavily on physical inventory but we track service availability / consumables
      defaults.addAll([
        InventoryItem(name: 'Standard Haircut', stock: 999, unit: 'sessions', minStock: 0, price: 700.0),
        InventoryItem(name: 'Beard Trim & Style', stock: 999, unit: 'sessions', minStock: 0, price: 400.0),
        InventoryItem(name: 'Full Vehicle Wash', stock: 100, unit: 'cars', minStock: 10, price: 2500.0),
        InventoryItem(name: 'Interior Detailing', stock: 50, unit: 'cars', minStock: 5, price: 1500.0),
        InventoryItem(name: 'General Consultation', stock: 999, unit: 'sessions', minStock: 0, price: 1000.0),
        InventoryItem(name: 'Urgent Device Repair', stock: 100, unit: 'repairs', minStock: 5, price: 3000.0),
      ]);
    } else {
      // Grocery & Retail
      defaults.addAll([
        InventoryItem(name: 'Keeri Samba Rice 1kg', stock: 150, unit: 'kg', minStock: 25, price: 280.0),
        InventoryItem(name: 'White Sugar 1kg', stock: 200, unit: 'kg', minStock: 30, price: 240.0),
        InventoryItem(name: 'Astra Margarine 250g', stock: 45, unit: 'tubs', minStock: 10, price: 550.0),
        InventoryItem(name: 'Anchor Milk Powder 400g', stock: 80, unit: 'packets', minStock: 15, price: 1050.0),
        InventoryItem(name: 'Red Dhal 1kg', stock: 120, unit: 'kg', minStock: 20, price: 320.0),
        InventoryItem(name: 'Dilmah Tea 100g', stock: 60, unit: 'boxes', minStock: 10, price: 450.0),
        InventoryItem(name: 'Coconut Oil 1L', stock: 75, unit: 'bottles', minStock: 12, price: 680.0),
        InventoryItem(name: 'Munchee Super Lemon Puff', stock: 90, unit: 'packets', minStock: 15, price: 150.0),
      ]);
    }

    for (var item in defaults) {
      await db.insert('inventory', item.toMap());
    }
  }

  // --- Sales operations ---
  Future<int> insertSale(Sale sale) async {
    final db = await database;
    return await db.transaction((txn) async {
      final saleId = await txn.insert('sales', sale.toMap());

      for (var item in sale.items) {
        await txn.insert('sale_items', item.toMap(saleId));
        
        // Deduct from inventory stock
        await txn.execute(
          'UPDATE inventory SET stock = MAX(0, stock - ?) WHERE name = ?',
          [item.quantity, item.name],
        );
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

  Future<void> clearDatabase() async {
    final db = await database;
    await db.delete('business_config');
    await db.delete('sale_items');
    await db.delete('sales');
    await db.delete('inventory');
  }
}
