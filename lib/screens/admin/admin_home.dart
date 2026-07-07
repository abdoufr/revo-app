import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/auth_providers.dart';
import '../../providers/admin_providers.dart';
import 'admin_scanner_screen.dart';
import 'admin_menu_screen.dart';
import 'admin_rewards_screen.dart';
import 'admin_settings_screen.dart';

class AdminHome extends ConsumerWidget {
  const AdminHome({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final analyticsAsync = ref.watch(analyticsProvider);

    return Scaffold(
      body: Stack(
        children: [
          // Background Elements
          Positioned(
            top: -100,
            right: -50,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppTheme.accentPurple.withOpacity(0.3),
                boxShadow: [
                  BoxShadow(color: AppTheme.accentPurple.withOpacity(0.3), blurRadius: 100, spreadRadius: 50),
                ],
              ),
            ),
          ),
          SafeArea(
            child: CustomScrollView(
              slivers: [
                SliverAppBar(
                  backgroundColor: Colors.transparent,
                  elevation: 0,
                  pinned: true,
                  title: Text(
                    'DASHBOARD',
                    style: Theme.of(context).textTheme.displayMedium?.copyWith(
                      letterSpacing: 2,
                      fontSize: 20,
                    ),
                  ),
                  actions: [
                    IconButton(
                      icon: const Icon(Icons.logout_rounded, color: Colors.white),
                      onPressed: () {
                        ref.read(authControllerProvider).signOut();
                      },
                    ),
                  ],
                ),
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
                          loading: () => const Center(child: CircularProgressIndicator(color: AppTheme.accentCyan)),
                          error: (err, stack) => Text('Erreur: $err', style: const TextStyle(color: Colors.red)),
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
        ],
      ),
    );
  }

  Widget _buildTrendyStatCard(BuildContext context, {required String title, required String value, required IconData icon, required bool isPrimary}) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: isPrimary ? AppTheme.primaryGradient : null,
        color: isPrimary ? null : AppTheme.bgLighter,
        borderRadius: BorderRadius.circular(24),
        border: isPrimary ? null : Border.all(color: Colors.white.withOpacity(0.05)),
        boxShadow: isPrimary ? [
          BoxShadow(
            color: AppTheme.accentCyan.withOpacity(0.3),
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
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: Colors.white, size: 24),
          ),
          const SizedBox(height: 20),
          Text(
            value,
            style: Theme.of(context).textTheme.displayLarge?.copyWith(fontSize: 32, color: Colors.white),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.white.withOpacity(0.8),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTrendyActionCard(BuildContext context, {required String title, required String subtitle, required IconData icon, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: GlassCard(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: AppTheme.primaryGradient,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(icon, color: Colors.white, size: 28),
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
                color: Colors.white.withOpacity(0.05),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.arrow_forward_ios_rounded, color: AppTheme.textGrey, size: 16),
            ),
          ],
        ),
      ),
    );
  }
}
