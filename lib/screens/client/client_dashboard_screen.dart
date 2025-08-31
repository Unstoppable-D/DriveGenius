import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../constants/app_constants.dart';
import '../../widgets/user_avatar.dart';
import '../../widgets/quick_action_card.dart';
import '../../widgets/stat_card.dart';
import '../../widgets/logout_button.dart';

class ClientDashboardScreen extends StatefulWidget {
  const ClientDashboardScreen({super.key});

  @override
  State<ClientDashboardScreen> createState() => _ClientDashboardScreenState();
}

class _ClientDashboardScreenState extends State<ClientDashboardScreen> {

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final scheme = Theme.of(context).colorScheme;
    final name = auth.user?.name ?? 'Client';
    final avatarUrl = auth.avatarUrl;
    final verified = auth.isVerified;
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        leading: IconButton(
          tooltip: 'Home',
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () {
            // Always go to Home, clear intermediate routes
            Navigator.pushNamedAndRemoveUntil(context, AppRoutes.home, (route) => false);
          },
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: UserAvatar(name: name, imageUrl: avatarUrl, size: 36),
          ),
          const LogoutButton.appBarIcon(),
          const SizedBox(width: 4),
        ],
      ),
      body: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            sliver: SliverToBoxAdapter(
        child: Column(
          children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [scheme.primaryContainer, scheme.primary.withOpacity(0.9)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
                        UserAvatar(name: name, imageUrl: avatarUrl, size: 56),
                        const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                              Text('Welcome back,',
                                  style: TextStyle(
                                    color: scheme.onPrimaryContainer.withOpacity(0.9),
                                    fontSize: 12.5,
                                  )),
                              const SizedBox(height: 2),
                Text(
                                name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: scheme.onPrimaryContainer,
                                  fontSize: 20,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: [
                                  _chip(
                                    label: 'CLIENT',
                                    icon: Icons.person_outline,
                                    bg: Colors.white.withOpacity(0.25),
                                    fg: scheme.onPrimaryContainer,
                                  ),
                                  _chip(
                                    label: verified ? 'Verified' : 'Pending',
                                    icon: verified ? Icons.check_circle : Icons.watch_later_outlined,
                                    bg: verified ? Colors.green.withOpacity(0.18) : Colors.orange.withOpacity(0.18),
                                    fg: verified ? Colors.green.shade900 : Colors.orange.shade900,
                                  ),
                                ],
                              ),
                            ],
                  ),
                ),
              ],
            ),
          ),
                  const SizedBox(height: 16),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Quick Actions',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                    ),
          ),
        ],
      ),
            ),
          ),

          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            sliver: SliverGrid(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
                mainAxisSpacing: 10,
                crossAxisSpacing: 10,
                mainAxisExtent: 96,
              ),
              delegate: SliverChildListDelegate.fixed([
            QuickActionCard(
              title: 'Profile',
                  subtitle: 'View & edit',
              icon: Icons.person_outline,
              onTap: () => Navigator.pushNamed(context, AppRoutes.profile),
                ),
                if (!verified)
                  QuickActionCard(
                    title: 'Verification',
                    subtitle: 'Complete now',
                    icon: Icons.verified_outlined,
                    color: Colors.orange,
                    onTap: () => Navigator.pushNamed(context, AppRoutes.verification),
            ),
                        QuickActionCard(
              title: 'Book a driver',
              subtitle: 'New request',
              icon: Icons.add_road_outlined,
              onTap: () => Navigator.pushNamed(context, AppRoutes.bookingRequest),
            ),
            QuickActionCard(
              title: 'Find Drivers',
              subtitle: 'Start chatting',
              icon: Icons.search_outlined,
              color: Colors.indigo,
              onTap: () => Navigator.pushNamed(context, AppRoutes.findDrivers),
            ),
            QuickActionCard(
              title: 'My trips',
              subtitle: 'Status & history',
              icon: Icons.event_available_outlined,
              color: Colors.purple,
              onTap: () => Navigator.pushNamed(context, AppRoutes.clientTrips),
            ),
            QuickActionCard(
              title: 'Messages',
              subtitle: 'Chat',
              icon: Icons.chat_bubble_outline,
              color: Colors.blue,
              onTap: () => Navigator.pushNamed(context, AppRoutes.chatInbox),
            ),
              ]),
            ),
          ),

          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            sliver: SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text('At a glance', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                  SizedBox(height: 10),
        Row(
          children: [
            Expanded(
                        child: StatCard(
                          label: 'Bookings (wk)',
                value: '0',
                          icon: Icons.event_available_outlined,
              ),
            ),
                      SizedBox(width: 10),
            Expanded(
                        child: StatCard(
                          label: 'Active',
                          value: '0',
                          icon: Icons.timelapse,
                          color: Colors.orange,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 10),
                  Row(
                    children: [
            Expanded(
                        child: StatCard(
                          label: 'Completed',
                value: '0',
                          icon: Icons.check_circle_outline,
                          color: Colors.green,
                        ),
                      ),
                      SizedBox(width: 10),
                      Expanded(
                        child: StatCard(
                          label: 'Rating',
                          value: '5.0',
                          icon: Icons.star_rate_rounded,
                          color: Colors.amber,
              ),
            ),
          ],
        ),
      ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _chip({
    required String label,
    required IconData icon,
    required Color bg,
    required Color fg,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 16, color: fg),
        const SizedBox(width: 6),
        Text(label, style: TextStyle(color: fg, fontWeight: FontWeight.w600, fontSize: 12)),
      ]),
    );
  }
}
