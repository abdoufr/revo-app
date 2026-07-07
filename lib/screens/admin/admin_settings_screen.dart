import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../theme/app_theme.dart';
import '../../providers/admin_providers.dart';
import '../../providers/settings_provider.dart';

class AdminSettingsScreen extends ConsumerStatefulWidget {
  const AdminSettingsScreen({super.key});

  @override
  ConsumerState<AdminSettingsScreen> createState() => _AdminSettingsScreenState();
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

  Future<void> _saveSettings() async {
    setState(() => _isLoading = true);
    try {
      await ref.read(adminActionsProvider).updateAppSettings(
        _nameController.text.trim(),
        _descController.text.trim(),
        _bannerController.text.trim(),
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Paramètres mis à jour avec succès!'), backgroundColor: AppTheme.success),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e'), backgroundColor: AppTheme.error),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final settingsAsync = ref.watch(appSettingsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Paramètres du Fastfood', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.transparent,
        elevation: 0,
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
                const Text('Informations Générales', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                TextField(
                  controller: _nameController,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    labelText: 'Nom du Fastfood',
                    prefixIcon: Icon(Icons.storefront, color: AppTheme.textGrey),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _descController,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    labelText: 'Description (ex: Le meilleur burger)',
                    prefixIcon: Icon(Icons.description, color: AppTheme.textGrey),
                  ),
                ),
                const SizedBox(height: 32),
                const Text('Promotion Live (Bannière Client)', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                const Text('Ce message s\'affichera chez tous les clients.', style: TextStyle(color: AppTheme.textGrey, fontSize: 12)),
                const SizedBox(height: 16),
                TextField(
                  controller: _bannerController,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    labelText: 'Annonce (Laisser vide pour cacher)',
                    prefixIcon: Icon(Icons.campaign, color: AppTheme.textGrey),
                  ),
                ),
                const SizedBox(height: 32),
                GradientButton(
                  text: 'Sauvegarder',
                  isLoading: _isLoading,
                  onPressed: _saveSettings,
                ),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator(color: AppTheme.accentCyan)),
        error: (err, stack) => Center(child: Text('Erreur: $err', style: const TextStyle(color: Colors.red))),
      ),
    );
  }
}
