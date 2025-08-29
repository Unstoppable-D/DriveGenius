import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/appwrite_service.dart';
import '../models/driver_profile.dart';
import '../providers/auth_provider.dart';
import '../widgets/public_profile_sheet.dart';

class BookingRequestScreen extends StatefulWidget {
  const BookingRequestScreen({super.key});

  @override
  State<BookingRequestScreen> createState() => _BookingRequestScreenState();
}

class _BookingRequestScreenState extends State<BookingRequestScreen> {
  late Future<List<DriverProfile>> _future;

  @override
  void initState() {
    super.initState();
    _future = context.read<AppwriteService>().fetchDrivers(verifiedOnly: true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Book a Trip')),
      body: FutureBuilder<List<DriverProfile>>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Failed to load drivers'),
                  const SizedBox(height: 8),
                  ElevatedButton(
                    onPressed: () => setState(() => _future = context.read<AppwriteService>().fetchDrivers(verifiedOnly: true)),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }
          final drivers = snap.data ?? [];
          if (drivers.isEmpty) {
            return const Center(child: Text('No drivers found'));
          }
          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            itemBuilder: (_, i) => _DriverTile(
              driver: drivers[i], 
              onBook: _openBookSheet,
              onTapDriver: _onTapDriver,
            ),
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemCount: drivers.length,
          );
        },
      ),
    );
  }

  void _openBookSheet(DriverProfile driver) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => _BookTripSheet(driver: driver),
    );
  }

  void _onTapDriver(BuildContext context, DriverProfile driver) async {
    final svc = context.read<AppwriteService>();
    final public = await svc.fetchPublicUserById(driver.id);
    if (public == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Driver profile not found')));
      return;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (ctx) => PublicProfileSheet(
        user: public,
        primaryLabel: 'Book this driver',
        primaryAction: () {
          Navigator.pop(ctx); // close profile sheet
          // Call your existing booking sheet / form
          _openBookSheet(driver); // reuse your existing method
        },
      ),
    );
  }
}

class _DriverTile extends StatelessWidget {
  const _DriverTile({required this.driver, required this.onBook, required this.onTapDriver});
  final DriverProfile driver;
  final void Function(DriverProfile) onBook;
  final void Function(BuildContext, DriverProfile) onTapDriver;

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.primary;
    return Material(
      color: Colors.grey.withOpacity(0.06),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => onTapDriver(context, driver),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: color.withOpacity(0.1),
                child: Text(
                  (driver.name.isNotEmpty ? driver.name[0].toUpperCase() : '?'),
                  style: TextStyle(color: color, fontWeight: FontWeight.w700),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(driver.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w700)),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        _pill(driver.isVerified ? 'Verified' : 'Unverified',
                            bg: driver.isVerified ? Colors.green.withOpacity(0.15) : Colors.orange.withOpacity(0.15),
                            fg: driver.isVerified ? Colors.green.shade900 : Colors.orange.shade900),
                      ],
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded),
            ],
          ),
        ),
      ),
    );
  }

  Widget _pill(String label, {required Color bg, required Color fg}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(999)),
      child: Text(label, style: TextStyle(color: fg, fontWeight: FontWeight.w600, fontSize: 12)),
    );
  }
}

class _BookTripSheet extends StatefulWidget {
  const _BookTripSheet({required this.driver});
  final DriverProfile driver;

  @override
  State<_BookTripSheet> createState() => _BookTripSheetState();
}

class _BookTripSheetState extends State<_BookTripSheet> {
  final _pickup = TextEditingController();
  final _destination = TextEditingController();
  final _note = TextEditingController();
  DateTime? _when;
  bool _submitting = false;

  @override
  void dispose() {
    _pickup.dispose();
    _destination.dispose();
    _note.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final insets = MediaQuery.of(context).viewInsets.bottom;
    final auth = context.read<AuthProvider>();
    return Padding(
      padding: EdgeInsets.only(bottom: insets),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Text('Book ${widget.driver.name}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                const Spacer(),
                IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close)),
              ],
            ),
            const SizedBox(height: 8),
            TextField(controller: _pickup, decoration: const InputDecoration(labelText: 'Pickup address', border: OutlineInputBorder())),
            const SizedBox(height: 10),
            TextField(controller: _destination, decoration: const InputDecoration(labelText: 'Destination', border: OutlineInputBorder())),
            const SizedBox(height: 10),
            OutlinedButton.icon(
              icon: const Icon(Icons.schedule),
              label: Text(_when == null ? 'Select date & time' : _when!.toLocal().toString().substring(0, 16)),
              onPressed: _pickDateTime,
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _note,
              minLines: 2,
              maxLines: 4,
              decoration: const InputDecoration(labelText: 'Note (optional)', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 14),
            FilledButton.icon(
              onPressed: _submitting ? null : () => _submit(auth),
              icon: const Icon(Icons.send_rounded),
              label: Text(_submitting ? 'Sending...' : 'Send request'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickDateTime() async {
    final now = DateTime.now();
    final d = await showDatePicker(
      context: context,
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
      initialDate: now,
    );
    if (d == null) return;
    final t = await showTimePicker(context: context, initialTime: TimeOfDay.fromDateTime(now.add(const Duration(minutes: 15))));
    if (t == null) return;
    setState(() => _when = DateTime(d.year, d.month, d.day, t.hour, t.minute));
  }

  Future<void> _submit(AuthProvider auth) async {
    if (_pickup.text.trim().isEmpty || _destination.text.trim().isEmpty || _when == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please fill all required fields')));
      return;
    }
    setState(() => _submitting = true);
    try {
      final svc = context.read<AppwriteService>();
      final clientId = auth.userId ?? await svc.currentUserId();
      await svc.createJobRequest(
        clientId: clientId,
        driverId: widget.driver.id,
        pickup: _pickup.text.trim(),
        destination: _destination.text.trim(),
        scheduledAt: _when!,
        note: _note.text.trim().isEmpty ? null : _note.text.trim(),
      );
      if (!mounted) return;
      Navigator.pop(context); // close sheet
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Trip request sent to driver')));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to send: $e')));
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }
}
