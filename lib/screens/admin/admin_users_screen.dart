import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../theme/app_theme.dart';
import '../../providers/admin_providers.dart';
import '../../providers/client_providers.dart';

class AdminUsersScreen extends ConsumerStatefulWidget {
  const AdminUsersScreen({super.key});

  @override
  ConsumerState<AdminUsersScreen> createState() => _AdminUsersScreenState();
}

class _AdminUsersScreenState extends ConsumerState<AdminUsersScreen> {
  String _searchQuery = '';

  void _confirmDelete(BuildContext context, ClientUser user) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Theme.of(context).colorScheme.surface,
        title: Text('Supprimer ${user.name} ?', style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color)),
        content: const Text('Cette action est irréversible et supprimera toutes les données de ce client.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Annuler', style: Theme.of(context).textTheme.bodyMedium),
          ),
          ElevatedButton(
            onPressed: () {
              ref.read(adminActionsProvider).deleteClient(user.id);
              Navigator.pop(ctx);
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.error),
            child: const Text('Supprimer', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _confirmReset(BuildContext context, ClientUser user) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Theme.of(context).colorScheme.surface,
        title: Text('Réinitialiser les points ?', style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color)),
        content: Text('Voulez-vous remettre les points de ${user.name} à zéro ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Annuler', style: Theme.of(context).textTheme.bodyMedium),
          ),
          ElevatedButton(
            onPressed: () {
              ref.read(adminActionsProvider).resetClientPoints(user.id);
              Navigator.pop(ctx);
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryOrange),
            child: const Text('Réinitialiser', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final clientsAsync = ref.watch(allClientsStreamProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text('Clients & Utilisateurs', style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color)),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              onChanged: (val) {
                setState(() {
                  _searchQuery = val;
                });
              },
              decoration: InputDecoration(
                hintText: 'Rechercher un client (nom, tél...)',
                prefixIcon: const Icon(Icons.search, color: AppTheme.primaryOrange),
                filled: true,
                fillColor: Theme.of(context).cardColor,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ),
          Expanded(
            child: clientsAsync.when(
              data: (clients) {
                final filteredClients = clients.where((c) {
                  final q = _searchQuery.toLowerCase();
                  return c.name.toLowerCase().contains(q) || 
                         (c.phone != null && c.phone!.toLowerCase().contains(q)) ||
                         (c.email != null && c.email!.toLowerCase().contains(q));
                }).toList();

                if (filteredClients.isEmpty) {
                  return Center(
                    child: Text('Aucun client trouvé.', style: Theme.of(context).textTheme.bodyMedium),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  itemCount: filteredClients.length,
                  itemBuilder: (context, index) {
                    final client = filteredClients[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: SoftCard(
                        padding: EdgeInsets.zero,
                        child: ExpansionTile(
                          iconColor: AppTheme.primaryOrange,
                          collapsedIconColor: Theme.of(context).iconTheme.color,
                          title: Text(
                            client.name,
                            style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text(
                            client.phone ?? client.email ?? 'Aucun contact',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                          leading: CircleAvatar(
                            backgroundColor: AppTheme.primaryOrange.withOpacity(0.2),
                            child: const Icon(Icons.person, color: AppTheme.primaryOrange),
                          ),
                          children: [
                            Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                children: [
                                  Column(
                                    children: [
                                      Text('${client.loyaltyPoints}', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.primaryOrange)),
                                      const Text('Points Actuels', style: TextStyle(fontSize: 12)),
                                    ],
                                  ),
                                  Column(
                                    children: [
                                      Text('${client.lifetimePoints}', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.grey)),
                                      const Text('Points à Vie', style: TextStyle(fontSize: 12)),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            ButtonBar(
                              alignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                TextButton.icon(
                                  onPressed: () => _confirmReset(context, client),
                                  icon: const Icon(Icons.refresh, color: AppTheme.primaryOrange),
                                  label: const Text('Zéro points', style: TextStyle(color: AppTheme.primaryOrange)),
                                ),
                                TextButton.icon(
                                  onPressed: () => _confirmDelete(context, client),
                                  icon: const Icon(Icons.delete_forever, color: AppTheme.error),
                                  label: const Text('Supprimer', style: TextStyle(color: AppTheme.error)),
                                ),
                              ],
                            )
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator(color: AppTheme.primaryOrange)),
              error: (err, stack) => Center(child: Text('Erreur: $err', style: const TextStyle(color: AppTheme.error))),
            ),
          ),
        ],
      ),
    );
  }
}
