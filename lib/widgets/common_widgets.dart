import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/book.dart';
import '../screens/add_edit_book_screen.dart' show isLocalImagePath;
import '../utils/app_theme.dart';

// ─── BOOK CARD ───────────────────────────────────────────────────────────────

class BookCard extends StatelessWidget {
  final Book book;
  final VoidCallback onTap;
  final VoidCallback? onDelete;

  const BookCard({
    super.key,
    required this.book,
    required this.onTap,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: BookCoverImage(
                  imagePath: book.image,
                  width: 80,
                  height: 110,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      book.title,
                      style: const TextStyle(
                        fontSize: 16,
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
                        fontSize: 13,
                        color: AppTheme.textGrey,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '\$${book.price.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.accent,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right,
                color: AppTheme.textGrey,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── LOADING OVERLAY ─────────────────────────────────────────────────────────

class LoadingOverlay extends StatelessWidget {
  final bool isLoading;
  final Widget child;

  const LoadingOverlay({
    super.key,
    required this.isLoading,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        child,
        if (isLoading)
          const Positioned.fill(
            child: ColoredBox(
              color: Color(0x66000000),
              child: Center(
                child: CircularProgressIndicator(
                  valueColor:
                      AlwaysStoppedAnimation<Color>(AppTheme.primaryLight),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

// ─── CONFIRM DIALOG ──────────────────────────────────────────────────────────

class ConfirmDialog extends StatelessWidget {
  final String title;
  final String message;
  final String confirmText;
  final Color confirmColor;

  const ConfirmDialog({
    super.key,
    required this.title,
    required this.message,
    this.confirmText = 'Confirm',
    this.confirmColor = AppTheme.error,
  });

  static Future<bool> show(
    BuildContext context, {
    required String title,
    required String message,
    String confirmText = 'Confirm',
    Color confirmColor = AppTheme.error,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (_) => ConfirmDialog(
        title: title,
        message: message,
        confirmText: confirmText,
        confirmColor: confirmColor,
      ),
    );
    return result ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text(title),
      content: Text(message),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: confirmColor,
            minimumSize: Size.zero,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          ),
          onPressed: () => Navigator.pop(context, true),
          child: Text(confirmText),
        ),
      ],
    );
  }
}

// ─── PRICE TAG ───────────────────────────────────────────────────────────────

class PriceTag extends StatelessWidget {
  final double price;
  final double fontSize;

  const PriceTag({super.key, required this.price, this.fontSize = 20});

  @override
  Widget build(BuildContext context) {
    return Text(
      '\$${price.toStringAsFixed(2)}',
      style: TextStyle(
        fontSize: fontSize,
        fontWeight: FontWeight.bold,
        color: AppTheme.accent,
      ),
    );
  }
}

// ─── CUSTOM TEXT FIELD ───────────────────────────────────────────────────────

class AppTextField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String? hint;
  final IconData? prefixIcon;
  final bool obscureText;
  final String? Function(String?)? validator;
  final TextInputType keyboardType;
  final int maxLines;
  final Widget? suffix;

  const AppTextField({
    super.key,
    required this.controller,
    required this.label,
    this.hint,
    this.prefixIcon,
    this.obscureText = false,
    this.validator,
    this.keyboardType = TextInputType.text,
    this.maxLines = 1,
    this.suffix,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      maxLines: maxLines,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: prefixIcon != null ? Icon(prefixIcon) : null,
        suffix: suffix,
      ),
    );
  }
}

// ─── EMPTY STATE ─────────────────────────────────────────────────────────────

class EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? action;

  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.action,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 80, color: AppTheme.divider),
            const SizedBox(height: 16),
            Text(
              title,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppTheme.textGrey,
              ),
              textAlign: TextAlign.center,
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 8),
              Text(
                subtitle!,
                style: const TextStyle(color: AppTheme.textGrey),
                textAlign: TextAlign.center,
              ),
            ],
            if (action != null) ...[
              const SizedBox(height: 24),
              action!,
            ],
          ],
        ),
      ),
    );
  }
}

// ─── BOOK COVER IMAGE ────────────────────────────────────────────────────────
/// Renders a book cover from either a local file path or a remote URL.
class BookCoverImage extends StatelessWidget {
  final String imagePath;
  final double? width;
  final double? height;
  final BoxFit fit;

  const BookCoverImage({
    super.key,
    required this.imagePath,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
  });

  Widget _fallback() => Container(
        width: width,
        height: height,
        color: AppTheme.divider,
        child: const Icon(Icons.book, color: AppTheme.textGrey),
      );

  @override
  Widget build(BuildContext context) {
    if (imagePath.isEmpty) return _fallback();

    if (isLocalImagePath(imagePath)) {
      final file = File(imagePath);
      return Image.file(
        file,
        width: width,
        height: height,
        fit: fit,
        errorBuilder: (_, __, ___) => _fallback(),
      );
    }

    return CachedNetworkImage(
      imageUrl: imagePath,
      width: width,
      height: height,
      fit: fit,
      placeholder: (_, __) => _fallback(),
      errorWidget: (_, __, ___) => _fallback(),
    );
  }
}

// ─── CART BADGE ──────────────────────────────────────────────────────────────

class CartBadge extends StatelessWidget {
  final int count;
  final VoidCallback onTap;

  const CartBadge({super.key, required this.count, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.topRight,
      children: [
        IconButton(
          icon: const Icon(Icons.shopping_cart),
          onPressed: onTap,
        ),
        if (count > 0)
          Positioned(
            right: 4,
            top: 4,
            child: Container(
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                color: AppTheme.accent,
                borderRadius: BorderRadius.circular(10),
              ),
              constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
              child: Text(
                count > 99 ? '99+' : count.toString(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
      ],
    );
  }
}
