import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/auth_providers.dart';
import '../../providers/admin_providers.dart';
import 'admin_scanner_screen.dart';
import 'admin_menu_screen.dart';
import 'admin_rewards_screen.dart';
import 'admin_settings_screen.dart';
import 'admin_approvals_screen.dart';
import 'admin_users_screen.dart';

class AdminHome extends ConsumerWidget {
  const AdminHome({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final analyticsAsync = ref.watch(analyticsProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'DASHBOARD',
          style: Theme.of(context).textTheme.displayMedium?.copyWith(
            letterSpacing: 2,
            fontSize: 20,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.logout_rounded, color: Theme.of(context).iconTheme.color),
            onPressed: () {
              ref.read(authControllerProvider).signOut();
            },
          ),
        ],
      ),
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Aperçu',
                      style: Theme.of(context).textTheme.displayMedium,
                    ),
                    const SizedBox(height: 24),
                    
                    // Real Analytics
                    analyticsAsync.when(
                      data: (stats) {
                        return Row(
                          children: [
                            Expanded(
                              child: _buildTrendyStatCard(
                                context, 
                                title: 'Clients', 
                                value: '${stats['totalClients']}', 
                                icon: Icons.people_outline,
                                isPrimary: true,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: _buildTrendyStatCard(
                                context, 
                                title: 'Points donnés', 
                                value: '${stats['totalPoints']}', 
                                icon: Icons.auto_awesome,
                                isPrimary: false,
                              ),
                            ),
                          ],
                        );
                      },
                      loading: () => const Center(child: CircularProgressIndicator(color: AppTheme.primaryOrange)),
                      error: (err, stack) => Text('Erreur: $err', style: const TextStyle(color: AppTheme.error)),
                    ),
                    const SizedBox(height: 48),

                    Text(
                      'Actions',
                      style: Theme.of(context).textTheme.displayMedium,
                    ),
                    const SizedBox(height: 16),
                    
                    _buildTrendyActionCard(
                      context,
                      title: 'Scanner un QR',
                      subtitle: 'Attribuer des points',
                      icon: Icons.qr_code_scanner_rounded,
                      onTap: () {
                        Navigator.of(context).push(MaterialPageRoute(builder: (context) => const AdminScannerScreen()));
                      },
                    ),
                    const SizedBox(height: 16),
                    _buildTrendyActionCard(
                      context,
                      title: 'Demandes d\'inscription',
                      subtitle: 'Valider les nouveaux comptes',
                      icon: Icons.person_add_alt_1_rounded,
                      onTap: () {
                        Navigator.of(context).push(MaterialPageRoute(builder: (context) => const AdminApprovalsScreen()));
                      },
                    ),
                    const SizedBox(height: 16),
                    _buildTrendyActionCard(
                      context,
                      title: 'Clients & Utilisateurs',
                      subtitle: 'Gérer tous les comptes',
                      icon: Icons.people_alt_rounded,
                      onTap: () {
                        Navigator.of(context).push(MaterialPageRoute(builder: (context) => const AdminUsersScreen()));
                      },
                    ),
                    const SizedBox(height: 16),
                    _buildTrendyActionCard(
                      context,
                      title: 'Menu & Articles',
                      subtitle: 'Gérer les produits',
                      icon: Icons.fastfood_rounded,
                      onTap: () {
                        Navigator.of(context).push(MaterialPageRoute(builder: (context) => const AdminMenuScreen()));
                      },
                    ),
                    const SizedBox(height: 16),
                    _buildTrendyActionCard(
                      context,
                      title: 'Cadeaux',
                      subtitle: 'Définir les récompenses',
                      icon: Icons.card_giftcard_rounded,
                      onTap: () {
                        Navigator.of(context).push(MaterialPageRoute(builder: (context) => const AdminRewardsScreen()));
                      },
                    ),
                    const SizedBox(height: 16),
                    _buildTrendyActionCard(
                      context,
                      title: 'Paramètres',
                      subtitle: 'Nom du Fastfood & Promos',
                      icon: Icons.settings_rounded,
                      onTap: () {
                        Navigator.of(context).push(MaterialPageRoute(builder: (context) => const AdminSettingsScreen()));
                      },
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTrendyStatCard(BuildContext context, {required String title, required String value, required IconData icon, required bool isPrimary}) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isPrimary ? AppTheme.primaryOrange : Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
        border: isPrimary ? null : Border.all(color: Theme.of(context).dividerColor),
        boxShadow: isPrimary ? [
          BoxShadow(
            color: AppTheme.primaryOrange.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          )
        ] : [],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isPrimary ? Colors.white.withOpacity(0.2) : AppTheme.primaryOrange.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: isPrimary ? Colors.white : AppTheme.primaryOrange, size: 24),
          ),
          const SizedBox(height: 20),
          Text(
            value,
            style: Theme.of(context).textTheme.displayLarge?.copyWith(fontSize: 32, color: isPrimary ? Colors.white : null),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: isPrimary ? Colors.white.withOpacity(0.8) : null,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTrendyActionCard(BuildContext context, {required String title, required String subtitle, required IconData icon, required VoidCallback onTap}) {
    return SoftCard(
      onTap: onTap,
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.primaryOrange.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, color: AppTheme.primaryOrange, size: 28),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Theme.of(context).dividerColor.withOpacity(0.5),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.arrow_forward_ios_rounded, color: Theme.of(context).iconTheme.color, size: 16),
          ),
        ],
      ),
    );
  }
}
