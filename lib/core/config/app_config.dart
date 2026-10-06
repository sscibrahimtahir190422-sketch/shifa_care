class AppConfig {
  AppConfig._();

  static const appName = 'Shifa Care';
  static const tagline = 'Healthcare with compassion for all';

  static const supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://gkblifbimuhowmdzfrhz.supabase.co',
  );

  static const supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImdrYmxpZmJpbXVob3dtZHpmcmh6Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3OTAzMzE3MDgsImV4cCI6MjEwNTkwNzcwOH0.lqw4g-7zZctLU5OajRrgURkM3elBQrnl-UzX1KKq4m8',
  );
}