# Showshop

A Flutter app for a used-goods resale business.  Items are listed on the home screen in a sortable table (newest first) and each entry links through to a full detail view.

---

## Features

| Feature | Details |
|---------|---------|
| 📋 Item listing | Scrollable table with **#**, **Description** (tappable link), **Price**, **Listing Date** |
| 🗃 Newest first | Items are always sorted by listing date descending |
| 🔗 Detail page | Shows description, price, condition, seller info, notes, and sync status |
| ➕ Add item | Form to enter description, price, date, condition, seller details, notes |
| 💾 Offline storage | SQLite via `sqflite` — works without internet |
| ☁️ Sync-ready | `SyncService` detects connectivity and pushes unsynced rows to your backend |

---

## Project Structure

```
lib/
├── main.dart                   # App entry point & theme
├── models/
│   └── item.dart               # Item data model (toMap / fromMap for SQLite)
├── providers/
│   └── item_provider.dart      # ChangeNotifier — state management
├── screens/
│   ├── home_screen.dart        # Table listing (home page)
│   ├── detail_screen.dart      # Item detail page
│   └── add_item_screen.dart    # Add-item form
└── services/
    ├── database_service.dart   # SQLite CRUD + unsynced query
    └── sync_service.dart       # Offline → online sync orchestrator
```

---

## Getting Started

### Prerequisites

* Flutter SDK ≥ 3.0 — <https://docs.flutter.dev/get-started/install>
* Android Studio **or** VS Code with the Flutter extension

### Run

```bash
git clone https://github.com/arundom/Showshop.git
cd Showshop
flutter pub get
flutter run
```

### Test

```bash
flutter test
```

---

## Data Storage Strategy

### Local (offline-first)

All writes go to a local **SQLite** database (`sqflite`) first.  The app is fully functional without internet.

| Table | Columns |
|-------|---------|
| `items` | `id`, `description`, `price`, `listing_date`, `image_url`, `condition`, `seller_name`, `seller_contact`, `notes`, `is_synced` |

The `is_synced` flag (`0` / `1`) marks whether a row has been pushed to the remote backend.

### Remote backend options

| Option | Best for | Setup |
|--------|----------|-------|
| **Firebase Firestore** | Rapid prototyping, real-time updates | Add `firebase_core` + `cloud_firestore` packages; initialise in `main()` |
| **Supabase** | SQL-familiar teams, open-source | Add `supabase_flutter` package; use the generated REST client |
| **Custom REST API** | Full control (Node.js / Django / Go) | Add `http` or `dio`; implement `_pushItemToRemote` in `SyncService` |

### How offline sync works

```
Write item → SQLite (is_synced = 0)
    ↓
App detects network restored  ← SyncService listens via connectivity_plus
    ↓
SyncService.syncPendingItems()
  └─ for each row where is_synced = 0
       push to remote backend
       on success → set is_synced = 1
```

#### Connecting a real backend

Open `lib/services/sync_service.dart` and replace `_pushItemToRemote` with your actual call:

```dart
// Firebase Firestore example
Future<bool> _pushItemToRemote(Item item) async {
  await FirebaseFirestore.instance
      .collection('items')
      .doc(item.id.toString())
      .set(item.toMap());
  return true;
}
```

```dart
// REST API example
Future<bool> _pushItemToRemote(Item item) async {
  final response = await http.post(
    Uri.parse('https://your-api.example.com/items'),
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode(item.toMap()),
  );
  return response.statusCode == 201;
}
```

---

## Roadmap

- [ ] Image upload (camera / gallery)
- [ ] Search and filter
- [ ] Edit / delete items
- [ ] Firebase authentication
- [ ] Push notifications when items are sold
