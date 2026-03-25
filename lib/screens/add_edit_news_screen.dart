import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../models/news.dart';
import '../providers/news_provider.dart';
import 'add_edit_book_screen.dart' show isLocalImagePath;
import '../utils/app_theme.dart';
import '../utils/validators.dart';
import '../widgets/common_widgets.dart';

class AddEditNewsScreen extends StatefulWidget {
  final News? news;

  const AddEditNewsScreen({super.key, this.news});

  bool get isEditing => news != null;

  @override
  State<AddEditNewsScreen> createState() => _AddEditNewsScreenState();
}

class _AddEditNewsScreenState extends State<AddEditNewsScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _descriptionController;
  final ImagePicker _picker = ImagePicker();
  String _imagePath = '';

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.news?.title ?? '');
    _descriptionController =
        TextEditingController(text: widget.news?.description ?? '');
    _imagePath = widget.news?.image ?? '';
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final picked = await _picker.pickImage(
        source: source,
        imageQuality: 85,
        maxWidth: 1200,
        maxHeight: 1200,
      );
      if (picked == null) return;
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
              ListTile(
                leading: const Icon(Icons.photo_library_outlined,
                    color: AppTheme.primary),
                title: const Text('Choose from Gallery'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.gallery);
                },
              ),
              ListTile(
                leading:
                    const Icon(Icons.camera_alt_outlined, color: AppTheme.accent),
                title: const Text('Take a Photo'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.camera);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    if (_imagePath.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a news image.'),
          backgroundColor: AppTheme.error,
        ),
      );
      return;
    }

    final provider = context.read<NewsProvider>();
    final item = News(
      id: widget.news?.id,
      title: _titleController.text.trim(),
      description: _descriptionController.text.trim(),
      image: _imagePath,
      createdAt: widget.news?.createdAt,
    );

    final success = widget.isEditing
        ? await provider.updateNews(item)
        : await provider.addNews(item);

    if (!mounted) return;

    if (success) {
      Navigator.pop(context, true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(provider.errorMessage ?? 'Failed to save news.'),
          backgroundColor: AppTheme.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isEditing ? 'Edit News' : 'Add News'),
      ),
      body: Consumer<NewsProvider>(
        builder: (_, provider, __) {
          return LoadingOverlay(
            isLoading: provider.isLoading,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    GestureDetector(
                      onTap: _showImageSourceSheet,
                      child: Container(
                        width: double.infinity,
                        height: 170,
                        decoration: BoxDecoration(
                          color: _imagePath.isEmpty ? const Color(0xFFF0F2FF) : Colors.black,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: _imagePath.isEmpty ? AppTheme.primary : Colors.transparent,
                            width: 1.5,
                          ),
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: _imagePath.isEmpty
                            ? const Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.add_photo_alternate_outlined,
                                        size: 36, color: AppTheme.primary),
                                    SizedBox(height: 8),
                                    Text(
                                      'Tap to pick image',
                                      style: TextStyle(
                                        color: AppTheme.primary,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            : (isLocalImagePath(_imagePath)
                                ? Image.file(
                                    File(_imagePath),
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) => _newsImageError(),
                                  )
                                : Image.network(
                                    _imagePath,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) => _newsImageError(),
                                  )),
                      ),
                    ),
                    const SizedBox(height: 16),
                    AppTextField(
                      controller: _titleController,
                      label: 'Title',
                      hint: 'Enter news title',
                      prefixIcon: Icons.title,
                      validator: (v) =>
                          Validators.required(v, fieldName: 'Title'),
                    ),
                    const SizedBox(height: 16),
                    AppTextField(
                      controller: _descriptionController,
                      label: 'Description',
                      hint: 'Enter news description',
                      prefixIcon: Icons.description_outlined,
                      maxLines: 4,
                      validator: (v) =>
                          Validators.required(v, fieldName: 'Description'),
                    ),
                    const SizedBox(height: 28),
                    ElevatedButton.icon(
                      onPressed: provider.isLoading ? null : _save,
                      icon: Icon(widget.isEditing ? Icons.save : Icons.add),
                      label:
                          Text(widget.isEditing ? 'Save Changes' : 'Create News'),
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

  Widget _newsImageError() => Container(
        color: AppTheme.divider,
        child: const Center(
          child: Icon(Icons.broken_image_outlined, color: AppTheme.textGrey),
        ),
      );
}
