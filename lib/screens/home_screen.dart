import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/book_provider.dart';
import '../providers/cart_provider.dart';
import '../utils/app_theme.dart';
import '../widgets/common_widgets.dart';
import 'book_detail_screen.dart';
import 'add_edit_book_screen.dart';
import 'cart_screen.dart';
import 'login_screen.dart';
import 'profile_screen.dart';
import 'category_list_screen.dart';
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
          ),

          IconButton(
            icon: const Icon(Icons.category),
            tooltip: 'Category',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const CategoryListScreen(),
                ),
              );
            },
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
            onSelected: (value) {
              if (value == 'logout') _logout();
            },
            itemBuilder: (_) => [
              PopupMenuItem(
                value: 'logout',
                child: Row(
                  children: const [
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
      body: Consumer<BookProvider>(
        builder: (context, bookProvider, _) {
          if (bookProvider.isLoading && bookProvider.books.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          final books = bookProvider.books;

          if (books.isEmpty) {
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
            onRefresh: () => bookProvider.loadBooks(),
            child: ListView.builder(
              padding: const EdgeInsets.only(bottom: 100, top: 8),
              itemCount: books.length,
              itemBuilder: (context, index) {
                final book = books[index];
                return BookCard(
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
                );
              },
            ),
          );
        },
      ),
    );
  }
}
