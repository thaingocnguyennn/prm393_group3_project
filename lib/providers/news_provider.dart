import 'package:flutter/foundation.dart';
import '../models/news.dart';
import '../services/database_helper.dart';

class NewsProvider with ChangeNotifier {
  final DatabaseHelper _db = DatabaseHelper();

  List<News> _news = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<News> get news => _news;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  News? get newestNews => _news.isEmpty ? null : _news.first;

  Future<void> loadNews() async {
    _setLoading(true);
    try {
      _news = await _db.getAllNews();
      _errorMessage = null;
    } catch (e) {
      _news = [];
      _errorMessage = 'Failed to load news.';
    }
    _setLoading(false);
  }

  Future<bool> addNews(News item) async {
    _setLoading(true);
    try {
      final id = await _db.insertNews(item);
      final created = await _db.getNewsById(id);
      if (created != null) {
        _news.insert(0, created);
      } else {
        _news.insert(0, item.copyWith(id: id, createdAt: DateTime.now()));
      }
      _errorMessage = null;
      _setLoading(false);
      return true;
    } catch (e) {
      _errorMessage = 'Failed to add news.';
      _setLoading(false);
      return false;
    }
  }

  Future<bool> updateNews(News item) async {
    _setLoading(true);
    try {
      await _db.updateNews(item);
      final index = _news.indexWhere((n) => n.id == item.id);
      if (index != -1) {
        _news[index] = item;
      }
      _news.sort((a, b) {
        final aDate = a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        final bDate = b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        return bDate.compareTo(aDate);
      });
      _errorMessage = null;
      _setLoading(false);
      return true;
    } catch (e) {
      _errorMessage = 'Failed to update news.';
      _setLoading(false);
      return false;
    }
  }

  Future<bool> deleteNews(int id) async {
    _setLoading(true);
    try {
      await _db.deleteNews(id);
      _news.removeWhere((n) => n.id == id);
      _errorMessage = null;
      _setLoading(false);
      return true;
    } catch (e) {
      _errorMessage = 'Failed to delete news.';
      _setLoading(false);
      return false;
    }
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
}
