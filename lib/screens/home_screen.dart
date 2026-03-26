import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/book_provider.dart';
import '../providers/cart_provider.dart';
import '../providers/wishlist_provider.dart';
import '../providers/news_provider.dart';
import '../utils/app_theme.dart';
import '../widgets/common_widgets.dart';
import 'book_detail_screen.dart';
import 'add_edit_book_screen.dart';
import 'cart_screen.dart';
import 'wishlist_screen.dart';
import 'news_detail_screen.dart';
import 'news_list_screen.dart';
import 'login_screen.dart';
import 'profile_screen.dart';
import 'category_list_screen.dart';
import 'add_edit_book_screen.dart' show isLocalImagePath;
import 'voucher_list_screen.dart';
import 'order_history_screen.dart';
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _searchController = TextEditingController();
  bool _searchActive = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<BookProvider>().loadBooks();
      context.read<NewsProvider>().loadNews();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearch(String query) {
    context.read<BookProvider>().searchBooks(query);
  }

  void _toggleSearch() {
    setState(() => _searchActive = !_searchActive);
    if (!_searchActive) {
      _searchController.clear();
      context.read<BookProvider>().clearSearch();
    }
  }

  Future<void> _logout() async {
    final auth = context.read<AuthProvider>();
    await auth.logout();
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 50,
        title: _searchActive
            ? TextField(
                controller: _searchController,
                autofocus: true,
                style: const TextStyle(color: Colors.white),
                cursorColor: Colors.white,
                decoration: const InputDecoration(
                  hintText: 'Search books...',
                  hintStyle: TextStyle(color: Colors.white70),
                  border: InputBorder.none,
                  fillColor: Colors.transparent,
                  filled: false,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  contentPadding: EdgeInsets.zero,
                ),
                onChanged: _onSearch,
              )
            : const Text('BookStore'),
        actions: [
          IconButton(
            icon: Icon(_searchActive ? Icons.close : Icons.search),
            onPressed: _toggleSearch,
            tooltip: _searchActive ? 'Close search' : 'Search',
          ),
          IconButton(
            icon: const Icon(Icons.person),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ProfileScreen()),
              );
            },
            tooltip: 'Profile',
          ),

          Consumer<WishlistProvider>(
            builder: (_, wishlist, __) => WishlistBadge(
              count: wishlist.itemCount,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const WishlistScreen()),
              ),
            ),
          ),

          Consumer<CartProvider>(
            builder: (_, cart, __) => CartBadge(
              count: cart.itemCount,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const CartScreen()),
              ),
            ),
          ),

          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            tooltip: 'Menu',
            onSelected: (value) {
              if (value == 'category') {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const CategoryListScreen(),
                  ),
                );
              } else if (value == 'news') {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const NewsListScreen()),
                );
              } else if (value == 'voucher') {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const VoucherListScreen()),
                );
              } else if (value == 'orders') {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const OrderHistoryScreen(),
                  ),
                );
              } else if (value == 'logout') {
                _logout();
              }
            },
            itemBuilder: (_) => const [
              PopupMenuItem(
                value: 'category',
                child: Row(
                  children: [
                    Icon(Icons.category),
                    SizedBox(width: 8),
                    Text('Category'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'news',
                child: Row(
                  children: [
                    Icon(Icons.newspaper_outlined),
                    SizedBox(width: 8),
                    Text('News'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'voucher',
                child: Row(
                  children: [
                    Icon(Icons.local_offer_outlined),
                    SizedBox(width: 8),
                    Text('Voucher'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'orders',
                child: Row(
                  children: [
                    Icon(Icons.history),
                    SizedBox(width: 8),
                    Text('Order History'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'logout',
                child: Row(
                  children: [
                    Icon(Icons.logout, color: AppTheme.error),
                    SizedBox(width: 8),
                    Text('Logout'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AddEditBookScreen()),
          );
        },
        icon: const Icon(Icons.add),
        label: const Text('Add Book'),
        backgroundColor: AppTheme.primary,
        foregroundColor: Colors.white,
      ),
      body: Consumer2<BookProvider, NewsProvider>(
        builder: (context, bookProvider, newsProvider, _) {
          if (bookProvider.isLoading && bookProvider.books.isEmpty && newsProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          final books = bookProvider.books;
          final newestNews = newsProvider.newestNews;

          if (books.isEmpty && newestNews == null) {
            return EmptyState(
              icon: Icons.library_books_outlined,
              title: bookProvider.searchQuery.isEmpty
                  ? 'No books yet'
                  : 'No results found',
              subtitle: bookProvider.searchQuery.isEmpty
                  ? 'Tap the + button to add your first book'
                  : 'Try a different search term',
            );
          }

          return RefreshIndicator(
            onRefresh: () async {
              await Future.wait([
                bookProvider.loadBooks(),
                newsProvider.loadNews(),
              ]);
            },
            child: Consumer<WishlistProvider>(
              builder: (context, wishlistProvider, _) {
                return ListView(
                  padding: const EdgeInsets.only(bottom: 100, top: 8),
                  children: [
                    if (newestNews != null)
                      _NewestNewsCard(
                        title: newestNews.title,
                        imageUrl: newestNews.image,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => NewsDetailScreen(news: newestNews),
                            ),
                          );
                        },
                      ),
                    ...books.map((book) {
                      final isInWishlist = wishlistProvider.isInWishlist(book.id!);
                      return BookCard(
                        key: ValueKey(book.id),
                        book: book,
                        isInWishlist: isInWishlist,
                        onTap: () async {
                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => BookDetailScreen(book: book),
                            ),
                          );
                        },
                        onWishlistToggle: () {
                          wishlistProvider.toggleWishlist(book.id!, book);
                        },
                      );
                    }),
                  ],
                );
              },
            ),
          );
        },
      ),
    );
  }
}

class _NewestNewsCard extends StatelessWidget {
  final String title;
  final String imageUrl;
  final VoidCallback onTap;

  const _NewestNewsCard({
    required this.title,
    required this.imageUrl,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.fromLTRB(12, 8, 12, 10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: isLocalImagePath(imageUrl)
                    ? Image.file(
                        File(imageUrl),
                        width: 68,
                        height: 68,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          width: 68,
                          height: 68,
                          color: AppTheme.divider,
                          child: const Icon(Icons.broken_image_outlined,
                              color: AppTheme.textGrey),
                        ),
                      )
                    : Image.network(
                        imageUrl,
                        width: 68,
                        height: 68,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          width: 68,
                          height: 68,
                          color: AppTheme.divider,
                          child: const Icon(Icons.broken_image_outlined,
                              color: AppTheme.textGrey),
                        ),
                      ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Newest News',
                      style: TextStyle(
                        color: AppTheme.primary,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppTheme.textDark,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: AppTheme.textGrey),
            ],
          ),
        ),
      ),
    );
  }
}
