import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../theme/app_theme.dart';
import '../../providers/auth_providers.dart';
import '../../providers/client_providers.dart';
import '../../providers/theme_provider.dart';
import '../../providers/referral_provider.dart';
import '../../l10n/app_translations.dart';
import 'client_history_screen.dart';
import 'wheel_of_fortune_screen.dart';
import 'composer_screen.dart';

class _ReferralSection extends ConsumerStatefulWidget {
  final String userId;
  const _ReferralSection({required this.userId});

  @override
  ConsumerState<_ReferralSection> createState() => _ReferralSectionState();
}

class _ReferralSectionState extends ConsumerState<_ReferralSection> {
  final _codeController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  void _applyCode() async {
    final code = _codeController.text.trim();
    if (code.isEmpty) return;

    setState(() => _isLoading = true);
    try {
      final msg = await ref.read(referralActionsProvider).applyReferralCode(code, ref);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: AppTheme.success));
        _codeController.clear();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString().replaceAll('Exception: ', '')), backgroundColor: AppTheme.error));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SoftCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.handshake_rounded, color: AppTheme.primaryRed),
              const SizedBox(width: 12),
              Text('Parrainage', style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontSize: 18, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 16),
          Text('Partagez ce code avec vos amis. S\'ils l\'utilisent, vous gagnez tous les deux des points bonus !', style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            decoration: BoxDecoration(color: AppTheme.primaryRed.withOpacity(0.1), borderRadius: BorderRadius.circular(12), border: Border.all(color: AppTheme.primaryRed)),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Mon Code :', style: TextStyle(fontWeight: FontWeight.bold)),
                Text(widget.userId.substring(0, 6).toUpperCase(), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.primaryRed, letterSpacing: 2)),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Text('J\'ai un code parrain :', style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _codeController,
                  decoration: const InputDecoration(hintText: 'Code à 6 lettres', isDense: true),
                  textCapitalization: TextCapitalization.characters,
                ),
              ),
              const SizedBox(width: 12),
              ElevatedButton(
                onPressed: _isLoading ? null : _applyCode,
                style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryRed),
                child: _isLoading 
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Text('Valider', style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

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
                Text('Modifier mon profil', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold, color: AppTheme.primaryRed)),
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
                            const Icon(Icons.person_rounded, color: AppTheme.primaryRed),
                            const SizedBox(width: 12),
                            Text('my_profile'.tr(context), style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontSize: 18, fontWeight: FontWeight.bold)),
                          ],
                        ),
                        IconButton(
                          icon: const Icon(Icons.edit_rounded, color: AppTheme.primaryRed),
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
                        const Icon(Icons.explore_rounded, color: AppTheme.primaryRed),
                        const SizedBox(width: 12),
                        Text('Plus d\'options', style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontSize: 18, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const SizedBox(height: 16),
                    ListTile(
                      leading: const Icon(Icons.history_rounded, color: AppTheme.primaryRed),
                      title: Text('history'.tr(context)),
                      trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 16),
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ClientHistoryScreen())),
                    ),
                    ListTile(
                      leading: const Icon(Icons.casino_rounded, color: AppTheme.primaryRed),
                      title: const Text('Roue de la Fortune'),
                      trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 16),
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const WheelOfFortuneScreen())),
                    ),
                    ListTile(
                      leading: const Icon(Icons.restaurant_rounded, color: AppTheme.primaryRed),
                      title: const Text('Composer mon Plat'),
                      trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 16),
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ComposerScreen())),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              _ReferralSection(userId: user.id),
              const SizedBox(height: 24),
              SoftCard(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.leaderboard_rounded, color: AppTheme.primaryRed),
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
                          activeColor: AppTheme.primaryRed,
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
                        const Icon(Icons.palette_rounded, color: AppTheme.primaryRed),
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
                          activeColor: AppTheme.primaryRed,
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
        loading: () => const Center(child: CircularProgressIndicator(color: AppTheme.primaryRed)),
        error: (e, s) => Center(child: Text('Erreur: $e', style: const TextStyle(color: AppTheme.error))),
      ),
    );
  }
}
