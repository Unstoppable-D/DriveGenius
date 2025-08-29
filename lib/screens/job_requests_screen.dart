import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:appwrite/appwrite.dart';
import '../services/appwrite_service.dart';
import '../models/job_request.dart';
import '../providers/auth_provider.dart';
import '../widgets/public_profile_sheet.dart';
import '../widgets/status_badge.dart';

class JobRequestsScreen extends StatefulWidget {
  const JobRequestsScreen({super.key});

  @override
  State<JobRequestsScreen> createState() => _JobRequestsScreenState();
}

class _JobRequestsScreenState extends State<JobRequestsScreen> {
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

    await _loadPending();

    _sub = svc.subscribeJobRequestsChanges(
      driverId: id,
      onChange: _loadPending, // refetch when anything for this driver changes
    );
  }

  Future<void> _loadPending() async {
    try {
      final svc = context.read<AppwriteService>();
      final id = _driverId ?? await svc.currentUserId();
      final data = await svc.listDriverJobRequests(id);
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
      appBar: AppBar(title: const Text('Job Requests')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _items.isEmpty
              ? const Center(child: Text('No pending requests'))
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
                        subtitle: Text('Scheduled: ${r.scheduledAt.toLocal()}'),
                        trailing: const Icon(Icons.chevron_right_rounded),
                        onTap: () => _openActionSheet(r),
                      ),
                    );
                  },
                ),
    );
  }

  void _openActionSheet(JobRequest r) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (ctx) => _RequestActionSheet(request: r, onUpdated: () {
        // Remove from list immediately
        setState(() => _items.removeWhere((x) => x.id == r.id));
      }),
    );
  }
}

class _RequestActionSheet extends StatefulWidget {
  const _RequestActionSheet({required this.request, required this.onUpdated});
  final JobRequest request;
  final VoidCallback onUpdated;

  @override
  State<_RequestActionSheet> createState() => _RequestActionSheetState();
}

class _RequestActionSheetState extends State<_RequestActionSheet> {
  DateTime? _eta;
  bool _submitting = false;

  @override
  Widget build(BuildContext context) {
    final r = widget.request;
    final insets = MediaQuery.of(context).viewInsets.bottom;
    return Padding(
      padding: EdgeInsets.only(bottom: insets),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(children: [
              const Text('Request details', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
              const Spacer(),
              IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close)),
            ]),
            const SizedBox(height: 8),
            ListTile(
              dense: true,
              leading: const Icon(Icons.route_outlined),
              title: Text('${r.pickup} → ${r.destination}'),
            ),
            ListTile(
              dense: true,
              leading: const Icon(Icons.event_outlined),
              title: Text('Scheduled: ${r.scheduledAt.toLocal()}'),
            ),
            if ((r.note ?? '').isNotEmpty)
              ListTile(
                dense: true,
                leading: const Icon(Icons.notes_outlined),
                title: Text(r.note ?? ''),
              ),
            const Divider(height: 24),
            const Text('Actions', style: TextStyle(fontWeight: FontWeight.w700)),
            const SizedBox(height: 10),
            FilledButton.icon(
              icon: const Icon(Icons.check_circle_outline),
              label: Text(_submitting ? 'Accepting...' : 'Accept with ETA'),
              onPressed: _submitting ? null : _accept,
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              icon: const Icon(Icons.cancel_outlined),
              label: Text(_submitting ? 'Rejecting...' : 'Reject'),
              onPressed: _submitting ? null : _reject,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _accept() async {
    // Ask for ETA
    final picked = await _pickEta(context);
    if (picked == null) return;
    setState(() => _submitting = true);
    try {
      final svc = context.read<AppwriteService>();
      await svc.updateJobRequestStatus(
        requestId: widget.request.id,
        status: 'ACCEPTED',
        estimatedPickupAt: picked,
      );
      if (!mounted) return;
      widget.onUpdated();
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Request accepted')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed: $e')));
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  Future<void> _reject() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Reject request?'),
        content: const Text('Are you sure you want to reject this trip request?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Reject')),
        ],
      ),
    );
    if (confirm != true) return;

    setState(() => _submitting = true);
    try {
      final svc = context.read<AppwriteService>();
      await svc.updateJobRequestStatus(
        requestId: widget.request.id,
        status: 'REJECTED',
      );
      if (!mounted) return;
      widget.onUpdated();
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Request rejected')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed: $e')));
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  Future<DateTime?> _pickEta(BuildContext context) async {
    final sched = widget.request.scheduledAt.toLocal();
    final d = await showDatePicker(
      context: context,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 7)),
      initialDate: DateTime(sched.year, sched.month, sched.day),
    );
    if (d == null) return null;
    final t = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(sched),
    );
    if (t == null) return null;
    return DateTime(d.year, d.month, d.day, t.hour, t.minute);
  }
}
