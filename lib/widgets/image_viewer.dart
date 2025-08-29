import 'package:flutter/material.dart';

Future<void> showImageViewer(BuildContext context, String imageUrl, {String? title}) {
  return showDialog<void>(
    context: context,
    barrierColor: Colors.black.withOpacity(0.85),
    builder: (ctx) {
      return GestureDetector(
        onTap: () => Navigator.pop(ctx),
        child: Scaffold(
          backgroundColor: Colors.transparent,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            title: Text(title ?? 'Preview'),
            foregroundColor: Colors.white,
          ),
          body: Center(
            child: InteractiveViewer(
              minScale: 0.5,
              maxScale: 4,
              child: Image.network(
                imageUrl,
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) => const Icon(
                  Icons.broken_image, 
                  color: Colors.white70, 
                  size: 56
                ),
                loadingBuilder: (_, child, prog) => prog == null
                    ? child
                    : const SizedBox(
                        width: 40,
                        height: 40,
                        child: CircularProgressIndicator(
                          color: Colors.white70, 
                          strokeWidth: 2
                        ),
                      ),
              ),
            ),
          ),
        ),
      );
    },
  );
}
