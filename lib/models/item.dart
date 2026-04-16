import 'dart:convert';

/// Represents a single item listed for sale in the Showshop app.
class Item {
  final String? id;
  final String? title;
  final String description;
  final double price;
  final double? originalPrice;
  final String? brand;
  final String? knownIssues;
  final List<String> imageUrls;
  final DateTime listingDate;
  final String? condition;
  final String? sellerName;
  final String? sellerContact;
  final String? notes;
  final bool isSynced;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const Item({
    this.id,
    this.title,
    required this.description,
    required this.price,
    this.originalPrice,
    this.brand,
    this.knownIssues,
    this.imageUrls = const [],
    required this.listingDate,
    this.condition,
    this.sellerName,
    this.sellerContact,
    this.notes,
    this.isSynced = false,
    this.createdAt,
    this.updatedAt,
  });

  /// Creates an [Item] from a SQLite row map.
  factory Item.fromMap(Map<String, dynamic> map) {
    // Support both old single image_url and new image_urls JSON array.
    List<String> imageUrls = [];
    if (map['image_urls'] != null) {
      final raw = map['image_urls'] as String;
      if (raw.isNotEmpty) {
        try {
          imageUrls = List<String>.from(jsonDecode(raw) as List);
        } catch (_) {
          imageUrls = [];
        }
      }
    } else if (map['image_url'] != null) {
      final url = map['image_url'] as String;
      if (url.isNotEmpty) imageUrls = [url];
    }

    return Item(
      id: map['id'] as String?,
      title: map['title'] as String?,
      description: map['description'] as String,
      price: (map['price'] as num).toDouble(),
      originalPrice: map['original_price'] != null
          ? (map['original_price'] as num).toDouble()
          : null,
      brand: map['brand'] as String?,
      knownIssues: map['known_issues'] as String?,
      imageUrls: imageUrls,
      listingDate: DateTime.parse(map['listing_date'] as String),
      condition: map['condition'] as String?,
      sellerName: map['seller_name'] as String?,
      sellerContact: map['seller_contact'] as String?,
      notes: map['notes'] as String?,
      isSynced: (map['is_synced'] as int? ?? 0) == 1,
      createdAt: map['created_at'] != null
          ? DateTime.tryParse(map['created_at'] as String)
          : null,
      updatedAt: map['updated_at'] != null
          ? DateTime.tryParse(map['updated_at'] as String)
          : null,
    );
  }

  /// Converts this [Item] to a SQLite row map.
  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      if (title != null) 'title': title,
      'description': description,
      'price': price,
      'original_price': originalPrice,
      'brand': brand,
      'known_issues': knownIssues,
      'image_urls': jsonEncode(imageUrls),
      'listing_date': listingDate.toIso8601String(),
      'condition': condition,
      'seller_name': sellerName,
      'seller_contact': sellerContact,
      'notes': notes,
      'is_synced': isSynced ? 1 : 0,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  /// Creates an [Item] from a Supabase JSON response.
  factory Item.fromJson(Map<String, dynamic> json) {
    final imageUrls = <String>[];
    if (json['item_images'] != null) {
      for (final img in json['item_images'] as List) {
        final url = img['image_url'] as String?;
        if (url != null && url.isNotEmpty) imageUrls.add(url);
      }
    }

    return Item(
      id: json['id'] as String?,
      title: json['title'] as String?,
      description: json['description'] as String? ?? '',
      price: json['price'] != null ? (json['price'] as num).toDouble() : 0.0,
      originalPrice: json['original_price'] != null
          ? (json['original_price'] as num).toDouble()
          : null,
      brand: json['brand'] as String?,
      knownIssues: json['known_issues'] as String?,
      imageUrls: imageUrls,
      listingDate: _parseDateFromJson(json),
      condition: json['condition'] as String?,
      sellerName: json['seller_name'] as String?,
      sellerContact: json['seller_contact'] as String?,
      notes: json['notes'] as String?,
      isSynced: true,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'] as String)
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'] as String)
          : null,
    );
  }

  /// Extracts [listingDate] from a Supabase JSON row, falling back to
  /// [created_at] and then [DateTime.now] when neither field is present.
  static DateTime _parseDateFromJson(Map<String, dynamic> json) {
    if (json['listing_date'] != null) {
      return DateTime.parse(json['listing_date'] as String);
    }
    if (json['created_at'] != null) {
      return DateTime.parse(json['created_at'] as String);
    }
    return DateTime.now();
  }

  /// Converts this [Item] to a JSON map for Supabase upload.
  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      if (title != null) 'title': title,
      'description': description,
      'price': price,
      if (originalPrice != null) 'original_price': originalPrice,
      if (brand != null) 'brand': brand,
      if (knownIssues != null) 'known_issues': knownIssues,
      if (condition != null) 'condition': condition,
      if (sellerName != null) 'seller_name': sellerName,
      if (sellerContact != null) 'seller_contact': sellerContact,
      if (notes != null) 'notes': notes,
      'listing_date': listingDate.toIso8601String(),
    };
  }

  Item copyWith({
    String? id,
    String? title,
    String? description,
    double? price,
    double? originalPrice,
    String? brand,
    String? knownIssues,
    List<String>? imageUrls,
    DateTime? listingDate,
    String? condition,
    String? sellerName,
    String? sellerContact,
    String? notes,
    bool? isSynced,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Item(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      price: price ?? this.price,
      originalPrice: originalPrice ?? this.originalPrice,
      brand: brand ?? this.brand,
      knownIssues: knownIssues ?? this.knownIssues,
      imageUrls: imageUrls ?? this.imageUrls,
      listingDate: listingDate ?? this.listingDate,
      condition: condition ?? this.condition,
      sellerName: sellerName ?? this.sellerName,
      sellerContact: sellerContact ?? this.sellerContact,
      notes: notes ?? this.notes,
      isSynced: isSynced ?? this.isSynced,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() =>
      'Item(id: $id, description: $description, price: $price, listingDate: $listingDate)';
}
