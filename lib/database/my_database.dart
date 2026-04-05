import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import 'user.dart';
import '../models/product.dart';

class MyDatabase {
  static final MyDatabase _myDatabase = MyDatabase._privateConstructor();

  MyDatabase._privateConstructor();

  static late Database _database;

  factory MyDatabase() {
    return _myDatabase;
  }

  // Table variables
  final String userTableName = 'users';
  final String userColumnId = 'id';
  final String userColumnEmail = 'email';
  final String userColumnPassword = 'password';
  final String userColumnName = 'name';
  final String userColumnIsAdmin = 'is_admin';
  final String userColumnCardNumber = 'card_number';
  final String userColumnCardName = 'card_name';
  final String userColumnCardExpiry = 'card_expiry';
  final String userColumnCardCVV = 'card_cvv';

  final String productTableName = 'products';
  final String productColumnId = 'id';
  final String productColumnName = 'name';
  final String productColumnDescription = 'description';
  final String productColumnPrice = 'price';
  final String productColumnImageUrl = 'image_url';

  final String cartTableName = 'carts';
  final String cartColumnId = 'id';
  final String cartColumnUserId = 'user_id';
  final String cartColumnProductId = 'product_id';
  final String cartColumnQuantity = 'quantity';

  // History table variables
  final String historyTableName = 'history';
  final String historyColumnId = 'id';
  final String historyColumnUserId = 'user_id';
  final String historyColumnDate = 'date';
  final String historyColumnTotal = 'total';
  
  final String historyItemTableName = 'history_items';
  final String historyItemColumnId = 'id';
  final String historyItemColumnHistoryId = 'history_id';
  final String historyItemColumnProductId = 'product_id';
  final String historyItemColumnQuantity = 'quantity';
  final String historyItemColumnPrice = 'price';

