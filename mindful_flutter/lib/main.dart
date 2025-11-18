import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:mindful/database/app_database.dart';
import 'package:mindful/services/google_calendar_service.dart';
import 'package:mindful/services/focus_mode_manager.dart';
import 'package:mindful/services/android_service.dart';
import 'package:mindful/services/notification_service.dart';
import 'package:mindful/services/usage_stats_service.dart';
import 'package:mindful/ui/navigation/router.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize services
  final db = AppDatabase();
  final androidService = AndroidService();
  final calendarService = GoogleCalendarService(db);
  final notificationService = NotificationService();
  final usageStatsService = UsageStatsService(db, androidService);

  // Initialize calendar service
  await calendarService.initialize();
  
  // Request necessary permissions
  await _requestPermissions();

  runApp(
    MyApp(
      db: db,
      androidService: androidService,
      calendarService: calendarService,
      notificationService: notificationService,
      usageStatsService: usageStatsService,
    ),
  );
}

Future<void> _requestPermissions() async {
  // Permissions are requested by Flutter plugins automatically
  // google_sign_in: Handles OAuth permissions
  // flutter_local_notifications: Handles notification permissions
  // Additional Android permissions defined in AndroidManifest.xml
  
  // Note: Users will be prompted for permissions when features are first used
  // This follows Android best practices for runtime permissions
}

class MyApp extends StatelessWidget {
  final AppDatabase db;
  final AndroidService androidService;
  final GoogleCalendarService calendarService;
  final NotificationService notificationService;
  final UsageStatsService usageStatsService;

  const MyApp({
    required this.db,
    required this.androidService,
    required this.calendarService,
    required this.notificationService,
    required this.usageStatsService,
  });

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // Database
        Provider<AppDatabase>.value(value: db),
        
        // Services
        Provider<AndroidService>.value(value: androidService),
        Provider<GoogleCalendarService>.value(value: calendarService),
        Provider<NotificationService>.value(value: notificationService),
        Provider<UsageStatsService>.value(value: usageStatsService),
        
        // Focus Mode Manager (ChangeNotifier for reactive updates)
        ChangeNotifierProvider(
          create: (_) => FocusModeManager(
            db,
            androidService,
            calendarService,
          ),
        ),
      ],
      child: MaterialApp.router(
        title: 'Neubofy Productive',
        theme: _buildLightTheme(),
        darkTheme: _buildDarkTheme(),
        themeMode: ThemeMode.system,
        routerConfig: appRouter,
        debugShowCheckedModeBanner: false,
      ),
    );
  }

  ThemeData _buildLightTheme() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorSchemeSeed: Colors.blue,
      fontFamily: 'Roboto',
      appBarTheme: const AppBarTheme(
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
      cardTheme: CardTheme(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  ThemeData _buildDarkTheme() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorSchemeSeed: Colors.blue,
      fontFamily: 'Roboto',
      appBarTheme: AppBarTheme(
        elevation: 0,
        backgroundColor: Colors.grey[900],
        foregroundColor: Colors.white,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
      cardTheme: CardTheme(
        elevation: 2,
        color: Colors.grey[850],
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }
}

// Router configuration
final appRouter = GoRouter(
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const HomeScreen(),
      routes: [
        GoRoute(
          path: 'focus',
          builder: (context, state) => const FocusModeScreen(),
        ),
        GoRoute(
          path: 'calendar',
          builder: (context, state) => const CalendarIntegrationScreen(),
        ),
        GoRoute(
          path: 'limits',
          builder: (context, state) => const AppLimitsScreen(),
        ),
        GoRoute(
          path: 'analytics',
          builder: (context, state) => const AnalyticsScreen(),
        ),
        GoRoute(
          path: 'settings',
          builder: (context, state) => const SettingsScreen(),
        ),
      ],
    ),
  ],
);

// Home Screen placeholder
class HomeScreen extends StatelessWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Neubofy Productive'),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Focus Mode Card
              _buildMenuCard(
                context,
                icon: Icons.timer,
                title: 'Focus Mode',
                description: 'Start a focused work session',
                onTap: () => context.go('/focus'),
              ),
              const SizedBox(height: 12),
              
              // Calendar Integration Card
              _buildMenuCard(
                context,
                icon: Icons.calendar_today,
                title: 'Calendar Integration',
                description: 'Connect Google Calendar for auto-focus',
                onTap: () => context.go('/calendar'),
              ),
              const SizedBox(height: 12),
              
              // App Limits Card
              _buildMenuCard(
                context,
                icon: Icons.apps,
                title: 'App Limits',
                description: 'Manage daily app usage limits',
                onTap: () => context.go('/limits'),
              ),
              const SizedBox(height: 12),
              
              // Analytics Card
              _buildMenuCard(
                context,
                icon: Icons.analytics,
                title: 'Analytics',
                description: 'View your usage insights',
                onTap: () => context.go('/analytics'),
              ),
              const SizedBox(height: 12),
              
              // Settings Card
              _buildMenuCard(
                context,
                icon: Icons.settings,
                title: 'Settings',
                description: 'Customize your experience',
                onTap: () => context.go('/settings'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMenuCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String description,
    required VoidCallback onTap,
  }) {
    return Card(
      child: ListTile(
        leading: Icon(icon, size: 32, color: Colors.blue),
        title: Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Text(description),
        trailing: const Icon(Icons.arrow_forward),
        onTap: onTap,
      ),
    );
  }
}

// Placeholder screens - to be implemented
class FocusModeScreen extends StatelessWidget {
  const FocusModeScreen({Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context) => const Placeholder();
}

class CalendarIntegrationScreen extends StatelessWidget {
  const CalendarIntegrationScreen({Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context) => const Placeholder();
}

class AppLimitsScreen extends StatelessWidget {
  const AppLimitsScreen({Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context) => const Placeholder();
}

class AnalyticsScreen extends StatelessWidget {
  const AnalyticsScreen({Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context) => const Placeholder();
}

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context) => const Placeholder();
}
