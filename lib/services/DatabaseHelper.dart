import 'dart:convert';
import 'package:ministock/models/StockLocation.dart';
import 'package:ministock/models/User.dart';
import 'package:ministock/models/purchase.dart';
import 'package:ministock/models/sale.dart';
import 'package:ministock/models/article.dart';
import 'package:ministock/models/supplier.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('stock.db');
    return _database!;
  }

Future<Database> _initDB(String filePath) async {
  final dbPath = await getDatabasesPath();
  final path = join(dbPath, filePath);

  // Remove PRAGMAs from onOpen and set them directly in openDatabase parameters
  return await openDatabase(
    path,
    version: 4,
    onCreate: _createDB,
    // Configure pragmas through openDatabase parameters instead
    readOnly: false,
    // These settings are equivalent to the PRAGMAs you wanted
    singleInstance: true,
  );
}
// Add this to your DatabaseHelper class
Future<T> runTransaction<T>(Future<T> Function(Transaction txn) action) async {
  final db = await database;
  try {
    return await db.transaction(action);
  } catch (e) {
    if (e.toString().contains('locked')) {
      await Future.delayed(Duration(milliseconds: 100));
      return await runTransaction(action); // Retry once
    }
    rethrow;
  }
}
  Future _createDB(Database db, int version) async {
    // Create supporting tables first
    await db.execute('''
      CREATE TABLE Supplier (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        contact TEXT NOT NULL,
        taxId TEXT,
        creditLimit REAL,
        paymentTerms TEXT
      )
    ''');
await db.execute('''
  CREATE TABLE User (
    id TEXT PRIMARY KEY,
    username TEXT NOT NULL UNIQUE,
    passwordHash TEXT NOT NULL,
    fullName TEXT NOT NULL,
    role TEXT NOT NULL,
    isActive INTEGER NOT NULL DEFAULT 1,
    lastLogin TEXT,
    permissions TEXT,
    photo BLOB
  )
''');

await db.execute('''
  CREATE TABLE StockLocation (
    id TEXT PRIMARY KEY,
    name TEXT NOT NULL,
    address TEXT NOT NULL,
    latitude REAL NOT NULL,
    longitude REAL NOT NULL
  )
''');

    await db.execute('''
      CREATE TABLE Article (
        reference TEXT PRIMARY KEY,
        title TEXT NOT NULL,
        barcode TEXT NOT NULL UNIQUE,
        type TEXT,
        category TEXT,
        priceWT REAL NOT NULL,
        vat REAL NOT NULL,
        priceTTC REAL NOT NULL,
        image BLOB,
        observations TEXT,
        manufacturer TEXT,
        expiryDate TEXT,
        batchNumber TEXT,
        alternativeCodes TEXT
      )
    ''');
await db.execute('''
  CREATE TABLE IF NOT EXISTS DraftSales (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    items TEXT NOT NULL,
    total REAL NOT NULL,
    cashierId TEXT,
    paymentMethod TEXT,
    notes TEXT,
    createdAt TEXT NOT NULL
  )
''');
    await db.execute('''
      CREATE TABLE Purchase (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        reference TEXT NOT NULL,
        title TEXT NOT NULL,
        quantity REAL NOT NULL,
        Bprice REAL NOT NULL,
        amount REAL NOT NULL,
        purchase_date TEXT NOT NULL,
        observations TEXT,
        supplier_id TEXT NOT NULL,
        po_number TEXT NOT NULL UNIQUE,
        delivery_note TEXT NOT NULL,
        quality_check_by TEXT NOT NULL,
        location_id TEXT NOT NULL,
        FOREIGN KEY (reference) REFERENCES Article(reference),
        FOREIGN KEY (supplier_id) REFERENCES Supplier(id),
        FOREIGN KEY (location_id) REFERENCES StockLocation(id)
      )
    ''');

    await db.execute('''
      CREATE TABLE Sales (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        salesType TEXT NOT NULL,
        reference TEXT NOT NULL,
        title TEXT NOT NULL,
        quantitySold REAL NOT NULL,
        priceWT REAL NOT NULL,
        C_WAT TEXT NOT NULL,
        priceTTC REAL NOT NULL,
        selling_price TEXT NOT NULL,
        sale_date TEXT NOT NULL,
        observations TEXT,
        customerId TEXT NOT NULL,
        cashierId TEXT NOT NULL,
        terminalId TEXT NOT NULL,
        invoiceNumber TEXT UNIQUE,
        discounts TEXT NOT NULL,
        paymentMethod TEXT NOT NULL,
        FOREIGN KEY (reference) REFERENCES Article(reference)
      )
    ''');

    await db.execute('''
      CREATE TABLE Stock (
        reference TEXT PRIMARY KEY,
        current_quantity REAL DEFAULT 0,
        FOREIGN KEY (reference) REFERENCES Article(reference)
      )
    ''');

    // Create indexes
    await db.execute('CREATE INDEX idx_article_barcode ON Article(barcode)');
    await db.execute('CREATE INDEX idx_purchase_supplier ON Purchase(supplier_id)');
    await db.execute('CREATE INDEX idx_sales_date ON Sales(sale_date)');
  }

  Future<User?> getUserById(String id) async {
    final db = await database;
    final users = await db.query(
      'User',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    return users.isNotEmpty ? User.fromMap(users.first) : null;
  }

  Future<bool> hasAnyUsers() async {
    final db = await database;
    final count = await db.rawQuery('SELECT COUNT(*) FROM User');
    return count.isNotEmpty && count.first.values.first as int > 0;
  }
  
// -- Supplier Operations --
Future<int> createSupplier(Supplier supplier) async {
  final db = await database;
  return await db.insert('Supplier', supplier.toMap());
}

Future<Supplier?> readSupplier(String id) async {
  final db = await database;
  final maps = await db.query(
    'Supplier',
    where: 'id = ?',
    whereArgs: [id],
  );
  return maps.isNotEmpty ? Supplier.fromMap(maps.first) : null;
}

Future<List<Supplier>> readAllSuppliers() async {
  final db = await database;
  final result = await db.query('Supplier');
  return result.map((map) => Supplier.fromMap(map)).toList();
}

Future<int> updateSupplier(Supplier supplier) async {
  final db = await database;
  return await db.update(
    'Supplier',
    supplier.toMap(),
    where: 'id = ?',
    whereArgs: [supplier.id],
  );
}

Future<int> deleteSupplier(String id) async {
  final db = await database;
  return await db.delete(
    'Supplier',
    where: 'id = ?',
    whereArgs: [id],
  );
}

// -- User CRUD Operations --
Future<int> createUser(User user) async {
  final db = await database;
  return await db.insert(
    'User',
    user.toMap(),
    conflictAlgorithm: ConflictAlgorithm.replace,
  );
}

Future<User?> readUser(String id) async {
  final db = await database;
  final maps = await db.query(
    'User',
    where: 'id = ?',
    whereArgs: [id],
  );
  return maps.isNotEmpty ? User.fromMap(maps.first) : null;
}
// Add this to your DatabaseHelper class
Future<int> updateUserPassword(String id, String newPasswordHash) async {
  final db = await database;
  return await db.update(
    'User',
    {'passwordHash': newPasswordHash},
    where: 'id = ?',
    whereArgs: [id],
  );
}
Future<User?> readUserByUsername(String username) async {
  final db = await database;
  final maps = await db.query(
    'User',
    where: 'username = ?',
    whereArgs: [username],
  );
  return maps.isNotEmpty ? User.fromMap(maps.first) : null;
}

Future<List<User>> readAllUsers() async {
  final db = await database;
  final result = await db.query('User');
  return result.map((map) => User.fromMap(map)).toList();
}

Future<int> updateUser(User user) async {
  final db = await database;
  return await db.update(
    'User',
    user.toMap(),
    where: 'id = ?',
    whereArgs: [user.id],
  );
}

Future<int> deleteUser(String id) async {
  final db = await database;
  return await db.delete(
    'User',
    where: 'id = ?',
    whereArgs: [id],
  );
}
  // -- Article Operations --
  Future<int> createArticle(Article article) async {
    final db = await instance.database;
    return await db.insert('Article', article.toMap());
  }

  Future<Article?> readArticle(String reference) async {
    final db = await database;
    final maps = await db.query(
      'Article',
      where: 'reference = ?',
      whereArgs: [reference],
    );
    return maps.isNotEmpty ? Article.fromMap(maps.first) : null;
  }

  Future<List<Article>> readAllArticles() async {
    final db = await database;
    final result = await db.query('Article');
    return result.map((map) => Article.fromMap(map)).toList();
  }

  Future<int> updateArticle(Article article) async {
    final db = await database;
    return await db.update(
      'Article',
      article.toMap(),
      where: 'reference = ?',
      whereArgs: [article.reference],
    );
  }

  Future<int> deleteArticle(String reference) async {
    final db = await database;
    return await db.delete(
      'Article',
      where: 'reference = ?',
      whereArgs: [reference],
    );
  }

  // -- Purchase Operations --
Future<int> createPurchase(Purchase purchase) async {
  return await withDatabaseRetry(() async {
    return await runTransaction((txn) async {
      final currentStock = await _getStockQuantity(txn, purchase.reference);
      
      await txn.insert(
        'Stock',
        {'reference': purchase.reference, 'current_quantity': currentStock + purchase.quantity},
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      
      return await txn.insert('Purchase', purchase.toMap());
    });
  });
}
Future<int> createStockLocation(StockLocation location) async {
  final db = await instance.database;
  return await db.insert('StockLocation', location.toMap());
}

Future<List<StockLocation>> getAllStockLocations() async {
  final db = await instance.database;
  final List<Map<String, dynamic>> maps = await db.query('StockLocation');
  return maps.map((map) => StockLocation.fromMap(map)).toList();
}

Future<int> updateStockLocation(StockLocation location) async {
  final db = await instance.database;
  return await db.update(
    'StockLocation',
    location.toMap(),
    where: 'id = ?',
    whereArgs: [location.id],
  );
}

Future<int> deleteStockLocation(String id) async {
  final db = await instance.database;
  return await db.delete(
    'StockLocation',
    where: 'id = ?',
    whereArgs: [id],
  );
}

  Future<Purchase?> readPurchase(int id) async {
    final db = await database;
    final maps = await db.query(
      'Purchase',
      where: 'id = ?',
      whereArgs: [id],
    );
    return maps.isNotEmpty ? Purchase.fromMap(maps.first) : null;
  }

  Future<List<Purchase>> readAllPurchases() async {
    final db = await database;
    final result = await db.query('Purchase');
    return result.map((map) => Purchase.fromMap(map)).toList();
  }

  Future<int> updatePurchase(Purchase purchase) async {
    final db = await database;
    return await db.update(
      'Purchase',
      purchase.toMap(),
      where: 'id = ?',
      whereArgs: [purchase.id],
    );
  }

  Future<int> deletePurchase(int id) async {
    final db = await database;
    return await db.delete(
      'Purchase',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // -- Sale Operations --
Future<int> createSale(Sale sale) async {
  return await runTransaction((txn) async {
    // Update stock
    final currentStock = await _getStockQuantity(txn, sale.reference);
    if (currentStock < sale.quantitySold) {
      throw Exception('Insufficient stock');
    }
    
    await txn.insert(
      'Stock',
      {'reference': sale.reference, 'current_quantity': currentStock - sale.quantitySold},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );

    final saleMap = sale.toMap();
    saleMap['discounts'] = jsonEncode(sale.discounts);
    
    return await txn.insert('Sales', saleMap);
  });
}

// Helper method to get stock quantity within transaction
Future<double> _getStockQuantity(Transaction txn, String reference) async {
  final maps = await txn.query(
    'Stock',
    where: 'reference = ?',
    whereArgs: [reference],
  );
  return maps.isNotEmpty ? maps.first['current_quantity'] as double : 0;
}
Future<void> bulkInsertArticles(List<Article> articles) async {
  await runTransaction((txn) async {
    final batch = txn.batch();
    for (var article in articles) {
      batch.insert('Article', article.toMap());
    }
    await batch.commit(noResult: true);
  });
}
Future<T> withDatabaseRetry<T>(Future<T> Function() operation, {int maxRetries = 3}) async {
  int attempt = 0;
  while (true) {
    try {
      return await operation();
    } catch (e) {
      if (e.toString().contains('locked') && attempt < maxRetries) {
        attempt++;
        await Future.delayed(Duration(milliseconds: 100 * attempt));
        continue;
      }
      rethrow;
    }
  }
}
Future<Sale?> readSale(int id) async {
  final db = await database;
  final maps = await db.query(
    'Sales',
    where: 'id = ?',
    whereArgs: [id],
  );
  if (maps.isEmpty) return null;
  
  final saleMap = maps.first.cast<String, dynamic>();
  final discountsJson = saleMap['discounts'] as String;
  
  return Sale(
    id: saleMap['id'] as int?,
    salesType: saleMap['salesType'] as String,
    reference: saleMap['reference'] as String,
    title: saleMap['title'] as String,
    quantitySold: (saleMap['quantitySold'] as num).toDouble(),
    priceWT: (saleMap['priceWT'] as num).toDouble(),
    vatCategory: saleMap['C_WAT'] as String,
    priceTTC: (saleMap['priceTTC'] as num).toDouble(),
    sellingPrice: saleMap['selling_price'] as String,
    observations: saleMap['observations'] as String?,
    saleDate: DateTime.parse(saleMap['sale_date'] as String),
    cashierId: saleMap['cashierId'] as String,
    terminalId: saleMap['terminalId'] as String,
    invoiceNumber: saleMap['invoiceNumber'] as String?,
    discounts: List<AppliedDiscount>.from(
      jsonDecode(discountsJson).map<AppliedDiscount>(
        (d) => AppliedDiscount.fromMap(d as Map<String, dynamic>)
      )
    ),
    paymentMethod: PaymentMethod.values.firstWhere(
      (e) => e.name == saleMap['paymentMethod'] as String,
      orElse: () => PaymentMethod.cash,
    ),
  );
}
// Add to DatabaseHelper class
Future<List<Map<String, dynamic>>> getRecentSales() async {
  final db = await database;
  final result = await db.query(
    'Sales',
    orderBy: 'sale_date DESC',
    limit: 50,
  );
  return result;
}
Future<List<Sale>> readAllSales() async {
  final db = await database;
  final result = await db.query('Sales');
  
  return result.map((map) {
    final saleMap = map.cast<String, dynamic>();
    final discountsJson = saleMap['discounts'] as String;

    return Sale(
      id: saleMap['id'] as int?,
      salesType: saleMap['salesType'] as String,
      reference: saleMap['reference'] as String,
      title: saleMap['title'] as String,
      quantitySold: (saleMap['quantitySold'] as num).toDouble(),
      priceWT: (saleMap['priceWT'] as num).toDouble(),
      vatCategory: saleMap['C_WAT'] as String,
      priceTTC: (saleMap['priceTTC'] as num).toDouble(),
      sellingPrice: saleMap['selling_price'] as String,
      observations: saleMap['observations'] as String?,
      saleDate: DateTime.parse(saleMap['sale_date'] as String),
      cashierId: saleMap['cashierId'] as String,
      terminalId: saleMap['terminalId'] as String,
      invoiceNumber: saleMap['invoiceNumber'] as String?,
      discounts: List<AppliedDiscount>.from(
        jsonDecode(discountsJson).map<AppliedDiscount>(
          (d) => AppliedDiscount.fromMap(d as Map<String, dynamic>)
        )
      ),
      paymentMethod: PaymentMethod.values.firstWhere(
        (e) => e.name == saleMap['paymentMethod'] as String,
        orElse: () => PaymentMethod.cash,
      ),
    );
  }).toList();
}

  Future<int> updateSale(Sale sale) async {
    final db = await database;
    final saleMap = sale.toMap();
    saleMap['discounts'] = jsonEncode(sale.discounts);
    return await db.update(
      'Sales',
      saleMap,
      where: 'id = ?',
      whereArgs: [sale.id],
    );
  }
// Add to DatabaseHelper class
Future<int> saveDraftSale(Map<String, dynamic> draft) async {
  final db = await database;
  return await db.insert('DraftSales', draft);
}

Future<List<Map<String, dynamic>>> getDraftSales() async {
  final db = await database;
  return await db.query('DraftSales', orderBy: 'createdAt DESC');
}

Future<int> deleteDraft(int id) async {
  final db = await database;
  return await db.delete('DraftSales', where: 'id = ?', whereArgs: [id]);
}

  Future<int> deleteSale(int id) async {
    final db = await database;
    return await db.delete(
      'Sales',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // -- Stock Operations --
  Future<double> getStockQuantity(String reference) async {
    final db = await database;
    final maps = await db.query(
      'Stock',
      where: 'reference = ?',
      whereArgs: [reference],
    );
    return maps.isNotEmpty ? maps.first['current_quantity'] as double : 0;
  }

  Future<void> updateStock(String reference, double quantity) async {
    final db = await database;
    await db.insert(
      'Stock',
      {'reference': reference, 'current_quantity': quantity},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

Future<void> close() async {
  if (_database != null && _database!.isOpen) {
    await _database!.close();
    _database = null;
  }
}
  
}