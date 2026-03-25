import 'package:flutter/foundation.dart';
import '../models/voucher.dart';
import '../services/database_helper.dart';

class VoucherProvider with ChangeNotifier {
  final DatabaseHelper _db = DatabaseHelper();

  List<Voucher> _vouchers = [];
  Voucher? _selectedVoucher;
  bool _isLoading = false;
  String? _errorMessage;

  List<Voucher> get vouchers => _vouchers;
  Voucher? get selectedVoucher => _selectedVoucher;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // Load danh sách voucher từ database
  Future<void> loadVouchers() async {
    _setLoading(true);
    try {
      _vouchers = await _db.getAllVouchers();

      // Đồng bộ voucher đang chọn nếu còn tồn tại
      if (_selectedVoucher != null) {
        final index = _vouchers.indexWhere((v) => v.id == _selectedVoucher!.id);
        _selectedVoucher = index == -1 ? null : _vouchers[index];
      }

      _errorMessage = null;
    } catch (e) {
      _vouchers = [];
      _errorMessage = 'Failed to load vouchers.';
    }
    _setLoading(false);
  }

  // Voucher đang hoạt động
  List<Voucher> get activeVouchers =>
      _vouchers.where((voucher) => voucher.isActive).toList();

  // Voucher áp dụng được theo tổng đơn
  List<Voucher> getApplicableVouchers(double orderTotal) {
    return activeVouchers
        .where((voucher) => orderTotal >= voucher.minOrderAmount)
        .toList();
  }

  // Áp dụng voucher
  bool applyVoucher(Voucher voucher, double orderTotal) {
    if (!voucher.isActive) {
      _errorMessage = 'Voucher is inactive.';
      notifyListeners();
      return false;
    }

    if (orderTotal < voucher.minOrderAmount) {
      _errorMessage =
      'Order must be at least \$${voucher.minOrderAmount.toStringAsFixed(2)}.';
      notifyListeners();
      return false;
    }

    _selectedVoucher = voucher;
    _errorMessage = null;
    notifyListeners();
    return true;
  }

  // Bỏ voucher đã chọn
  void clearSelectedVoucher() {
    _selectedVoucher = null;
    notifyListeners();
  }

  // Tính số tiền giảm
  double getDiscountAmount(double orderTotal) {
    if (_selectedVoucher == null) return 0;

    final voucher = _selectedVoucher!;
    if (!voucher.isActive) return 0;
    if (orderTotal < voucher.minOrderAmount) return 0;

    return orderTotal * voucher.discountPercent / 100;
  }

  // Tổng cuối sau giảm
  double getFinalTotal(double orderTotal) {
    final total = orderTotal - getDiscountAmount(orderTotal);
    return total < 0 ? 0 : total;
  }

  Future<bool> addVoucher(Voucher voucher) async {
    _setLoading(true);
    try {
      final id = await _db.insertVoucher(voucher);
      _vouchers.insert(0, voucher.copyWith(id: id));
      _errorMessage = null;
      _setLoading(false);
      return true;
    } catch (e) {
      _errorMessage = 'Failed to add voucher. Code may already exist.';
      _setLoading(false);
      return false;
    }
  }

  Future<bool> updateVoucher(Voucher voucher) async {
    _setLoading(true);
    try {
      await _db.updateVoucher(voucher);

      final index = _vouchers.indexWhere((v) => v.id == voucher.id);
      if (index != -1) {
        _vouchers[index] = voucher;
      }

      if (_selectedVoucher?.id == voucher.id) {
        _selectedVoucher = voucher;
      }

      _errorMessage = null;
      _setLoading(false);
      return true;
    } catch (e) {
      _errorMessage = 'Failed to update voucher.';
      _setLoading(false);
      return false;
    }
  }

  Future<bool> deleteVoucher(int id) async {
    _setLoading(true);
    try {
      await _db.deleteVoucher(id);
      _vouchers.removeWhere((voucher) => voucher.id == id);

      if (_selectedVoucher?.id == id) {
        _selectedVoucher = null;
      }

      _errorMessage = null;
      _setLoading(false);
      return true;
    } catch (e) {
      _errorMessage = 'Failed to delete voucher.';
      _setLoading(false);
      return false;
    }
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
}