import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../theme/app_theme.dart';
import '../../providers/client_providers.dart';

final pendingUsersProvider = StreamProvider<List<ClientUser>>((ref) {
  return FirebaseFirestore.instance
      .collection('users')
      .where('role', isEqualTo: 'client')
      .where('status', isEqualTo: 'pending')
      .snapshots()
      .map((snapshot) {
        final docs = snapshot.docs;
        final users = docs.map((doc) => ClientUser.fromMap(doc.data(), doc.id)).toList();
        // Tri local au lieu de orderBy pour éviter l'erreur d'index Firestore
        users.sort((a, b) => b.id.compareTo(a.id)); // Ou un autre tri si nécessaire, on peut juste laisser par défaut
        return users;
      });
});

class AdminApprovalsScreen extends ConsumerWidget {
  const AdminApprovalsScreen({super.key});

  Future<void> _approveUser(BuildContext context, String uid) async {
    try {
      await FirebaseFirestore.instance.collection('users').doc(uid).update({
        'status': 'active',
      });
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Compte approuvé !', style: TextStyle(color: Colors.white)), backgroundColor: AppTheme.success),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e', style: const TextStyle(color: Colors.white)), backgroundColor: AppTheme.error),
        );
      }
    }
  }

  Future<void> _rejectUser(BuildContext context, String uid) async {
    try {
      // Pour refuser, on supprime simplement le document de la base de données
      await FirebaseFirestore.instance.collection('users').doc(uid).delete();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Compte refusé et supprimé.', style: TextStyle(color: Colors.white)), backgroundColor: Colors.orange),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e', style: const TextStyle(color: Colors.white)), backgroundColor: AppTheme.error),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pendingAsync = ref.watch(pendingUsersProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text('Comptes en attente', style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color)),
      ),
      body: pendingAsync.when(
        data: (users) {
          if (users.isEmpty) {
            return Center(
              child: Text(
                'Aucune demande en attente.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontSize: 16),
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: users.length,
            itemBuilder: (context, index) {
              final user = users[index];
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: SoftCard(
                  padding: EdgeInsets.zero,
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(16),
                    title: Text(
                      user.name,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold, fontSize: 18),
                    ),
                    subtitle: Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Text(
                        'Nouvelle inscription via Email',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          onPressed: () => _rejectUser(context, user.id),
                          icon: const Icon(Icons.close_rounded, color: AppTheme.error),
                          tooltip: 'Refuser',
                          style: IconButton.styleFrom(
                            backgroundColor: AppTheme.error.withOpacity(0.1),
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          onPressed: () => _approveUser(context, user.id),
                          icon: const Icon(Icons.check_rounded, color: AppTheme.success),
                          tooltip: 'Accepter',
                          style: IconButton.styleFrom(
                            backgroundColor: AppTheme.success.withOpacity(0.1),
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
        loading: () => Center(child: CircularProgressIndicator(color: Theme.of(context).primaryColor)),
        error: (e, stack) => Center(child: Text('Erreur: $e', style: const TextStyle(color: AppTheme.error))),
      ),
    );
  }
}