import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/item.dart';
import '../providers/admin_auth_provider.dart';
import '../providers/item_provider.dart';
import '../services/database_service.dart';
import '../services/supabase_service.dart';

/// Form screen for editing an existing [Item].
///
/// Pre-fills all fields from [item] and calls [ItemProvider.updateItem] on save.
/// Pops with the updated [Item] as the navigation result so callers can
/// refresh their displayed data.
class EditItemScreen extends StatefulWidget {
  const EditItemScreen({super.key, required this.item});

  final Item item;

  @override
  State<EditItemScreen> createState() => _EditItemScreenState();
}

class _EditItemScreenState extends State<EditItemScreen> {
  final _formKey = GlobalKey<FormState>();
  final _db = DatabaseService();
  final _remote = SupabaseService();
  final _picker = ImagePicker();
  late final TextEditingController _titleController;
  late final TextEditingController _descController;
  late final TextEditingController _priceController;
  late final TextEditingController _originalPriceController;
  late final TextEditingController _brandController;
  late final TextEditingController _knownIssuesController;
  late final TextEditingController _conditionController;
  late final TextEditingController _sellerNameController;
  late final TextEditingController _sellerContactController;
  late final TextEditingController _notesController;

  late DateTime _listingDate;
  late List<String> _imageUrls;
  bool _isSaving = false;
  int? _uploadingImageIndex;

  static final _dateFormat = DateFormat('dd MMM yyyy');

  @override
  void initState() {
    super.initState();
    final i = widget.item;
    _titleController = TextEditingController(text: i.title ?? '');
    _descController = TextEditingController(text: i.description);
    _priceController = TextEditingController(text: i.price.toString());
    _originalPriceController =
        TextEditingController(text: i.originalPrice?.toString() ?? '');
    _brandController = TextEditingController(text: i.brand ?? '');
    _knownIssuesController = TextEditingController(text: i.knownIssues ?? '');
    _conditionController = TextEditingController(text: i.condition ?? '');
    _sellerNameController = TextEditingController(text: i.sellerName ?? '');
    _sellerContactController =
        TextEditingController(text: i.sellerContact ?? '');
    _notesController = TextEditingController(text: i.notes ?? '');
    _listingDate = i.listingDate;
    _imageUrls = List<String>.from(i.imageUrls.take(4));
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    _priceController.dispose();
    _originalPriceController.dispose();
    _brandController.dispose();
    _knownIssuesController.dispose();
    _conditionController.dispose();
    _sellerNameController.dispose();
    _sellerContactController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _listingDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (picked != null) setState(() => _listingDate = picked);
  }

  String? _nonEmpty(String text) =>
      text.trim().isEmpty ? null : text.trim();

