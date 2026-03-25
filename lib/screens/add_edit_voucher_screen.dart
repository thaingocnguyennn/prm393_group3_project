import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/voucher.dart';
import '../providers/voucher_provider.dart';
import '../utils/app_theme.dart';
import '../widgets/common_widgets.dart';

class AddEditVoucherScreen extends StatefulWidget {
  final Voucher? voucher;

  const AddEditVoucherScreen({super.key, this.voucher});

  @override
  State<AddEditVoucherScreen> createState() => _AddEditVoucherScreenState();
}

class _AddEditVoucherScreenState extends State<AddEditVoucherScreen> {
  final _formKey = GlobalKey<FormState>();

  final _codeController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _discountController = TextEditingController();
  final _minOrderController = TextEditingController();

  bool _isActive = true;

  bool get _isEditing => widget.voucher != null;

  @override
  void initState() {
    super.initState();

    final voucher = widget.voucher;
    if (voucher != null) {
      _codeController.text = voucher.code;
      _descriptionController.text = voucher.description;
      _discountController.text = voucher.discountPercent.toStringAsFixed(0);
      _minOrderController.text = voucher.minOrderAmount.toStringAsFixed(2);
      _isActive = voucher.isActive;
    }
  }

  @override
  void dispose() {
    _codeController.dispose();
    _descriptionController.dispose();
    _discountController.dispose();
    _minOrderController.dispose();
    super.dispose();
  }

  double _parseDouble(String text) {
    return double.parse(text.trim().replaceAll(',', '.'));
  }

  Future<void> _saveVoucher() async {
    if (!_formKey.currentState!.validate()) return;

    final provider = context.read<VoucherProvider>();

    final voucher = Voucher(
      id: widget.voucher?.id,
      code: _codeController.text.trim().toUpperCase(),
      description: _descriptionController.text.trim(),
      discountPercent: _parseDouble(_discountController.text),
      minOrderAmount: _parseDouble(_minOrderController.text),
      isActive: _isActive,
    );

    final success = _isEditing
        ? await provider.updateVoucher(voucher)
        : await provider.addVoucher(voucher);

    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _isEditing
                ? 'Cập nhật voucher thành công.'
                : 'Thêm voucher thành công.',
          ),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context, true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(provider.errorMessage ?? 'Có lỗi xảy ra.'),
          backgroundColor: AppTheme.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<VoucherProvider>(
      builder: (context, provider, _) {
        return Scaffold(
          appBar: AppBar(
            title: Text(_isEditing ? 'Edit Voucher' : 'Add Voucher'),
          ),
          body: LoadingOverlay(
            isLoading: provider.isLoading,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    AppTextField(
                      controller: _codeController,
                      label: 'Voucher Code',
                      hint: 'Ví dụ: WELCOME10',
                      prefixIcon: Icons.confirmation_number_outlined,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Vui lòng nhập mã voucher';
                        }
                        if (value.trim().length < 3) {
                          return 'Mã voucher phải có ít nhất 3 ký tự';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    AppTextField(
                      controller: _descriptionController,
                      label: 'Description',
                      hint: 'Mô tả ngắn cho voucher',
                      prefixIcon: Icons.description_outlined,
                      maxLines: 2,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Vui lòng nhập mô tả voucher';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    AppTextField(
                      controller: _discountController,
                      label: 'Discount Percent',
                      hint: 'Ví dụ: 10',
                      prefixIcon: Icons.percent,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Vui lòng nhập phần trăm giảm giá';
                        }

                        final number =
                        double.tryParse(value.trim().replaceAll(',', '.'));
                        if (number == null) {
                          return 'Giá trị không hợp lệ';
                        }
                        if (number <= 0 || number > 100) {
                          return 'Phần trăm phải lớn hơn 0 và nhỏ hơn hoặc bằng 100';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    AppTextField(
                      controller: _minOrderController,
                      label: 'Minimum Order Amount',
                      hint: 'Ví dụ: 50',
                      prefixIcon: Icons.attach_money,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Vui lòng nhập giá trị đơn tối thiểu';
                        }

                        final number =
                        double.tryParse(value.trim().replaceAll(',', '.'));
                        if (number == null) {
                          return 'Giá trị không hợp lệ';
                        }
                        if (number < 0) {
                          return 'Giá trị không được âm';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 8),
                    SwitchListTile.adaptive(
                      value: _isActive,
                      activeColor: AppTheme.primary,
                      title: const Text('Active'),
                      subtitle: Text(
                        _isActive
                            ? 'Voucher đang hoạt động'
                            : 'Voucher đang bị khóa',
                      ),
                      contentPadding: EdgeInsets.zero,
                      onChanged: (value) {
                        setState(() => _isActive = value);
                      },
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton.icon(
                      onPressed: _saveVoucher,
                      icon: const Icon(Icons.save_outlined),
                      label: Text(_isEditing ? 'Update Voucher' : 'Save Voucher'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}