import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/item.dart';
import '../providers/item_provider.dart';
import 'add_item_screen.dart';
import 'detail_screen.dart';

/// Home screen — shows a scrollable table of all listed items ordered by
/// most-recent listing date first.
///
/// Columns: #  |  Description (tappable link)  |  Price  |  Listing Date
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  static final _dateFormat = DateFormat('dd MMM yyyy');
  static final _priceFormat = NumberFormat.currency(symbol: '₹');
  StreamSubscription<String>? _syncErrorSubscription;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _syncErrorSubscription = context.read<ItemProvider>().syncErrors.listen((message) {
        if (!mounted) return;
        final messenger = ScaffoldMessenger.of(context);
        messenger
          ..hideCurrentSnackBar()
          ..showSnackBar(
            SnackBar(
              content: Text(message),
              behavior: SnackBarBehavior.floating,
            ),
          );
      });

      // Load items after the first frame so the widget tree is ready.
      context.read<ItemProvider>().loadItems();
    });
  }

  @override
  void dispose() {
    _syncErrorSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Showshop – Items for Sale'),
        centerTitle: false,
        elevation: 2,
        actions: [
          Consumer<ItemProvider>(
            builder: (context, provider, _) {
              return IconButton(
                tooltip: provider.isSyncing ? 'Syncing...' : 'Sync now',
                onPressed: provider.isSyncing ? null : _syncNow,
                icon: provider.isSyncing
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.sync),
              );
            },
          ),
        ],
      ),
      body: Consumer<ItemProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.error != null) {
            return Center(
              child: Text(
                'Error loading items:\n${provider.error}',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.red),
              ),
            );
          }

          if (provider.items.isEmpty) {
            return const Center(
              child: Text(
                'No items listed yet.\nTap + to add the first item.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            );
          }

          return _buildTable(context, provider.items);
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const AddItemScreen()),
        ),
        tooltip: 'Add item',
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildTable(BuildContext context, List<Item> items) {
    return SingleChildScrollView(
      scrollDirection: Axis.vertical,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          headingRowColor: WidgetStateProperty.all(
            Theme.of(context).colorScheme.primaryContainer,
          ),
          columnSpacing: 24,
          columns: const [
            DataColumn(label: Text('#', style: TextStyle(fontWeight: FontWeight.bold))),
            DataColumn(label: Text('Title', style: TextStyle(fontWeight: FontWeight.bold))),
            DataColumn(
              label: Text('Price', style: TextStyle(fontWeight: FontWeight.bold)),
              numeric: true,
            ),
            DataColumn(label: Text('Listing Date', style: TextStyle(fontWeight: FontWeight.bold))),
          ],
          rows: List.generate(items.length, (index) {
            final item = items[index];
            return DataRow(
              cells: [
                DataCell(Text('${index + 1}')),
                DataCell(_buildTitleLink(context, item)),
                DataCell(Text(_priceFormat.format(item.price))),
                DataCell(Text(_dateFormat.format(item.listingDate))),
              ],
            );
          }),
        ),
      ),
    );
  }

  Widget _buildTitleLink(BuildContext context, Item item) {
    return GestureDetector(
      onTap: () => _openDetail(context, item),
      child: Text(
        item.title?.isEmpty ?? true ? '(No title)' : item.title!,
        style: TextStyle(
          color: Theme.of(context).colorScheme.primary,
          decoration: TextDecoration.underline,
        ),
        overflow: TextOverflow.ellipsis,
        maxLines: 2,
      ),
    );
  }

  void _openDetail(BuildContext context, Item item) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => DetailScreen(item: item)),
    );
  }

  Future<void> _syncNow() async {
    final provider = context.read<ItemProvider>();
    try {
      await provider.syncNow();
      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            content: Text('Sync completed'),
            behavior: SnackBarBehavior.floating,
          ),
        );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            content: Text('Sync failed. Please try again.'),
            behavior: SnackBarBehavior.floating,
          ),
        );
    }
  }
}