  Future<void> _pickImage(int index) async {
    final itemId = widget.item.id;
    if (itemId == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Save item first before uploading images.')),
        );
      }
      return;
    }

    final picked = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
      maxWidth: 1800,
    );
    if (picked == null) return;

    setState(() => _uploadingImageIndex = index);
    try {
      final remoteUrl = await _remote.uploadImage(File(picked.path), itemId);
      if (!mounted) return;
      setState(() {
        if (_imageUrls.length > index) {
          _imageUrls[index] = remoteUrl;
        } else {
          _imageUrls.add(remoteUrl);
        }
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Image upload failed: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _uploadingImageIndex = null);
    }
  }

  void _removeImage(int index) {
    if (_imageUrls.length <= index) return;
    setState(() => _imageUrls.removeAt(index));
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);

    // Construct a fresh Item so optional fields can be cleared to null.
    final updated = Item(
      id: widget.item.id,
      imageUrls: List<String>.unmodifiable(_imageUrls),
      createdAt: widget.item.createdAt,
      title: _nonEmpty(_titleController.text),
      description: _descController.text.trim(),
      price: double.parse(_priceController.text.trim()),
      originalPrice: _nonEmpty(_originalPriceController.text) != null
          ? double.tryParse(_originalPriceController.text.trim())
          : null,
      brand: _nonEmpty(_brandController.text),
      knownIssues: _nonEmpty(_knownIssuesController.text),
      listingDate: _listingDate,
      condition: _nonEmpty(_conditionController.text),
      sellerName: _nonEmpty(_sellerNameController.text),
      sellerContact: _nonEmpty(_sellerContactController.text),
      notes: _nonEmpty(_notesController.text),
      isSynced: false,
      updatedAt: DateTime.now(),
    );

    try {
      final itemId = widget.item.id;
      if (itemId != null) {
        await _remote.replaceItemImages(itemId, updated.imageUrls);
        await _db.replaceItemImages(itemId: itemId, imageUrls: updated.imageUrls);
      }
      await context.read<ItemProvider>().updateItem(updated);
      if (mounted) Navigator.of(context).pop(updated);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isAdmin = context.watch<AdminAuthProvider>().isAdmin;
    if (!isAdmin) {
      return Scaffold(
        appBar: AppBar(title: const Text('Edit Item')),
        body: const Center(
          child: Text('Admin access required.'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Item'),
        actions: [
          if (_isSaving)
            const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            )
          else
            TextButton(
              onPressed: _save,
              style: TextButton.styleFrom(foregroundColor: Colors.white),
              child: const Text('SAVE'),
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const Text(
              'Images',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: 4,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 1.1,
              ),
              itemBuilder: (context, index) {
                final hasImage = _imageUrls.length > index;
                final imageUrl = hasImage ? _imageUrls[index] : '';
                final isRemoteImage = hasImage &&
                  (imageUrl.startsWith('http://') ||
                    imageUrl.startsWith('https://'));

                return GestureDetector(
                  onTap: () => _pickImage(index),
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.grey.shade400),
                      color: Colors.grey.shade50,
                    ),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        if (hasImage)
                          ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: isRemoteImage
                                ? Image.network(imageUrl, fit: BoxFit.cover)
                                : Image.file(File(imageUrl), fit: BoxFit.cover),
                          )
                        else
                          Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: const [
                              Icon(Icons.add_photo_alternate_outlined, size: 32),
                              SizedBox(height: 8),
                              Text('Add image'),
                            ],
                          ),
                        if (_uploadingImageIndex == index)
                          Container(
                            color: Colors.black38,
                            child: const Center(
                              child: CircularProgressIndicator(),
                            ),
                          ),
                        Positioned(
                          left: 8,
                          bottom: 8,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.black54,
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              'Image ${index + 1}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ),
                        Positioned(
                          right: 8,
                          top: 8,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                decoration: const BoxDecoration(
                                  color: Colors.black54,
                                  shape: BoxShape.circle,
                                ),
                                child: IconButton(
                                  onPressed: () => _pickImage(index),
                                  icon: const Icon(
                                    Icons.edit_outlined,
                                    color: Colors.white,
                                    size: 18,
                                  ),
                                ),
                              ),
                              if (hasImage) const SizedBox(width: 8),
                              if (hasImage)
                                Container(
                                  decoration: const BoxDecoration(
                                    color: Colors.black54,
                                    shape: BoxShape.circle,
                                  ),
                                  child: IconButton(
                                    onPressed: () => _removeImage(index),
                                    icon: const Icon(
                                      Icons.close,
                                      color: Colors.white,
                                      size: 18,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 8),
            Text(
              'You can keep up to 4 images. Tap a slot to add or replace.',
              style: TextStyle(color: Colors.grey.shade700),
            ),
            const SizedBox(height: 24),

            // ── Title ──────────────────────────────────────────────────
            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Title',
                border: OutlineInputBorder(),
              ),
              textCapitalization: TextCapitalization.words,
            ),
            const SizedBox(height: 16),

            // ── Description ──────────────────────────────────────────────
            TextFormField(
              controller: _descController,
              decoration: const InputDecoration(
                labelText: 'Description *',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
              textCapitalization: TextCapitalization.sentences,
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Description is required' : null,
            ),
            const SizedBox(height: 16),

            // ── Price ────────────────────────────────────────────────────
            TextFormField(
              controller: _priceController,
              decoration: const InputDecoration(
                labelText: 'Price (₹) *',
                border: OutlineInputBorder(),
                prefixText: '₹ ',
              ),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Price is required';
                if (double.tryParse(v.trim()) == null) {
                  return 'Enter a valid number';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // ── Original Price ───────────────────────────────────────────
            TextFormField(
              controller: _originalPriceController,
              decoration: const InputDecoration(
                labelText: 'Original Price (₹)',
                border: OutlineInputBorder(),
                prefixText: '₹ ',
              ),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              validator: (v) {
                if (v != null &&
                    v.trim().isNotEmpty &&
                    double.tryParse(v.trim()) == null) {
                  return 'Enter a valid number';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // ── Brand ────────────────────────────────────────────────────
            TextFormField(
              controller: _brandController,
              decoration: const InputDecoration(
                labelText: 'Brand',
                border: OutlineInputBorder(),
              ),
              textCapitalization: TextCapitalization.words,
            ),
            const SizedBox(height: 16),

            // ── Known Issues ─────────────────────────────────────────────
            TextFormField(
              controller: _knownIssuesController,
              decoration: const InputDecoration(
                labelText: 'Known Issues',
                border: OutlineInputBorder(),
                helperText: 'Any defects or issues',
              ),
              maxLines: 2,
              textCapitalization: TextCapitalization.sentences,
            ),
            const SizedBox(height: 16),

            // ── Listing Date ─────────────────────────────────────────────
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Listing Date *'),
              subtitle: Text(_dateFormat.format(_listingDate)),
              trailing: const Icon(Icons.calendar_today_outlined),
              onTap: _pickDate,
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.all(Radius.circular(4)),
                side: BorderSide(color: Colors.grey),
              ),
            ),
            const SizedBox(height: 16),

            // ── Condition ────────────────────────────────────────────────
            TextFormField(
              controller: _conditionController,
              decoration: const InputDecoration(
                labelText: 'Condition',
                border: OutlineInputBorder(),
                helperText: 'E.g. Good, Excellent, Fair',
              ),
            ),
            const SizedBox(height: 16),

            // ── Seller Name ──────────────────────────────────────────────
            TextFormField(
              controller: _sellerNameController,
              decoration: const InputDecoration(
                labelText: 'Seller Name',
                border: OutlineInputBorder(),
              ),
              textCapitalization: TextCapitalization.words,
            ),
            const SizedBox(height: 16),

            // ── Seller Contact ───────────────────────────────────────────
            TextFormField(
              controller: _sellerContactController,
              decoration: const InputDecoration(
                labelText: 'Seller Contact',
                border: OutlineInputBorder(),
                helperText: 'Phone number or email',
              ),
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 16),

            // ── Notes ────────────────────────────────────────────────────
            TextFormField(
              controller: _notesController,
              decoration: const InputDecoration(
                labelText: 'Additional Notes',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
              textCapitalization: TextCapitalization.sentences,
            ),
            const SizedBox(height: 32),

            ElevatedButton(
              onPressed: _isSaving ? null : _save,
              style: ElevatedButton.styleFrom(
                minimumSize: const Size.fromHeight(48),
              ),
              child: const Text('Save Changes'),
            ),
          ],
        ),
      ),
    );
  }
}
