import 'dart:convert';
import 'package:image_picker/image_picker.dart';
import '../../widgets/smart_image.dart';
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
  final ClientUser user;
  const _ReferralSection({required this.user});

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
      final msg = await ref
          .read(referralActionsProvider)
          .applyReferralCode(code, ref);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(msg), backgroundColor: AppTheme.success),
        );
        _codeController.clear();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll('Exception: ', '')),
            backgroundColor: AppTheme.error,
          ),
        );
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
              Icon(
                Icons.handshake_rounded,
                color: Theme.of(context).primaryColor,
              ),
              const SizedBox(width: 12),
              Text(
                'Parrainage',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'Partagez ce code avec vos amis. S\'ils l\'utilisent, vous gagnez tous les deux des points bonus !',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Theme.of(context).primaryColor),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Mon Code :',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(
                  widget.user.id.substring(0, 6).toUpperCase(),
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).primaryColor,
                    letterSpacing: 2,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          if (widget.user.referredBy == null) ...[
            Text(
              'J\'ai un code parrain :',
              style: Theme.of(
                context,
              ).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _codeController,
                    decoration: const InputDecoration(
                      hintText: 'Code à 6 lettres',
                      isDense: true,
                    ),
                    textCapitalization: TextCapitalization.characters,
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: _isLoading ? null : _applyCode,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).primaryColor,
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text(
                          'Valider',
                          style: TextStyle(color: Colors.white),
                        ),
                ),
              ],
            ),
          ] else ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.success.withAlpha(20),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.success.withAlpha(100)),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.check_circle_rounded,
                    color: AppTheme.success,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Vous avez déjà été parrainé !',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppTheme.success,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class ClientSettingsScreen extends ConsumerWidget {
  const ClientSettingsScreen({super.key});

  Future<void> _togglePublicProfile(
    bool value,
    String userId,
    BuildContext context,
  ) async {
    try {
      await FirebaseFirestore.instance.collection('users').doc(userId).update({
        'is_public': value,
      });
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              value ? 'Profil rendu public !' : 'Profil rendu anonyme !',
            ),
            backgroundColor: AppTheme.success,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: $e'),
            backgroundColor: AppTheme.error,
          ),
        );
      }
    }
  }

  Future<void> _showEditProfileDialog(
    BuildContext context,
    ClientUser user,
  ) async {
    final nameController = TextEditingController(text: user.name);
    final phoneController = TextEditingController(text: user.phone ?? '');
    String? base64Image = user.photoUrl;

    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      'Modifier mon profil',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).primaryColor,
                      ),
                    ),
                    const SizedBox(height: 20),
                    GestureDetector(
                      onTap: () async {
                        try {
                          final picker = ImagePicker();
                          final f = await picker.pickImage(source: ImageSource.gallery, maxWidth: 300, imageQuality: 40);
                          if (f != null) {
                            final bytes = await f.readAsBytes();
                            setState(() => base64Image = 'data:image/jpeg;base64,${base64Encode(bytes)}');
                          }
                        } catch (e) {
                          debugPrint('Error picking image: $e');
                        }
                      },
                      child: Stack(
                        children: [
                          Container(
                            height: 90,
                            width: 90,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Theme.of(context).primaryColor.withOpacity(0.1),
                              border: Border.all(color: Theme.of(context).primaryColor, width: 2),
                            ),
                            child: base64Image != null && base64Image!.isNotEmpty
                                ? ClipRRect(
                                    borderRadius: BorderRadius.circular(45),
                                    child: SmartImage(base64Image!, fit: BoxFit.cover),
                                  )
                                : Icon(Icons.person_rounded, color: Theme.of(context).primaryColor, size: 50),
                          ),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: Theme.of(context).primaryColor,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.camera_alt_rounded, color: Colors.white, size: 16),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    TextFormField(
                      controller: nameController,
                      decoration: const InputDecoration(
                        labelText: 'Nom / Prénom',
                        prefixIcon: Icon(Icons.person_rounded),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: phoneController,
                      decoration: const InputDecoration(
                        labelText: 'Téléphone',
                        prefixIcon: Icon(Icons.phone_rounded),
                      ),
                      keyboardType: TextInputType.phone,
                    ),
                    const SizedBox(height: 24),
                    PrimaryButton(
                      text: 'Enregistrer',
                      onPressed: () async {
                        try {
                          await FirebaseFirestore.instance
                              .collection('users')
                              .doc(user.id)
                              .update({
                                'name': nameController.text.trim(),
                                'phone': phoneController.text.trim(),
                                'photo_url': base64Image,
                              });
                          if (context.mounted) {
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Profil mis à jour !'),
                                backgroundColor: AppTheme.success,
                              ),
                            );
                          }
                        } catch (e) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Erreur: $e'),
                                backgroundColor: AppTheme.error,
                              ),
                            );
                          }
                        }
                      },
                    ),
                    const SizedBox(height: 12),
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text(
                        'Annuler',
                        style: TextStyle(color: Colors.grey),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
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
        title: Text(
          'settings'.tr(context),
          style: TextStyle(
            color: Theme.of(context).textTheme.bodyLarge?.color,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: userAsync.when(
        data: (user) {
          if (user == null)
            return Center(
              child: Text(
                'error_user'.tr(context),
                style: TextStyle(
                  color: Theme.of(context).textTheme.bodyLarge?.color,
                ),
              ),
            );

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
                            Icon(
                              Icons.person_rounded,
                              color: Theme.of(context).primaryColor,
                            ),
                            const SizedBox(width: 12),
                            Text(
                              'my_profile'.tr(context),
                              style: Theme.of(context).textTheme.bodyLarge
                                  ?.copyWith(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                          ],
                        ),
                        IconButton(
                          icon: Icon(
                            Icons.edit_rounded,
                            color: Theme.of(context).primaryColor,
                          ),
                          onPressed: () =>
                              _showEditProfileDialog(context, user),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      '${'first_name'.tr(context)} : ${user.name}',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 8),
                    if (user.email != null && user.email!.isNotEmpty) ...[
                      Text(
                        '${'email'.tr(context)} : ${user.email}',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 8),
                    ],
                    if (user.phone != null && user.phone!.isNotEmpty)
                      Text(
                        '${'phone'.tr(context)} : ${user.phone}',
                        style: Theme.of(context).textTheme.bodyMedium,
                      )
                    else
                      Text(
                        '${'phone'.tr(context)} : ${'not_provided'.tr(context)}',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.grey,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              _ReferralSection(user: user),
              const SizedBox(height: 24),
              SoftCard(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.leaderboard_rounded,
                          color: Theme.of(context).primaryColor,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'public_ranking'.tr(context),
                          style: Theme.of(context).textTheme.bodyLarge
                              ?.copyWith(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                        ),
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
                        Expanded(
                          child: Text(
                            'participate_ranking'.tr(context),
                            style: Theme.of(context).textTheme.bodyLarge
                                ?.copyWith(fontWeight: FontWeight.w600),
                          ),
                        ),
                        Switch(
                          value: user.isPublic,
                          activeColor: Theme.of(context).primaryColor,
                          onChanged: (val) =>
                              _togglePublicProfile(val, user.id, context),
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
                        Icon(
                          Icons.palette_rounded,
                          color: Theme.of(context).primaryColor,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'display_prefs'.tr(context),
                          style: Theme.of(context).textTheme.bodyLarge
                              ?.copyWith(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'dark_mode'.tr(context),
                          style: Theme.of(context).textTheme.bodyLarge
                              ?.copyWith(fontWeight: FontWeight.w600),
                        ),
                        Switch(
                          value: themeState.themeMode == ThemeMode.dark,
                          activeColor: Theme.of(context).primaryColor,
                          onChanged: (val) =>
                              ref.read(themeProvider.notifier).toggleTheme(),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'language'.tr(context),
                          style: Theme.of(context).textTheme.bodyLarge
                              ?.copyWith(fontWeight: FontWeight.w600),
                        ),
                        DropdownButton<String>(
                          value: themeState.locale.languageCode,
                          dropdownColor: Theme.of(context).colorScheme.surface,
                          style: Theme.of(context).textTheme.bodyLarge,
                          underline: const SizedBox(),
                          items: const [
                            DropdownMenuItem(
                              value: 'fr',
                              child: Text('Français'),
                            ),
                            DropdownMenuItem(
                              value: 'en',
                              child: Text('English'),
                            ),
                            DropdownMenuItem(
                              value: 'ar',
                              child: Text('العربية'),
                            ),
                          ],
                          onChanged: (val) {
                            if (val != null)
                              ref.read(themeProvider.notifier).setLanguage(val);
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
        loading: () => Center(
          child: CircularProgressIndicator(
            color: Theme.of(context).primaryColor,
          ),
        ),
        error: (e, s) => Center(
          child: Text(
            'Erreur: $e',
            style: const TextStyle(color: AppTheme.error),
          ),
        ),
      ),
    );
  }
}
