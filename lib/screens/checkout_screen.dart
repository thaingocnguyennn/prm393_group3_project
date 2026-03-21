import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/cart_provider.dart';
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Checkout')),
      body: Consumer2<CartProvider, AuthProvider>(
        builder: (context, cart, auth, _) {
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
                              padding:
                                  const EdgeInsets.symmetric(vertical: 4),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Text(
                                      '${item.book?.title ?? 'Book'} x${item.quantity}',
                                      style: const TextStyle(
                                          color: AppTheme.textGrey),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  Text(
                                    '\$${item.totalPrice.toStringAsFixed(2)}',
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w500),
                                  ),
                                ],
                              ),
                            ),
                          ),
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
                                '\$${cart.totalPrice.toStringAsFixed(2)}',
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
                          'Place Order • \$${cart.totalPrice.toStringAsFixed(2)}'),
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
