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
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          if (_items.any((n) => (n['status'] as String? ?? 'UNREAD') == 'UNREAD'))
            TextButton(
              onPressed: _markAllRead,
              child: const Text('Mark all read'),
            ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: _items.isEmpty
                  ? ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      children: const [
                        SizedBox(height: 120),
                        Center(child: Text('No notifications yet')),
                        SizedBox(height: 120),
                      ],
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                      itemCount: _items.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (_, i) => _NotifTile(
                        data: _items[i],
                        onRead: (id) async {
                          await context.read<AppwriteService>().markNotificationRead(id);
                          if (!mounted) return;
                          // Optimistic: update local state to READ
                          setState(() {
                            _items[i]['status'] = 'READ';
                          });
                        },
                      ),
                    ),
            ),
    );
  }

  Future<void> _markAllRead() async {
    final svc = context.read<AppwriteService>();
    for (final n in _items) {
      if ((n['status'] as String? ?? 'UNREAD') == 'UNREAD') {
        await svc.markNotificationRead(n[r'$id'] as String);
      }
    }
    if (!mounted) return;
    setState(() {
      for (final n in _items) {
        n['status'] = 'READ';
      }
    });
  }
}

class _NotifTile extends StatelessWidget {
  const _NotifTile({required this.data, required this.onRead});

  final Map<String, dynamic> data;
  final Future<void> Function(String id) onRead;

  @override
  Widget build(BuildContext context) {
    final id = data[r'$id'] as String;
    final type = (data['type'] as String? ?? '').toUpperCase();
    final title = data['title'] as String? ?? 'Update';
    final body = data['body'] as String? ?? '';
    final unread = (data['status'] as String? ?? 'UNREAD') == 'UNREAD';
    // Support both custom createdAt and system $createdAt
    final createdIso = (data['createdAt'] as String?) ?? (data[r'$createdAt'] as String?);

    IconData icon;
    Color color;
    switch (type) {
      case 'JOB_ACCEPTED':
        icon = Icons.check_circle_outline;
        color = Colors.green;
        break;
      case 'JOB_REJECTED':
        icon = Icons.cancel_outlined;
        color = Colors.red;
        break;
      default:
        icon = Icons.notifications_outlined;
        color = Theme.of(context).colorScheme.primary;
    }

    return Material(
      color: unread ? Colors.blue.withOpacity(0.06) : Colors.grey.withOpacity(0.06),
      borderRadius: BorderRadius.circular(16),
      child: ListTile(
        leading: Stack(
          clipBehavior: Clip.none,
          children: [
            Icon(icon, color: color, size: 26),
            if (unread)
              Positioned(
                right: -2,
                top: -2,
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                ),
              ),
          ],
        ),
        title: Text(title, maxLines: 1, overflow: TextOverflow.ellipsis),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (body.isNotEmpty) Text(body, maxLines: 2, overflow: TextOverflow.ellipsis),
            if (createdIso != null && createdIso.isNotEmpty)
              Text(
                DateTime.tryParse(createdIso)?.toLocal().toString().substring(0, 16) ?? '',
                style: Theme.of(context).textTheme.bodySmall,
              ),
          ],
        ),
        onTap: () => onRead(id),
      ),
    );
  }
}
