import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../../theme/app_theme.dart';

final adminHistoryProvider = StreamProvider<List<Map<String, dynamic>>>((ref) {
  return FirebaseFirestore.instance
      .collection('transactions')
      .orderBy('date', descending: true)
      .limit(100)
      .snapshots()
      .map((snapshot) {
    return snapshot.docs
        .where((doc) => doc.data()['type'] == 'earn')
        .map((doc) => {'id': doc.id, ...doc.data()})
        .toList();
  });
});

class AdminHistoryScreen extends ConsumerWidget {
  const AdminHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final historyAsync = ref.watch(adminHistoryProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text('Historique des Points', style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color)),
      ),
      body: historyAsync.when(
        data: (history) {
          if (history.isEmpty) {
            return Center(child: Text('Aucun historique récent.', style: Theme.of(context).textTheme.bodyMedium));
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: history.length,
            separatorBuilder: (context, index) => const Divider(),
            itemBuilder: (context, index) {
              final tx = history[index];
              final date = tx['date'] != null ? (tx['date'] as Timestamp).toDate() : DateTime.now();
              final formattedDate = DateFormat('dd/MM/yyyy HH:mm').format(date);
              final points = tx['points_earned'] ?? 0;
              final amount = tx['amount_spent'] ?? 0;
              final clientName = tx['client_name'] ?? 'Client Inconnu';
              final adminName = tx['admin_name'] ?? 'Admin';

              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: AppTheme.success.withValues(alpha: 0.2),
                  child: const Icon(Icons.add_circle_outline, color: AppTheme.success),
                ),
                title: Text('+$points pts à $clientName', style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text('Dépense: $amount DA\nPar: $adminName\nLe $formattedDate'),
                isThreeLine: true,
              );
            },
          );
        },
        loading: () => Center(child: CircularProgressIndicator(color: Theme.of(context).primaryColor)),
        error: (e, s) => Center(child: Text('Erreur: $e', style: const TextStyle(color: AppTheme.error))),
      ),
    );
  }
}
