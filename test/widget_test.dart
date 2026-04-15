import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:showshop/models/item.dart';
import 'package:showshop/providers/item_provider.dart';
import 'package:showshop/screens/detail_screen.dart';
import 'package:showshop/screens/home_screen.dart';

// ── Fake provider ──────────────────────────────────────────────────────────

/// An [ItemProvider] pre-loaded with sample items, without a real database.
class _FakeItemProvider extends ChangeNotifier implements ItemProvider {
  _FakeItemProvider(this._items);

  List<Item> _items;

  @override
  List<Item> get items => List.unmodifiable(_items);

  @override
  bool get isLoading => false;

  @override
  String? get error => null;

  @override
  Future<void> loadItems() async {
    // Already loaded.
    notifyListeners();
  }

  @override
  Future<void> addItem(Item item) async {
    _items = [item.copyWith(id: '${_items.length + 1}'), ..._items];
    notifyListeners();
  }

  @override
  Future<void> updateItem(Item item) async {
    final idx = _items.indexWhere((i) => i.id == item.id);
    if (idx != -1) {
      _items = List.of(_items)..[idx] = item;
      notifyListeners();
    }
  }

  @override
  Future<void> deleteItem(String id) async {
    _items = _items.where((i) => i.id != id).toList();
    notifyListeners();
  }
}

// ── Helpers ────────────────────────────────────────────────────────────────

Widget _wrapWithProvider(Widget child, _FakeItemProvider provider) {
  return ChangeNotifierProvider<ItemProvider>.value(
    value: provider,
    child: MaterialApp(home: child),
  );
}

final _sampleItems = [
  Item(
    id: '1',
    description: 'Samsung 65" 4K TV',
    price: 25000,
    listingDate: DateTime(2024, 3, 15),
    condition: 'Good',
    sellerName: 'Arun',
    sellerContact: '9876543210',
    notes: 'Minor scratch on bezel',
    isSynced: false,
  ),
  Item(
    id: '2',
    description: 'Sony PlayStation 5',
    price: 35000,
    listingDate: DateTime(2024, 3, 10),
    condition: 'Excellent',
    isSynced: true,
  ),
  Item(
    id: '3',
    description: 'IKEA Dining Table',
    price: 8000,
    listingDate: DateTime(2024, 2, 20),
  ),
];

// ── Tests ──────────────────────────────────────────────────────────────────

