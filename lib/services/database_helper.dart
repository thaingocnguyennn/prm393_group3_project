import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/user.dart';
import '../models/book.dart';
import '../models/cart_item.dart';

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
      version: 1,
      onCreate: _onCreate,
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

    await _insertSampleBooks(db);
  }

  Future<void> _insertSampleBooks(Database db) async {
    final sampleBooks = [
      {
        'title': 'Clean Code',
        'author': 'Robert C. Martin',
        'price': 29.99,
        'image':
            'https://m.media-amazon.com/images/I/41xShlnTZTL._SX376_BO1,204,203,200_.jpg',
        'description':
            'A handbook of agile software craftsmanship. Even bad code can function. But if code isn\'t clean, it can bring a development organization to its knees.',
      },
      {
        'title': 'The Pragmatic Programmer',
        'author': 'Andrew Hunt & David Thomas',
        'price': 34.99,
        'image':
            'https://m.media-amazon.com/images/I/51cUVaBWZzL._SX380_BO1,204,203,200_.jpg',
        'description':
            'Your journey to mastery. Examines the core process of software development - finding the right problem to solve, designing a solution, and implementing it.',
      },
      {
        'title': 'Design Patterns',
        'author': 'Gang of Four',
        'price': 44.99,
        'image':
            'https://m.media-amazon.com/images/I/51szD9HC9pL._SX395_BO1,204,203,200_.jpg',
        'description':
            'Elements of Reusable Object-Oriented Software. Capturing a wealth of experience about the design of object-oriented software formatted in a structured and easy-to-read format.',
      },
      {
        'title': 'Introduction to Algorithms',
        'author': 'Cormen, Leiserson, Rivest & Stein',
        'price': 79.99,
        'image':
            'https://m.media-amazon.com/images/I/61Pgdn8Ys-L._AC_UL320_.jpg',
        'description':
            'A comprehensive introduction to the modern study of computer algorithms. It presents many algorithms and covers them in considerable depth, yet makes their design and analysis accessible to all levels of readers.',
      },
      {
        'title': 'Flutter in Action',
        'author': 'Eric Windmill',
        'price': 39.99,
        'image':
            'https://m.media-amazon.com/images/I/51Dc13JJVWL._SX397_BO1,204,203,200_.jpg',
        'description':
            'A hands-on guide to developing iOS and Android apps with Flutter. Teaches you to build production-quality apps that look great, perform quickly, and feel natural on any platform.',
      },
      {
        'title': 'You Don\'t Know JS',
        'author': 'Kyle Simpson',
        'price': 24.99,
        'image':
            'https://m.media-amazon.com/images/I/51oSmDaAdFL._SX376_BO1,204,203,200_.jpg',
        'description':
            'A series that dives deep into the core mechanisms of the JavaScript language. Series covers scope & closures, this & object prototypes, types & grammar, async & performance, and ES6 & beyond.',
      },
    ];

    for (final book in sampleBooks) {
      await db.insert('books', book);
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
}
