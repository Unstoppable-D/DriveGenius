import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'constants/app_constants.dart';
import 'constants/app_theme.dart';
import 'providers/auth_provider.dart';
import 'providers/theme_provider.dart';
import 'screens/welcome_screen.dart';
import 'screens/login_screen.dart';
import 'screens/signup_screen.dart';
import 'screens/role_selection_screen.dart';
import 'screens/home_screen.dart';
import 'screens/verification_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/placeholder_screens.dart' as placeholder;
import 'screens/booking_request_screen.dart';
import 'screens/job_requests_screen.dart';
import 'screens/client_trip_requests_screen.dart';
import 'screens/active_jobs_screen.dart';
import 'screens/notifications_screen.dart';
import 'screens/find_drivers_screen.dart';
import 'screens/chat_inbox_screen.dart';
import 'screens/chat_room_screen.dart';
import 'services/appwrite_service.dart';
import 'services/push_notifications.dart';
import 'constants/appwrite_constants.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Setup push notifications (prevents Firebase crashes)
  await setupPushNotifications();
  
  // Initialize Appwrite
  final appwriteService = AppwriteService();
  appwriteService.initialize();
  print('✅ Appwrite initialized successfully');
  
  // Debug: Check collection IDs
  print('🔍 Collection IDs:');
  print('   Database: ${AppwriteIds.databaseId}');
  print('   Job Requests: ${AppwriteIds.jobRequestsCollectionId}');
  print('   Notifications: ${AppwriteIds.notificationsCollectionId}');
  
  // Force clear all authentication data and sessions for fresh start
  try {
    // Clear secure storage
    final secureStorage = FlutterSecureStorage();
    await secureStorage.deleteAll();
    print('✅ Cleared stored authentication data');
    
    // Clear all Appwrite sessions
    await appwriteService.deleteAllSessions();
    print('✅ Cleared all Appwrite sessions');
  } catch (e) {
    print('⚠️ Error clearing auth data: $e');
  }
  
  runApp(DriveGeniusApp(appwriteService: appwriteService));
}

class DriveGeniusApp extends StatelessWidget {
  final AppwriteService appwriteService;
  
  const DriveGeniusApp({super.key, required this.appwriteService});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<AppwriteService>.value(value: appwriteService),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => AuthProvider(appwriteService: appwriteService)),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) {
          return MaterialApp(
            title: AppStrings.appName,
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: themeProvider.themeMode,
            
            // Always start at Welcome screen
            initialRoute: AppRoutes.welcome,
            
            routes: {
              AppRoutes.welcome: (context) => const WelcomeScreen(),
              AppRoutes.login: (context) => const LoginScreen(),
              AppRoutes.roleSelection: (context) => const RoleSelectionScreen(),
              AppRoutes.verification: (context) => const VerificationScreen(),
              AppRoutes.profile: (context) => const ProfileScreen(),
              AppRoutes.driverListing: (context) => const placeholder.DriverListingScreen(),
              AppRoutes.bookingRequest: (context) => const BookingRequestScreen(),
              AppRoutes.earnings: (context) => const placeholder.EarningsScreen(),
              AppRoutes.subscriptions: (context) => const placeholder.SubscriptionsScreen(),
              AppRoutes.messages: (context) => const placeholder.MessagesScreen(),
              AppRoutes.emergency: (context) => const placeholder.EmergencyScreen(),
              AppRoutes.jobRequests: (context) => const JobRequestsScreen(),
              AppRoutes.clientTrips: (context) => const ClientTripRequestsScreen(),
              AppRoutes.activeJobs: (context) => const ActiveJobsScreen(),
              AppRoutes.notifications: (context) => const NotificationsScreen(),
              AppRoutes.findDrivers: (context) => const FindDriversScreen(),
              AppRoutes.chatInbox: (context) => const ChatInboxScreen(),
              AppRoutes.chatRoom: (context) => const ChatRoomScreen(),
            },
            
            // Guard Home route: only allow when authenticated
            onGenerateRoute: (settings) {
              if (settings.name == AppRoutes.home) {
                return MaterialPageRoute(
                  settings: settings,
                  builder: (context) {
                    final auth = Provider.of<AuthProvider>(context, listen: false);
                    final isAuthed = auth.isAuthenticated;
                    if (!isAuthed) {
                      // Not logged in: redirect to Welcome
                      return const WelcomeScreen();
                    }
                    return const HomeScreen();
                  },
                );
              }
              return null; // fallback to routes map
            },
            
            // Safety net so unknown routes don't crash
            onUnknownRoute: (_) => MaterialPageRoute(
              builder: (_) => const WelcomeScreen(),
            ),
          );
        },
      ),
    );
  }
}
