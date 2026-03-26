import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/news.dart';
import '../providers/news_provider.dart';
import '../utils/app_theme.dart';
import '../widgets/common_widgets.dart';
import 'add_edit_book_screen.dart' show isLocalImagePath;
import 'add_edit_news_screen.dart';
import 'news_detail_screen.dart';

class NewsListScreen extends StatefulWidget {
  const NewsListScreen({super.key});

  @override
  State<NewsListScreen> createState() => _NewsListScreenState();
}

class _NewsListScreenState extends State<NewsListScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<NewsProvider>().loadNews();
    });
  }

  // Mở màn hình thêm tin mới
  Future<void> _goToCreate() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const AddEditNewsScreen()),
    );
  }

  // Mở màn hình edit và truyền dữ liệu tin hiện tại
  Future<void> _goToEdit(News item) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => AddEditNewsScreen(news: item)),
    );
  }

  // Hiển thị dialog xác nhận trước khi xóa
  Future<void> _delete(News item) async {
    final confirmed = await ConfirmDialog.show(
      context,
      title: 'Delete News',
      message: 'Do you want to delete "${item.title}"?',
      confirmText: 'Delete',
      confirmColor: AppTheme.error,
    );

    if (!confirmed || item.id == null) return;

    final success = await context.read<NewsProvider>().deleteNews(item.id!);
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(success
            ? 'News deleted successfully.'
            : 'Failed to delete news.'),
        backgroundColor: success ? AppTheme.primary : AppTheme.error,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('News Management')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _goToCreate,
        icon: const Icon(Icons.add),
        label: const Text('Add News'),
      ),
      body: Consumer<NewsProvider>(
        builder: (_, provider, __) {
          if (provider.isLoading && provider.news.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.news.isEmpty) {
            return const EmptyState(
              icon: Icons.newspaper_outlined,
              title: 'No news yet',
              subtitle: 'Tap Add News to create your first item',
            );
          }

          return RefreshIndicator(
            onRefresh: provider.loadNews,
            child: ListView.builder(
              itemCount: provider.news.length,
              itemBuilder: (context, index) {
                final item = provider.news[index];
                return Card(
                  margin:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  child: ListTile(
                    leading: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: isLocalImagePath(item.image)
                          ? Image.file(
                              File(item.image),
                              width: 56,
                              height: 56,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Container(
                                width: 56,
                                height: 56,
                                color: AppTheme.divider,
                                child: const Icon(Icons.broken_image_outlined,
                                    color: AppTheme.textGrey),
                              ),
                            )
                          : Image.network(
                              item.image,
                              width: 56,
                              height: 56,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Container(
                                width: 56,
                                height: 56,
                                color: AppTheme.divider,
                                child: const Icon(Icons.broken_image_outlined,
                                    color: AppTheme.textGrey),
                              ),
                            ),
                    ),
                    title: Text(
                      item.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    subtitle: Text(
                      item.description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => NewsDetailScreen(news: item),
                      ),
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit_outlined),
                          onPressed: () => _goToEdit(item),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline,
                              color: AppTheme.error),
                          onPressed: () => _delete(item),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
