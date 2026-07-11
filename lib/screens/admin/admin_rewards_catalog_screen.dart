import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../theme/app_theme.dart';
import '../../providers/reward_catalog_provider.dart';

class AdminRewardsCatalogScreen extends ConsumerWidget {
  const AdminRewardsCatalogScreen({super.key});

  void _showAddRewardDialog(BuildContext context, WidgetRef ref) {
    final nameController = TextEditingController();
    final costController = TextEditingController();
    String? base64Image;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              backgroundColor: Theme.of(context).colorScheme.surface,
              title: Text('Nouveau Cadeau', style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color)),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    GestureDetector(
                      onTap: () async {
                        try {
                          final picker = ImagePicker();
                          final pickedFile = await picker.pickImage(source: ImageSource.gallery, maxWidth: 400, imageQuality: 85);
                          if (pickedFile != null) {
                            final bytes = await pickedFile.readAsBytes();
                            final base64String = 'data:image/jpeg;base64,${base64Encode(bytes)}';
                            setState(() {
                              base64Image = base64String;
                            });
                          }
                        } catch (e) {
                          // Ignore
                        }
                      },
                      child: Container(
                        height: 120,
                        width: 120,
                        decoration: BoxDecoration(
                          color: Theme.of(context).primaryColor.withOpacity(0.1),
                          shape: BoxShape.circle,
                          border: Border.all(color: Theme.of(context).primaryColor),
                        ),
                        child: base64Image != null && base64Image!.startsWith('data:image')
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(60),
                                child: Image.memory(
                                  base64Decode(base64Image!.split(',').last),
                                  fit: BoxFit.cover,
                                ),
                              )
                            : Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.add_photo_alternate_rounded, color: Theme.of(context).primaryColor, size: 30),
                                  const SizedBox(height: 4),
                                  Text('Image', style: TextStyle(color: Theme.of(context).primaryColor, fontSize: 12)),
                                ],
                              ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    TextField(
                      controller: nameController,
                      decoration: const InputDecoration(labelText: 'Nom du cadeau (ex: Boisson)'),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: costController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Coût en points (ex: 50)'),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text('Annuler', style: Theme.of(context).textTheme.bodyMedium),
                ),
                ElevatedButton(
                  onPressed: () {
                    final cost = int.tryParse(costController.text.trim()) ?? 0;
                    if (base64Image != null && nameController.text.isNotEmpty && cost > 0) {
                      ref.read(rewardCatalogActionsProvider).addRewardItem(nameController.text.trim(), cost, base64Image!);
                      Navigator.pop(context);
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Veuillez remplir tous les champs correctement.'), backgroundColor: AppTheme.error),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: Theme.of(context).primaryColor),
                  child: const Text('Ajouter', style: TextStyle(color: Colors.white)),
                ),
              ],
            );
          }
        );
      },
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final catalogAsync = ref.watch(rewardCatalogProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text('Boutique de Cadeaux', style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color)),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddRewardDialog(context, ref),
        backgroundColor: Theme.of(context).primaryColor,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Ajouter Cadeau', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      body: catalogAsync.when(
        data: (items) {
          if (items.isEmpty) {
            return Center(child: Text('Aucun cadeau dans la boutique.', style: Theme.of(context).textTheme.bodyMedium));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: items.length,
            itemBuilder: (context, index) {
              final item = items[index];
              return Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: SoftCard(
                  padding: const EdgeInsets.all(12),
                  child: ListTile(
                    leading: Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        image: DecorationImage(
                          image: MemoryImage(base64Decode(item.imageUrl.split(',').last)),
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    title: Text(item.name, style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold)),
                    subtitle: Text('${item.pointsCost} points', style: TextStyle(color: Theme.of(context).primaryColor, fontWeight: FontWeight.bold)),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete_outline, color: AppTheme.error),
                      onPressed: () {
                        ref.read(rewardCatalogActionsProvider).deleteRewardItem(item.id);
                      },
                    ),
                  ),
                ),
              );
            },
          );
        },
        loading: () => Center(child: CircularProgressIndicator(color: Theme.of(context).primaryColor)),
        error: (err, stack) => Center(child: Text('Erreur: $err', style: const TextStyle(color: AppTheme.error))),
      ),
    );
  }
}