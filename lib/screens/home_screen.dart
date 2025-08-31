import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../constants/app_constants.dart';
import '../constants/appwrite_constants.dart';
import '../models/user_model.dart';
import '../providers/auth_provider.dart';
import '../services/appwrite_service.dart';
import 'profile_screen.dart';
import 'verification_screen.dart';
import 'client/client_dashboard_screen.dart';
import 'driver/driver_dashboard_screen.dart';
import '../widgets/home/hero_header.dart';
import '../widgets/home/animated_banner.dart';
import '../widgets/home/about_section.dart';
import '../widgets/home/footer_contact.dart';
import '../widgets/home/quick_action_card.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final AppwriteService _appwriteService = AppwriteService();
  
  Map<String, dynamic>? _profileData;
  Map<String, dynamic>? _verificationData;
  bool _isLoading = true;
  String? _profileImageUrl;
  
  @override
  void initState() {
    super.initState();
    _loadUserData();
  }
  
  Future<void> _loadUserData() async {
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final user = authProvider.user;
      
      if (user == null) return;
      
      // Load profile data
      final profileDoc = await _appwriteService.getUserProfile(user.id);
      _profileData = profileDoc.data;
      
      // Load verification data
      try {
        final verificationDoc = await _appwriteService.getVerificationData(user.id);
        if (verificationDoc != null) {
          _verificationData = verificationDoc.data;
          
          // Get profile image URL if available
          if (_verificationData?['profileImageUrl'] != null) {
            _profileImageUrl = _appwriteService.getFileUrl(
              bucketId: AppwriteConfig.profileImagesBucket,
              fileId: _verificationData!['profileImageUrl'],
            );
          }
        }
      } catch (e) {
        // Verification data might not exist yet
        print('No verification data found: $e');
      }
      
      // Also check if user has a profile image in their profile data
      if (_profileData?['profileImage'] != null && _profileImageUrl == null) {
        _profileImageUrl = _appwriteService.getFileUrl(
          bucketId: AppwriteConfig.profileImagesBucket,
          fileId: _profileData!['profileImage'],
        );
      }
      
    } catch (e) {
      print('Error loading user data: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
  
  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.user;
    
    if (_isLoading || user == null) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: _buildAppBar(context, user),
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }
    
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: _buildAppBar(context, user),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.pushNamed(context, AppRoutes.emergency);
        },
        backgroundColor: Colors.red,
        icon: const Icon(Icons.emergency, color: Colors.white),
        label: const Text(
          'SOS',
          style: TextStyle(color: Colors.white),
        ),
      ),
      body: CustomScrollView(
        slivers: [
          // Hero Header
          SliverToBoxAdapter(
            child: HeroHeader(
              user: user,
              verificationData: _verificationData,
              onVerificationTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const VerificationScreen(),
                  ),
                );
              },
            ),
          ),
          
          // Animated Banner
          SliverToBoxAdapter(
            child: AnimatedBanner(
              onTapPrimary: () => _navigateToDashboard(context, user),
            ),
          ),
          

          
          // Quick Actions Grid
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            sliver: SliverGrid(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 0.9,
              ),
              delegate: SliverChildListDelegate(
                _buildQuickActions(user),
              ),
            ),
          ),
          
          // About Section
          const SliverToBoxAdapter(
            child: AboutSection(),
          ),
          
          // Footer Contact
          const SliverToBoxAdapter(
            child: FooterContact(),
          ),
          
          // Extra bottom space for FAB
          const SliverToBoxAdapter(
            child: SizedBox(height: 96),
          ),
        ],
      ),
    );
  }
  
  PreferredSizeWidget _buildAppBar(BuildContext context, User? user) {
    return AppBar(
      title: Text(
        'DriveGenius',
        style: AppTextStyles.h4.copyWith(
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
      ),
      backgroundColor: AppColors.primary,
      foregroundColor: Colors.white,
      elevation: 0,
      actions: [
        // Notifications icon
        IconButton(
          icon: const Icon(Icons.notifications_outlined),
          onPressed: () {
            Navigator.pushNamed(context, AppRoutes.notifications);
          },
        ),
        
        // Profile avatar button
        GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const ProfileScreen(),
              ),
            );
          },
          child: Container(
            margin: const EdgeInsets.only(right: AppSizes.md),
            child: Consumer<AuthProvider>(
              builder: (context, authProvider, child) {
                final avatarUrl = authProvider.avatarUrl;
                
                if (avatarUrl != null && avatarUrl.isNotEmpty) {
                  return CircleAvatar(
                    radius: 18,
                    backgroundColor: Colors.white,
                    backgroundImage: NetworkImage(avatarUrl),
                    onBackgroundImageError: (exception, stackTrace) {
                      // Fallback to letter avatar on error
                    },
                  );
                } else {
                  return CircleAvatar(
                    radius: 18,
                    backgroundColor: Colors.white,
                    child: Text(
                      (user?.name ?? '').isNotEmpty ? (user?.name ?? '')[0].toUpperCase() : '?',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                  );
                }
              },
            ),
          ),
        ),
      ],
    );
  }
  

  
  void _navigateToDashboard(BuildContext context, User user) {
    final isDriver = user.role == UserRole.driver;
    
    if (isDriver) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => const DriverDashboardScreen(),
        ),
      );
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => const ClientDashboardScreen(),
        ),
      );
    }
  }
  
  List<Widget> _buildQuickActions(User user) {
    final isDriver = user.role == UserRole.driver;
    
    if (isDriver) {
      return [
        QuickActionCard(
          title: 'Job Requests',
          subtitle: 'View incoming trips',
          icon: Icons.work_outline,
          color: AppColors.primary,
          onTap: () => Navigator.pushNamed(context, AppRoutes.jobRequests),
        ),
        QuickActionCard(
          title: 'Availability',
          subtitle: 'Set your status',
          icon: Icons.toggle_on_outlined,
          color: AppColors.accent,
          onTap: () => _showAvailabilityDialog(),
        ),
        QuickActionCard(
          title: 'Subscriptions',
          subtitle: 'Manage plans',
          icon: Icons.subscriptions,
          color: AppColors.info,
          onTap: () => Navigator.pushNamed(context, AppRoutes.subscriptions),
        ),
        QuickActionCard(
          title: 'Messages',
          subtitle: 'Chat with clients',
          icon: Icons.chat_outlined,
          color: AppColors.secondary,
          onTap: () => Navigator.pushNamed(context, AppRoutes.messages),
        ),
      ];
    } else {
      return [
        QuickActionCard(
          title: 'Find Drivers',
          subtitle: 'Search available drivers',
          icon: Icons.search,
          color: AppColors.primary,
          onTap: () => Navigator.pushNamed(context, AppRoutes.driverListing),
        ),
        QuickActionCard(
          title: 'Book a Trip',
          subtitle: 'Request a ride',
          icon: Icons.add_location,
          color: AppColors.accent,
          onTap: () => Navigator.pushNamed(context, AppRoutes.bookingRequest),
        ),
        QuickActionCard(
          title: 'Subscriptions',
          subtitle: 'Manage plans',
          icon: Icons.subscriptions,
          color: AppColors.info,
          onTap: () => Navigator.pushNamed(context, AppRoutes.subscriptions),
        ),
        QuickActionCard(
          title: 'Messages',
          subtitle: 'Chat with drivers',
          icon: Icons.chat_outlined,
          color: AppColors.secondary,
          onTap: () => Navigator.pushNamed(context, AppRoutes.messages),
        ),
      ];
    }
  }
  
  void _showAvailabilityDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Set Availability'),
        content: const Text('This feature will be implemented soon. For now, you can toggle your availability here.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Availability updated!')),
              );
            },
            child: const Text('Set Available'),
          ),
        ],
      ),
    );
  }
}
