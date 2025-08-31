import 'package:flutter/material.dart';

class AppColors {
  // Primary Colors
  static const Color primary = Color(0xFF2563EB);
  static const Color primaryDark = Color(0xFF1D4ED8);
  static const Color primaryLight = Color(0xFF3B82F6);
  
  // Secondary Colors
  static const Color secondary = Color(0xFF10B981);
  static const Color secondaryDark = Color(0xFF059669);
  static const Color secondaryLight = Color(0xFF34D399);
  
  // Accent Colors
  static const Color accent = Color(0xFFF59E0B);
  static const Color accentDark = Color(0xFFD97706);
  static const Color accentLight = Color(0xFFFBBF24);
  
  // Neutral Colors
  static const Color background = Color(0xFFF8FAFC);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color card = Color(0xFFFFFFFF);
  
  // Text Colors
  static const Color textPrimary = Color(0xFF1E293B);
  static const Color textSecondary = Color(0xFF64748B);
  static const Color textTertiary = Color(0xFF94A3B8);
  
  // Status Colors
  static const Color success = Color(0xFF10B981);
  static const Color warning = Color(0xFFF59E0B);
  static const Color error = Color(0xFFEF4444);
  static const Color info = Color(0xFF3B82F6);
  
  // Emergency Colors
  static const Color emergency = Color(0xFFDC2626);
  static const Color emergencyLight = Color(0xFFFEE2E2);
  
  // Border Colors
  static const Color border = Color(0xFFE2E8F0);
  static const Color borderLight = Color(0xFFF1F5F9);
  
  // Shadow Colors
  static const Color shadow = Color(0x1A000000);
  static const Color shadowLight = Color(0x0A000000);
}

class AppTextStyles {
  // Headings
  static const TextStyle h1 = TextStyle(
    fontSize: 32,
    fontWeight: FontWeight.bold,
    color: AppColors.textPrimary,
  );
  
  static const TextStyle h2 = TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.bold,
    color: AppColors.textPrimary,
  );
  
  static const TextStyle h3 = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
  );
  
  static const TextStyle h4 = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
  );
  
  static const TextStyle h5 = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
  );
  
  static const TextStyle h6 = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
  );
  
  // Body Text
  static const TextStyle bodyLarge = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.normal,
    color: AppColors.textPrimary,
  );
  
  static const TextStyle bodyMedium = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.normal,
    color: AppColors.textPrimary,
  );
  
  static const TextStyle bodySmall = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.normal,
    color: AppColors.textSecondary,
  );
  
  // Button Text
  static const TextStyle buttonLarge = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: Colors.white,
  );
  
  static const TextStyle buttonMedium = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    color: Colors.white,
  );
  
  static const TextStyle buttonSmall = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w600,
    color: Colors.white,
  );
  
  // Caption
  static const TextStyle caption = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.normal,
    color: AppColors.textTertiary,
  );
  
  // Overline
  static const TextStyle overline = TextStyle(
    fontSize: 10,
    fontWeight: FontWeight.w500,
    color: AppColors.textSecondary,
    letterSpacing: 1.5,
  );
}

class AppSizes {
  // Padding & Margins
  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double md = 16.0;
  static const double lg = 24.0;
  static const double xl = 32.0;
  static const double xxl = 48.0;
  
  // Border Radius
  static const double radiusXs = 4.0;
  static const double radiusSm = 8.0;
  static const double radiusMd = 12.0;
  static const double radiusLg = 16.0;
  static const double radiusXl = 24.0;
  static const double radiusRound = 50.0;
  
  // Icon Sizes
  static const double iconXs = 16.0;
  static const double iconSm = 20.0;
  static const double iconMd = 24.0;
  static const double iconLg = 32.0;
  static const double iconXl = 48.0;
  
  // Button Heights
  static const double buttonHeightXxs = 22.0; // Ultra-small button height for very compact layouts
  static const double buttonHeightXs = 26.0; // Very small button height for compact layouts
  static const double buttonHeightSm = 36.0;
  static const double buttonHeightMd = 48.0;
  static const double buttonHeightLg = 56.0;
  
