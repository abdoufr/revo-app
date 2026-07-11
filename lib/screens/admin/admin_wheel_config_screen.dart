import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../theme/app_theme.dart';
import '../../providers/gamification_provider.dart';

class AdminWheelConfigScreen extends ConsumerStatefulWidget {
  const AdminWheelConfigScreen({super.key});

  @override
  ConsumerState<AdminWheelConfigScreen> createState() => _AdminWheelConfigScreenState();
}

class _AdminWheelConfigScreenState extends ConsumerState<AdminWheelConfigScreen> {
  final _costController = TextEditingController();
  List<String> _prizes = [];
  bool _isEnabled = false;
  bool _isInitialized = false;

  @override
  void dispose() {
    _costController.dispose();
    super.dispose();
  }

  void _saveConfig() {
    final cost = int.tryParse(_costController.text) ?? 50;
    if (_prizes.length < 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Il faut au moins 2 parts sur la roue.'), backgroundColor: AppTheme.error),
      );
      return;
    }

    final newConfig = GamificationConfig(
      isWheelEnabled: _isEnabled,
      wheelCost: cost,
      wheelPrizes: _prizes,
    );

    ref.read(gamificationActionsProvider).updateConfig(newConfig);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Configuration sauvegardée'), backgroundColor: AppTheme.success),
    );
  }

  void _addPrize() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Theme.of(context).colorScheme.surface,
        title: const Text('Ajouter un lot'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(hintText: 'ex: Boisson Gratuite, 10 Points...'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Annuler')),
          ElevatedButton(
            onPressed: () {
              if (controller.text.isNotEmpty) {
                setState(() => _prizes.add(controller.text.trim()));
                Navigator.pop(ctx);
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryOrange),
            child: const Text('Ajouter', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final configAsync = ref.watch(gamificationConfigProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text('Configuration Roue', style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color)),
        actions: [
          IconButton(
            icon: const Icon(Icons.save_rounded, color: AppTheme.primaryOrange),
            onPressed: _saveConfig,
          ),
        ],
      ),
      body: configAsync.when(
        data: (config) {
          if (!_isInitialized) {
            _isEnabled = config.isWheelEnabled;
            _costController.text = config.wheelCost.toString();
            _prizes = List.from(config.wheelPrizes);
            _isInitialized = true;
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SoftCard(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Activer la Roue', style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold)),
                            const SizedBox(height: 4),
                            Text('Permet aux clients de tourner la roue', style: Theme.of(context).textTheme.bodyMedium),
                          ],
                        ),
                      ),
                      Switch(
                        value: _isEnabled,
                        activeColor: AppTheme.primaryOrange,
                        onChanged: (val) => setState(() => _isEnabled = val),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                Text('Coût d\'un tour (en points)', style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                TextField(
                  controller: _costController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.stars_rounded, color: AppTheme.primaryOrange),
                    hintText: 'ex: 50',
                  ),
                ),
                const SizedBox(height: 32),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Lots sur la roue (${_prizes.length})', style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold)),
                    IconButton(
                      icon: const Icon(Icons.add_circle_outline, color: AppTheme.primaryOrange),
                      onPressed: _addPrize,
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                ..._prizes.asMap().entries.map((entry) {
                  final index = entry.key;
                  final prize = entry.value;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      tileColor: Theme.of(context).colorScheme.surface,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      title: Text(prize),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete_outline, color: AppTheme.error),
                        onPressed: () => setState(() => _prizes.removeAt(index)),
                      ),
                    ),
                  );
                }),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator(color: AppTheme.primaryOrange)),
        error: (e, s) => Center(child: Text('Erreur: $e', style: const TextStyle(color: AppTheme.error))),
      ),
    );
  }
}
