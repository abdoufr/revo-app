import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../theme/app_theme.dart';
import '../../providers/auth_providers.dart';
import '../../providers/client_providers.dart';

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

  Color _getVipColor(int points) {
    if (points >= 500) return Colors.amber; // Gold
    if (points >= 200) return Colors.grey.shade300; // Silver
    return AppTheme.accentPurple; // Bronze / Default
  }

  String _getVipTier(int points) {
    if (points >= 500) return 'GOLD';
    if (points >= 200) return 'SILVER';
    return 'BRONZE';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final leaderboardAsync = ref.watch(leaderboardProvider);
    final currentUser = ref.watch(authStateProvider).value;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Top Clients 🏆', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: leaderboardAsync.when(
        data: (users) {
          if (users.isEmpty) {
            return const Center(
              child: Text(
                'Aucun client public pour le moment.',
                style: TextStyle(color: AppTheme.textGrey, fontSize: 16),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(24),
            itemCount: users.length,
            itemBuilder: (context, index) {
              final user = users[index];
              final isMe = currentUser?.uid == user.id;
              final rank = index + 1;
              final vipColor = _getVipColor(user.lifetimePoints);

              return Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: isMe ? AppTheme.primaryGradient : null,
                  color: isMe ? null : AppTheme.bgLighter,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isMe ? AppTheme.accentCyan.withOpacity(0.5) : vipColor.withOpacity(0.3),
                    width: isMe ? 2 : 1,
                  ),
                  boxShadow: isMe ? [
                    BoxShadow(
                      color: AppTheme.accentCyan.withOpacity(0.3),
                      blurRadius: 20,
                      offset: const Offset(0, 5),
                    )
                  ] : null,
                ),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: rank <= 3 ? vipColor.withOpacity(0.2) : Colors.white.withOpacity(0.05),
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        '#$rank',
                        style: TextStyle(
                          color: rank <= 3 ? vipColor : Colors.white,
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
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Membre ${_getVipTier(user.lifetimePoints)}',
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
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 22,
                          ),
                        ),
                        const Text(
                          'pts à vie',
                          style: TextStyle(color: AppTheme.textGrey, fontSize: 10),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator(color: AppTheme.accentCyan)),
        error: (error, stack) => Center(child: Text('Erreur: $error', style: const TextStyle(color: AppTheme.error))),
      ),
    );
  }
}
