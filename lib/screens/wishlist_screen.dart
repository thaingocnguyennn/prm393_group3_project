import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../providers/wishlist_provider.dart';
import '../utils/app_theme.dart';
import '../widgets/common_widgets.dart';
import '../models/book.dart';
import 'book_detail_screen.dart';
import 'add_edit_book_screen.dart' show isLocalImagePath;

class WishlistScreen extends StatefulWidget {
  const WishlistScreen({super.key});

  @override
  State<WishlistScreen> createState() => _WishlistScreenState();
}

class _WishlistScreenState extends State<WishlistScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<WishlistProvider>().loadWishlist();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Wishlist'),
        elevation: 0,
      ),
      body: Consumer<WishlistProvider>(
        builder: (context, wishlistProvider, _) {
          if (wishlistProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          final books = wishlistProvider.wishlistBooks;

          if (books.isEmpty) {
            return EmptyState(
              icon: Icons.favorite_border,
              title: 'No wishlist items',
              subtitle: 'Add books to your wishlist to see them here',
            );
          }

          return RefreshIndicator(
            onRefresh: () => wishlistProvider.loadWishlist(),
            child: ListView.builder(
              padding: const EdgeInsets.only(bottom: 20, top: 8),
              itemCount: books.length,
              itemBuilder: (context, index) {
                final book = books[index];
                return WishlistBookCard(
                  key: ValueKey(book.id),
                  book: book,
                  onTap: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => BookDetailScreen(book: book),
                      ),
                    );
                  },
                  onRemove: () async {
                    final removed = await wishlistProvider.removeFromWishlist(book.id!);
                    if (removed && mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('${book.title} removed from wishlist'),
                          backgroundColor: AppTheme.primary,
                          duration: const Duration(seconds: 2),
                          action: SnackBarAction(
                            label: 'Undo',
                            onPressed: () {
                              wishlistProvider.toggleWishlist(book.id!, book);
                            },
                          ),
                        ),
                      );
                    }
                  },
                );
              },
            ),
          );
        },
      ),
    );
  }
}

// ─── WISHLIST BOOK CARD ──────────────────────────────────────────────────────

class WishlistBookCard extends StatelessWidget {
  final Book book;
  final VoidCallback onTap;
  final VoidCallback onRemove;

  const WishlistBookCard({
    super.key,
    required this.book,
    required this.onTap,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: BookCoverImage(
                  imagePath: book.image,
                  width: 70,
                  height: 100,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      book.title,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textDark,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      book.author,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppTheme.textGrey,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '\$${book.price.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.accent,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.favorite, color: AppTheme.error),
                onPressed: onRemove,
                tooltip: 'Remove from wishlist',
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── BOOK COVER IMAGE ────────────────────────────────────────────────────────

class BookCoverImage extends StatelessWidget {
  final String imagePath;
  final double width;
  final double height;

  const BookCoverImage({
    super.key,
    required this.imagePath,
    this.width = 100,
    this.height = 140,
  });

  @override
  Widget build(BuildContext context) {
    if (imagePath.isEmpty) {
      return Container(
        width: width,
        height: height,
        color: AppTheme.divider,
        child: const Icon(Icons.image_not_supported, color: AppTheme.textGrey),
      );
    }

    if (isLocalImagePath(imagePath)) {
      return Image.file(
        File(imagePath),
        width: width,
        height: height,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _errorWidget(),
      );
    }

    return CachedNetworkImage(
      imageUrl: imagePath,
      width: width,
      height: height,
      fit: BoxFit.cover,
      placeholder: (_, __) => _loadingWidget(),
      errorWidget: (_, __, ___) => _errorWidget(),
    );
  }

  Widget _errorWidget() => Container(
        width: width,
        height: height,
        color: AppTheme.divider,
        child: const Icon(Icons.broken_image, color: AppTheme.textGrey),
      );

  Widget _loadingWidget() => Container(
        width: width,
        height: height,
        color: AppTheme.divider,
        child: const Center(child: CircularProgressIndicator()),
      );
}
