import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../theme/app_theme.dart';
import '../../providers/client_providers.dart';
import '../../providers/auth_providers.dart';
import '../../providers/admin_providers.dart';

class ClientHome extends ConsumerWidget {
  const ClientHome({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(clientUserProvider);
    final rewardConfigAsync = ref.watch(rewardConfigProvider);
    final productsAsync = ref.watch(productsStreamProvider);

    return Scaffold(
      body: Stack(
        children: [
          // Trendy background elements
          Positioned(
            top: -150,
            left: -50,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppTheme.accentCyan.withOpacity(0.3),
                boxShadow: [
                  BoxShadow(color: AppTheme.accentCyan.withOpacity(0.3), blurRadius: 100, spreadRadius: 50),
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
                    'REVO',
                    style: Theme.of(context).textTheme.displayMedium?.copyWith(
                      letterSpacing: 2,
                    ),
                  ),
                  actions: [
                    IconButton(
                      icon: const Icon(Icons.notifications_outlined, color: Colors.white),
                      onPressed: () {},
                    ),
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
                        userAsync.when(
                          data: (user) {
                            if (user == null) return const Text('Utilisateur introuvable', style: TextStyle(color: Colors.white));
                            
                            return rewardConfigAsync.when(
                              data: (config) {
                                int userPoints = user.loyaltyPoints;
                                int pointsForReward = config.pointsRequiredForReward;
                                double progress = pointsForReward > 0 ? userPoints / pointsForReward : 0;
                                if (progress > 1.0) progress = 1.0;
                                
                                return Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Mrehba ${user.name},',
                                      style: Theme.of(context).textTheme.displayLarge?.copyWith(fontSize: 32),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'Voici ta carte de fidélité numérique.',
                                      style: Theme.of(context).textTheme.bodyMedium,
                                    ),
                                    const SizedBox(height: 32),

                                    // Trendy Loyalty Card
                                    Container(
                                      decoration: BoxDecoration(
                                        gradient: AppTheme.primaryGradient,
                                        borderRadius: BorderRadius.circular(30),
                                        boxShadow: [
                                          BoxShadow(
                                            color: AppTheme.accentPurple.withOpacity(0.4),
                                            blurRadius: 30,
                                            offset: const Offset(0, 10),
                                          ),
                                        ],
                                      ),
                                      child: Stack(
                                        children: [
                                          // Glass effect over gradient
                                          Positioned.fill(
                                            child: Container(
                                              decoration: BoxDecoration(
                                                borderRadius: BorderRadius.circular(30),
                                                color: Colors.white.withOpacity(0.1),
                                                border: Border.all(color: Colors.white.withOpacity(0.2)),
                                              ),
                                            ),
                                          ),
                                          Padding(
                                            padding: const EdgeInsets.all(32.0),
                                            child: Column(
                                              children: [
                                                // QR Code Container
                                                Container(
                                                  padding: const EdgeInsets.all(16),
                                                  decoration: BoxDecoration(
                                                    color: Colors.white,
                                                    borderRadius: BorderRadius.circular(20),
                                                    boxShadow: [
                                                      BoxShadow(
                                                        color: Colors.black.withOpacity(0.2),
                                                        blurRadius: 20,
                                                        spreadRadius: -5,
                                                      ),
                                                    ],
                                                  ),
                                                  child: QrImageView(
                                                    data: user.id,
                                                    version: QrVersions.auto,
                                                    size: 160.0,
                                                  ),
                                                ),
                                                const SizedBox(height: 32),
                                                Row(
                                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                  children: [
                                                    Text(
                                                      'Points Cumulés',
                                                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                                        color: Colors.white.withOpacity(0.9),
                                                      ),
                                                    ),
                                                    Text(
                                                      '$userPoints / $pointsForReward',
                                                      style: Theme.of(context).textTheme.displayMedium?.copyWith(
                                                        fontSize: 20,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                                const SizedBox(height: 16),
                                                ClipRRect(
                                                  borderRadius: BorderRadius.circular(10),
                                                  child: LinearProgressIndicator(
                                                    value: progress,
                                                    backgroundColor: Colors.white.withOpacity(0.2),
                                                    valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                                                    minHeight: 12,
                                                  ),
                                                ),
                                                const SizedBox(height: 16),
                                                Text(
                                                  userPoints >= pointsForReward 
                                                    ? '🎉 Félicitations! Tu as gagné: ${config.rewardDescription}'
                                                    : 'Encore ${pointsForReward - userPoints} pts pour une surprise!',
                                                  style: const TextStyle(
                                                    color: Colors.white,
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                );
                              },
                              loading: () => const Center(child: CircularProgressIndicator(color: AppTheme.accentCyan)),
                              error: (err, stack) => const Text('Erreur config', style: TextStyle(color: Colors.red)),
                            );
                          },
                          loading: () => const Center(child: CircularProgressIndicator(color: AppTheme.accentCyan)),
                          error: (err, stack) => const Text('Erreur utilisateur', style: TextStyle(color: Colors.red)),
                        ),

                        const SizedBox(height: 48),

                        // Menu Header
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Notre Menu',
                              style: Theme.of(context).textTheme.displayMedium?.copyWith(fontSize: 24),
                            ),
                            const Icon(Icons.restaurant_menu, color: AppTheme.textGrey),
                          ],
                        ),
                        const SizedBox(height: 24),

                        // Trendy Menu List
                        productsAsync.when(
                          data: (products) {
                            if (products.isEmpty) {
                              return const Center(child: Text('Le menu est vide pour le moment.', style: TextStyle(color: AppTheme.textGrey)));
                            }
                            return ListView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: products.length,
                              itemBuilder: (context, index) {
                                final product = products[index];
                                return Container(
                                  margin: const EdgeInsets.only(bottom: 16),
                                  decoration: BoxDecoration(
                                    color: AppTheme.bgLighter,
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(color: Colors.white.withOpacity(0.05)),
                                  ),
                                  child: ListTile(
                                    contentPadding: const EdgeInsets.all(16),
                                    leading: Container(
                                      width: 60,
                                      height: 60,
                                      decoration: BoxDecoration(
                                        gradient: AppTheme.primaryGradient,
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                      child: const Icon(Icons.coffee_rounded, color: Colors.white),
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
                                            color: AppTheme.accentCyan,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            );
                          },
                          loading: () => const Center(child: CircularProgressIndicator(color: AppTheme.accentCyan)),
                          error: (err, stack) => const Text('Erreur chargement menu', style: TextStyle(color: Colors.red)),
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
}
