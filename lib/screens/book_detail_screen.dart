import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/book.dart';
import '../providers/auth_provider.dart';
import '../providers/book_provider.dart';
import '../providers/cart_provider.dart';
import '../utils/app_theme.dart';
import '../widgets/common_widgets.dart';
import 'add_edit_book_screen.dart';

class BookDetailScreen extends StatelessWidget {
  final Book book;

  const BookDetailScreen({super.key, required this.book});

  Future<void> _addToCart(BuildContext context) async {
    final auth = context.read<AuthProvider>();
    final cart = context.read<CartProvider>();

    if (auth.currentUser == null) return;

    final success = await cart.addToCart(auth.currentUser!.id!, book.id!);
    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
            success ? '${book.title} added to cart!' : 'Failed to add to cart'),
        backgroundColor: success ? AppTheme.primary : AppTheme.error,
        action: success
            ? SnackBarAction(
                label: 'View Cart',
                textColor: Colors.white,
                onPressed: () => Navigator.pop(context),
              )
            : null,
      ),
    );
  }

  Future<void> _deleteBook(BuildContext context) async {
    final confirmed = await ConfirmDialog.show(
      context,
      title: 'Delete Book',
      message:
          'Are you sure you want to delete "${book.title}"? This action cannot be undone.',
      confirmText: 'Delete',
    );

    if (!confirmed || !context.mounted) return;

    final bookProvider = context.read<BookProvider>();
    final success = await bookProvider.deleteBook(book.id!);

    if (!context.mounted) return;

    if (success) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Book deleted successfully'),
          backgroundColor: AppTheme.primary,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(bookProvider.errorMessage ?? 'Failed to delete book'),
          backgroundColor: AppTheme.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Consumer<BookProvider>(
        builder: (context, bookProvider, _) {
          // Reflect any edits from book list
          final currentBook = bookProvider.books.firstWhere(
            (b) => b.id == book.id,
            orElse: () => book,
          );

          return CustomScrollView(
            slivers: [
              SliverAppBar(
                expandedHeight: 300,
                pinned: true,
                flexibleSpace: FlexibleSpaceBar(
                  background: BookCoverImage(
                    imagePath: currentBook.image,
                    width: double.infinity,
                    height: 300,
                  ),
                ),
                actions: [
                  IconButton(
                    icon: const Icon(Icons.edit),
                    tooltip: 'Edit Book',
                    onPressed: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              AddEditBookScreen(book: currentBook),
                        ),
                      );
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete),
                    tooltip: 'Delete Book',
                    onPressed: () => _deleteBook(context),
                  ),
                ],
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        currentBook.title,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textDark,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(Icons.person,
                              size: 16, color: AppTheme.textGrey),
                          const SizedBox(width: 4),
                          Text(
                            currentBook.author,
                            style: const TextStyle(
                              fontSize: 16,
                              color: AppTheme.textGrey,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      PriceTag(price: currentBook.price, fontSize: 28),
                      const SizedBox(height: 24),
                      const Text(
                        'Description',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textDark,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        currentBook.description,
                        style: const TextStyle(
                          fontSize: 15,
                          color: AppTheme.textGrey,
                          height: 1.6,
                        ),
                      ),
                      const SizedBox(height: 32),
                      Consumer<CartProvider>(
                        builder: (_, cart, __) => ElevatedButton.icon(
                          onPressed: cart.isLoading
                              ? null
                              : () => _addToCart(context),
                          icon: const Icon(Icons.shopping_cart),
                          label: const Text('Add to Cart'),
                        ),
                      ),
                      const SizedBox(height: 12),
                      OutlinedButton.icon(
                        onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                AddEditBookScreen(book: currentBook),
                          ),
                        ),
                        icon: const Icon(Icons.edit),
                        label: const Text('Edit Book'),
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size(double.infinity, 52),
                          foregroundColor: AppTheme.primary,
                          side: const BorderSide(color: AppTheme.primary),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      OutlinedButton.icon(
                        onPressed: () => _deleteBook(context),
                        icon: const Icon(Icons.delete),
                        label: const Text('Delete Book'),
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size(double.infinity, 52),
                          foregroundColor: AppTheme.error,
                          side: const BorderSide(color: AppTheme.error),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
