/// Supabase backend configuration for the Showshop app.
class SupabaseConfig {
  SupabaseConfig._();

  static const String supabaseUrl =
      'https://rdyszutpwabhqimvltvq.supabase.co';

  static const String supabaseAnonKey =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9'
      '.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InJkeXN6dXRwd2FiaHFpbXZsdHZxIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzYyMzY1NDcsImV4cCI6MjA5MTgxMjU0N30'
      '.fz6BzW_pR9dLGqrGJXyZ7B-iBXOc0Y5Q-KQSfSS8kWM';

  /// Supabase Storage bucket that holds item images.
  static const String imageBucket = 'item-images';
}
