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

  // Load danh sách news từ database
// Cập nhật state và notify UI
  Future<void> loadNews() async {
    _setLoading(true);
    try {
      _news = await _db.getAllNews(); // lấy từ DB
      _errorMessage = null;
    } catch (e) {
      _news = [];
      _errorMessage = 'Failed to load news.';
    }
    _setLoading(false);
  }

  // Thêm news mới vào DB và cập nhật list local
  Future<bool> addNews(News item) async {
    _setLoading(true);
    try {
      final id = await _db.insertNews(item); //Insert → lấy id mới
      final created = await _db.getNewsById(id); //Lấy lại từ DB (có createdAt chuẩn)
      if (created != null) {
        _news.insert(0, created); //Thêm vào đầu list (tin mới nhất)
      } else {
        _news.insert(0, item.copyWith(id: id, createdAt: DateTime.now())); //Nếu không fetch được từ DB
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

  // Cập nhật news trong DB và list local
  Future<bool> updateNews(News item) async {
    _setLoading(true);
    try {
      await _db.updateNews(item); //Update DB
      final index = _news.indexWhere((n) => n.id == item.id); //Update list local
      if (index != -1) {
        _news[index] = item;
      }
      //Sắp xếp lại Giữ đúng thứ tự mới nhất ở trên
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
 // Xóa news khỏi DB và list local
  Future<bool> deleteNews(int id) async {
    _setLoading(true);
    try {
      await _db.deleteNews(id); // Xóa DB
      _news.removeWhere((n) => n.id == id); //Xóa trong list
      _errorMessage = null;
      _setLoading(false);
      return true;
    } catch (e) {
      _errorMessage = 'Failed to delete news.';
      _setLoading(false);
      return false;
    }
  }

  // Cập nhật trạng thái loading và refresh UI
  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
}
