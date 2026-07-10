import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../theme/app_theme.dart';
import '../../providers/client_providers.dart';
import '../../providers/auth_providers.dart';
import '../../providers/admin_providers.dart';
import '../../providers/settings_provider.dart';
import 'client_history_screen.dart';
import 'client_leaderboard_screen.dart';
import 'client_settings_screen.dart';
import '../../l10n/app_translations.dart';
import 'loyalty_cards.dart';
import 'dart:convert';

class ClientHome extends ConsumerWidget {
  const ClientHome({super.key});

  Color _getVipColor(int points) {
    if (points >= 500) return Colors.amber; // Gold
    if (points >= 200) return Colors.grey.shade400; // Silver
    return AppTheme.primaryOrange; // Bronze / Default
  }

  String _getVipTier(int points, BuildContext context) {
    if (points >= 500) return 'GOLD ${'member'.tr(context)}';
    if (points >= 200) return 'SILVER ${'member'.tr(context)}';
    return 'BASIC ${'member'.tr(context)}';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(clientUserProvider);
    final rewardConfigAsync = ref.watch(rewardConfigProvider);
    final productsAsync = ref.watch(productsStreamProvider);
    final settingsAsync = ref.watch(appSettingsProvider);
    
    // Pre-loading pour un affichage instantané des nouvelles pages
    ref.watch(clientHistoryProvider);
    ref.watch(leaderboardProvider);

    return Scaffold(
      appBar: AppBar(
        title: settingsAsync.when(
          data: (settings) => Text(
            settings.fastfoodName.toUpperCase(),
            style: Theme.of(context).textTheme.displayMedium?.copyWith(
              letterSpacing: 1,
              fontSize: 22,
            ),
          ),
          loading: () => Text('loading'.tr(context)),
          error: (_, __) => const Text('REVO APP'),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.settings_rounded, color: Theme.of(context).iconTheme.color),
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ClientSettingsScreen())),
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
                    settingsAsync.whenData((settings) {
                      if (settings.announcementBanner.isNotEmpty) {
                        return Container(
                          margin: const EdgeInsets.only(bottom: 24),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryOrangeLight.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: AppTheme.primaryOrangeLight),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.campaign_rounded, color: AppTheme.primaryOrange),
                              const SizedBox(width: 12),
                              Expanded(child: Text(settings.announcementBanner, style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color, fontWeight: FontWeight.bold))),
                            ],
                          ),
                        );
                      }
                      return const SizedBox();
                    }).value ?? const SizedBox(),

                    userAsync.when(
                      data: (user) {
                        if (user == null) return const Text('Utilisateur introuvable');
                        
                        return rewardConfigAsync.when(
                          data: (config) {
                            int userPoints = user.loyaltyPoints;
                            int lifetimePoints = user.lifetimePoints;
                            int pointsForReward = config.pointsRequiredForReward;
                            double progress = pointsForReward > 0 ? userPoints / pointsForReward : 0;
                            if (progress > 1.0) progress = 1.0;
                            
                            final vipColor = _getVipColor(lifetimePoints);
                            final isDark = Theme.of(context).brightness == Brightness.dark;

                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${'hello'.tr(context)} ${user.name},',
                                  style: Theme.of(context).textTheme.displayLarge?.copyWith(fontSize: 28),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'loyalty_card'.tr(context),
                                  style: Theme.of(context).textTheme.bodyMedium,
                                ),
                                const SizedBox(height: 32),

                                // New Swipeable Cards
                                LoyaltyCardsCarousel(
                                  user: user,
                                  config: config,
                                  vipColor: vipColor,
                                  lifetimePoints: lifetimePoints,
                                  vipTierName: _getVipTier(lifetimePoints, context),
                                ),
                              ],
                            );
                          },
                          loading: () => const Center(child: CircularProgressIndicator(color: AppTheme.primaryOrange)),
                          error: (err, stack) => Text('error_config'.tr(context), style: const TextStyle(color: AppTheme.error)),
                        );
                      },
                      loading: () => const Center(child: CircularProgressIndicator(color: AppTheme.primaryOrange)),
                      error: (err, stack) => Text('error_user'.tr(context), style: const TextStyle(color: AppTheme.error)),
                    ),

                    const SizedBox(height: 32),
                    
                    // Client Actions
                    Row(
                      children: [
                        Expanded(
                          child: _buildActionCard(
                            context,
                            icon: Icons.history_rounded,
                            title: 'history'.tr(context),
                            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ClientHistoryScreen())),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildActionCard(
                            context,
                            icon: Icons.leaderboard_rounded,
                            title: 'top_clients'.tr(context),
                            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ClientLeaderboardScreen())),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 48),                        
                    // Menu Header
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'our_menu'.tr(context),
                          style: Theme.of(context).textTheme.displayMedium?.copyWith(fontSize: 22),
                        ),
                        Icon(Icons.restaurant_menu, color: Theme.of(context).primaryColor),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Soft Menu List
                    productsAsync.when(
                      data: (products) {
                        if (products.isEmpty) {
                          return Center(child: Text('empty_menu'.tr(context), style: Theme.of(context).textTheme.bodyMedium));
                        }
                        return ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: products.length,
                          itemBuilder: (context, index) {
                            final product = products[index];
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 16),
                              child: SoftCard(
                                padding: EdgeInsets.zero,
                                child: ListTile(
                                  contentPadding: const EdgeInsets.all(16),
                                  leading: Container(
                                    width: 60,
                                    height: 60,
                                    decoration: BoxDecoration(
                                      color: AppTheme.primaryOrange.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    child: product.imageUrl != null && product.imageUrl!.startsWith('data:image')
                                        ? ClipRRect(
                                            borderRadius: BorderRadius.circular(16),
                                            child: Image.memory(
                                              base64Decode(product.imageUrl!.split(',').last),
                                              fit: BoxFit.cover,
                                            ),
                                          )
                                        : const Icon(Icons.fastfood, color: AppTheme.primaryOrange),
                                  ),
                                  title: Text(
                                    product.name,
                                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w700),
                                  ),
                                  subtitle: Padding(
                                    padding: const EdgeInsets.only(top: 8.0),
                                    child: Text(
                                      product.description,
                                      style: Theme.of(context).textTheme.bodyMedium,
                                    ),
                                  ),
                                  trailing: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        '${product.price} DA',
                                        style: const TextStyle(
                                          color: AppTheme.primaryOrange,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        );
                      },
                      loading: () => const Center(child: CircularProgressIndicator(color: AppTheme.primaryOrange)),
                      error: (err, stack) => const Text('Erreur chargement menu', style: TextStyle(color: AppTheme.error)),
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

  Widget _buildActionCard(BuildContext context, {required IconData icon, required String title, required VoidCallback onTap}) {
    return SoftCard(
      onTap: onTap,
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 8),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.primaryOrange.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: AppTheme.primaryOrange, size: 28),
          ),
          const SizedBox(height: 12),
          Text(
            title,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontSize: 14, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}
