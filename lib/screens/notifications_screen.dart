import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:appwrite/appwrite.dart';
import '../services/appwrite_service.dart';
import '../providers/auth_provider.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  List<Map<String, dynamic>> _items = [];
  bool _loading = true;
  RealtimeSubscription? _sub;
  String? _userId;

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    final svc = context.read<AppwriteService>();
    final id = context.read<AuthProvider>().userId ?? await svc.currentUserId();
    _userId = id;

    await _load();

    _sub = svc.subscribeClientNotifications(
      userId: id,
      onChange: _load,
    );
  }

  Future<void> _load() async {
    try {
      final svc = context.read<AppwriteService>();
      final id = _userId ?? await svc.currentUserId();
      final docs = await svc.listClientNotifications(id);
      if (!mounted) return;
      setState(() {
        _items = docs.map((d) => { ...d.data, r'$id': d.$id }).toList();
        _loading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _sub?.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Notifications')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _items.isEmpty
              ? const Center(child: Text('No notifications'))
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                  itemCount: _items.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (_, i) {
                    final n = _items[i];
                    final type = n['type'] as String? ?? '';
                    final title = n['title'] as String? ?? 'Update';
                    final body = n['body'] as String? ?? '';
                    final unread = (n['status'] as String? ?? 'UNREAD') == 'UNREAD';
                    return Material(
                      color: unread ? Colors.blue.withOpacity(0.06) : Colors.grey.withOpacity(0.06),
                      borderRadius: BorderRadius.circular(16),
                      child: ListTile(
                        leading: Icon(
                          type == 'JOB_ACCEPTED' ? Icons.check_circle_outline : Icons.cancel_outlined,
                          color: type == 'JOB_ACCEPTED' ? Colors.green : Colors.red,
                        ),
                        title: Text(title, maxLines: 1, overflow: TextOverflow.ellipsis),
                        subtitle: Text(body, maxLines: 2, overflow: TextOverflow.ellipsis),
                        onTap: () async {
                          // mark read
                          await context.read<AppwriteService>().markNotificationRead(n[r'$id'] as String);
                          if (!mounted) return;
                          setState(() => n['status'] = 'READ');
                          // Optionally navigate to My Trips
                          // Navigator.pushNamed(context, AppRoutes.clientTrips);
                        },
                      ),
                    );
                  },
                ),
    );
  }
}
