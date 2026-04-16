import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'config/supabase_config.dart';
import 'providers/item_provider.dart';
import 'screens/home_screen.dart';
import 'services/sync_service.dart';

/// The Supabase client — available globally after [main] initialises it.
SupabaseClient get supabase => Supabase.instance.client;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: SupabaseConfig.supabaseUrl,
    anonKey: SupabaseConfig.supabaseAnonKey,
  );

  // Start background sync listener.
  final syncService = SyncService();
  syncService.startListening();
  // Intentionally not awaited: sync runs in the background so startup is fast.
  // ignore: unawaited_futures
  syncService.syncOnStartup();

  runApp(
    ChangeNotifierProvider(
      create: (_) => ItemProvider(syncService: syncService),
      child: const ShowshopApp(),
    ),
  );
}

class ShowshopApp extends StatelessWidget {
  const ShowshopApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Showshop',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1565C0), // deep blue
        ),
        useMaterial3: true,
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF1565C0),
          foregroundColor: Colors.white,
        ),
      ),
      home: const HomeScreen(),
    );
  }
}
