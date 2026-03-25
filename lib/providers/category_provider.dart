import 'package:flutter/material.dart';
import '../models/category_model.dart';
import '../services/database_helper.dart';

class CategoryProvider with ChangeNotifier {
  final DatabaseHelper _db = DatabaseHelper();

  List<CategoryModel> _categories = [];
  bool _isLoading = false;

  List<CategoryModel> get categories => _categories;
  bool get isLoading => _isLoading;

  // Load toàn bộ category từ database
  Future<void> loadCategories() async {
    _isLoading = true;
    notifyListeners();

    try {
      _categories = await _db.getAllCategories();
    } catch (e) {
      _categories = [];
    }

    _isLoading = false;
    notifyListeners();
  }

  // Thêm category mới
  Future<bool> addCategory(CategoryModel category) async {
    try {
      final id = await _db.insertCategory(category);

      // Thêm luôn vào list để UI cập nhật ngay
      _categories.insert(0, category.copyWith(id: id));
      notifyListeners();
      return true;
    } catch (e) {
      return false;
    }
  }

  // Cập nhật category
  Future<bool> updateCategory(CategoryModel category) async {
    try {
      await _db.updateCategory(category);

      final index = _categories.indexWhere((item) => item.id == category.id);
      if (index != -1) {
        _categories[index] = category;
      }

      notifyListeners();
      return true;
    } catch (e) {
      return false;
    }
  }

  // Xóa category
  Future<bool> deleteCategory(int id) async {
    try {
      await _db.deleteCategory(id);

      _categories.removeWhere((item) => item.id == id);
      notifyListeners();
      return true;
    } catch (e) {
      return false;
    }
  }
}