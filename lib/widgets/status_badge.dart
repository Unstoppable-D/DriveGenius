import 'package:flutter/material.dart';

class StatusBadge extends StatelessWidget {
  const StatusBadge({super.key, required this.status});
  final String status;

  @override
  Widget build(BuildContext context) {
    late Color bg;
    late Color fg;
    String label = status;

    switch (status) {
      case 'ACCEPTED':
        bg = Colors.green.withOpacity(0.18);
        fg = Colors.green.shade900;
        label = 'Accepted';
        break;
      case 'REJECTED':
        bg = Colors.red.withOpacity(0.18);
        fg = Colors.red.shade900;
        label = 'Rejected';
        break;
      case 'CANCELLED':
        bg = Colors.grey.withOpacity(0.18);
        fg = Colors.grey.shade800;
        label = 'Cancelled';
        break;
      default:
        bg = Colors.orange.withOpacity(0.18);
        fg = Colors.orange.shade900;
        label = 'Pending';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(999)),
      child: Text(label, style: TextStyle(color: fg, fontSize: 12, fontWeight: FontWeight.w700)),
    );
  }
}
