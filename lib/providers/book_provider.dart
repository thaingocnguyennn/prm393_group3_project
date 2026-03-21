import 'package:flutter/foundation.dart';
import '../models/book.dart';
import '../services/database_helper.dart';

class BookProvider with ChangeNotifier {
  List<Book> _books = [];
  List<Book> _filteredBooks = [];
  bool _isLoading = false;
  String? _errorMessage;
  String _searchQuery = '';

  List<Book> get books => _searchQuery.isEmpty ? _books : _filteredBooks;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String get searchQuery => _searchQuery;

  final DatabaseHelper _db = DatabaseHelper();

  Future<void> loadBooks() async {
    _setLoading(true);
    try {
      _books = await _db.getAllBooks();
      _errorMessage = null;
    } catch (e) {
      _errorMessage = 'Failed to load books.';
    }
    _setLoading(false);
  }

  Future<void> searchBooks(String query) async {
    _searchQuery = query;
    if (query.isEmpty) {
      _filteredBooks = [];
      notifyListeners();
      return;
    }
    try {
      _filteredBooks = await _db.searchBooks(query);
    } catch (e) {
      _filteredBooks = [];
    }
    notifyListeners();
  }

  void clearSearch() {
    _searchQuery = '';
    _filteredBooks = [];
    notifyListeners();
  }

  Future<bool> addBook(Book book) async {
    _setLoading(true);
    try {
      final id = await _db.insertBook(book);
      final newBook = book.copyWith(id: id);
      _books.insert(0, newBook);
      _errorMessage = null;
      _setLoading(false);
      return true;
    } catch (e) {
      _errorMessage = 'Failed to add book.';
      _setLoading(false);
      return false;
    }
  }

  Future<bool> updateBook(Book book) async {
    _setLoading(true);
    try {
      await _db.updateBook(book);
      final index = _books.indexWhere((b) => b.id == book.id);
      if (index != -1) {
        _books[index] = book;
      }
      _errorMessage = null;
      _setLoading(false);
      return true;
    } catch (e) {
      _errorMessage = 'Failed to update book.';
      _setLoading(false);
      return false;
    }
  }

  Future<bool> deleteBook(int id) async {
    _setLoading(true);
    try {
      await _db.deleteBook(id);
      _books.removeWhere((b) => b.id == id);
      _filteredBooks.removeWhere((b) => b.id == id);
      _errorMessage = null;
      _setLoading(false);
      return true;
    } catch (e) {
      _errorMessage = 'Failed to delete book.';
      _setLoading(false);
      return false;
    }
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
}
