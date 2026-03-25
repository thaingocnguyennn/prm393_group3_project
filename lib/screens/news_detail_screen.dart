import 'dart:io';
import 'package:flutter/material.dart';
import '../models/news.dart';
import '../utils/app_theme.dart';
import 'add_edit_book_screen.dart' show isLocalImagePath;

class NewsDetailScreen extends StatelessWidget {
  final News news;

  const NewsDetailScreen({super.key, required this.news});

  String _formatDate(DateTime? value) {
    if (value == null) return 'Unknown date';
    return value.toLocal().toString().split('.').first;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('News Detail')),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AspectRatio(
              aspectRatio: 16 / 9,
              child: isLocalImagePath(news.image)
                  ? Image.file(
                      File(news.image),
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        color: AppTheme.divider,
                        child: const Center(
                          child: Icon(
                            Icons.broken_image_outlined,
                            size: 40,
                            color: AppTheme.textGrey,
                          ),
                        ),
                      ),
                    )
                  : Image.network(
                      news.image,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        color: AppTheme.divider,
                        child: const Center(
                          child: Icon(
                            Icons.broken_image_outlined,
                            size: 40,
                            color: AppTheme.textGrey,
                          ),
                        ),
                      ),
                    ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    news.title,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textDark,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Created at: ${_formatDate(news.createdAt)}',
                    style: const TextStyle(
                      color: AppTheme.textGrey,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    news.description,
                    style: const TextStyle(
                      fontSize: 15,
                      height: 1.5,
                      color: AppTheme.textDark,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
