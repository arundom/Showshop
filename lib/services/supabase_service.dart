import 'dart:io';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../config/supabase_config.dart';
import '../models/item.dart';

/// Handles all remote operations with the Supabase backend.
///
/// Tables used:
/// - `items`       — core item data
/// - `item_images` — image URLs linked to an item (one-to-many)
///
/// Storage bucket: [SupabaseConfig.imageBucket]
class SupabaseService {
  SupabaseService({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  // ── Items ──────────────────────────────────────────────────────────────────

  /// Fetches all items joined with their images, ordered newest first.
  Future<List<Item>> getItems() async {
    final response = await _client
        .from('items')
        .select('*, item_images(image_url, display_order)')
        .order('listing_date', ascending: false);

    return (response as List)
        .map((row) => Item.fromJson(row as Map<String, dynamic>))
        .toList();
  }

  /// Fetches a single item by [id], including its images.
  Future<Item?> getItemById(String id) async {
    final response = await _client
        .from('items')
        .select('*, item_images(image_url, display_order)')
        .eq('id', id)
        .maybeSingle();

    if (response == null) return null;
    return Item.fromJson(response);
  }

  /// Creates a new item in Supabase and returns its assigned UUID.
  Future<String> createItem(Item item) async {
    final response = await _client
        .from('items')
        .insert(item.toJson())
        .select('id')
        .single();

    return response['id'] as String;
  }

  /// Updates an existing item identified by [id].
  Future<void> updateItem(String id, Item item) async {
    final data = item.toJson()..remove('id');
    await _client.from('items').update(data).eq('id', id);
  }

  /// Deletes the item with [id] and cascades to its images.
  Future<void> deleteItem(String id) async {
    await _client.from('items').delete().eq('id', id);
  }

  // ── Item Images ────────────────────────────────────────────────────────────

  /// Uploads [imageFile] to Storage under [itemId] and returns the public URL.
  Future<String> uploadImage(File imageFile, String itemId) async {
    final fileName =
        '$itemId/${DateTime.now().millisecondsSinceEpoch}_${imageFile.path.split('/').last}';

    await _client.storage
        .from(SupabaseConfig.imageBucket)
        .upload(fileName, imageFile);

    try {
      // Prefer a long-lived signed URL so private buckets still render images.
      return await _client.storage
          .from(SupabaseConfig.imageBucket)
          .createSignedUrl(fileName, 60 * 60 * 24 * 365);
    } catch (_) {
      // Fallback for public buckets or projects without signed-url permissions.
      return _client.storage
          .from(SupabaseConfig.imageBucket)
          .getPublicUrl(fileName);
    }
  }

  /// Inserts a record into `item_images` linking [imageUrl] to [itemId].
  Future<void> addItemImage(
    String itemId,
    String imageUrl,
    int displayOrder,
  ) async {
    await _client.from('item_images').insert({
      'item_id': itemId,
      'image_url': imageUrl,
      'display_order': displayOrder,
    });
  }

  /// Replaces all image rows for [itemId] with [imageUrls] in display order.
  Future<void> replaceItemImages(String itemId, List<String> imageUrls) async {
    await _client.from('item_images').delete().eq('item_id', itemId);
    if (imageUrls.isEmpty) return;

    await _client.from('item_images').insert(
      List.generate(
        imageUrls.length,
        (index) => {
          'item_id': itemId,
          'image_url': imageUrls[index],
          'display_order': index,
        },
      ),
    );
  }

  /// Removes an image file from Storage given its full public [imageUrl].
  Future<void> deleteImage(String imageUrl) async {
    // Extract the storage path after the bucket prefix.
    final bucketPrefix =
        '/storage/v1/object/public/${SupabaseConfig.imageBucket}/';
    final index = imageUrl.indexOf(bucketPrefix);
    if (index == -1) return;
    final path = imageUrl.substring(index + bucketPrefix.length);
    await _client.storage.from(SupabaseConfig.imageBucket).remove([path]);
  }
}
