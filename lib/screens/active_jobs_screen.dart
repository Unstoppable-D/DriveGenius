import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:appwrite/appwrite.dart';
import '../services/appwrite_service.dart';
import '../providers/auth_provider.dart';
import '../models/job_request.dart';
import '../widgets/status_badge.dart';

class ActiveJobsScreen extends StatefulWidget {
  const ActiveJobsScreen({super.key});

  @override
  State<ActiveJobsScreen> createState() => _ActiveJobsScreenState();
}

class _ActiveJobsScreenState extends State<ActiveJobsScreen> {
  List<JobRequest> _items = [];
  bool _loading = true;
  RealtimeSubscription? _sub;
  String? _driverId;

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    final svc = context.read<AppwriteService>();
    final id = context.read<AuthProvider>().userId ?? await svc.currentUserId();
    _driverId = id;
    await _load();

    _sub = svc.subscribeJobRequestsChanges(
      driverId: id,
      onChange: _load, // refresh list when any doc for this driver changes
    );
  }

  Future<void> _load() async {
    try {
      final svc = context.read<AppwriteService>();
      final id = _driverId ?? await svc.currentUserId();
      final data = await svc.listDriverActiveJobs(id);
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
      appBar: AppBar(title: const Text('Active Jobs')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _items.isEmpty
              ? const Center(child: Text('No active jobs'))
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                  itemCount: _items.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (_, i) {
                    final r = _items[i];
                    return Material(
                      color: Colors.grey.withOpacity(0.06),
                      borderRadius: BorderRadius.circular(16),
                      child: ListTile(
                        title: Text('${r.pickup} → ${r.destination}', maxLines: 2, overflow: TextOverflow.ellipsis),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (r.estimatedPickupAt != null)
                              Text('ETA pickup: ${r.estimatedPickupAt!.toLocal()}'),
                            Text('Scheduled: ${r.scheduledAt.toLocal()}'),
                          ],
                        ),
                        trailing: const StatusBadge(status: 'ACCEPTED'),
                      ),
                    );
                  },
                ),
    );
  }
}
