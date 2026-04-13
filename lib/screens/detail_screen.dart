import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/item.dart';

/// Displays the full details of a single [Item].
///
/// Accessible by tapping the description link on the home screen.
class DetailScreen extends StatelessWidget {
  const DetailScreen({super.key, required this.item});

  final Item item;

  static final _dateFormat = DateFormat('dd MMMM yyyy');
  static final _priceFormat = NumberFormat.currency(symbol: '₹');

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Item Details'),
        elevation: 2,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Hero price banner ──────────────────────────────────────────
            _PriceBanner(item: item, colorScheme: colorScheme),
            const SizedBox(height: 24),

            // ── Description ────────────────────────────────────────────────
            _SectionLabel(label: 'Description'),
            const SizedBox(height: 4),
            Text(item.description, style: theme.textTheme.bodyLarge),
            const SizedBox(height: 20),

            // ── Details grid ───────────────────────────────────────────────
            _DetailCard(
              children: [
                _DetailRow(
                  icon: Icons.calendar_today_outlined,
                  label: 'Listing Date',
                  value: _dateFormat.format(item.listingDate),
                ),
                if (item.condition != null && item.condition!.isNotEmpty) ...[
                  const Divider(height: 1),
                  _DetailRow(
                    icon: Icons.star_outline,
                    label: 'Condition',
                    value: item.condition!,
                  ),
                ],
                if (item.sellerName != null && item.sellerName!.isNotEmpty) ...[
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

            // ── Sync status chip ───────────────────────────────────────────
            const SizedBox(height: 20),
            Row(
              children: [
                Icon(
                  item.isSynced
                      ? Icons.cloud_done_outlined
                      : Icons.cloud_off_outlined,
                  size: 16,
                  color: item.isSynced ? Colors.green : Colors.orange,
                ),
                const SizedBox(width: 6),
                Text(
                  item.isSynced ? 'Synced to cloud' : 'Pending sync',
                  style: TextStyle(
                    fontSize: 12,
                    color: item.isSynced ? Colors.green : Colors.orange,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ── Private helper widgets ────────────────────────────────────────────────────

class _PriceBanner extends StatelessWidget {
  const _PriceBanner({required this.item, required this.colorScheme});

  final Item item;
  final ColorScheme colorScheme;

  static final _priceFormat = NumberFormat.currency(symbol: '₹');

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
      decoration: BoxDecoration(
        color: colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            item.description,
            style: Theme.of(context)
                .textTheme
                .titleLarge
                ?.copyWith(fontWeight: FontWeight.bold),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 8),
          Text(
            _priceFormat.format(item.price),
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  color: colorScheme.primary,
                  fontWeight: FontWeight.bold,
                ),
          ),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: Theme.of(context)
          .textTheme
          .labelLarge
          ?.copyWith(color: Theme.of(context).colorScheme.primary),
    );
  }
}

class _DetailCard extends StatelessWidget {
  const _DetailCard({required this.children});
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Theme.of(context).dividerColor),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Column(children: children),
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
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: theme.colorScheme.primary),
          const SizedBox(width: 12),
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: theme.textTheme.bodyMedium
                  ?.copyWith(fontWeight: FontWeight.w600),
            ),
          ),
          Expanded(
            child: Text(value, style: theme.textTheme.bodyMedium),
          ),
        ],
      ),
    );
  }
}
