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
          const SnackBar(content: Text('Compte approuvé !', style: TextStyle(color: Colors.white)), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e', style: const TextStyle(color: Colors.white)), backgroundColor: Colors.red),
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
          SnackBar(content: Text('Erreur: $e', style: const TextStyle(color: Colors.white)), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pendingAsync = ref.watch(pendingUsersProvider);

    return Scaffold(
      backgroundColor: AppTheme.bgDark,
      appBar: AppBar(
        title: const Text('Comptes en attente', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: pendingAsync.when(
        data: (users) {
          if (users.isEmpty) {
            return const Center(
              child: Text(
                'Aucune demande en attente.',
                style: TextStyle(color: AppTheme.textGrey, fontSize: 16),
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: users.length,
            itemBuilder: (context, index) {
              final user = users[index];
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: AppTheme.bgLighter,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppTheme.accentPurple.withValues(alpha: 0.3)),
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.all(16),
                  title: Text(
                    user.name,
                    style: const TextStyle(color: AppTheme.textWhite, fontWeight: FontWeight.bold, fontSize: 18),
                  ),
                  subtitle: const Padding(
                    padding: EdgeInsets.only(top: 8.0),
                    child: Text(
                      'Nouvelle inscription via Email',
                      style: TextStyle(color: AppTheme.textGrey),
                    ),
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        onPressed: () => _rejectUser(context, user.id),
                        icon: const Icon(Icons.close_rounded, color: Colors.red),
                        tooltip: 'Refuser',
                        style: IconButton.styleFrom(
                          backgroundColor: Colors.red.withValues(alpha: 0.1),
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        onPressed: () => _approveUser(context, user.id),
                        icon: const Icon(Icons.check_rounded, color: Colors.green),
                        tooltip: 'Accepter',
                        style: IconButton.styleFrom(
                          backgroundColor: Colors.green.withValues(alpha: 0.1),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator(color: AppTheme.accentPurple)),
        error: (e, stack) => Center(child: Text('Erreur: $e', style: const TextStyle(color: Colors.red))),
      ),
    );
  }
}
