/// Represents a single item listed for sale in the Showshop app.
class Item {
  final int? id;
  final String description;
  final double price;
  final DateTime listingDate;
  final String? imageUrl;
  final String? condition;
  final String? sellerName;
  final String? sellerContact;
  final String? notes;
  final bool isSynced;

  const Item({
    this.id,
    required this.description,
    required this.price,
    required this.listingDate,
    this.imageUrl,
    this.condition,
    this.sellerName,
    this.sellerContact,
    this.notes,
    this.isSynced = false,
  });

  /// Creates an [Item] from a SQLite row map.
  factory Item.fromMap(Map<String, dynamic> map) {
    return Item(
      id: map['id'] as int?,
      description: map['description'] as String,
      price: (map['price'] as num).toDouble(),
      listingDate: DateTime.parse(map['listing_date'] as String),
      imageUrl: map['image_url'] as String?,
      condition: map['condition'] as String?,
      sellerName: map['seller_name'] as String?,
      sellerContact: map['seller_contact'] as String?,
      notes: map['notes'] as String?,
      isSynced: (map['is_synced'] as int? ?? 0) == 1,
    );
  }

  /// Converts this [Item] to a SQLite row map.
  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'description': description,
      'price': price,
      'listing_date': listingDate.toIso8601String(),
      'image_url': imageUrl,
      'condition': condition,
      'seller_name': sellerName,
      'seller_contact': sellerContact,
      'notes': notes,
      'is_synced': isSynced ? 1 : 0,
    };
  }

  Item copyWith({
    int? id,
    String? description,
    double? price,
    DateTime? listingDate,
    String? imageUrl,
    String? condition,
    String? sellerName,
    String? sellerContact,
    String? notes,
    bool? isSynced,
  }) {
    return Item(
      id: id ?? this.id,
      description: description ?? this.description,
      price: price ?? this.price,
      listingDate: listingDate ?? this.listingDate,
      imageUrl: imageUrl ?? this.imageUrl,
      condition: condition ?? this.condition,
      sellerName: sellerName ?? this.sellerName,
      sellerContact: sellerContact ?? this.sellerContact,
      notes: notes ?? this.notes,
      isSynced: isSynced ?? this.isSynced,
    );
  }

  @override
  String toString() =>
      'Item(id: $id, description: $description, price: $price, listingDate: $listingDate)';
}
