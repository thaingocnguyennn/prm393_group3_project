import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/cart_item.dart';
import '../providers/auth_provider.dart';
import '../providers/cart_provider.dart';
import '../utils/app_theme.dart';
import '../widgets/common_widgets.dart';
import 'checkout_screen.dart';

class CartScreen extends StatelessWidget {
  const CartScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Cart'),
      ),
      body: Consumer2<CartProvider, AuthProvider>(
        builder: (context, cart, auth, _) {
          if (cart.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (cart.items.isEmpty) {
            return EmptyState(
              icon: Icons.shopping_cart_outlined,
              title: 'Your cart is empty',
              subtitle: 'Add some books to get started!',
              action: ElevatedButton.icon(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.arrow_back),
                label: const Text('Browse Books'),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(0, 48),
                ),
              ),
            );
          }

          return Column(
            children: [
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.only(top: 8, bottom: 16),
                  itemCount: cart.items.length,
                  itemBuilder: (context, index) {
                    return _CartItemCard(
                      item: cart.items[index],
                      userId: auth.currentUser!.id!,
                    );
                  },
                ),
              ),
              _CartSummary(cart: cart, userId: auth.currentUser!.id!),
            ],
          );
        },
      ),
    );
  }
}

class _CartItemCard extends StatelessWidget {
  final CartItem item;
  final int userId;

  const _CartItemCard({required this.item, required this.userId});

  @override
  Widget build(BuildContext context) {
    final cart = context.read<CartProvider>();
    final book = item.book;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: BookCoverImage(
                imagePath: book?.image ?? '',
                width: 60,
                height: 80,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    book?.title ?? 'Unknown',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    book?.author ?? '',
                    style: const TextStyle(
                      color: AppTheme.textGrey,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '\$${item.totalPrice.toStringAsFixed(2)}',
                    style: const TextStyle(
                      color: AppTheme.accent,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
            Column(
              children: [
                // Quantity controls
                Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: AppTheme.divider),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      InkWell(
                        onTap: () => cart.decreaseQuantity(userId, item),
                        borderRadius: const BorderRadius.horizontal(
                            left: Radius.circular(8)),
                        child: const Padding(
                          padding: EdgeInsets.all(6),
                          child: Icon(Icons.remove, size: 18),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Text(
                          '${item.quantity}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                      ),
                      InkWell(
                        onTap: () => cart.increaseQuantity(userId, item),
                        borderRadius: const BorderRadius.horizontal(
                            right: Radius.circular(8)),
                        child: const Padding(
                          padding: EdgeInsets.all(6),
                          child: Icon(Icons.add, size: 18),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                InkWell(
                  onTap: () async {
                    final confirmed = await ConfirmDialog.show(
                      context,
                      title: 'Remove Item',
                      message: 'Remove "${book?.title}" from cart?',
                      confirmText: 'Remove',
                    );
                    if (confirmed && context.mounted) {
                      cart.removeItem(userId, item);
                    }
                  },
                  child: const Icon(Icons.delete_outline,
                      color: AppTheme.error, size: 22),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _CartSummary extends StatelessWidget {
  final CartProvider cart;
  final int userId;

  const _CartSummary({required this.cart, required this.userId});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${cart.itemCount} item${cart.itemCount == 1 ? '' : 's'}',
                  style: const TextStyle(
                    color: AppTheme.textGrey,
                    fontSize: 15,
                  ),
                ),
                Text(
                  'Total: \$${cart.totalPrice.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textDark,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const CheckoutScreen()),
              ),
              icon: const Icon(Icons.payment),
              label: const Text('Proceed to Checkout'),
            ),
          ],
        ),
      ),
    );
  }
}
