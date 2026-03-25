import 'package:flutter/foundation.dart';
import '../models/book.dart';
import '../services/database_helper.dart';

class WishlistProvider with ChangeNotifier {
  List<Book> _wishlistBooks = [];
  Set<int> _wishlistBookIds = {};
  int? _currentUserId;
  bool _isLoading = false;

  List<Book> get wishlistBooks => _wishlistBooks;
  int get itemCount => _wishlistBooks.length;
  bool get isLoading => _isLoading;

  final DatabaseHelper _db = DatabaseHelper();

  /// Set current user and load their wishlist
  Future<void> setUserAndLoad(int userId) async {
    _currentUserId = userId;
    await loadWishlist();
  }

  /// Load wishlist for current user
  Future<void> loadWishlist() async {
    if (_currentUserId == null) return;

    _setLoading(true);
    try {
      _wishlistBooks = await _db.getWishlistBooks(_currentUserId!);
      _wishlistBookIds = {for (var book in _wishlistBooks) book.id!};
    } catch (e) {
      _wishlistBooks = [];
      _wishlistBookIds = {};
    }
    _setLoading(false);
  }

  /// Check if a book is in wishlist
  bool isInWishlist(int bookId) {
    return _wishlistBookIds.contains(bookId);
  }

  /// Get wishlist count for a specific user
  Future<int> getWishlistCount(int userId) async {
    try {
      return await _db.getWishlistCount(userId);
    } catch (e) {
      return 0;
    }
  }

  /// Toggle book in wishlist (add or remove)
  Future<bool> toggleWishlist(int bookId, Book bookData) async {
    if (_currentUserId == null) return false;

    try {
      if (isInWishlist(bookId)) {
        // Remove from wishlist
        await _db.removeFromWishlist(_currentUserId!, bookId);
        _wishlistBooks.removeWhere((b) => b.id == bookId);
        _wishlistBookIds.remove(bookId);
      } else {
        // Add to wishlist
        await _db.addToWishlist(_currentUserId!, bookId);
        _wishlistBooks.insert(0, bookData);
        _wishlistBookIds.add(bookId);
      }
      notifyListeners();
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Remove specific book from wishlist
  Future<bool> removeFromWishlist(int bookId) async {
    if (_currentUserId == null) return false;

    try {
      await _db.removeFromWishlist(_currentUserId!, bookId);
      _wishlistBooks.removeWhere((b) => b.id == bookId);
      _wishlistBookIds.remove(bookId);
      notifyListeners();
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Clear entire wishlist
  Future<void> clearWishlist() async {
    _wishlistBooks = [];
    _wishlistBookIds = {};
    notifyListeners();
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
}
