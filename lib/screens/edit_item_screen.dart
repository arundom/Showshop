import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/item.dart';
import '../providers/item_provider.dart';

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
  bool _isSaving = false;

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

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);

    // Construct a fresh Item so optional fields can be cleared to null.
    final updated = Item(
      id: widget.item.id,
      imageUrls: widget.item.imageUrls,
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
