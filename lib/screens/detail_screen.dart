import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/item.dart';

/// Displays the full details of a single [Item].
///
/// Features a gradient background (blue → purple), a 2×2 image grid,
/// and green rounded buttons for Optional Price, Brand and Known Issues.
class DetailScreen extends StatelessWidget {
  const DetailScreen({super.key, required this.item});

  final Item item;

  static final _dateFormat = DateFormat('dd MMMM yyyy');
  static final _priceFormat = NumberFormat.currency(symbol: '₹');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text('Item Details', style: TextStyle(color: Colors.white)),
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
                    return Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(30),
                      ),
                      child: Center(
                        child: hasImage
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(30),
                                child: Image.network(
                                  item.imageUrls[index],
                                  fit: BoxFit.cover,
                                  width: double.infinity,
                                  height: double.infinity,
                                  errorBuilder: (_, __, ___) => Text(
                                    'image ${index + 1}',
                                    style: const TextStyle(
                                        fontSize: 14, color: Colors.black54),
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

                // ── Optional info buttons ────────────────────────────────
                if (item.originalPrice != null) ...[
                  _InfoButton(
                    label: 'Original Price',
                    value: _priceFormat.format(item.originalPrice!),
                  ),
                  const SizedBox(height: 12),
                ],
                if (item.brand != null && item.brand!.isNotEmpty) ...[
                  _InfoButton(label: 'Brand', value: item.brand!),
                  const SizedBox(height: 12),
                ],
                if (item.knownIssues != null &&
                    item.knownIssues!.isNotEmpty) ...[
                  _InfoButton(label: 'Known Issues', value: item.knownIssues!),
                  const SizedBox(height: 12),
                ],

                // ── Current price banner ────────────────────────────────
                const SizedBox(height: 4),
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
                        'Current Price',
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
                      if (item.condition != null &&
                          item.condition!.isNotEmpty) ...[
                        const Divider(height: 1),
                        _DetailRow(
                          icon: Icons.star_outline,
                          label: 'Condition',
                          value: item.condition!,
                        ),
                      ],
                      if (item.sellerName != null &&
                          item.sellerName!.isNotEmpty) ...[
                        const Divider(height: 1),
                        _DetailRow(
                          icon: Icons.person_outline,
                          label: 'Seller',
                          value: item.sellerName!,
                        ),
                      ],
                      if (item.sellerContact != null &&
                          item.sellerContact!.isNotEmpty) ...[
                        const Divider(height: 1),
                        _DetailRow(
                          icon: Icons.phone_outlined,
                          label: 'Contact',
                          value: item.sellerContact!,
                        ),
                      ],
                      if (item.notes != null && item.notes!.isNotEmpty) ...[
                        const Divider(height: 1),
                        _DetailRow(
                          icon: Icons.notes_outlined,
                          label: 'Notes',
                          value: item.notes!,
                        ),
                      ],
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

class _InfoButton extends StatelessWidget {
  const _InfoButton({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0xFF4CAF50),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ),
          Text(
            value,
            style: const TextStyle(fontSize: 15, color: Colors.white),
          ),
        ],
      ),
    );
  }
}

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
