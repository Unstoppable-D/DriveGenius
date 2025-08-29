import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/public_user.dart';
import 'image_viewer.dart';

class PublicProfileSheet extends StatelessWidget {
  const PublicProfileSheet({
    super.key,
    required this.user,
    this.primaryAction,
    this.primaryLabel,
  });

  final PublicUser user;
  final VoidCallback? primaryAction; // e.g., "Book this driver"
  final String? primaryLabel;

  bool _isImage(String url) {
    final u = url.toLowerCase();
    return u.endsWith('.jpg') || u.endsWith('.jpeg') || u.endsWith('.png') || u.endsWith('.webp') || u.endsWith('.gif');
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final name = user.name;
    final role = user.role.toUpperCase();
    final verified = user.isVerified;

    Widget avatarWidget() {
      final url = user.avatarUrl;
      final letter = name.isNotEmpty ? name.trim()[0].toUpperCase() : '?';
      final base = Theme.of(context).colorScheme.primary;
      final fallback = CircleAvatar(
        radius: 36,
        backgroundColor: base.withOpacity(0.1),
        child: Text(letter, style: TextStyle(color: base, fontWeight: FontWeight.w800, fontSize: 24)),
      );

      if (url == null || url.isEmpty) return fallback;
      
      return GestureDetector(
        onTap: () => showImageViewer(context, url, title: name),
        child: ClipOval(
          child: Image.network(
            url,
            width: 72,
            height: 72,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => fallback,
            loadingBuilder: (_, child, prog) => prog == null ? child : fallback,
          ),
        ),
      );
    }

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Text('Profile', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
                const Spacer(),
                IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close)),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                avatarWidget(),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _chip(role, Icons.badge_outlined, bg: Colors.black12, fg: Colors.black87),
                          _chip(verified ? 'Verified' : 'Pending', verified ? Icons.check_circle : Icons.watch_later_outlined,
                              bg: verified ? Colors.green.withOpacity(0.18) : Colors.orange.withOpacity(0.18),
                              fg: verified ? Colors.green.shade900 : Colors.orange.shade900),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),

            // Address section
            if ((user.addressString?.isNotEmpty ?? false)) ...[
              const SizedBox(height: 10),
              ListTile(
                dense: true,
                leading: const Icon(Icons.location_on_outlined),
                title: Text('Address', style: Theme.of(context).textTheme.bodySmall),
                subtitle: Text(user.addressString!, maxLines: 2, overflow: TextOverflow.ellipsis),
                trailing: IconButton(
                  tooltip: 'Open in Maps',
                  icon: const Icon(Icons.map_outlined),
                  onPressed: () {
                    final q = Uri.encodeComponent(user.addressString!);
                    launchUrl(
                      Uri.parse('https://www.google.com/maps/search/?api=1&query=$q'), 
                      mode: LaunchMode.externalApplication
                    );
                  },
                ),
              ),
            ],

            const SizedBox(height: 12),
            if (user.email != null && user.email!.isNotEmpty)
              ListTile(
                dense: true,
                leading: const Icon(Icons.email_outlined),
                title: Text(user.email!, maxLines: 1, overflow: TextOverflow.ellipsis),
              ),
            if (user.phone != null && user.phone!.isNotEmpty)
              ListTile(
                dense: true,
                leading: const Icon(Icons.phone_outlined),
                title: Text(user.phone!, maxLines: 1, overflow: TextOverflow.ellipsis),
              ),
            if (user.role == 'driver' && (user.documentUrl?.isNotEmpty ?? false)) ...[
              const SizedBox(height: 4),
              OutlinedButton.icon(
                icon: const Icon(Icons.insert_drive_file_outlined),
                label: const Text('View document'),
                onPressed: () async {
                  final url = user.documentUrl!;
                  if (_isImage(url)) {
                    await showImageViewer(context, url, title: 'Document');
                  } else {
                    final uri = Uri.parse(url);
                    if (await canLaunchUrl(uri)) {
                      await launchUrl(uri, mode: LaunchMode.externalApplication);
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Cannot open document')));
                    }
                  }
                },
              ),
            ],
            if (primaryAction != null) ...[
              const SizedBox(height: 12),
              FilledButton(
                onPressed: primaryAction,
                child: Text(primaryLabel ?? 'Continue'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _chip(String label, IconData icon, {required Color bg, required Color fg}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(999)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 16, color: fg),
        const SizedBox(width: 6),
        Text(label, style: TextStyle(color: fg, fontWeight: FontWeight.w600, fontSize: 12)),
      ]),
    );
  }


}
