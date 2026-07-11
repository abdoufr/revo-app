import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../theme/app_theme.dart';
import '../../providers/auth_providers.dart';

final clientHistoryProvider = StreamProvider<List<Map<String, dynamic>>>((ref) {
  final user = ref.watch(authStateProvider).value;
  if (user == null) return const Stream.empty();

  return FirebaseFirestore.instance
      .collection('transactions')
      .where('user_id', isEqualTo: user.uid)
      .snapshots()
      .map((snapshot) {
        final docs = snapshot.docs.map((doc) => doc.data()).toList();
        docs.sort((a, b) {
          final dateA = a['date'] as Timestamp?;
          final dateB = b['date'] as Timestamp?;
          if (dateA == null && dateB == null) return 0;
          if (dateA == null) return 1;
          if (dateB == null) return -1;
          return dateB.compareTo(dateA); // descending
        });
        return docs;
      });
});

class ClientHistoryScreen extends ConsumerWidget {
  const ClientHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final historyAsync = ref.watch(clientHistoryProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text('Mon Historique', style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color, fontWeight: FontWeight.bold)),
      ),
      body: historyAsync.when(
        data: (transactions) {
          if (transactions.isEmpty) {
            return Center(
              child: Text(
                'Aucune transaction pour le moment.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(24),
            itemCount: transactions.length,
            itemBuilder: (context, index) {
              final tx = transactions[index];
              final isEarn = tx['type'] == 'earn';
              final points = isEarn ? (tx['points_earned'] ?? 0) : (tx['points_deducted'] ?? 0);
              final date = tx['date'] != null ? (tx['date'] as Timestamp).toDate() : DateTime.now();

              return Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: SoftCard(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isEarn ? AppTheme.success.withOpacity(0.1) : AppTheme.error.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          isEarn ? Icons.add_rounded : Icons.card_giftcard_rounded,
                          color: isEarn ? AppTheme.success : AppTheme.error,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              isEarn ? 'Points Gagnés' : 'Cadeau Réclamé',
                              style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year} à ${date.hour.toString().padLeft(2, '0')}h${date.minute.toString().padLeft(2, '0')}',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ),
                      Text(
                        isEarn ? '+$points' : '-$points',
                        style: TextStyle(
                          color: isEarn ? AppTheme.success : AppTheme.error,
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
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