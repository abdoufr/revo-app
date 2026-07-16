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
  final _newCategoryController = TextEditingController();
  final _latController = TextEditingController();
  final _lngController = TextEditingController();
  final _newMessageController = TextEditingController();
  List<String> _geofenceMessages = [];
  bool _isLoading = false;
  bool _isInit = false;

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    _bannerController.dispose();
    _newCategoryController.dispose();
    _latController.dispose();
    _lngController.dispose();
    _newMessageController.dispose();
    super.dispose();
  }

  Future<void> _saveSettings() async {
    setState(() => _isLoading = true);
    try {
      await ref
          .read(adminActionsProvider)
          .updateAppSettings(
            _nameController.text.trim(),
            _descController.text.trim(),
            _bannerController.text.trim(),
            double.tryParse(_latController.text.trim()) ?? 0.0,
            double.tryParse(_lngController.text.trim()) ?? 0.0,
            _geofenceMessages,
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
    final categoriesAsync = ref.watch(categoriesProvider);

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
            _latController.text = settings.storeLat.toString();
            _lngController.text = settings.storeLng.toString();
            _geofenceMessages = List.from(settings.geofenceMessages);
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
                Text(
                  'Localisation et Notifications',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Gérez la position GPS du magasin et les messages de bienvenue lorsque le client s\'approche à moins de 100m.',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Lat: ${_latController.text.isNotEmpty ? _latController.text : "0.0"}\nLng: ${_lngController.text.isNotEmpty ? _lngController.text : "0.0"}',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ),
                    ElevatedButton.icon(
                      onPressed: () async {
                        final lat = double.tryParse(_latController.text) ?? 0.0;
                        final lng = double.tryParse(_lngController.text) ?? 0.0;
                        final result = await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => MapPickerScreen(
                              initialLat: lat,
                              initialLng: lng,
                            ),
                          ),
                        );
                        if (result != null && result is LatLng) {
                          setState(() {
                            _latController.text = result.latitude.toString();
                            _lngController.text = result.longitude.toString();
                          });
                        }
                      },
                      icon: const Icon(Icons.map),
                      label: const Text('Ouvrir la carte'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).primaryColor,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  'Messages d\'approche (100m)',
                  style: Theme.of(
                    context,
                  ).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _geofenceMessages.map((msg) {
                    return Chip(
                      label: Text(
                        msg,
                        style: const TextStyle(color: Colors.white),
                      ),
                      backgroundColor: Theme.of(context).primaryColor,
                      deleteIcon: const Icon(
                        Icons.close,
                        color: Colors.white,
                        size: 18,
                      ),
                      onDeleted: () {
                        setState(() {
                          _geofenceMessages.remove(msg);
                        });
                      },
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _newMessageController,
                        style: Theme.of(context).textTheme.bodyLarge,
                        decoration: InputDecoration(
                          labelText:
                              'Nouveau message (ex: Vous êtes si proche !)',
                          prefixIcon: Icon(
                            Icons.message,
                            color: Theme.of(context).primaryColor,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: Icon(
                        Icons.add_circle,
                        color: Theme.of(context).primaryColor,
                        size: 40,
                      ),
                      onPressed: () {
                        final val = _newMessageController.text.trim();
                        if (val.isNotEmpty &&
                            !_geofenceMessages.contains(val)) {
                          setState(() {
                            _geofenceMessages.add(val);
                            _newMessageController.clear();
                          });
                        }
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 32),
                Text(
                  'Gestion des Catégories',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Gérez les catégories disponibles pour vos produits.',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 16),
                categoriesAsync.when(
                  data: (categories) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: categories.map((cat) {
                            return Chip(
                              label: Text(
                                cat,
                                style: const TextStyle(color: Colors.white),
                              ),
                              backgroundColor: Theme.of(context).primaryColor,
                              deleteIcon: const Icon(
                                Icons.close,
                                color: Colors.white,
                                size: 18,
                              ),
                              onDeleted: () {
                                final newList = List<String>.from(categories)
                                  ..remove(cat);
                                ref
                                    .read(adminActionsProvider)
                                    .updateCategories(newList);
                              },
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _newCategoryController,
                                style: Theme.of(context).textTheme.bodyLarge,
                                decoration: InputDecoration(
                                  labelText: 'Nouvelle catégorie',
                                  prefixIcon: Icon(
                                    Icons.category,
                                    color: Theme.of(context).primaryColor,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            IconButton(
                              icon: Icon(
                                Icons.add_circle,
                                color: Theme.of(context).primaryColor,
                                size: 40,
                              ),
                              onPressed: () {
                                final val = _newCategoryController.text.trim();
                                if (val.isNotEmpty &&
                                    !categories.contains(val)) {
                                  final newList = List<String>.from(categories)
                                    ..add(val);
                                  ref
                                      .read(adminActionsProvider)
                                      .updateCategories(newList);
                                  _newCategoryController.clear();
                                }
                              },
                            ),
                          ],
                        ),
                      ],
                    );
                  },
                  loading: () => Center(
                    child: CircularProgressIndicator(
                      color: Theme.of(context).primaryColor,
                    ),
                  ),
                  error: (err, stack) => const Text(
                    'Erreur chargement catégories',
                    style: TextStyle(color: AppTheme.error),
                  ),
                ),
                const SizedBox(height: 32),
                PrimaryButton(
                  text: 'Sauvegarder',
                  isLoading: _isLoading,
                  onPressed: _saveSettings,
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
