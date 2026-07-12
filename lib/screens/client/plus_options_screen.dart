import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/client_providers.dart';
import '../../theme/app_theme.dart';
import '../../l10n/app_translations.dart';
import 'loyalty_cards.dart';
import 'client_history_screen.dart';
import 'wheel_of_fortune_screen.dart';
import 'composer_screen.dart';
import 'client_leaderboard_screen.dart';
import 'client_settings_screen.dart';

class PlusOptionsScreen extends ConsumerWidget {
  const PlusOptionsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(clientUserProvider);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Plus d\'options', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        children: [
          // Loyalty Cards section
          Text(
            'Mes Cartes de Fidélité',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          userAsync.when(
            data: (user) => user == null ? const SizedBox() : LoyaltyCardsCarousel(user: user),
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (_, __) => const SizedBox(),
          ),
          const SizedBox(height: 32),
          
          // Menu Options
          SoftCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                _buildOptionTile(
                  context,
                  icon: Icons.history_rounded,
                  title: 'history'.tr(context),
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ClientHistoryScreen())),
                ),
                const Divider(height: 1, indent: 56),
                _buildOptionTile(
                  context,
                  icon: Icons.casino_rounded,
                  title: 'Roue de la Fortune',
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const WheelOfFortuneScreen())),
                ),

                const Divider(height: 1, indent: 56),
                _buildOptionTile(
                  context,
                  icon: Icons.emoji_events_rounded,
                  title: 'Classement',
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ClientLeaderboardScreen())),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          
          SoftCard(
            padding: EdgeInsets.zero,
            child: _buildOptionTile(
              context,
              icon: Icons.settings_rounded,
              title: 'settings'.tr(context),
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ClientSettingsScreen())),
            ),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildOptionTile(BuildContext context, {required IconData icon, required String title, required VoidCallback onTap}) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Theme.of(context).primaryColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: Theme.of(context).primaryColor, size: 22),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
      trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 16, color: Colors.grey),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      onTap: onTap,
    );
  }
}
