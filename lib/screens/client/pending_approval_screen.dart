import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../theme/app_theme.dart';
import '../../providers/auth_providers.dart';

class PendingApprovalScreen extends ConsumerWidget {
  const PendingApprovalScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: AppTheme.bgDark,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(32.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: AppTheme.accentPurple.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.hourglass_empty_rounded,
                    size: 80,
                    color: AppTheme.accentPurple,
                  ),
                ),
                const SizedBox(height: 32),
                Text(
                  'Compte en attente',
                  style: Theme.of(context).textTheme.displayMedium?.copyWith(
                    color: Colors.white,
                    fontSize: 28,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Votre inscription a bien été enregistrée.\n\nCependant, un administrateur doit vérifier et valider votre compte avant que vous puissiez accéder à l\'application.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppTheme.textGrey,
                    fontSize: 16,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 48),
                const CircularProgressIndicator(
                  color: AppTheme.accentCyan,
                ),
                const SizedBox(height: 24),
                const Text(
                  'Cette page s\'actualisera automatiquement dès que votre compte sera validé.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppTheme.accentCyan,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 48),
                TextButton.icon(
                  onPressed: () {
                    ref.read(authControllerProvider).signOut();
                  },
                  icon: const Icon(Icons.logout, color: Colors.white54),
                  label: const Text(
                    'Se déconnecter',
                    style: TextStyle(color: Colors.white54),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
