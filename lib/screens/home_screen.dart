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

  @override
  void initState() {
    super.initState();
    // Load items after the first frame so the widget tree is ready.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ItemProvider>().loadItems();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Showshop – Items for Sale'),
        centerTitle: false,
        elevation: 2,
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
            DataColumn(label: Text('Description', style: TextStyle(fontWeight: FontWeight.bold))),
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
                DataCell(_buildDescriptionLink(context, item)),
                DataCell(Text(_priceFormat.format(item.price))),
                DataCell(Text(_dateFormat.format(item.listingDate))),
              ],
            );
          }),
        ),
      ),
    );
  }

  Widget _buildDescriptionLink(BuildContext context, Item item) {
    return GestureDetector(
      onTap: () => _openDetail(context, item),
      child: Text(
        item.description,
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
}
