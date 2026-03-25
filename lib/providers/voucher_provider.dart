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

  // Load toàn bộ voucher từ database
  Future<void> loadVouchers() async {
    _setLoading(true);
    try {
      _vouchers = await _db.getAllVouchers();

      // Nếu voucher đang chọn vẫn còn tồn tại thì đồng bộ lại object mới
      if (_selectedVoucher != null) {
        final index = _vouchers.indexWhere((v) => v.id == _selectedVoucher!.id);
        _selectedVoucher = index == -1 ? null : _vouchers[index];
      }

      _errorMessage = null;
    } catch (e) {
      _errorMessage = 'Không thể tải danh sách voucher.';
    }
    _setLoading(false);
  }

  // Lấy các voucher đang active
  List<Voucher> get activeVouchers =>
      _vouchers.where((voucher) => voucher.isActive).toList();

  // Lấy các voucher phù hợp với tổng đơn hiện tại
  List<Voucher> getApplicableVouchers(double orderTotal) {
    return activeVouchers
        .where((voucher) => orderTotal >= voucher.minOrderAmount)
        .toList();
  }

  // Áp dụng voucher cho đơn hàng
  bool applyVoucher(Voucher voucher, double orderTotal) {
    if (!voucher.isActive) {
      _errorMessage = 'Voucher này hiện đang bị khóa.';
      notifyListeners();
      return false;
    }

    if (orderTotal < voucher.minOrderAmount) {
      _errorMessage =
      'Đơn hàng phải từ \$${voucher.minOrderAmount.toStringAsFixed(2)} để dùng voucher này.';
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

  // Tính số tiền được giảm
  double getDiscountAmount(double orderTotal) {
    if (_selectedVoucher == null) return 0;

    final voucher = _selectedVoucher!;
    if (!voucher.isActive) return 0;
    if (orderTotal < voucher.minOrderAmount) return 0;

    return orderTotal * voucher.discountPercent / 100;
  }

  // Tính tổng cuối cùng sau giảm giá
  double getFinalTotal(double orderTotal) {
    final total = orderTotal - getDiscountAmount(orderTotal);
    return total < 0 ? 0 : total;
  }

  Future<bool> addVoucher(Voucher voucher) async {
    _setLoading(true);
    try {
      final id = await _db.insertVoucher(voucher);
      final newVoucher = voucher.copyWith(id: id);

      _vouchers.insert(0, newVoucher);
      _errorMessage = null;
      _setLoading(false);
      return true;
    } catch (e) {
      _errorMessage = 'Không thể thêm voucher. Có thể mã voucher đã tồn tại.';
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
      _errorMessage = 'Không thể cập nhật voucher.';
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
      _errorMessage = 'Không thể xóa voucher.';
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