import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../theme/app_theme.dart';
import '../../providers/admin_providers.dart';
import '../../models/reward.dart';

class AdminRewardsScreen extends ConsumerStatefulWidget {
  const AdminRewardsScreen({super.key});

  @override
  ConsumerState<AdminRewardsScreen> createState() => _AdminRewardsScreenState();
}

class _AdminRewardsScreenState extends ConsumerState<AdminRewardsScreen> {
  final _spendingController = TextEditingController();
  final _pointsRequiredController = TextEditingController();
  final _descriptionController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _spendingController.dispose();
    _pointsRequiredController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _saveConfig() async {
    final spending = double.tryParse(_spendingController.text) ?? 100.0;
    final points = int.tryParse(_pointsRequiredController.text) ?? 50;
    final description = _descriptionController.text.trim();

    setState(() => _isLoading = true);
    try {
      await ref.read(adminActionsProvider).updateRewardConfig(
        RewardConfig(spendingPerPoint: spending, pointsRequiredForReward: points, rewardDescription: description)
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Configuration enregistrée!', style: TextStyle(color: Colors.white)), backgroundColor: AppTheme.success),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e', style: const TextStyle(color: Colors.white)), backgroundColor: AppTheme.error),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final configAsyncValue = ref.watch(rewardConfigProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text('Gérer les Cadeaux', style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color)),
      ),
      body: configAsyncValue.when(
        data: (config) {
          // Initialize controllers with current values if empty
          if (_spendingController.text.isEmpty && !_isLoading) {
            _spendingController.text = config.spendingPerPoint.toString();
            _pointsRequiredController.text = config.pointsRequiredForReward.toString();
            _descriptionController.text = config.rewardDescription;
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Configuration des Points',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  'Définissez combien d\'argent le client doit dépenser pour gagner 1 point.',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _spendingController,
                  keyboardType: TextInputType.number,
                  style: Theme.of(context).textTheme.bodyLarge,
                  decoration: const InputDecoration(
                    labelText: 'Dépense pour 1 Point (DA)',
                    prefixIcon: Icon(Icons.monetization_on, color: AppTheme.primaryRed),
                  ),
                ),
                
                const SizedBox(height: 32),
                
                Text(
                  'Configuration du Cadeau',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  'Définissez le nombre de points requis pour obtenir le cadeau, et la description du cadeau.',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _pointsRequiredController,
                  keyboardType: TextInputType.number,
                  style: Theme.of(context).textTheme.bodyLarge,
                  decoration: const InputDecoration(
                    labelText: 'Points requis pour le Cadeau',
                    prefixIcon: Icon(Icons.star, color: AppTheme.primaryRed),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _descriptionController,
                  style: Theme.of(context).textTheme.bodyLarge,
                  decoration: const InputDecoration(
                    labelText: 'Description du Cadeau (ex: Un café offert)',
                    prefixIcon: Icon(Icons.card_giftcard, color: AppTheme.primaryRed),
                  ),
                ),

                const SizedBox(height: 48),
                PrimaryButton(
                  text: 'Sauvegarder',
                  isLoading: _isLoading,
                  onPressed: _saveConfig,
                ),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator(color: AppTheme.primaryRed)),
        error: (error, stack) => Center(child: Text('Erreur: $error', style: const TextStyle(color: AppTheme.error))),
      ),
    );
  }
}
