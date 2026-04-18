import 'dart:io';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/item.dart';
import '../providers/admin_auth_provider.dart';
import 'edit_item_screen.dart';

/// Displays the full details of a single [Item].
///
/// Features a gradient background (blue → purple), a 2×2 image grid,
/// and a details card with all item fields. An edit button in the app bar
/// opens [EditItemScreen] and refreshes the displayed data on return.
class DetailScreen extends StatefulWidget {
  const DetailScreen({super.key, required this.item});

  final Item item;

  @override
  State<DetailScreen> createState() => _DetailScreenState();
}

class _DetailScreenState extends State<DetailScreen> {
  late Item _item;

  static final _dateFormat = DateFormat('dd MMMM yyyy');
  static final _priceFormat = NumberFormat.currency(symbol: '₹');

  @override
  void initState() {
    super.initState();
    _item = widget.item;
  }

  Future<void> _openEdit() async {
    final updated = await Navigator.of(context).push<Item>(
      MaterialPageRoute(builder: (_) => EditItemScreen(item: _item)),
    );
    if (updated != null) {
      setState(() => _item = updated);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isAdmin = context.watch<AdminAuthProvider>().isAdmin;
    final item = _item;
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text('Item Details', style: TextStyle(color: Colors.white)),
        actions: [
          if (isAdmin)
            IconButton(
              icon: const Icon(Icons.edit_outlined, color: Colors.white),
              tooltip: 'Edit item',
              onPressed: _openEdit,
            ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF6BA4E0), // blue
              Color(0xFFB57FD8), // purple
            ],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ── Title ────────────────────────────────────────────────
                Text(
                  item.title ?? item.description,
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w300,
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),

                // ── Image grid ───────────────────────────────────────────
                GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 2,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 2.2,
                  children: List.generate(4, (index) {
                    final hasImage = item.imageUrls.length > index;
                    final imageUrl = hasImage ? item.imageUrls[index] : '';
                    final isRemoteImage = hasImage &&
                      (imageUrl.startsWith('http://') ||
                        imageUrl.startsWith('https://'));
                    return Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(30),
                      ),
                      child: Center(
                        child: hasImage
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(30),
                                child: isRemoteImage
                                    ? Image.network(
                                    imageUrl,
                                        fit: BoxFit.cover,
                                        width: double.infinity,
                                        height: double.infinity,
                                        errorBuilder:
                                            (context, error, stackTrace) => Text(
                                          'image ${index + 1}',
                                          style: const TextStyle(
                                              fontSize: 14,
                                              color: Colors.black54),
                                        ),
                                      )
                                    : Image.file(
                                        File(imageUrl),
                                        fit: BoxFit.cover,
                                        width: double.infinity,
                                        height: double.infinity,
                                        errorBuilder:
                                            (context, error, stackTrace) => Text(
                                          'image ${index + 1}',
                                          style: const TextStyle(
                                              fontSize: 14,
                                              color: Colors.black54),
                                        ),
                                      ),
                              )
                            : Text(
                                'image ${index + 1}',
                                style: const TextStyle(
                                    fontSize: 14, color: Colors.black54),
                              ),
                      ),
                    );
                  }),
                ),
                const SizedBox(height: 24),

                // ── Current price banner ────────────────────────────────
                Container(
                  padding: const EdgeInsets.symmetric(
                      vertical: 16, horizontal: 24),
                  decoration: BoxDecoration(
                    color: Colors.white.withAlpha(230),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Offer Price',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Colors.grey.shade700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _priceFormat.format(item.price),
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2E7D32),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // ── Details card ────────────────────────────────────────
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.withAlpha(200),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _DetailRow(
                        icon: Icons.description_outlined,
                        label: 'Description',
                        value: item.description,
                      ),
                      const Divider(height: 1),
                      _DetailRow(
                        icon: Icons.calendar_today_outlined,
                        label: 'Listing Date',
                        value: _dateFormat.format(item.listingDate),
                      ),
                      const Divider(height: 1),
                      _DetailRow(
                        icon: Icons.currency_rupee_outlined,
                        label: 'Original Price',
                        value: item.originalPrice != null
                            ? _priceFormat.format(item.originalPrice!)
                            : '—',
                      ),
                      const Divider(height: 1),
                      _DetailRow(
                        icon: Icons.label_outline,
                        label: 'Brand',
                        value: (item.brand != null && item.brand!.isNotEmpty)
                            ? item.brand!
                            : '—',
                      ),
                      const Divider(height: 1),
                      _DetailRow(
                        icon: Icons.warning_amber_outlined,
                        label: 'Known Issues',
                        value: (item.knownIssues != null &&
                                item.knownIssues!.isNotEmpty)
                            ? item.knownIssues!
                            : '—',
                      ),
                      const Divider(height: 1),
                      _DetailRow(
                        icon: Icons.star_outline,
                        label: 'Condition',
                        value: (item.condition != null &&
                                item.condition!.isNotEmpty)
                            ? item.condition!
                            : '—',
                      ),
                      const Divider(height: 1),
                      _DetailRow(
                        icon: Icons.person_outline,
                        label: 'Seller Name',
                        value: (item.sellerName != null &&
                                item.sellerName!.isNotEmpty)
                            ? item.sellerName!
                            : '—',
                      ),
                      const Divider(height: 1),
                      _DetailRow(
                        icon: Icons.phone_outlined,
                        label: 'Seller Contact',
                        value: (item.sellerContact != null &&
                                item.sellerContact!.isNotEmpty)
                            ? item.sellerContact!
                            : '—',
                      ),
                      const Divider(height: 1),
                      _DetailRow(
                        icon: Icons.notes_outlined,
                        label: 'Notes',
                        value:
                            (item.notes != null && item.notes!.isNotEmpty)
                                ? item.notes!
                                : '—',
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // ── Sync status ─────────────────────────────────────────
                Row(
                  children: [
                    Icon(
                      item.isSynced
                          ? Icons.cloud_done_outlined
                          : Icons.cloud_off_outlined,
                      size: 16,
                      color: item.isSynced ? Colors.white : Colors.white70,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      item.isSynced ? 'Synced to cloud' : 'Pending sync',
                      style: TextStyle(
                        fontSize: 12,
                        color: item.isSynced ? Colors.white : Colors.white70,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Private helper widgets ────────────────────────────────────────────────────

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: const Color(0xFF1565C0)),
          const SizedBox(width: 12),
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: const TextStyle(
                  fontSize: 14, fontWeight: FontWeight.w600),
            ),
          ),
          Expanded(
            child: Text(value, style: const TextStyle(fontSize: 14)),
          ),
        ],
      ),
    );
  }
}