  initializeDatabase() async {
    Directory directory = await getApplicationDocumentsDirectory();
    String path = '${directory.path}/app.db';
    _database = await openDatabase(
      path,
      version: 4,
      onCreate: (db, version) async {
        // Create users table
        await db.execute(
          'CREATE TABLE $userTableName ($userColumnId INTEGER PRIMARY KEY AUTOINCREMENT, $userColumnEmail TEXT UNIQUE, $userColumnPassword TEXT, $userColumnName TEXT, $userColumnIsAdmin INTEGER DEFAULT 0, $userColumnCardNumber TEXT, $userColumnCardName TEXT, $userColumnCardExpiry TEXT, $userColumnCardCVV TEXT)',
        );
        // Create products table
        await db.execute(
          'CREATE TABLE $productTableName ($productColumnId INTEGER PRIMARY KEY AUTOINCREMENT, $productColumnName TEXT, $productColumnDescription TEXT, $productColumnPrice REAL, $productColumnImageUrl TEXT)',
        );
        // Create carts table (many-to-many relationship)
        await db.execute(
          'CREATE TABLE $cartTableName ($cartColumnId INTEGER PRIMARY KEY AUTOINCREMENT, $cartColumnUserId INTEGER, $cartColumnProductId INTEGER, $cartColumnQuantity INTEGER, FOREIGN KEY($cartColumnUserId) REFERENCES $userTableName($userColumnId), FOREIGN KEY($cartColumnProductId) REFERENCES $productTableName($productColumnId))',
        );
        // Create history tables
        await db.execute(
          'CREATE TABLE $historyTableName ($historyColumnId INTEGER PRIMARY KEY AUTOINCREMENT, $historyColumnUserId INTEGER, $historyColumnDate TEXT, $historyColumnTotal REAL, FOREIGN KEY($historyColumnUserId) REFERENCES $userTableName($userColumnId))',
        );
        await db.execute(
          'CREATE TABLE $historyItemTableName ($historyItemColumnId INTEGER PRIMARY KEY AUTOINCREMENT, $historyItemColumnHistoryId INTEGER, $historyItemColumnProductId INTEGER, $historyItemColumnQuantity INTEGER, $historyItemColumnPrice REAL, FOREIGN KEY($historyItemColumnHistoryId) REFERENCES $historyTableName($historyColumnId), FOREIGN KEY($historyItemColumnProductId) REFERENCES $productTableName($productColumnId))',
        );
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          // Add products and carts tables if upgrading from v1
          await db.execute(
            'CREATE TABLE IF NOT EXISTS $productTableName ($productColumnId INTEGER PRIMARY KEY AUTOINCREMENT, $productColumnName TEXT, $productColumnDescription TEXT, $productColumnPrice REAL, $productColumnImageUrl TEXT)',
          );
          await db.execute(
            'CREATE TABLE IF NOT EXISTS $cartTableName ($cartColumnId INTEGER PRIMARY KEY AUTOINCREMENT, $cartColumnUserId INTEGER, $cartColumnProductId INTEGER, $cartColumnQuantity INTEGER, FOREIGN KEY($cartColumnUserId) REFERENCES $userTableName($userColumnId), FOREIGN KEY($cartColumnProductId) REFERENCES $productTableName($productColumnId))',
          );
        }
        if (oldVersion < 3) {
          // Add history tables if upgrading from v2
          await db.execute(
            'CREATE TABLE IF NOT EXISTS $historyTableName ($historyColumnId INTEGER PRIMARY KEY AUTOINCREMENT, $historyColumnUserId INTEGER, $historyColumnDate TEXT, $historyColumnTotal REAL, FOREIGN KEY($historyColumnUserId) REFERENCES $userTableName($userColumnId))',
          );
          await db.execute(
            'CREATE TABLE IF NOT EXISTS $historyItemTableName ($historyItemColumnId INTEGER PRIMARY KEY AUTOINCREMENT, $historyItemColumnHistoryId INTEGER, $historyItemColumnProductId INTEGER, $historyItemColumnQuantity INTEGER, $historyItemColumnPrice REAL, FOREIGN KEY($historyItemColumnHistoryId) REFERENCES $historyTableName($historyColumnId), FOREIGN KEY($historyItemColumnProductId) REFERENCES $productTableName($productColumnId))',
          );
        }
        if (oldVersion < 4) {
          // Add card information columns to users table if upgrading from v3
          await db.execute(
            'ALTER TABLE $userTableName ADD COLUMN $userColumnCardNumber TEXT;'
          );
          await db.execute(
            'ALTER TABLE $userTableName ADD COLUMN $userColumnCardName TEXT;'
          );
          await db.execute(
            'ALTER TABLE $userTableName ADD COLUMN $userColumnCardExpiry TEXT;'
          );
          await db.execute(
            'ALTER TABLE $userTableName ADD COLUMN $userColumnCardCVV TEXT;'
          );
        }
      },
    );

    // Check if admin user exists
    List<Map<String, dynamic>> adminUser = await _database.query(
      userTableName,
      where: '$userColumnEmail = ?',
      whereArgs: ['admin'],
    );

