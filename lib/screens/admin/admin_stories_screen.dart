import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import '../../theme/app_theme.dart';
import '../../providers/story_provider.dart';

class AdminStoriesScreen extends ConsumerWidget {
  const AdminStoriesScreen({super.key});

  void _showAddStoryDialog(BuildContext context, WidgetRef ref) {
    final titleController = TextEditingController();
    String? base64Image;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              backgroundColor: Theme.of(context).colorScheme.surface,
              title: Text('Nouvelle Story', style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color)),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    GestureDetector(
                      onTap: () async {
                        try {
                          final picker = ImagePicker();
                          final pickedFile = await picker.pickImage(source: ImageSource.gallery, maxWidth: 800, imageQuality: 85);
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
                        height: 200,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: AppTheme.primaryOrange.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppTheme.primaryOrange),
                        ),
                        child: base64Image != null && base64Image!.startsWith('data:image')
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(16),
                                child: Image.memory(
                                  base64Decode(base64Image!.split(',').last),
                                  fit: BoxFit.cover,
                                ),
                              )
                            : Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(Icons.add_photo_alternate_rounded, color: AppTheme.primaryOrange, size: 40),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Ajouter une image',
                                    style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color, fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    TextField(
                      controller: titleController,
                      style: Theme.of(context).textTheme.bodyLarge,
                      decoration: const InputDecoration(hintText: 'Titre ou description courte'),
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
                    if (base64Image != null && titleController.text.isNotEmpty) {
                      ref.read(storyActionsProvider).addStory(titleController.text.trim(), base64Image!);
                      Navigator.pop(context);
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Veuillez ajouter une image et un titre.'), backgroundColor: AppTheme.error),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryOrange),
                  child: const Text('Publier', style: TextStyle(color: Colors.white)),
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
    final storiesAsync = ref.watch(storiesProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text('Gérer les Stories', style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color)),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddStoryDialog(context, ref),
        backgroundColor: AppTheme.primaryOrange,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Nouvelle Story', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      body: storiesAsync.when(
        data: (stories) {
          if (stories.isEmpty) {
            return Center(child: Text('Aucune story publiée.', style: Theme.of(context).textTheme.bodyMedium));
          }

          return GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 0.7,
            ),
            itemCount: stories.length,
            itemBuilder: (context, index) {
              final story = stories[index];
              return Stack(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      image: DecorationImage(
                        image: MemoryImage(base64Decode(story.imageUrl.split(',').last)),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      gradient: LinearGradient(
                        colors: [Colors.black.withOpacity(0.7), Colors.transparent],
                        begin: Alignment.bottomCenter,
                        end: Alignment.center,
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 16,
                    left: 16,
                    right: 16,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          story.title,
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          DateFormat('dd/MM à HH:mm').format(story.createdAt),
                          style: const TextStyle(color: Colors.white70, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: GestureDetector(
                      onTap: () {
                        showDialog(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            backgroundColor: Theme.of(context).colorScheme.surface,
                            title: const Text('Supprimer ?', style: TextStyle(color: AppTheme.error)),
                            content: const Text('Voulez-vous vraiment supprimer cette story ?'),
                            actions: [
                              TextButton(onPressed: () => Navigator.pop(ctx), child: Text('Annuler', style: Theme.of(context).textTheme.bodyMedium)),
                              ElevatedButton(
                                onPressed: () {
                                  ref.read(storyActionsProvider).deleteStory(story.id);
                                  Navigator.pop(ctx);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Story supprimée !'), backgroundColor: AppTheme.success),
                                  );
                                },
                                style: ElevatedButton.styleFrom(backgroundColor: AppTheme.error),
                                child: const Text('Supprimer', style: TextStyle(color: Colors.white)),
                              ),
                            ],
                          ),
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppTheme.error,
                          shape: BoxShape.circle,
                          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 6)],
                        ),
                        child: const Icon(Icons.delete_outline_rounded, color: Colors.white, size: 20),
                      ),
                    ),
                  ),
                ],
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator(color: AppTheme.primaryOrange)),
        error: (err, stack) => Center(child: Text('Erreur: $err', style: const TextStyle(color: AppTheme.error))),
      ),
    );
  }
}
