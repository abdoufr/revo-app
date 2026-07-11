import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../theme/app_theme.dart';
import '../../providers/auth_providers.dart';
import '../../providers/client_providers.dart';
import '../../services/vip_tier_service.dart';

final leaderboardProvider = StreamProvider<List<ClientUser>>((ref) {
  return FirebaseFirestore.instance
      .collection('users')
      .where('role', isEqualTo: 'client')
      .where('is_public', isEqualTo: true)
      .snapshots()
      .map((snapshot) {
        final users = snapshot.docs.map((doc) => ClientUser.fromMap(doc.data(), doc.id)).toList();
        users.sort((a, b) => b.lifetimePoints.compareTo(a.lifetimePoints));
        return users.take(10).toList();
      });
});

class ClientLeaderboardScreen extends ConsumerWidget {
  const ClientLeaderboardScreen({super.key});



  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final leaderboardAsync = ref.watch(leaderboardProvider);
    final currentUser = ref.watch(authStateProvider).value;

    return Scaffold(
      appBar: AppBar(
        title: Text('Top Clients 🏆', style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color, fontWeight: FontWeight.bold)),
      ),
      body: leaderboardAsync.when(
        data: (users) {
          if (users.isEmpty) {
            return Center(
              child: Text(
                'Aucun client public pour le moment.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(24),
            itemCount: users.length,
            itemBuilder: (context, index) {
              final user = users[index];
              final isMe = currentUser != null && user.id == currentUser.uid;
              final rank = index + 1;
              final vipColor = VipTierService.getTierColor(user.lifetimePoints);

              return Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: SoftCard(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: rank <= 3 ? vipColor.withOpacity(0.2) : Theme.of(context).dividerColor.withOpacity(0.2),
                          shape: BoxShape.circle,
                        ),
                        child: Text(
                          '#$rank',
                          style: TextStyle(
                            color: rank <= 3 ? vipColor : Theme.of(context).textTheme.bodyLarge?.color,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              isMe ? 'Moi (${user.name})' : user.name,
                              style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold, fontSize: 18, color: isMe ? Theme.of(context).primaryColor : null),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              VipTierService.getTierName(user.lifetimePoints),
                              style: TextStyle(color: vipColor, fontSize: 12, fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            '${user.lifetimePoints}',
                            style: Theme.of(context).textTheme.displayLarge?.copyWith(
                              fontSize: 22,
                            ),
                          ),
                          Text(
                            'pts à vie',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
        loading: () => Center(child: CircularProgressIndicator(color: Theme.of(context).primaryColor)),
        error: (error, stack) => Center(child: Text('Erreur: $error', style: const TextStyle(color: AppTheme.error))),
      ),
    );
  }
}