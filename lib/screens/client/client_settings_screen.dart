import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../theme/app_theme.dart';
import '../../providers/auth_providers.dart';
import '../../providers/client_providers.dart';
import '../../providers/theme_provider.dart';
import '../../l10n/app_translations.dart';

class ClientSettingsScreen extends ConsumerWidget {
  const ClientSettingsScreen({super.key});

  Future<void> _togglePublicProfile(bool value, String userId, BuildContext context) async {
    try {
      await FirebaseFirestore.instance.collection('users').doc(userId).update({
        'is_public': value,
      });
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(value ? 'Profil rendu public !' : 'Profil rendu anonyme !'),
            backgroundColor: AppTheme.success,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e'), backgroundColor: AppTheme.error),
        );
      }
    }
  }

  Future<void> _showEditProfileDialog(BuildContext context, ClientUser user) async {
    final nameController = TextEditingController(text: user.name);
    final phoneController = TextEditingController(text: user.phone ?? '');
    
    await showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('Modifier mon profil', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold, color: AppTheme.primaryOrange)),
                const SizedBox(height: 24),
                TextFormField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: 'Prénom', prefixIcon: Icon(Icons.person_rounded)),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: phoneController,
                  decoration: const InputDecoration(labelText: 'Téléphone', prefixIcon: Icon(Icons.phone_rounded)),
                  keyboardType: TextInputType.phone,
                ),
                const SizedBox(height: 24),
                PrimaryButton(
                  text: 'Enregistrer',
                  onPressed: () async {
                    try {
                      await FirebaseFirestore.instance.collection('users').doc(user.id).update({
                        'name': nameController.text.trim(),
                        'phone': phoneController.text.trim(),
                      });
                      if (context.mounted) {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Profil mis à jour !'), backgroundColor: AppTheme.success),
                        );
                      }
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Erreur: $e'), backgroundColor: AppTheme.error),
                        );
                      }
                    }
                  },
                ),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Annuler', style: TextStyle(color: Colors.grey)),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(clientUserProvider);
    final themeState = ref.watch(themeProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text('settings'.tr(context), style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color, fontWeight: FontWeight.bold)),
      ),
      body: userAsync.when(
        data: (user) {
          if (user == null) return Center(child: Text('error_user'.tr(context), style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color)));
          
          return ListView(
            padding: const EdgeInsets.all(24),
            children: [
              SoftCard(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.person_rounded, color: AppTheme.primaryOrange),
                            const SizedBox(width: 12),
                            Text('my_profile'.tr(context), style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontSize: 18, fontWeight: FontWeight.bold)),
                          ],
                        ),
                        IconButton(
                          icon: const Icon(Icons.edit_rounded, color: AppTheme.primaryOrange),
                          onPressed: () => _showEditProfileDialog(context, user),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text('${'first_name'.tr(context)} : ${user.name}', style: Theme.of(context).textTheme.bodyMedium),
                    const SizedBox(height: 8),
                    if (user.email != null && user.email!.isNotEmpty) ...[
                      Text('${'email'.tr(context)} : ${user.email}', style: Theme.of(context).textTheme.bodyMedium),
                      const SizedBox(height: 8),
                    ],
                    if (user.phone != null && user.phone!.isNotEmpty)
                      Text('${'phone'.tr(context)} : ${user.phone}', style: Theme.of(context).textTheme.bodyMedium)
                    else
                      Text('${'phone'.tr(context)} : ${'not_provided'.tr(context)}', style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey, fontStyle: FontStyle.italic)),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              SoftCard(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.leaderboard_rounded, color: AppTheme.primaryOrange),
                        const SizedBox(width: 12),
                        Text('public_ranking'.tr(context), style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontSize: 18, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'public_ranking_desc'.tr(context),
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(child: Text('participate_ranking'.tr(context), style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600))),
                        Switch(
                          value: user.isPublic,
                          activeColor: AppTheme.primaryOrange,
                          onChanged: (val) => _togglePublicProfile(val, user.id, context),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              SoftCard(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.palette_rounded, color: AppTheme.primaryOrange),
                        const SizedBox(width: 12),
                        Text('display_prefs'.tr(context), style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontSize: 18, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('dark_mode'.tr(context), style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600)),
                        Switch(
                          value: themeState.themeMode == ThemeMode.dark,
                          activeColor: AppTheme.primaryOrange,
                          onChanged: (val) => ref.read(themeProvider.notifier).toggleTheme(),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('language'.tr(context), style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600)),
                        DropdownButton<String>(
                          value: themeState.locale.languageCode,
                          dropdownColor: Theme.of(context).colorScheme.surface,
                          style: Theme.of(context).textTheme.bodyLarge,
                          underline: const SizedBox(),
                          items: const [
                            DropdownMenuItem(value: 'fr', child: Text('Français')),
                            DropdownMenuItem(value: 'en', child: Text('English')),
                            DropdownMenuItem(value: 'ar', child: Text('العربية')),
                          ],
                          onChanged: (val) {
                            if (val != null) ref.read(themeProvider.notifier).setLanguage(val);
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              ElevatedButton.icon(
                onPressed: () async {
                  await ref.read(authControllerProvider).signOut();
                  if (context.mounted) {
                    Navigator.of(context).popUntil((route) => route.isFirst);
                  }
                },
                icon: const Icon(Icons.logout_rounded),
                label: Text('logout'.tr(context)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.error.withOpacity(0.1),
                  foregroundColor: AppTheme.error,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: const BorderSide(color: AppTheme.error),
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator(color: AppTheme.primaryOrange)),
        error: (e, s) => Center(child: Text('Erreur: $e', style: const TextStyle(color: AppTheme.error))),
      ),
    );
  }
}
