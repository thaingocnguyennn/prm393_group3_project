import 'package:flutter/foundation.dart';
import '../models/cart_item.dart';
import '../services/database_helper.dart';

class CartProvider with ChangeNotifier {
  List<CartItem> _items = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<CartItem> get items => _items;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  int get itemCount => _items.fold(0, (sum, item) => sum + item.quantity);

  double get totalPrice =>
      _items.fold(0.0, (sum, item) => sum + item.totalPrice);

  final DatabaseHelper _db = DatabaseHelper();

  Future<void> loadCart(int userId) async {
    _setLoading(true);
    try {
      _items = await _db.getCartItems(userId);
      _errorMessage = null;
    } catch (e) {
      _errorMessage = 'Failed to load cart.';
    }
    _setLoading(false);
  }

  Future<bool> addToCart(int userId, int bookId) async {
    try {
      await _db.addToCart(userId, bookId);
      await loadCart(userId);
      return true;
    } catch (e) {
      _errorMessage = 'Failed to add to cart.';
      notifyListeners();
      return false;
    }
  }

  Future<void> increaseQuantity(int userId, CartItem item) async {
    try {
      await _db.updateCartQuantity(item.id!, item.quantity + 1);
      final index = _items.indexWhere((i) => i.id == item.id);
      if (index != -1) {
        _items[index].quantity++;
        notifyListeners();
      }
    } catch (e) {
      _errorMessage = 'Failed to update quantity.';
      notifyListeners();
    }
  }

  Future<void> decreaseQuantity(int userId, CartItem item) async {
    try {
      if (item.quantity <= 1) {
        await removeItem(userId, item);
        return;
      }
      await _db.updateCartQuantity(item.id!, item.quantity - 1);
      final index = _items.indexWhere((i) => i.id == item.id);
      if (index != -1) {
        _items[index].quantity--;
        notifyListeners();
      }
    } catch (e) {
      _errorMessage = 'Failed to update quantity.';
      notifyListeners();
    }
  }

  Future<void> removeItem(int userId, CartItem item) async {
    try {
      await _db.removeFromCart(item.id!);
      _items.removeWhere((i) => i.id == item.id);
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Failed to remove item.';
      notifyListeners();
    }
  }

  Future<bool> checkout(int userId) async {
    _setLoading(true);
    try {
      await _db.clearCart(userId);
      _items = [];
      _setLoading(false);
      return true;
    } catch (e) {
      _errorMessage = 'Checkout failed.';
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
