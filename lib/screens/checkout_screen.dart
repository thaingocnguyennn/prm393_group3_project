import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/cart_provider.dart';
import '../providers/voucher_provider.dart';
import '../utils/app_theme.dart';
import '../widgets/common_widgets.dart';
import 'home_screen.dart';

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _addressController = TextEditingController();
  final _cardController = TextEditingController();

  String _paymentMethod = 'Credit Card';

  @override
  void initState() {
    super.initState();

    // Load voucher khi mở màn hình checkout
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<VoucherProvider>().loadVouchers();
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    _cardController.dispose();
    super.dispose();
  }

  Future<void> _placeOrder() async {
    if (!_formKey.currentState!.validate()) return;

    final auth = context.read<AuthProvider>();
    final cart = context.read<CartProvider>();
    final voucherProvider = context.read<VoucherProvider>();

    final selectedVoucher = voucherProvider.selectedVoucher;
    if (selectedVoucher != null) {
      if (!selectedVoucher.isActive) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Voucher đã chọn hiện không còn hoạt động.'),
            backgroundColor: AppTheme.error,
          ),
        );
        return;
      }

      if (cart.totalPrice < selectedVoucher.minOrderAmount) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Đơn hàng chưa đạt mức tối thiểu để dùng voucher ${selectedVoucher.code}.',
            ),
            backgroundColor: AppTheme.error,
          ),
        );
        return;
      }
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const AlertDialog(
        content: Row(
          children: [
            CircularProgressIndicator(),
            SizedBox(width: 20),
            Text('Processing order...'),
          ],
        ),
      ),
    );

    await Future.delayed(const Duration(seconds: 2));
    final success = await cart.checkout(auth.currentUser!.id!);

    if (!mounted) return;
    Navigator.pop(context);

    if (success) {
      // Sau khi checkout thành công thì xóa voucher đã chọn
      voucherProvider.clearSelectedVoucher();
      _showSuccessDialog();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(cart.errorMessage ?? 'Checkout failed.'),
          backgroundColor: AppTheme.error,
        ),
      );
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: const BoxDecoration(
                color: Color(0xFF4CAF50),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check, color: Colors.white, size: 50),
            ),
            const SizedBox(height: 20),
            const Text(
              'Order Placed!',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: AppTheme.textDark,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Thank you for your purchase!\nYour books are on their way.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppTheme.textGrey),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => const HomeScreen()),
                    (route) => false,
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF4CAF50),
              minimumSize: const Size(double.infinity, 48),
            ),
            child: const Text('Back to Store'),
          ),
        ],
      ),
    );
  }

  void _showVoucherPicker(
      CartProvider cart,
      VoucherProvider voucherProvider,
      ) {
    final orderTotal = cart.totalPrice;
    final vouchers = voucherProvider.getApplicableVouchers(orderTotal);

    if (vouchers.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Không có voucher phù hợp với đơn hàng hiện tại.'),
          backgroundColor: AppTheme.error,
        ),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (bottomContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Row(
                  children: [
                    Icon(Icons.local_offer_outlined, color: AppTheme.primary),
                    SizedBox(width: 8),
                    Text(
                      'Chọn voucher',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                SizedBox(
                  height: math.min(360, vouchers.length * 108).toDouble(),
                  child: ListView.separated(
                    itemCount: vouchers.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final voucher = vouchers[index];
                      final isSelected =
                          voucherProvider.selectedVoucher?.id == voucher.id;

                      return InkWell(
                        borderRadius: BorderRadius.circular(16),
                        onTap: () {
                          final success =
                          voucherProvider.applyVoucher(voucher, orderTotal);

                          Navigator.pop(bottomContext);

                          ScaffoldMessenger.of(this.context).showSnackBar(
                            SnackBar(
                              content: Text(
                                success
                                    ? 'Đã áp dụng voucher ${voucher.code}.'
                                    : (voucherProvider.errorMessage ??
                                    'Không thể áp dụng voucher.'),
                              ),
                              backgroundColor:
                              success ? Colors.green : AppTheme.error,
                            ),
                          );
                        },
                        child: Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? AppTheme.primary.withOpacity(0.08)
                                : Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: isSelected
                                  ? AppTheme.primary
                                  : AppTheme.divider,
                              width: isSelected ? 1.5 : 1,
                            ),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.discount_outlined,
                                color: AppTheme.primary,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      voucher.code,
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      voucher.description,
                                      style: const TextStyle(
                                        color: AppTheme.textGrey,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      'Giảm ${voucher.discountPercent.toStringAsFixed(0)}% • Đơn từ \$${voucher.minOrderAmount.toStringAsFixed(2)}',
                                      style: const TextStyle(
                                        color: AppTheme.primary,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              if (isSelected)
                                const Icon(Icons.check_circle,
                                    color: Colors.green),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildVoucherSection(
      CartProvider cart,
      VoucherProvider voucherProvider,
      ) {
    final selectedVoucher = voucherProvider.selectedVoucher;
    final applicableVouchers =
    voucherProvider.getApplicableVouchers(cart.totalPrice);
    final discount = voucherProvider.getDiscountAmount(cart.totalPrice);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.local_offer_outlined, color: AppTheme.primary),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Voucher',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
              TextButton.icon(
                onPressed: () => _showVoucherPicker(cart, voucherProvider),
                icon: const Icon(Icons.add_circle_outline),
                label: Text(selectedVoucher == null ? 'Chọn' : 'Đổi'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (selectedVoucher == null)
            Text(
              applicableVouchers.isEmpty
                  ? 'Hiện chưa có voucher phù hợp với đơn hàng này.'
                  : 'Có ${applicableVouchers.length} voucher có thể áp dụng.',
              style: const TextStyle(color: AppTheme.textGrey),
            )
          else
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.divider),
              ),
              child: Row(
                children: [
                  const Icon(Icons.confirmation_number_outlined,
                      color: AppTheme.primary),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          selectedVoucher.code,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          selectedVoucher.description,
                          style: const TextStyle(color: AppTheme.textGrey),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Giảm ${selectedVoucher.discountPercent.toStringAsFixed(0)}% • Tiết kiệm \$${discount.toStringAsFixed(2)}',
                          style: const TextStyle(
                            color: Colors.green,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: 'Bỏ voucher',
                    onPressed: voucherProvider.clearSelectedVoucher,
                    icon: const Icon(Icons.close, color: AppTheme.error),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Checkout')),
      body: Consumer3<CartProvider, AuthProvider, VoucherProvider>(
        builder: (context, cart, auth, voucherProvider, _) {
          final subtotal = cart.totalPrice;
          final discount = voucherProvider.getDiscountAmount(subtotal);
          final finalTotal = voucherProvider.getFinalTotal(subtotal);

          return LoadingOverlay(
            isLoading: cart.isLoading || voucherProvider.isLoading,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _sectionTitle('Delivery Information'),
                    const SizedBox(height: 12),
                    AppTextField(
                      controller: _nameController,
                      label: 'Full Name',
                      prefixIcon: Icons.person_outline,
                      validator: (v) => v == null || v.trim().isEmpty
                          ? 'Name is required'
                          : null,
                    ),
                    const SizedBox(height: 12),
                    AppTextField(
                      controller: _addressController,
                      label: 'Shipping Address',
                      prefixIcon: Icons.location_on_outlined,
                      maxLines: 2,
                      validator: (v) => v == null || v.trim().isEmpty
                          ? 'Address is required'
                          : null,
                    ),
                    const SizedBox(height: 24),
                    _sectionTitle('Payment Method'),
                    const SizedBox(height: 12),
                    ...[
                      'Credit Card',
                      'Debit Card',
                      'Cash on Delivery',
                    ].map(
                          (method) => RadioListTile<String>(
                        value: method,
                        groupValue: _paymentMethod,
                        title: Text(method),
                        activeColor: AppTheme.primary,
                        contentPadding: EdgeInsets.zero,
                        onChanged: (v) =>
                            setState(() => _paymentMethod = v ?? method),
                      ),
                    ),
                    if (_paymentMethod != 'Cash on Delivery') ...[
                      const SizedBox(height: 12),
                      AppTextField(
                        controller: _cardController,
                        label: 'Card Number',
                        prefixIcon: Icons.credit_card,
                        keyboardType: TextInputType.number,
                        validator: (v) {
                          if (_paymentMethod == 'Cash on Delivery') return null;
                          if (v == null || v.trim().length < 16) {
                            return 'Enter a valid 16-digit card number';
                          }
                          return null;
                        },
                      ),
                    ],
                    const SizedBox(height: 24),

                    // Khu vực voucher
                    _buildVoucherSection(cart, voucherProvider),

                    const SizedBox(height: 24),
                    _sectionTitle('Order Summary'),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppTheme.divider),
                      ),
                      child: Column(
                        children: [
                          ...cart.items.map(
                                (item) => Padding(
                              padding: const EdgeInsets.symmetric(vertical: 4),
                              child: Row(
                                mainAxisAlignment:
                                MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Text(
                                      '${item.book?.title ?? 'Book'} x${item.quantity}',
                                      style: const TextStyle(
                                        color: AppTheme.textGrey,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  Text(
                                    '\$${item.totalPrice.toStringAsFixed(2)}',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const Divider(),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Subtotal'),
                              Text('\$${subtotal.toStringAsFixed(2)}'),
                            ],
                          ),
                          if (discount > 0) ...[
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'Discount',
                                  style: TextStyle(color: Colors.green),
                                ),
                                Text(
                                  '-\$${discount.toStringAsFixed(2)}',
                                  style: const TextStyle(
                                    color: Colors.green,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ],
                          const Divider(),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Total',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              Text(
                                '\$${finalTotal.toStringAsFixed(2)}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                  color: AppTheme.accent,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),
                    ElevatedButton.icon(
                      onPressed: cart.isLoading ? null : _placeOrder,
                      icon: const Icon(Icons.check_circle_outline),
                      label: Text(
                        'Place Order • \$${finalTotal.toStringAsFixed(2)}',
                      ),
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

  Widget _sectionTitle(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 17,
        fontWeight: FontWeight.bold,
        color: AppTheme.primary,
      ),
    );
  }
}