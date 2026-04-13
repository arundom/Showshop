import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/item.dart';
import '../providers/item_provider.dart';

/// Form screen for adding a new [Item] to the local database.
class AddItemScreen extends StatefulWidget {
  const AddItemScreen({super.key});

  @override
  State<AddItemScreen> createState() => _AddItemScreenState();
}

class _AddItemScreenState extends State<AddItemScreen> {
  final _formKey = GlobalKey<FormState>();
  final _descController = TextEditingController();
  final _priceController = TextEditingController();
  final _conditionController = TextEditingController();
  final _sellerNameController = TextEditingController();
  final _sellerContactController = TextEditingController();
  final _notesController = TextEditingController();

  DateTime _listingDate = DateTime.now();
  bool _isSaving = false;

  static final _dateFormat = DateFormat('dd MMM yyyy');

  @override
  void dispose() {
    _descController.dispose();
    _priceController.dispose();
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
    if (picked != null) {
      setState(() => _listingDate = picked);
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    final item = Item(
      description: _descController.text.trim(),
      price: double.parse(_priceController.text.trim()),
      listingDate: _listingDate,
      condition: _conditionController.text.trim().isEmpty
          ? null
          : _conditionController.text.trim(),
      sellerName: _sellerNameController.text.trim().isEmpty
          ? null
          : _sellerNameController.text.trim(),
      sellerContact: _sellerContactController.text.trim().isEmpty
          ? null
          : _sellerContactController.text.trim(),
      notes: _notesController.text.trim().isEmpty
          ? null
          : _notesController.text.trim(),
    );

    try {
      await context.read<ItemProvider>().addItem(item);
      if (mounted) Navigator.of(context).pop();
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
        title: const Text('Add Item'),
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
              child: const Text('SAVE'),
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // ── Description ──────────────────────────────────────────────
            TextFormField(
              controller: _descController,
              decoration: const InputDecoration(
                labelText: 'Description *',
                border: OutlineInputBorder(),
                helperText: 'E.g. Samsung 65" 4K TV',
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
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Price is required';
                if (double.tryParse(v.trim()) == null) {
                  return 'Enter a valid number';
                }
                return null;
              },
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
              child: const Text('Save Item'),
            ),
          ],
        ),
      ),
    );
  }
}
