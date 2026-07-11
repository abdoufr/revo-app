import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../theme/app_theme.dart';
import '../../providers/analytics_provider.dart';

class AdminAnalyticsScreen extends ConsumerWidget {
  const AdminAnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final analyticsAsync = ref.watch(advancedAnalyticsProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text('Tableau de Bord', style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color)),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: AppTheme.primaryRed),
            onPressed: () => ref.refresh(advancedAnalyticsProvider),
          ),
        ],
      ),
      body: analyticsAsync.when(
        data: (data) {
          return RefreshIndicator(
            onRefresh: () async => ref.refresh(advancedAnalyticsProvider),
            color: AppTheme.primaryRed,
            child: ListView(
              padding: const EdgeInsets.all(24),
              children: [
                _buildStatCard(
                  context,
                  title: 'Utilisateurs Inscrits',
                  value: '${data.totalUsers}',
                  icon: Icons.people_alt_rounded,
                  color: Colors.blueAccent,
                ),
                const SizedBox(height: 16),
                _buildStatCard(
                  context,
                  title: 'Points Distribués (Total)',
                  value: '${data.totalPointsDistributed}',
                  icon: Icons.stars_rounded,
                  color: AppTheme.primaryRed,
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _buildStatCard(
                        context,
                        title: 'Points en circulation',
                        value: '${data.totalPointsAvailable}',
                        icon: Icons.account_balance_wallet_rounded,
                        color: Colors.green,
                        small: true,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildStatCard(
                        context,
                        title: 'Moyenne / Utilisateur',
                        value: '${data.averagePointsPerUser.toStringAsFixed(1)}',
                        icon: Icons.analytics_rounded,
                        color: Colors.purple,
                        small: true,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _buildStatCard(
                  context,
                  title: 'Avis Clients Laissés',
                  value: '${data.totalReviews}',
                  icon: Icons.reviews_rounded,
                  color: Colors.amber,
                ),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator(color: AppTheme.primaryRed)),
        error: (e, s) => Center(child: Text('Erreur: $e', style: const TextStyle(color: AppTheme.error))),
      ),
    );
  }

  Widget _buildStatCard(BuildContext context, {required String title, required String value, required IconData icon, required Color color, bool small = false}) {
    return SoftCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: small ? 24 : 32),
              ),
              const SizedBox(width: 16),
              Expanded(child: Text(title, style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600))),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            value,
            style: Theme.of(context).textTheme.displayMedium?.copyWith(
              color: color,
              fontSize: small ? 28 : 36,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
