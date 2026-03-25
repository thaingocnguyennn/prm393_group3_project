import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/voucher.dart';
import '../providers/voucher_provider.dart';
import '../utils/app_theme.dart';
import '../widgets/common_widgets.dart';

class AddEditVoucherScreen extends StatefulWidget {
  final Voucher? voucher;

  const AddEditVoucherScreen({super.key, this.voucher});

  bool get isEditing => voucher != null;

  @override
  State<AddEditVoucherScreen> createState() => _AddEditVoucherScreenState();
}

class _AddEditVoucherScreenState extends State<AddEditVoucherScreen> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _codeController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _discountController;
  late final TextEditingController _minOrderController;

  bool _isActive = true;

  @override
  void initState() {
    super.initState();
    _codeController = TextEditingController(text: widget.voucher?.code ?? '');
    _descriptionController =
        TextEditingController(text: widget.voucher?.description ?? '');
    _discountController = TextEditingController(
      text: widget.voucher?.discountPercent.toStringAsFixed(0) ?? '',
    );
    _minOrderController = TextEditingController(
      text: widget.voucher?.minOrderAmount.toStringAsFixed(2) ?? '',
    );
    _isActive = widget.voucher?.isActive ?? true;
  }

  @override
  void dispose() {
    _codeController.dispose();
    _descriptionController.dispose();
    _discountController.dispose();
    _minOrderController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final provider = context.read<VoucherProvider>();

    final voucher = Voucher(
      id: widget.voucher?.id,
      code: _codeController.text.trim().toUpperCase(),
      description: _descriptionController.text.trim(),
      discountPercent: double.parse(_discountController.text.trim()),
      minOrderAmount: double.parse(_minOrderController.text.trim()),
      isActive: _isActive,
    );

    final success = widget.isEditing
        ? await provider.updateVoucher(voucher)
        : await provider.addVoucher(voucher);

    if (!mounted) return;

    if (success) {
      Navigator.pop(context, true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(provider.errorMessage ?? 'Failed to save voucher.'),
          backgroundColor: AppTheme.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isEditing ? 'Edit Voucher' : 'Add Voucher'),
      ),
      body: Consumer<VoucherProvider>(
        builder: (_, provider, __) {
          return LoadingOverlay(
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
                      hint: 'Enter voucher code',
                      prefixIcon: Icons.confirmation_number_outlined,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Voucher code is required';
                        }
                        if (value.trim().length < 3) {
                          return 'Voucher code must be at least 3 characters';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    AppTextField(
                      controller: _descriptionController,
                      label: 'Description',
                      hint: 'Enter voucher description',
                      prefixIcon: Icons.description_outlined,
                      maxLines: 2,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Description is required';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    AppTextField(
                      controller: _discountController,
                      label: 'Discount Percent',
                      hint: 'Enter discount percent',
                      prefixIcon: Icons.percent,
                      keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Discount percent is required';
                        }
                        final number = double.tryParse(value.trim());
                        if (number == null) return 'Invalid number';
                        if (number <= 0 || number > 100) {
                          return 'Discount percent must be between 1 and 100';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    AppTextField(
                      controller: _minOrderController,
                      label: 'Minimum Order Amount',
                      hint: 'Enter minimum order amount',
                      prefixIcon: Icons.attach_money,
                      keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Minimum order amount is required';
                        }
                        final number = double.tryParse(value.trim());
                        if (number == null) return 'Invalid number';
                        if (number < 0) return 'Minimum order cannot be negative';
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    SwitchListTile.adaptive(
                      value: _isActive,
                      activeColor: AppTheme.primary,
                      title: const Text('Active'),
                      subtitle: Text(
                        _isActive ? 'Voucher is active' : 'Voucher is inactive',
                      ),
                      contentPadding: EdgeInsets.zero,
                      onChanged: (value) {
                        setState(() => _isActive = value);
                      },
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      onPressed: provider.isLoading ? null : _save,
                      icon: Icon(widget.isEditing ? Icons.save : Icons.add),
                      label:
                      Text(widget.isEditing ? 'Save Changes' : 'Create Voucher'),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}