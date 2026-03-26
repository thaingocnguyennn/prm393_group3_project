import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/cart_provider.dart';
import '../providers/voucher_provider.dart';
import '../utils/app_theme.dart';
import '../widgets/common_widgets.dart';
import 'home_screen.dart';
import '../services/database_helper.dart';
import 'order_history_screen.dart';
import '../models/order_history_item.dart';
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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<VoucherProvider>().loadVouchers();
      // xóa snackbar cũ đang nổi từ màn hình trước
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).removeCurrentSnackBar();
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    _cardController.dispose();
    super.dispose();
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
          content: Text('No applicable vouchers for this order.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      builder: (bottomContext) {
        return SafeArea(
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: vouchers.length,
            itemBuilder: (_, index) {
              final voucher = vouchers[index];
              return ListTile(
                title: Text(voucher.code),
                subtitle: Text(
                  '${voucher.description}\n'
                  'Discount ${voucher.discountPercent.toStringAsFixed(0)}% • '
                  'Min \$${voucher.minOrderAmount.toStringAsFixed(2)}',
                ),
                isThreeLine: true,
                onTap: () {
                  final success =
                      voucherProvider.applyVoucher(voucher, orderTotal);
                  Navigator.pop(bottomContext);

                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        success
                            ? 'Voucher ${voucher.code} applied.'
                            : (voucherProvider.errorMessage ??
                                'Could not apply voucher.'),
                      ),
                      backgroundColor: success ? Colors.green : Colors.red,
                    ),
                  );
                },
              );
            },
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
    final discount = voucherProvider.getDiscountAmount(cart.totalPrice);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.black12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Voucher',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          if (selectedVoucher == null)
            const Text('No voucher selected')
          else
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  selectedVoucher.code,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(selectedVoucher.description),
                const SizedBox(height: 4),
                Text(
                  'Discount: \$${discount.toStringAsFixed(2)}',
                  style: const TextStyle(
                    color: Colors.green,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => _showVoucherPicker(cart, voucherProvider),
                  child: Text(
                    selectedVoucher == null ? 'Choose Voucher' : 'Change Voucher',
                  ),
                ),
              ),
              if (selectedVoucher != null) ...[
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: voucherProvider.clearSelectedVoucher,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                    ),
                    child: const Text('Remove'),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _placeOrder() async {
    if (!_formKey.currentState!.validate()) return;

    final auth = context.read<AuthProvider>();
    final cart = context.read<CartProvider>();
    final voucherProvider = context.read<VoucherProvider>();
    final selectedVoucher = voucherProvider.selectedVoucher;
    final finalTotal = voucherProvider.getFinalTotal(cart.totalPrice);
    if (selectedVoucher != null) {
      if (!selectedVoucher.isActive) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Selected voucher is inactive.'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      if (cart.totalPrice < selectedVoucher.minOrderAmount) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Order does not meet minimum amount for ${selectedVoucher.code}.',
            ),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
    }

    // Show processing dialog
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
    Navigator.pop(context); // close processing dialog

    if (success) {
      final db = DatabaseHelper();

      final orderId = await db.insertOrder(
        totalPrice: finalTotal,
        fullName: _nameController.text.trim(),
        address: _addressController.text.trim(),
        paymentMethod: _paymentMethod,
        cardNumber: _paymentMethod == 'Cash on Delivery'
            ? ''
            : _cardController.text.trim(),
      );

      for (final item in cart.items) {
        await db.insertOrderItem(
          OrderHistoryItem(
            orderId: orderId,
            bookId: item.book?.id ?? 0,
            title: item.book?.title ?? 'Book',
            price: item.book?.price ?? 0,
            quantity: item.quantity,
            image: item.book?.image ?? '',
          ),
        );
      }

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
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
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
              const SizedBox(height: 8),
              OutlinedButton(
                onPressed: () {
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute(
                      builder: (_) => const OrderHistoryScreen(),
                    ),
                  );
                },
                child: const Text('View Order History'),
              ),
            ],
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
            isLoading: cart.isLoading,
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
                    ].map((method) => RadioListTile<String>(
                          value: method,
                          groupValue: _paymentMethod,
                          title: Text(method),
                          activeColor: AppTheme.primary,
                          contentPadding: EdgeInsets.zero,
                          onChanged: (v) =>
                              setState(() => _paymentMethod = v ?? method),
                        )),
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
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Text(
                                      '${item.book?.title ?? 'Book'} x${item.quantity}',
                                      style:
                                          const TextStyle(color: AppTheme.textGrey),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  Text(
                                    '\$${item.totalPrice.toStringAsFixed(2)}',
                                    style:
                                        const TextStyle(fontWeight: FontWeight.w500),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
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
                      label: Text('Place Order • \$${finalTotal.toStringAsFixed(2)}'),
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
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Text(
          text,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      );
    }
  }
