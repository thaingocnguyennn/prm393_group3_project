import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../models/book.dart';
import '../providers/book_provider.dart';
import '../utils/app_theme.dart';
import '../utils/validators.dart';
import '../widgets/common_widgets.dart';

/// Returns true if the stored image path is a local file (not a URL).
bool isLocalImagePath(String path) =>
    path.isNotEmpty && !path.startsWith('http');

class AddEditBookScreen extends StatefulWidget {
  final Book? book;

  const AddEditBookScreen({super.key, this.book});

  bool get isEditing => book != null;

  @override
  State<AddEditBookScreen> createState() => _AddEditBookScreenState();
}

class _AddEditBookScreenState extends State<AddEditBookScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _authorController;
  late final TextEditingController _priceController;
  late final TextEditingController _descriptionController;

  /// Holds either a local absolute file path or a remote URL.
  String _imagePath = '';

  final ImagePicker _picker = ImagePicker();

  // ─── LIFECYCLE ─────────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    final book = widget.book;
    _titleController = TextEditingController(text: book?.title ?? '');
    _authorController = TextEditingController(text: book?.author ?? '');
    _priceController = TextEditingController(
        text: book != null ? book.price.toStringAsFixed(2) : '');
    _descriptionController =
        TextEditingController(text: book?.description ?? '');
    _imagePath = book?.image ?? '';
  }

  @override
  void dispose() {
    _titleController.dispose();
    _authorController.dispose();
    _priceController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  // ─── IMAGE PICKING ─────────────────────────────────────────────────────────

  void _showImageSourceSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle bar
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: AppTheme.divider,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Choose Image Source',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textDark,
                    ),
                  ),
                ),
              ),
              const Divider(height: 16),
              ListTile(
                leading: const CircleAvatar(
                  backgroundColor: Color(0xFFE8EAF6),
                  child: Icon(Icons.photo_library_outlined,
                      color: AppTheme.primary),
                ),
                title: const Text('Choose from Gallery'),
                subtitle: const Text('Pick an existing photo'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.gallery);
                },
              ),
              ListTile(
                leading: const CircleAvatar(
                  backgroundColor: Color(0xFFFFF3E0),
                  child:
                      Icon(Icons.camera_alt_outlined, color: AppTheme.accent),
                ),
                title: const Text('Take a Photo'),
                subtitle: const Text('Use your camera'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.camera);
                },
              ),
              if (_imagePath.isNotEmpty) ...[
                const Divider(height: 16),
                ListTile(
                  leading: const CircleAvatar(
                    backgroundColor: Color(0xFFFFEBEE),
                    child: Icon(Icons.delete_outline, color: AppTheme.error),
                  ),
                  title: const Text(
                    'Remove Image',
                    style: TextStyle(color: AppTheme.error),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    setState(() => _imagePath = '');
                  },
                ),
              ],
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? picked = await _picker.pickImage(
        source: source,
        imageQuality: 85,
        maxWidth: 1200,
        maxHeight: 1200,
      );
      if (picked == null) return; // user cancelled
      setState(() => _imagePath = picked.path);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not pick image: $e'),
          backgroundColor: AppTheme.error,
        ),
      );
    }
  }

  // ─── SAVE ──────────────────────────────────────────────────────────────────

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    if (_imagePath.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a cover image.'),
          backgroundColor: AppTheme.error,
        ),
      );
      return;
    }

    final bookProvider = context.read<BookProvider>();

    final book = Book(
      id: widget.book?.id,
      title: _titleController.text.trim(),
      author: _authorController.text.trim(),
      price: double.parse(_priceController.text.trim()),
      image: _imagePath,
      description: _descriptionController.text.trim(),
    );

    final bool success = widget.isEditing
        ? await bookProvider.updateBook(book)
        : await bookProvider.addBook(book);

    if (!mounted) return;

    if (success) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(widget.isEditing
              ? '${book.title} updated successfully!'
              : '${book.title} added successfully!'),
          backgroundColor: AppTheme.primary,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(bookProvider.errorMessage ?? 'Failed to save book.'),
          backgroundColor: AppTheme.error,
        ),
      );
    }
  }

  // ─── BUILD ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isEditing ? 'Edit Book' : 'Add New Book'),
      ),
      body: Consumer<BookProvider>(
        builder: (context, bookProvider, _) {
          return LoadingOverlay(
            isLoading: bookProvider.isLoading,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // ── Cover image picker ──────────────────────────────────
                    _ImagePickerTile(
                      imagePath: _imagePath,
                      onTap: _showImageSourceSheet,
                    ),
                    const SizedBox(height: 20),

                    // ── Fields ──────────────────────────────────────────────
                    AppTextField(
                      controller: _titleController,
                      label: 'Title',
                      hint: 'e.g. Clean Code',
                      prefixIcon: Icons.title,
                      validator: (v) =>
                          Validators.required(v, fieldName: 'Title'),
                    ),
                    const SizedBox(height: 16),
                    AppTextField(
                      controller: _authorController,
                      label: 'Author',
                      hint: 'e.g. Robert C. Martin',
                      prefixIcon: Icons.person_outline,
                      validator: (v) =>
                          Validators.required(v, fieldName: 'Author'),
                    ),
                    const SizedBox(height: 16),
                    AppTextField(
                      controller: _priceController,
                      label: 'Price (USD)',
                      hint: 'e.g. 29.99',
                      prefixIcon: Icons.attach_money,
                      keyboardType: const TextInputType.numberWithOptions(
                          decimal: true),
                      validator: Validators.price,
                    ),
                    const SizedBox(height: 16),
                    AppTextField(
                      controller: _descriptionController,
                      label: 'Description',
                      hint: 'Enter book description...',
                      prefixIcon: Icons.description_outlined,
                      maxLines: 4,
                      validator: (v) =>
                          Validators.required(v, fieldName: 'Description'),
                    ),
                    const SizedBox(height: 32),

                    // ── Actions ─────────────────────────────────────────────
                    ElevatedButton.icon(
                      onPressed: bookProvider.isLoading ? null : _save,
                      icon:
                          Icon(widget.isEditing ? Icons.save : Icons.add),
                      label: Text(widget.isEditing
                          ? 'Save Changes'
                          : 'Add Book'),
                    ),
                    if (widget.isEditing) ...[
                      const SizedBox(height: 12),
                      OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size(double.infinity, 52),
                          foregroundColor: AppTheme.textGrey,
                          side:
                              const BorderSide(color: AppTheme.divider),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text('Cancel'),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

// ─── IMAGE PICKER TILE ───────────────────────────────────────────────────────

class _ImagePickerTile extends StatelessWidget {
  final String imagePath;
  final VoidCallback onTap;

  const _ImagePickerTile({required this.imagePath, required this.onTap});

  bool get _hasImage => imagePath.isNotEmpty;
  bool get _isLocal => isLocalImagePath(imagePath);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        height: _hasImage ? 220 : 160,
        decoration: BoxDecoration(
          color: _hasImage ? Colors.black : const Color(0xFFF0F2FF),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: _hasImage ? Colors.transparent : AppTheme.primary,
            width: 2,
          ),
          boxShadow: _hasImage
              ? [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.15),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  )
                ]
              : [],
        ),
        clipBehavior: Clip.antiAlias,
        child: _hasImage ? _preview() : _placeholder(),
      ),
    );
  }

  Widget _preview() {
    return Stack(
      fit: StackFit.expand,
      children: [
        // Image
        _isLocal
            ? Image.file(
                File(imagePath),
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => _errorTile(),
              )
            : Image.network(
                imagePath,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => _errorTile(),
                loadingBuilder: (_, child, progress) =>
                    progress == null ? child : _loadingTile(),
              ),
        // Bottom gradient + edit hint
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: Container(
            padding:
                const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.transparent, Color(0xBB000000)],
              ),
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.edit, color: Colors.white, size: 15),
                SizedBox(width: 6),
                Text(
                  'Tap to change image',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 0.2,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _placeholder() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            color: AppTheme.primary.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.add_photo_alternate_outlined,
            size: 32,
            color: AppTheme.primary,
          ),
        ),
        const SizedBox(height: 12),
        const Text(
          'Add Cover Image',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: AppTheme.primary,
          ),
        ),
        const SizedBox(height: 4),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _chip(Icons.photo_library_outlined, 'Gallery'),
            const SizedBox(width: 8),
            _chip(Icons.camera_alt_outlined, 'Camera'),
          ],
        ),
      ],
    );
  }

  Widget _chip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppTheme.primary.withOpacity(0.08),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Icon(icon, size: 13, color: AppTheme.primary),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: AppTheme.primary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _errorTile() => Container(
        color: AppTheme.divider,
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.broken_image_outlined,
                  size: 40, color: AppTheme.textGrey),
              SizedBox(height: 8),
              Text('Image unavailable',
                  style: TextStyle(color: AppTheme.textGrey)),
            ],
          ),
        ),
      );

  Widget _loadingTile() => Container(
        color: AppTheme.divider,
        child: const Center(child: CircularProgressIndicator()),
      );
}