  // Input Heights
  static const double inputHeightSm = 40.0;
  static const double inputHeightMd = 48.0;
  static const double inputHeightLg = 56.0;
}

class AppStrings {
  // App Info
  static const String appName = 'DriveGenius';
  static const String appTagline = 'AI-Powered Driver-Client Platform';
  static const String appVersion = '1.0.0';
  
  // Authentication
  static const String login = 'Login';
  static const String signup = 'Sign Up';
  static const String email = 'Email';
  static const String password = 'Password';
  static const String confirmPassword = 'Confirm Password';
  static const String forgotPassword = 'Forgot Password?';
  static const String orContinueWith = 'Or continue with';
  
  // Roles
  static const String client = 'Client';
  static const String driver = 'Driver';
  static const String selectRole = 'Select Your Role';
  static const String clientDescription = 'Book professional drivers for your trips';
  static const String driverDescription = 'Earn money by providing driving services';
  
  // Common
  static const String next = 'Next';
  static const String back = 'Back';
  static const String cancel = 'Cancel';
  static const String save = 'Save';
  static const String edit = 'Edit';
  static const String delete = 'Delete';
  static const String confirm = 'Confirm';
  static const String loading = 'Loading...';
  static const String error = 'Error';
  static const String success = 'Success';
  static const String warning = 'Warning';
  static const String info = 'Information';
  
  // Navigation
  static const String home = 'Home';
  static const String profile = 'Profile';
  static const String settings = 'Settings';
  static const String notifications = 'Notifications';
  static const String help = 'Help';
  static const String about = 'About';
  
  // Emergency
  static const String emergency = 'Emergency';
  static const String panicButton = 'Panic Button';
  static const String sos = 'SOS';
  static const String emergencyContacts = 'Emergency Contacts';
  
  // Booking
  static const String bookNow = 'Book Now';
  static const String createBooking = 'Create Booking';
  static const String tripDetails = 'Trip Details';
  static const String payment = 'Payment';
  static const String confirmBooking = 'Confirm Booking';
}



class AppRoutes {
  // Authentication
  static const String splash = '/';
  static const String welcome = '/welcome';
  static const String roleSelection = '/role-selection';
  static const String login = '/login';
  static const String signup = '/signup';
  static const String verification = '/verification';
  
  // Home Route
  static const String home = '/home';
  
  // Client Routes
  static const String clientDashboard = '/client/dashboard';
  static const String driverSearch = '/client/driver-search';
  static const String driverProfile = '/client/driver-profile';
  static const String createBooking = '/client/create-booking';
  static const String bookingConfirmation = '/client/booking-confirmation';
  static const String chat = '/client/chat';
  static const String subscription = '/client/subscription';
  static const String emergency = '/client/emergency';
  static const String clientProfile = '/client/profile';
  static const String clientTrips = '/client/trips'; // NEW: My Trips screen
  
  // Driver Routes
  static const String driverDashboard = '/driver/dashboard';
  static const String jobRequests = '/driver/job-requests';
  static const String activeJobs = '/driver/active-jobs'; // NEW: Active Jobs screen
  static const String tripManagement = '/driver/trip-management';
  static const String driverProfileEdit = '/driver/profile-edit';
  static const String earnings = '/driver/earnings';
  static const String driverEmergency = '/driver/emergency';
  
  // Common Routes
  static const String profile = '/profile';
  static const String settings = '/settings';
  static const String notifications = '/notifications';
  static const String findDrivers = '/find-drivers';
  static const String chatInbox = '/chat-inbox';
  static const String chatRoom = '/chat';
  static const String help = '/help';
  static const String about = '/about';
  
  // Placeholder Routes
  static const String driverListing = '/driver-listing';
  static const String bookingRequest = '/booking-request';
  static const String subscriptions = '/subscriptions';
  static const String messages = '/messages';
}
