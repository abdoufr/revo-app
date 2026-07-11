import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../theme/app_theme.dart';
import '../../providers/referral_provider.dart';

class AdminReferralConfigScreen extends ConsumerStatefulWidget {
  const AdminReferralConfigScreen({super.key});

  @override
  ConsumerState<AdminReferralConfigScreen> createState() => _AdminReferralConfigScreenState();
}

class _AdminReferralConfigScreenState extends ConsumerState<AdminReferralConfigScreen> {
  final _referrerController = TextEditingController();
  final _referredController = TextEditingController();
  bool _isInitialized = false;

  @override
  void dispose() {
    _referrerController.dispose();
    _referredController.dispose();
    super.dispose();
  }

  void _saveConfig() {
    final referrerPts = int.tryParse(_referrerController.text) ?? 50;
    final referredPts = int.tryParse(_referredController.text) ?? 50;

    final config = ReferralConfig(
      pointsForReferrer: referrerPts,
      pointsForReferred: referredPts,
    );

    ref.read(referralActionsProvider).updateConfig(config);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Configuration du parrainage sauvegardée'), backgroundColor: AppTheme.success),
    );
  }

  @override
  Widget build(BuildContext context) {
    final configAsync = ref.watch(referralConfigProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text('Parrainage', style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color)),
        actions: [
          IconButton(
            icon: const Icon(Icons.save_rounded, color: AppTheme.primaryRed),
            onPressed: _saveConfig,
          ),
        ],
      ),
      body: configAsync.when(
        data: (config) {
          if (!_isInitialized) {
            _referrerController.text = config.pointsForReferrer.toString();
            _referredController.text = config.pointsForReferred.toString();
            _isInitialized = true;
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SoftCard(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.handshake_rounded, color: AppTheme.primaryRed, size: 32),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Text(
                              'Récompenses de parrainage',
                              style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold, fontSize: 18),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Définissez combien de points gagnent les utilisateurs lorsqu\'ils invitent un ami (Parrain) et lorsque l\'ami s\'inscrit (Filleul).',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
                Text('Points offerts au Parrain', style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                TextField(
                  controller: _referrerController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.person_add_alt_1_rounded, color: AppTheme.primaryRed),
                    hintText: 'ex: 50',
                    suffixText: 'points',
                  ),
                ),
                const SizedBox(height: 24),
                Text('Points offerts au Filleul', style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                TextField(
                  controller: _referredController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.person_outline_rounded, color: AppTheme.primaryRed),
                    hintText: 'ex: 50',
                    suffixText: 'points',
                  ),
                ),
                const SizedBox(height: 48),
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _saveConfig,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryRed,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    child: const Text('Enregistrer les modifications', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator(color: AppTheme.primaryRed)),
        error: (e, s) => Center(child: Text('Erreur: $e', style: const TextStyle(color: AppTheme.error))),
      ),
    );
  }
}
