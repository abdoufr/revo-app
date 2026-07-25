import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../theme/app_theme.dart';
import '../../providers/admin_providers.dart';
import '../../providers/settings_provider.dart';
import '../../providers/theme_provider.dart';
import 'package:latlong2/latlong.dart';
import 'map_picker_screen.dart';

class AdminSettingsScreen extends ConsumerStatefulWidget {
  const AdminSettingsScreen({super.key});

  @override
  ConsumerState<AdminSettingsScreen> createState() =>
      _AdminSettingsScreenState();
}

class _AdminSettingsScreenState extends ConsumerState<AdminSettingsScreen> {
  final _nameController = TextEditingController();
  final _descController = TextEditingController();
  final _bannerController = TextEditingController();
  bool _isLoading = false;
  bool _isInit = false;

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    _bannerController.dispose();
    super.dispose();
  }

  Future<void> _saveSettings(AppSettings settings) async {
    setState(() => _isLoading = true);
    try {
      await ref
          .read(adminActionsProvider)
          .updateAppSettings(
            _nameController.text.trim(),
            _descController.text.trim(),
            _bannerController.text.trim(),
            settings.storeLat,
            settings.storeLng,
            settings.geofenceRadius,
            settings.geofenceMessages,
          );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Paramètres mis à jour avec succès!'),
            backgroundColor: AppTheme.success,
          ),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: $e'),
            backgroundColor: AppTheme.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Widget build(BuildContext context) {
    final settingsAsync = ref.watch(appSettingsProvider);
    final themeState = ref.watch(themeProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Paramètres du Fastfood',
          style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color),
        ),
      ),
      body: settingsAsync.when(
        data: (settings) {
          if (!_isInit) {
            _nameController.text = settings.fastfoodName;
            _descController.text = settings.fastfoodDescription;
            _bannerController.text = settings.announcementBanner;
            _isInit = true;
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
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
                            'Préférences d\'Affichage',
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
                            'Mode Sombre (Dark Mode)',
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
                            'Langue',
                            style: Theme.of(context).textTheme.bodyLarge
                                ?.copyWith(fontWeight: FontWeight.w600),
                          ),
                          DropdownButton<String>(
                            value: themeState.locale.languageCode,
                            dropdownColor: Theme.of(
                              context,
                            ).colorScheme.surface,
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
                                ref
                                    .read(themeProvider.notifier)
                                    .setLanguage(val);
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
                Text(
                  'Informations Générales',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _nameController,
                  style: Theme.of(context).textTheme.bodyLarge,
                  decoration: InputDecoration(
                    labelText: 'Nom du Fastfood',
                    prefixIcon: Icon(
                      Icons.storefront,
                      color: Theme.of(context).primaryColor,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _descController,
                  style: Theme.of(context).textTheme.bodyLarge,
                  decoration: InputDecoration(
                    labelText: 'Description (ex: Le meilleur burger)',
                    prefixIcon: Icon(
                      Icons.description,
                      color: Theme.of(context).primaryColor,
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                Text(
                  'Promotion Live (Bannière Client)',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Ce message s\'affichera chez tous les clients.',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _bannerController,
                  style: Theme.of(context).textTheme.bodyLarge,
                  decoration: InputDecoration(
                    labelText: 'Annonce (Laisser vide pour cacher)',
                    prefixIcon: Icon(
                      Icons.campaign,
                      color: Theme.of(context).primaryColor,
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                PrimaryButton(
                  text: 'Sauvegarder',
                  isLoading: _isLoading,
                  onPressed: () => _saveSettings(settings),
                ),
              ],
            ),
          );
        },
        loading: () => Center(
          child: CircularProgressIndicator(
            color: Theme.of(context).primaryColor,
          ),
        ),
        error: (err, stack) => Center(
          child: Text(
            'Erreur: $err',
            style: const TextStyle(color: AppTheme.error),
          ),
        ),
      ),
    );
  }
}
