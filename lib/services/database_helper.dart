import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/user.dart';
import '../models/book.dart';
import '../models/cart_item.dart';
import '../models/category_model.dart';
import '../models/news.dart';
import '../models/voucher.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;
  DatabaseHelper._internal();

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'bookstore.db');

    return await openDatabase(
      path,
      version: 6,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE users (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        username TEXT NOT NULL UNIQUE,
        password TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE books (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        author TEXT NOT NULL,
        price REAL NOT NULL,
        image TEXT NOT NULL,
        description TEXT NOT NULL,
        categoryId INTEGER,
        FOREIGN KEY (categoryId) REFERENCES categories(id)
      )
    ''');

    await db.execute('''
      CREATE TABLE categories (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        description TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE cart (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        userId INTEGER NOT NULL,
        bookId INTEGER NOT NULL,
        quantity INTEGER NOT NULL DEFAULT 1,
        FOREIGN KEY (userId) REFERENCES users(id),
        FOREIGN KEY (bookId) REFERENCES books(id)
      )
    ''');

    await db.execute('''
      CREATE TABLE wishlist (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        userId INTEGER NOT NULL,
        bookId INTEGER NOT NULL,
        createdAt DATETIME DEFAULT CURRENT_TIMESTAMP,
        UNIQUE(userId, bookId),
        FOREIGN KEY (userId) REFERENCES users(id),
        FOREIGN KEY (bookId) REFERENCES books(id)
      )
    ''');

    await db.execute('''
      CREATE TABLE news (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        description TEXT NOT NULL,
        image TEXT NOT NULL,
        createdAt DATETIME DEFAULT CURRENT_TIMESTAMP
      )
    ''');

    await db.execute('''
      CREATE TABLE vouchers (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        code TEXT NOT NULL UNIQUE,
        description TEXT NOT NULL,
        discountPercent REAL NOT NULL,
        minOrderAmount REAL NOT NULL,
        isActive INTEGER NOT NULL DEFAULT 1
      )
    ''');

    await _insertSampleBooks(db);
    await _insertSampleNews(db);
    await _insertSampleVouchers(db);
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS categories (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          name TEXT NOT NULL,
          description TEXT NOT NULL
        )
      ''');
    }
    if (oldVersion < 3) {
      // Add categoryId column to existing books table
      await db.execute('''
        ALTER TABLE books ADD COLUMN categoryId INTEGER
      ''');
    }
    if (oldVersion < 4) {
      // Add wishlist table
      await db.execute('''
        CREATE TABLE IF NOT EXISTS wishlist (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          userId INTEGER NOT NULL,
          bookId INTEGER NOT NULL,
          createdAt DATETIME DEFAULT CURRENT_TIMESTAMP,
          UNIQUE(userId, bookId),
          FOREIGN KEY (userId) REFERENCES users(id),
          FOREIGN KEY (bookId) REFERENCES books(id)
        )
      ''');
    }
    if (oldVersion < 5) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS news (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          title TEXT NOT NULL,
          description TEXT NOT NULL,
          image TEXT NOT NULL,
          createdAt DATETIME DEFAULT CURRENT_TIMESTAMP
        )
      ''');
    }
    if (oldVersion < 6) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS vouchers (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          code TEXT NOT NULL UNIQUE,
          description TEXT NOT NULL,
          discountPercent REAL NOT NULL,
          minOrderAmount REAL NOT NULL,
          isActive INTEGER NOT NULL DEFAULT 1
        )
      ''');
    }
  }

  Future<void> _insertSampleBooks(Database db) async {
    // Insert sample categories first
    final categories = [
      {'name': 'Software Development', 'description': 'Books about software development and programming'},
      {'name': 'Algorithms & Data Structures', 'description': 'Books about algorithms and data structures'},
      {'name': 'Mobile Development', 'description': 'Books about mobile app development'},
      {'name': 'Web Development', 'description': 'Books about web development'},
    ];

    final categoryIds = <int>[];
    for (final cat in categories) {
      final id = await db.insert('categories', cat);
      categoryIds.add(id);
    }

    final sampleBooks = [
      {
        'title': 'Clean Code',
        'author': 'Robert C. Martin',
        'price': 29.99,
        'image':
            'https://m.media-amazon.com/images/I/41xShlnTZTL._SX376_BO1,204,203,200_.jpg',
        'description':
            'A handbook of agile software craftsmanship. Even bad code can function. But if code isn\'t clean, it can bring a development organization to its knees.',
        'categoryId': categoryIds[0],
      },
      {
        'title': 'The Pragmatic Programmer',
        'author': 'Andrew Hunt & David Thomas',
        'price': 34.99,
        'image':
            'https://m.media-amazon.com/images/I/51cUVaBWZzL._SX380_BO1,204,203,200_.jpg',
        'description':
            'Your journey to mastery. Examines the core process of software development - finding the right problem to solve, designing a solution, and implementing it.',
        'categoryId': categoryIds[0],
      },
      {
        'title': 'Design Patterns',
        'author': 'Gang of Four',
        'price': 44.99,
        'image':
            'https://m.media-amazon.com/images/I/51szD9HC9pL._SX395_BO1,204,203,200_.jpg',
        'description':
            'Elements of Reusable Object-Oriented Software. Capturing a wealth of experience about the design of object-oriented software formatted in a structured and easy-to-read format.',
        'categoryId': categoryIds[0],
      },
      {
        'title': 'Introduction to Algorithms',
        'author': 'Cormen, Leiserson, Rivest & Stein',
        'price': 79.99,
        'image':
            'https://m.media-amazon.com/images/I/61Pgdn8Ys-L._AC_UL320_.jpg',
        'description':
            'A comprehensive introduction to the modern study of computer algorithms. It presents many algorithms and covers them in considerable depth, yet makes their design and analysis accessible to all levels of readers.',
        'categoryId': categoryIds[1],
      },
      {
        'title': 'Flutter in Action',
        'author': 'Eric Windmill',
        'price': 39.99,
        'image':
            'https://m.media-amazon.com/images/I/51Dc13JJVWL._SX397_BO1,204,203,200_.jpg',
        'description':
            'A hands-on guide to developing iOS and Android apps with Flutter. Teaches you to build production-quality apps that look great, perform quickly, and feel natural on any platform.',
        'categoryId': categoryIds[2],
      },
      {
        'title': 'You Don\'t Know JS',
        'author': 'Kyle Simpson',
        'price': 24.99,
        'image':
            'https://m.media-amazon.com/images/I/51oSmDaAdFL._SX376_BO1,204,203,200_.jpg',
        'description':
            'A series that dives deep into the core mechanisms of the JavaScript language. Series covers scope & closures, this & object prototypes, types & grammar, async & performance, and ES6 & beyond.',
        'categoryId': categoryIds[3],
      },
    ];

    for (final book in sampleBooks) {
      await db.insert('books', book);
    }
  }

  Future<void> _insertSampleNews(Database db) async {
    final sampleNews = [
      {
        'title': 'Welcome to BookStore News',
        'description':
            'This is the latest place to share bookstore announcements, new arrivals, and important updates.',
        'image':
            'https://images.unsplash.com/photo-1512820790803-83ca734da794?auto=format&fit=crop&w=800&q=80',
      },
    ];

    for (final item in sampleNews) {
      await db.insert('news', item);
    }
  }

  // ─── USER OPERATIONS ──────────────────────────────────────────────────────

  Future<int> insertUser(User user) async {
    final db = await database;
    return await db.insert('users', user.toMap(),
        conflictAlgorithm: ConflictAlgorithm.abort);
  }

  Future<User?> getUserByUsername(String username) async {
    final db = await database;
    final maps =
        await db.query('users', where: 'username = ?', whereArgs: [username]);
    if (maps.isEmpty) return null;
    return User.fromMap(maps.first);
  }

  Future<User?> loginUser(String username, String password) async {
    final db = await database;
    final maps = await db.query(
      'users',
      where: 'username = ? AND password = ?',
      whereArgs: [username, password],
    );
    if (maps.isEmpty) return null;
    return User.fromMap(maps.first);
  }

  // ─── BOOK OPERATIONS ──────────────────────────────────────────────────────

  Future<List<Book>> getAllBooks() async {
    final db = await database;
    final maps = await db.query('books', orderBy: 'id DESC');
    return maps.map((m) => Book.fromMap(m)).toList();
  }

  Future<List<Book>> searchBooks(String query) async {
    final db = await database;
    final maps = await db.query(
      'books',
      where: 'title LIKE ? OR author LIKE ?',
      whereArgs: ['%$query%', '%$query%'],
      orderBy: 'title ASC',
    );
    return maps.map((m) => Book.fromMap(m)).toList();
  }

  Future<Book?> getBookById(int id) async {
    final db = await database;
    final maps = await db.query('books', where: 'id = ?', whereArgs: [id]);
    if (maps.isEmpty) return null;
    return Book.fromMap(maps.first);
  }

  Future<int> insertBook(Book book) async {
    final db = await database;
    return await db.insert('books', book.toMap());
  }

  Future<int> updateBook(Book book) async {
    final db = await database;
    return await db.update(
      'books',
      book.toMap(),
      where: 'id = ?',
      whereArgs: [book.id],
    );
  }

  Future<int> deleteBook(int id) async {
    final db = await database;
    await db.delete('cart', where: 'bookId = ?', whereArgs: [id]);
    return await db.delete('books', where: 'id = ?', whereArgs: [id]);
  }

  // Get books by category ID
  Future<List<Book>> getBooksByCategory(int categoryId) async {
    final db = await database;
    final maps = await db.query(
      'books',
      where: 'categoryId = ?',
      whereArgs: [categoryId],
      orderBy: 'id DESC',
    );
    return maps.map((m) => Book.fromMap(m)).toList();
  }

  // Get books with category name using JOIN
  Future<List<Map<String, dynamic>>> getBooksWithCategory() async {
    final db = await database;
    final maps = await db.rawQuery('''
      SELECT 
        b.id,
        b.title,
        b.author,
        b.price,
        b.image,
        b.description,
        b.categoryId,
        c.name as categoryName,
        c.description as categoryDescription
      FROM books b
      LEFT JOIN categories c ON b.categoryId = c.id
      ORDER BY b.id DESC
    ''');
    return maps;
  }

  // ─── CART OPERATIONS ──────────────────────────────────────────────────────

  Future<List<CartItem>> getCartItems(int userId) async {
    final db = await database;
    final cartMaps = await db.query(
      'cart',
      where: 'userId = ?',
      whereArgs: [userId],
    );

    final List<CartItem> items = [];
    for (final map in cartMaps) {
      final bookId = map['bookId'] as int;
      final book = await getBookById(bookId);
      items.add(CartItem.fromMap(map, book: book));
    }
    return items;
  }

  Future<void> addToCart(int userId, int bookId) async {
    final db = await database;
    final existing = await db.query(
      'cart',
      where: 'userId = ? AND bookId = ?',
      whereArgs: [userId, bookId],
    );

    if (existing.isNotEmpty) {
      final current = existing.first['quantity'] as int;
      await db.update(
        'cart',
        {'quantity': current + 1},
        where: 'userId = ? AND bookId = ?',
        whereArgs: [userId, bookId],
      );
    } else {
      await db.insert('cart', {
        'userId': userId,
        'bookId': bookId,
        'quantity': 1,
      });
    }
  }

  Future<void> updateCartQuantity(int cartId, int quantity) async {
    final db = await database;
    if (quantity <= 0) {
      await db.delete('cart', where: 'id = ?', whereArgs: [cartId]);
    } else {
      await db.update(
        'cart',
        {'quantity': quantity},
        where: 'id = ?',
        whereArgs: [cartId],
      );
    }
  }

  Future<void> removeFromCart(int cartId) async {
    final db = await database;
    await db.delete('cart', where: 'id = ?', whereArgs: [cartId]);
  }

  Future<void> clearCart(int userId) async {
    final db = await database;
    await db.delete('cart', where: 'userId = ?', whereArgs: [userId]);
  }

  Future<int> getCartCount(int userId) async {
    final db = await database;
    final result = await db.rawQuery(
      'SELECT SUM(quantity) as total FROM cart WHERE userId = ?',
      [userId],
    );
    return (result.first['total'] as int?) ?? 0;
  }
  Future<int> updateUser(User user) async {
    final db = await database;
    return await db.update(
      'users',
      user.toMap(),
      where: 'id = ?',
      whereArgs: [user.id],
    );
  }

  Future<int> updatePassword(String username, String password) async {
    final db = await database;
    return await db.update(
      'users',
      {'password': password},
      where: 'username = ?',
      whereArgs: [username],
    );
  }
  Future<List<CategoryModel>> getAllCategories() async {
    final db = await database;
    final maps = await db.query(
      'categories',
      orderBy: 'id DESC',
    );
    return maps.map((map) => CategoryModel.fromMap(map)).toList();
  }

  Future<int> insertCategory(CategoryModel category) async {
    final db = await database;
    return await db.insert(
      'categories',
      category.toMap(),
    );
  }

  Future<int> updateCategory(CategoryModel category) async {
    final db = await database;
    return await db.update(
      'categories',
      category.toMap(),
      where: 'id = ?',
      whereArgs: [category.id],
    );
  }

  Future<int> deleteCategory(int id) async {
    final db = await database;
    return await db.delete(
      'categories',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // ─── NEWS OPERATIONS ──────────────────────────────────────────────────────

  Future<List<News>> getAllNews() async {
    final db = await database;
    final maps = await db.rawQuery('''
      SELECT * FROM news
      ORDER BY datetime(createdAt) DESC, id DESC
    ''');
    return maps.map((m) => News.fromMap(m)).toList();
  }

  Future<News?> getNewestNews() async {
    final db = await database;
    final maps = await db.rawQuery('''
      SELECT * FROM news
      ORDER BY datetime(createdAt) DESC, id DESC
      LIMIT 1
    ''');
    if (maps.isEmpty) return null;
    return News.fromMap(maps.first);
  }

  Future<News?> getNewsById(int id) async {
    final db = await database;
    final maps = await db.query('news', where: 'id = ?', whereArgs: [id]);
    if (maps.isEmpty) return null;
    return News.fromMap(maps.first);
  }

  Future<int> insertNews(News news) async {
    final db = await database;
    final map = news.toMap()..remove('id')..remove('createdAt');
    return await db.insert('news', map);
  }

  Future<int> updateNews(News news) async {
    final db = await database;
    final map = news.toMap()..remove('createdAt');
    return await db.update(
      'news',
      map,
      where: 'id = ?',
      whereArgs: [news.id],
    );
  }

  Future<int> deleteNews(int id) async {
    final db = await database;
    return await db.delete('news', where: 'id = ?', whereArgs: [id]);
  }

  // ─── VOUCHER OPERATIONS ──────────────────────────────────────────────────────

  Future<List<Voucher>> getAllVouchers() async {
    final db = await database;
    final maps = await db.query(
      'vouchers',
      orderBy: 'isActive DESC, id DESC',
    );
    return maps.map((map) => Voucher.fromMap(map)).toList();
  }

  Future<int> insertVoucher(Voucher voucher) async {
    final db = await database;
    return await db.insert(
      'vouchers',
      voucher.toMap(),
      conflictAlgorithm: ConflictAlgorithm.abort,
    );
  }

  Future<int> updateVoucher(Voucher voucher) async {
    final db = await database;
    return await db.update(
      'vouchers',
      voucher.toMap(),
      where: 'id = ?',
      whereArgs: [voucher.id],
    );
  }

  Future<int> deleteVoucher(int id) async {
    final db = await database;
    return await db.delete(
      'vouchers',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // ─── WISHLIST OPERATIONS ─────────────────────────────────────────────────────

  Future<List<Book>> getWishlistBooks(int userId) async {
    final db = await database;
    final maps = await db.rawQuery('''
      SELECT b.* FROM books b
      INNER JOIN wishlist w ON b.id = w.bookId
      WHERE w.userId = ?
      ORDER BY w.createdAt DESC
    ''', [userId]);
    return maps.map((m) => Book.fromMap(m)).toList();
  }

  Future<bool> isBookInWishlist(int userId, int bookId) async {
    final db = await database;
    final maps = await db.query(
      'wishlist',
      where: 'userId = ? AND bookId = ?',
      whereArgs: [userId, bookId],
    );
    return maps.isNotEmpty;
  }

  Future<void> addToWishlist(int userId, int bookId) async {
    final db = await database;
    try {
      await db.insert('wishlist', {
        'userId': userId,
        'bookId': bookId,
      });
    } catch (e) {
      // UNIQUE constraint violation means it's already in wishlist
      // Silent fail is acceptable here
    }
  }

  Future<void> removeFromWishlist(int userId, int bookId) async {
    final db = await database;
    await db.delete(
      'wishlist',
      where: 'userId = ? AND bookId = ?',
      whereArgs: [userId, bookId],
    );
  }

  Future<int> getWishlistCount(int userId) async {
    final db = await database;
    final result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM wishlist WHERE userId = ?',
      [userId],
    );
    return (result.first['count'] as int?) ?? 0;
  }

  Future<void> deleteDatabaseFile() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'bookstore.db');

    await deleteDatabase(path);
    _database = null; // reset instance
  }

  Future<void> _insertSampleVouchers(Database db) async {
    final sampleVouchers = [
      {
        'code': 'WELCOME10',
        'description': 'Get 10% off for orders from \$20',
        'discountPercent': 10.0,
        'minOrderAmount': 20.0,
        'isActive': 1,
      },
      {
        'code': 'SAVE15',
        'description': 'Get 15% off for orders from \$50',
        'discountPercent': 15.0,
        'minOrderAmount': 50.0,
        'isActive': 1,
      },
      {
        'code': 'VIP20',
        'description': 'Get 20% off for orders from \$100',
        'discountPercent': 20.0,
        'minOrderAmount': 100.0,
        'isActive': 1,
      },
    ];

    for (final item in sampleVouchers) {
      await db.insert('vouchers', item);
    }
  }
}
