import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/appwrite_service.dart';
import '../providers/auth_provider.dart';
import '../constants/app_constants.dart';
import 'confirm_logout_dialog.dart';

class LogoutButton extends StatelessWidget {
  const LogoutButton.appBarIcon({super.key}) : _variant = _Variant.appBarIcon;
  const LogoutButton.block({super.key}) : _variant = _Variant.block;

  final _Variant _variant;

  Future<void> _handleLogout(BuildContext context) async {
    final confirmed = await showConfirmLogoutDialog(context);
    if (!confirmed) return;

    final svc = context.read<AppwriteService>();
    final auth = context.read<AuthProvider>();

    await svc.logout();

    if (!context.mounted) return;

    // 1) Navigate first to avoid UI flicker on current screen
    Navigator.pushNamedAndRemoveUntil(context, AppRoutes.login, (route) => false);

    // 2) Clear provider silently on the next frame (no rebuild on disposed pages)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      auth.clearForLogout(silent: true);
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_variant == _Variant.appBarIcon) {
      return IconButton(
        tooltip: 'Log out',
        icon: const Icon(Icons.logout_rounded),
        onPressed: () => _handleLogout(context),
      );
    }

    // Block variant (full-width button)
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        icon: const Icon(Icons.logout_rounded),
        label: const Text('Log out'),
        onPressed: () => _handleLogout(context),
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 14),
          textStyle: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}

enum _Variant { appBarIcon, block }
