import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:appwrite/appwrite.dart';
import '../services/appwrite_service.dart';
import '../models/job_request.dart';
import '../providers/auth_provider.dart';
import '../widgets/status_badge.dart';

class ClientTripRequestsScreen extends StatefulWidget {
  const ClientTripRequestsScreen({super.key});

  @override
  State<ClientTripRequestsScreen> createState() => _ClientTripRequestsScreenState();
}

class _ClientTripRequestsScreenState extends State<ClientTripRequestsScreen> {
  List<JobRequest> _items = [];
  bool _loading = true;
  RealtimeSubscription? _sub;
  String? _clientId;

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    final svc = context.read<AppwriteService>();
    final id = context.read<AuthProvider>().userId ?? await svc.currentUserId();
    _clientId = id;

    await _load();

    _sub = svc.subscribeClientRequestsChanges(
      clientId: id,
      onChange: _load,
    );
  }

  Future<void> _load() async {
    try {
      final svc = context.read<AppwriteService>();
      final id = _clientId ?? await svc.currentUserId();
      final data = await svc.listClientJobRequests(id);
      if (!mounted) return;
      setState(() {
        _items = data;
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
      appBar: AppBar(title: const Text('My Trips')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _items.isEmpty
              ? const Center(child: Text('No trip requests yet'))
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                  itemCount: _items.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (ctx, i) {
                    final r = _items[i];
                    return Material(
                      color: Colors.grey.withOpacity(0.06),
                      borderRadius: BorderRadius.circular(16),
                      child: ListTile(
                        title: Text('${r.pickup} → ${r.destination}', maxLines: 2, overflow: TextOverflow.ellipsis),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Requested: ${r.createdAt.toLocal()}'),
                            if (r.estimatedPickupAt != null)
                              Text('ETA pickup: ${r.estimatedPickupAt!.toLocal()}'),
                          ],
                        ),
                        trailing: StatusBadge(status: r.status),
                      ),
                    );
                  },
                ),
    );
  }
}
