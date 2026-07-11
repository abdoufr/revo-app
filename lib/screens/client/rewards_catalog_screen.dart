import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../theme/app_theme.dart';
import '../../providers/reward_catalog_provider.dart';
import '../../providers/client_providers.dart';
import '../../providers/auth_providers.dart';

class RewardsCatalogScreen extends ConsumerWidget {
  const RewardsCatalogScreen({super.key});

  void _claimReward(BuildContext context, WidgetRef ref, RewardItem item, int userPoints) async {
    if (userPoints < item.pointsCost) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Vous n\'avez pas assez de points pour ce cadeau.'), backgroundColor: AppTheme.error),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Theme.of(context).colorScheme.surface,
        title: const Text('Confirmer l\'échange'),
        content: Text('Voulez-vous échanger ${item.pointsCost} points contre "${item.name}" ?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Annuler')),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final authUser = ref.read(authStateProvider).value;
              if (authUser != null) {
                await ref.read(clientActionsProvider).deductPoints(authUser.uid, item.pointsCost);
              }
              if (context.mounted) {
                showDialog(
                  context: context,
                  builder: (_) => AlertDialog(
                    backgroundColor: Theme.of(context).colorScheme.surface,
                    title: const Text('Félicitations ! 🎉', style: TextStyle(color: AppTheme.success)),
                    content: Text('Vous avez obtenu "${item.name}" !\n\nPrésentez cet écran à la caisse pour récupérer votre cadeau.'),
                    actions: [
                      ElevatedButton(
                        onPressed: () => Navigator.pop(context),
                        style: ElevatedButton.styleFrom(backgroundColor: AppTheme.success),
                        child: const Text('OK', style: TextStyle(color: Colors.white)),
                      ),
                    ],
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryOrange),
            child: const Text('Échanger', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final catalogAsync = ref.watch(rewardCatalogProvider);
    final userAsync = ref.watch(clientUserProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text('Boutique de Cadeaux', style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color)),
      ),
      body: userAsync.when(
        data: (user) {
          if (user == null) return const Center(child: Text('Erreur utilisateur'));

          return Column(
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                width: double.infinity,
                decoration: BoxDecoration(
                  color: AppTheme.primaryOrange.withOpacity(0.1),
                  border: const Border(bottom: BorderSide(color: AppTheme.primaryOrange, width: 2)),
                ),
                child: Column(
                  children: [
                    const Text('Vos points disponibles', style: TextStyle(fontSize: 16)),
                    const SizedBox(height: 8),
                    Text(
                      '${user.loyaltyPoints}',
                      style: const TextStyle(fontSize: 36, fontWeight: FontWeight.bold, color: AppTheme.primaryOrange),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: catalogAsync.when(
                  data: (items) {
                    if (items.isEmpty) {
                      return const Center(child: Text('La boutique est vide pour le moment.'));
                    }

                    return GridView.builder(
                      padding: const EdgeInsets.all(16),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                        childAspectRatio: 0.8,
                      ),
                      itemCount: items.length,
                      itemBuilder: (context, index) {
                        final item = items[index];
                        final canAfford = user.loyaltyPoints >= item.pointsCost;

                        return SoftCard(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Expanded(
                                child: Container(
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    image: DecorationImage(
                                      image: MemoryImage(base64Decode(item.imageUrl.split(',').last)),
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                item.name,
                                textAlign: TextAlign.center,
                                style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 8),
                              ElevatedButton(
                                onPressed: () => _claimReward(context, ref, item, user.loyaltyPoints),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: canAfford ? AppTheme.primaryOrange : Colors.grey,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                ),
                                child: Text(
                                  '${item.pointsCost} pts',
                                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    );
                  },
                  loading: () => const Center(child: CircularProgressIndicator(color: AppTheme.primaryOrange)),
                  error: (e, s) => Center(child: Text('Erreur: $e')),
                ),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator(color: AppTheme.primaryOrange)),
        error: (e, s) => Center(child: Text('Erreur: $e')),
      ),
    );
  }
}
