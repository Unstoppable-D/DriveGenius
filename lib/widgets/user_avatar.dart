import 'package:flutter/material.dart';

class UserAvatar extends StatelessWidget {
  const UserAvatar({
    super.key,
    required this.name,
    this.imageUrl,
    this.size = 56,
  });

  final String? name;
  final String? imageUrl;
  final double size;

  @override
  Widget build(BuildContext context) {
    final initial = (name?.trim().isNotEmpty ?? false)
        ? name!.trim()[0].toUpperCase()
        : '?';
    final bg = Theme.of(context).colorScheme.primary.withOpacity(0.1);
    final fg = Theme.of(context).colorScheme.primary;

    Widget fallback() => CircleAvatar(
          radius: size / 2,
          backgroundColor: bg,
          child: Text(
            initial,
            style: TextStyle(
              color: fg,
              fontWeight: FontWeight.w700,
              fontSize: size * 0.42,
            ),
          ),
        );

    if (imageUrl == null || imageUrl!.isEmpty) return fallback();

    return ClipOval(
      child: Image.network(
        imageUrl!,
        width: size,
        height: size,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => fallback(),
        loadingBuilder: (_, child, progress) =>
            progress == null ? child : fallback(),
      ),
    );
  }
}