    if (adminUser.isEmpty) {
      // Insert admin user if not exists
      await _database.insert(userTableName, {
        userColumnEmail: 'admin',
        userColumnPassword: 'admin',
        userColumnName: 'Administrator',
        userColumnIsAdmin: 1,
      });
    }
  }

  // User authentication methods
  Future<int> insertUser(User user) async {
    try {
      return await _database.insert(userTableName, user.toMap());
    } catch (e) {
      if (e.toString().contains('UNIQUE constraint failed')) {
        throw Exception('Email already registered');
      }
      throw Exception('Failed to register user');
    }
  }

  Future<User?> getUserByEmail(String email) async {
    List<Map<String, dynamic>> maps = await _database.query(
      userTableName,
      where: '$userColumnEmail = ?',
      whereArgs: [email],
    );
    print('getUserByEmail: $maps'); // Debug print
    if (maps.isNotEmpty) {
      return User.fromMap(maps.first);
    }
    return null;
  }

  Future<User?> getUserById(int userId) async {
    List<Map<String, dynamic>> maps = await _database.query(
      userTableName,
      where: '$userColumnId = ?',
      whereArgs: [userId],
    );
    if (maps.isNotEmpty) {
      return User.fromMap(maps.first);
    }
    return null;
  }

  Future<Map<String, dynamic>> validateUser(String email, String password) async {
    User? user = await getUserByEmail(email);
    if (user != null && user.password == password) {
      // Check if user is admin
      List<Map<String, dynamic>> result = await _database.query(
        userTableName,
        where: '$userColumnEmail = ? AND $userColumnIsAdmin = ?',
        whereArgs: [email, 1],
      );
      bool isAdmin = result.isNotEmpty;
      return {
        'isValid': true,
        'isAdmin': isAdmin,
        'user': user,
      };
    }
    return {
      'isValid': false,
      'isAdmin': false,
      'user': null,
    };
  }

  Future<List<User>> getAllUsers() async {
    List<Map<String, dynamic>> maps = await _database.query(userTableName);
    return List.generate(maps.length, (i) => User.fromMap(maps[i]));
  }

  Future<int> updateUser(User user) async {
    return await _database.update(
      userTableName,
      user.toMap(),
      where: '$userColumnId = ?',
      whereArgs: [user.id],
    );
  }

  Future<int> deleteUser(int userId) async {
    return await _database.delete(
      userTableName,
      where: '$userColumnId = ?',
      whereArgs: [userId],
    );
  }

  Future<int> updateUserCardInfo(int userId, String cardNumber, String cardName, String cardExpiry, String cardCVV) async {
    return await _database.update(
      userTableName,
      {
        userColumnCardNumber: cardNumber,
        userColumnCardName: cardName,
        userColumnCardExpiry: cardExpiry,
        userColumnCardCVV: cardCVV,
      },
      where: '$userColumnId = ?',
      whereArgs: [userId],
    );
  }

  Future<Map<String, String?>> getUserCardInfo(int userId) async {
    List<Map<String, dynamic>> maps = await _database.query(
      userTableName,
      columns: [userColumnCardNumber, userColumnCardName, userColumnCardExpiry, userColumnCardCVV],
      where: '$userColumnId = ?',
      whereArgs: [userId],
    );
    
    if (maps.isNotEmpty) {
      return {
        'cardNumber': maps.first[userColumnCardNumber] as String?,
        'cardName': maps.first[userColumnCardName] as String?,
        'cardExpiry': maps.first[userColumnCardExpiry] as String?,
        'cardCVV': maps.first[userColumnCardCVV] as String?,
      };
    }
    
    return {
      'cardNumber': null,
      'cardName': null,
      'cardExpiry': null,
      'cardCVV': null,
    };
  }

  // Product CRUD
  Future<int> insertProduct(Product product) async {
    return await _database.insert(productTableName, product.toMap());
  }

  Future<List<Product>> getAllProducts() async {
    List<Map<String, dynamic>> maps = await _database.query(productTableName);
    return List.generate(maps.length, (i) => Product.fromMap(maps[i]));
  }

  Future<int> updateProduct(Product product) async {
    return await _database.update(
      productTableName,
      product.toMap(),
      where: '$productColumnId = ?',
      whereArgs: [product.id],
    );
  }

  Future<int> deleteProduct(int productId) async {
    return await _database.delete(
      productTableName,
      where: '$productColumnId = ?',
      whereArgs: [productId],
    );
  }

  // Cart CRUD
  Future<int> addToCart(int userId, int productId, int quantity) async {
    // Check if already in cart
    List<Map<String, dynamic>> existing = await _database.query(
      cartTableName,
      where: '$cartColumnUserId = ? AND $cartColumnProductId = ?',
      whereArgs: [userId, productId],
    );
    if (existing.isNotEmpty) {
      // Update quantity
      int newQuantity = existing.first[cartColumnQuantity] + quantity;
      return await _database.update(
        cartTableName,
        {cartColumnQuantity: newQuantity},
        where: '$cartColumnId = ?',
        whereArgs: [existing.first[cartColumnId]],
      );
    } else {
      // Insert new
      return await _database.insert(cartTableName, {
        cartColumnUserId: userId,
        cartColumnProductId: productId,
        cartColumnQuantity: quantity,
      });
    }
  }

  Future<List<Map<String, dynamic>>> getCartForUser(int userId) async {
    return await _database.query(
      cartTableName,
      where: '$cartColumnUserId = ?',
      whereArgs: [userId],
    );
  }
  
  Future<List<Map<String, dynamic>>> getCartItemsWithProductDetails(int userId) async {
    // Get cart items for the user
    final cartItems = await getCartForUser(userId);
    
    // Return empty list if cart is empty
    if (cartItems.isEmpty) {
      return [];
    }
    
    // For each cart item, get the product details
    List<Map<String, dynamic>> result = [];
    for (var cartItem in cartItems) {
      int productId = cartItem[cartColumnProductId];
      int quantity = cartItem[cartColumnQuantity];
      
      // Get product details
      List<Map<String, dynamic>> productMaps = await _database.query(
        productTableName,
        where: '$productColumnId = ?',
        whereArgs: [productId],
      );
      
      if (productMaps.isNotEmpty) {
        Product product = Product.fromMap(productMaps.first);
        result.add({
          'product': product,
          'quantity': quantity,
          'cart_id': cartItem[cartColumnId],
        });
      }
    }
    
    return result;
  }

  Future<int> updateCartQuantity(int cartId, int quantity) async {
    return await _database.update(
      cartTableName,
      {cartColumnQuantity: quantity},
      where: '$cartColumnId = ?',
      whereArgs: [cartId],
    );
  }

  Future<int> removeFromCart(int cartId) async {
    return await _database.delete(
      cartTableName,
      where: '$cartColumnId = ?',
      whereArgs: [cartId],
    );
  }

  // History methods
  Future<int> saveCartToHistory(int userId, double total, List<Map<String, dynamic>> cartItems) async {
    // Begin transaction
    return await _database.transaction((txn) async {
      // 1. Create history entry
      final historyId = await txn.insert(historyTableName, {
        historyColumnUserId: userId,
        historyColumnDate: DateTime.now().toIso8601String(),
        historyColumnTotal: total,
      });

      // 2. Save all cart items to history_items
      for (var item in cartItems) {
        final product = item['product'] as Product;
        final quantity = item['quantity'] as int;
        final cartId = item['cart_id'] as int;
        
        await txn.insert(historyItemTableName, {
          historyItemColumnHistoryId: historyId,
          historyItemColumnProductId: product.id,
          historyItemColumnQuantity: quantity,
          historyItemColumnPrice: product.price,
        });
        
        // 3. Remove item from cart
        await txn.delete(
          cartTableName,
          where: '$cartColumnId = ?',
          whereArgs: [cartId],
        );
      }

      return historyId;
    });
  }
  
  Future<List<Map<String, dynamic>>> getHistoryForUser(int userId) async {
    // Get all history entries for the user
    final historyEntries = await _database.query(
      historyTableName,
      where: '$historyColumnUserId = ?',
      whereArgs: [userId],
      orderBy: '$historyColumnDate DESC',
    );
    
    List<Map<String, dynamic>> result = [];
    
    // For each history entry, get all the items
    for (var entry in historyEntries) {
      final historyId = entry[historyColumnId] as int;
      final date = DateTime.parse(entry[historyColumnDate] as String);
      final total = entry[historyColumnTotal] as double;
      
      // Get all items for this history entry
      final items = await getHistoryItemsWithProductDetails(historyId);
      
      result.add({
        'id': historyId,
        'date': date,
        'total': total,
        'items': items,
      });
    }
    
    return result;
  }
  
  Future<List<Map<String, dynamic>>> getHistoryItemsWithProductDetails(int historyId) async {
    // Get all history items for the given history ID
    final historyItems = await _database.query(
      historyItemTableName,
      where: '$historyItemColumnHistoryId = ?',
      whereArgs: [historyId],
    );
    
    List<Map<String, dynamic>> result = [];
    
    // For each history item, get the product details
    for (var item in historyItems) {
      int productId = item[historyItemColumnProductId] as int;
      int quantity = item[historyItemColumnQuantity] as int;
      double price = item[historyItemColumnPrice] as double;
      
      // Get product details
      List<Map<String, dynamic>> productMaps = await _database.query(
        productTableName,
        where: '$productColumnId = ?',
        whereArgs: [productId],
      );
      
      if (productMaps.isNotEmpty) {
        Product product = Product.fromMap(productMaps.first);
        result.add({
          'product': product,
          'quantity': quantity,
          'price': price,
        });
      }
    }
    
    return result;
  }
}
