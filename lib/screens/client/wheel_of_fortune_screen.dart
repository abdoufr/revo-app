import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_fortune_wheel/flutter_fortune_wheel.dart';
import '../../theme/app_theme.dart';
import '../../providers/gamification_provider.dart';
import '../../providers/client_providers.dart';
import '../../providers/auth_providers.dart';

class WheelOfFortuneScreen extends ConsumerStatefulWidget {
  const WheelOfFortuneScreen({super.key});

  @override
  ConsumerState<WheelOfFortuneScreen> createState() => _WheelOfFortuneScreenState();
}

class _WheelOfFortuneScreenState extends ConsumerState<WheelOfFortuneScreen> {
  StreamController<int> selected = StreamController<int>();
  bool _isSpinning = false;

  @override
  void dispose() {
    selected.close();
    super.dispose();
  }

  void _spinWheel(GamificationConfig config, int userPoints, String userId) async {
    if (_isSpinning) return;
    if (userPoints < config.wheelCost) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Vous n\'avez pas assez de points (${config.wheelCost} requis).'), backgroundColor: AppTheme.error),
      );
      return;
    }

    setState(() => _isSpinning = true);

    // Deduct points
    final authUser = ref.read(authStateProvider).value;
    if (authUser != null) {
      await ref.read(clientActionsProvider).deductPoints(authUser.uid, config.wheelCost);
    }

    // Random prize
    final randomIndex = Random().nextInt(config.wheelPrizes.length);
    selected.add(randomIndex);

    // Wait for animation
    await Future.delayed(const Duration(seconds: 5));
    
    if (mounted) {
      setState(() => _isSpinning = false);
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: Theme.of(context).colorScheme.surface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('🎉 Résultat', textAlign: TextAlign.center),
          content: Text(
            'Vous avez gagné :\n\n${config.wheelPrizes[randomIndex]}',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Theme.of(context).primaryColor),
          ),
          actions: [
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx),
              style: ElevatedButton.styleFrom(backgroundColor: Theme.of(context).primaryColor),
              child: const Text('Génial !', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final configAsync = ref.watch(gamificationConfigProvider);
    final userAsync = ref.watch(clientUserProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text('La Roue de la Fortune', style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color)),
      ),
      body: configAsync.when(
        data: (config) {
          if (!config.isWheelEnabled) {
            return Center(child: Text('La roue n\'est pas disponible pour le moment.', style: Theme.of(context).textTheme.bodyLarge));
          }

          return userAsync.when(
            data: (user) {
              if (user == null) return const Center(child: Text('Erreur utilisateur'));

              return Column(
                children: [
                  const SizedBox(height: 24),
                  Text(
                    'Vos Points: ${user.loyaltyPoints}',
                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Theme.of(context).primaryColor),
                  ),
                  const SizedBox(height: 8),
                  Text('Tourner la roue coûte ${config.wheelCost} points', style: Theme.of(context).textTheme.bodyMedium),
                  const SizedBox(height: 48),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: FortuneWheel(
                        selected: selected.stream,
                        items: [
                          for (var prize in config.wheelPrizes)
                            FortuneItem(
                              child: Text(prize, style: const TextStyle(fontWeight: FontWeight.bold)),
                              style: FortuneItemStyle(
                                color: Theme.of(context).primaryColor.withOpacity(config.wheelPrizes.indexOf(prize) % 2 == 0 ? 1 : 0.8),
                                borderColor: Colors.white,
                                borderWidth: 2,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
                    child: SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: _isSpinning ? null : () => _spinWheel(config, user.loyaltyPoints, user.id),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Theme.of(context).primaryColor,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                        child: _isSpinning
                            ? const CircularProgressIndicator(color: Colors.white)
                            : const Text('Tenter ma chance !', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ),
                ],
              );
            },
            loading: () => const Center(child: CircularProgressIndicator(color: Theme.of(context).primaryColor)),
            error: (e, s) => Center(child: Text('Erreur: $e')),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator(color: Theme.of(context).primaryColor)),
        error: (e, s) => Center(child: Text('Erreur: $e')),
      ),
    );
  }
}