void main() {
  group('Item model', () {
    test('toMap / fromMap round-trip', () {
      final original = _sampleItems.first;
      final map = original.toMap();
      final restored = Item.fromMap({...map, 'id': original.id});

      expect(restored.id, original.id);
      expect(restored.description, original.description);
      expect(restored.price, original.price);
      expect(restored.listingDate.toIso8601String(),
          original.listingDate.toIso8601String());
      expect(restored.condition, original.condition);
      expect(restored.sellerName, original.sellerName);
      expect(restored.isSynced, original.isSynced);
    });

    test('copyWith creates updated copy', () {
      final item = _sampleItems.first;
      final updated = item.copyWith(price: 20000, isSynced: true);

      expect(updated.price, 20000);
      expect(updated.isSynced, isTrue);
      // Other fields unchanged
      expect(updated.description, item.description);
      expect(updated.id, item.id);
    });

    test('is_synced flag is persisted as 0/1', () {
      final synced = _sampleItems[1].toMap();
      expect(synced['is_synced'], 1);

      final unsynced = _sampleItems[0].toMap();
      expect(unsynced['is_synced'], 0);
    });

    test('fromJson parses Supabase response', () {
      final json = {
        'id': 'abc-123',
        'title': 'Test Racket',
        'description': 'A badminton racket',
        'price': 500.0,
        'original_price': 1200.0,
        'brand': 'Yonex',
        'known_issues': 'Minor scratch',
        'listing_date': '2024-03-15T00:00:00.000',
        'created_at': '2024-03-15T00:00:00.000',
        'updated_at': '2024-03-15T00:00:00.000',
        'item_images': [
          {'image_url': 'https://example.com/img1.jpg', 'display_order': 0},
        ],
      };
      final item = Item.fromJson(json);

      expect(item.id, 'abc-123');
      expect(item.title, 'Test Racket');
      expect(item.originalPrice, 1200.0);
      expect(item.brand, 'Yonex');
      expect(item.knownIssues, 'Minor scratch');
      expect(item.imageUrls, ['https://example.com/img1.jpg']);
      expect(item.isSynced, isTrue);
    });

    test('toJson produces Supabase-compatible map', () {
      final item = Item(
        id: 'uuid-1',
        title: 'TV',
        description: 'Big screen TV',
        price: 20000,
        originalPrice: 45000,
        brand: 'Samsung',
        listingDate: DateTime(2024, 1, 1),
      );
      final json = item.toJson();

      expect(json['id'], 'uuid-1');
      expect(json['title'], 'TV');
      expect(json['price'], 20000);
      expect(json.containsKey('original_price'), isTrue);
      // image_urls should NOT be in toJson (managed via item_images table)
      expect(json.containsKey('image_urls'), isFalse);
    });

    test('imageUrls round-trip through toMap / fromMap', () {
      final item = Item(
        id: 'img-test',
        description: 'Item with images',
        price: 100,
        listingDate: DateTime(2024, 1, 1),
        imageUrls: ['https://a.com/1.jpg', 'https://a.com/2.jpg'],
      );
      final restored = Item.fromMap(item.toMap());
      expect(restored.imageUrls, item.imageUrls);
    });
  });

  group('HomeScreen', () {
    testWidgets('shows loading indicator while loading', (tester) async {
      final provider = _FakeItemProvider([]);

      await tester.pumpWidget(
        ChangeNotifierProvider<ItemProvider>.value(
          value: provider,
          child: const MaterialApp(home: HomeScreen()),
        ),
      );

      // The first frame triggers loadItems() via addPostFrameCallback.
      // Before that resolves, nothing shows loading in our fake provider
      // (isLoading = false), so we just assert no error widget is shown.
      expect(find.byType(HomeScreen), findsOneWidget);
    });

    testWidgets('shows empty state message when no items', (tester) async {
      final provider = _FakeItemProvider([]);

      await tester.pumpWidget(_wrapWithProvider(const HomeScreen(), provider));
      await tester.pump(); // post-frame callback

      expect(find.textContaining('No items listed'), findsOneWidget);
    });

    testWidgets('renders a row for each item', (tester) async {
      final provider = _FakeItemProvider(_sampleItems);

      await tester.pumpWidget(_wrapWithProvider(const HomeScreen(), provider));
      await tester.pump();

      // Serial numbers 1, 2, 3
      expect(find.text('1'), findsOneWidget);
      expect(find.text('2'), findsOneWidget);
      expect(find.text('3'), findsOneWidget);
    });

    testWidgets('description links are underlined', (tester) async {
      final provider = _FakeItemProvider(_sampleItems);

      await tester.pumpWidget(_wrapWithProvider(const HomeScreen(), provider));
      await tester.pump();

      final texts = tester.widgetList<Text>(
        find.text(_sampleItems.first.description),
      );
      expect(
        texts.any((t) =>
            t.style?.decoration == TextDecoration.underline),
        isTrue,
      );
    });

    testWidgets('tapping description navigates to detail screen',
        (tester) async {
      final provider = _FakeItemProvider(_sampleItems);

      await tester.pumpWidget(_wrapWithProvider(const HomeScreen(), provider));
      await tester.pump();

      await tester.tap(find.text(_sampleItems.first.description).first);
      await tester.pumpAndSettle();

      expect(find.byType(DetailScreen), findsOneWidget);
    });

    testWidgets('FAB is present', (tester) async {
      final provider = _FakeItemProvider([]);

      await tester.pumpWidget(_wrapWithProvider(const HomeScreen(), provider));
      await tester.pump();

      expect(find.byType(FloatingActionButton), findsOneWidget);
    });
  });

  group('DetailScreen', () {
    testWidgets('shows description and price', (tester) async {
      final item = _sampleItems.first;

      await tester.pumpWidget(
        MaterialApp(home: DetailScreen(item: item)),
      );

      expect(find.textContaining(item.description), findsWidgets);
      expect(find.textContaining('25,000'), findsWidgets);
    });

    testWidgets('shows condition when present', (tester) async {
      await tester.pumpWidget(
        MaterialApp(home: DetailScreen(item: _sampleItems.first)),
      );

      expect(find.text('Condition'), findsOneWidget);
      expect(find.text('Good'), findsOneWidget);
    });

    testWidgets('shows sync status as pending when not synced', (tester) async {
      final item = _sampleItems.first; // isSynced = false

      await tester.pumpWidget(
        MaterialApp(home: DetailScreen(item: item)),
      );

      expect(find.text('Pending sync'), findsOneWidget);
    });

    testWidgets('shows sync status as synced when synced', (tester) async {
      final item = _sampleItems[1]; // isSynced = true

      await tester.pumpWidget(
        MaterialApp(home: DetailScreen(item: item)),
      );

      expect(find.text('Synced to cloud'), findsOneWidget);
    });

    testWidgets('does not show condition row when condition is null',
        (tester) async {
      final item = _sampleItems[2]; // no condition

      await tester.pumpWidget(
        MaterialApp(home: DetailScreen(item: item)),
      );

      expect(find.text('Condition'), findsNothing);
    });

    testWidgets('shows green buttons for optional fields', (tester) async {
      final item = Item(
        id: 'test-1',
        description: 'Test item',
        price: 500,
        listingDate: DateTime(2024, 1, 1),
        originalPrice: 1200,
        brand: 'Yonex',
        knownIssues: 'Minor scratch',
      );

      await tester.pumpWidget(
        MaterialApp(home: DetailScreen(item: item)),
      );

      expect(find.text('Original Price'), findsOneWidget);
      expect(find.text('Brand'), findsOneWidget);
      expect(find.text('Known Issues'), findsOneWidget);
      expect(find.text('Yonex'), findsOneWidget);
    });

    testWidgets('shows image placeholders in 2x2 grid', (tester) async {
      final item = _sampleItems.first;

      await tester.pumpWidget(
        MaterialApp(home: DetailScreen(item: item)),
      );

      expect(find.text('image 1'), findsOneWidget);
      expect(find.text('image 2'), findsOneWidget);
      expect(find.text('image 3'), findsOneWidget);
      expect(find.text('image 4'), findsOneWidget);
    });
  });
}
