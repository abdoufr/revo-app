import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:convert';
import '../../theme/app_theme.dart';
import '../../providers/client_providers.dart';
import '../../providers/auth_providers.dart';
import '../../providers/admin_providers.dart';
import '../../providers/settings_provider.dart';
import '../../providers/story_provider.dart';
import '../../providers/notification_provider.dart';
import 'client_settings_screen.dart';
import 'client_menu_section.dart';
import 'story_viewer_screen.dart';
import 'client_history_screen.dart';
import 'client_leaderboard_screen.dart';
import 'wheel_of_fortune_screen.dart';
import 'composer_screen.dart';

class ClientHome extends ConsumerStatefulWidget {
  const ClientHome({super.key});

  @override
  ConsumerState<ClientHome> createState() => _ClientHomeState();
}

class _ClientHomeState extends ConsumerState<ClientHome> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    final userAsync = ref.watch(clientUserProvider);
    final storiesAsync = ref.watch(storiesProvider);

    return Scaffold(
      extendBody: true, // For floating bottom nav bar
      body: SafeArea(
        bottom: false,
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Header (Profile + Notifications)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        GestureDetector(
                          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ClientSettingsScreen())),
                          child: CircleAvatar(
                            radius: 24,
                            backgroundColor: AppTheme.primaryRed.withOpacity(0.1),
                            child: userAsync.when(
                              data: (user) => Text(
                                user?.name.isNotEmpty == true ? user!.name[0].toUpperCase() : 'U',
                                style: const TextStyle(color: AppTheme.primaryRed, fontWeight: FontWeight.bold, fontSize: 20),
                              ),
                              loading: () => const CircularProgressIndicator(strokeWidth: 2),
                              error: (_, __) => const Icon(Icons.person, color: AppTheme.primaryRed),
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.notifications_none_rounded, size: 28),
                          onPressed: () {
                            // Notifications handler (could show a bottom sheet with past announcements)
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    
                    // Title
                    Text(
                      'Choose\nYour Favorite Food',
                      style: Theme.of(context).textTheme.displayMedium?.copyWith(
                        fontSize: 28,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Stories (optional, keeping it if they exist)
                    storiesAsync.when(
                      data: (stories) {
                        if (stories.isEmpty) return const SizedBox();
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SizedBox(
                              height: 100,
                              child: ListView.builder(
                                scrollDirection: Axis.horizontal,
                                itemCount: stories.length,
                                itemBuilder: (context, index) {
                                  final story = stories[index];
                                  return GestureDetector(
                                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => StoryViewerScreen(stories: stories, initialIndex: index))),
                                    child: Container(
                                      margin: const EdgeInsets.only(right: 16),
                                      width: 80,
                                      child: Column(
                                        children: [
                                          Container(
                                            height: 70,
                                            width: 70,
                                            decoration: BoxDecoration(
                                              shape: BoxShape.circle,
                                              border: Border.all(color: AppTheme.primaryRed, width: 3),
                                            ),
                                            child: ClipRRect(
                                              borderRadius: BorderRadius.circular(35),
                                              child: story.imageUrl.startsWith('data:image') 
                                                  ? Image.memory(base64Decode(story.imageUrl.split(',').last), fit: BoxFit.cover)
                                                  : Container(color: Colors.grey),
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            story.title,
                                            style: Theme.of(context).textTheme.bodySmall,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            textAlign: TextAlign.center,
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                            const SizedBox(height: 24),
                          ],
                        );
                      },
                      loading: () => const SizedBox(),
                      error: (err, stack) => const SizedBox(),
                    ),

                    // Menu Section (Search, Categories, Grids)
                    const ClientMenuSection(),
                    
                    const SizedBox(height: 32),
                    
                    // Mini Actions (History, Leaderboard, Wheel, Composer) - Kept as small pills or row
                    Text('Plus d\'options', style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold, fontSize: 18)),
                    const SizedBox(height: 16),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _buildMiniAction(context, icon: Icons.history, label: 'Historique', onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ClientHistoryScreen()))),
                          _buildMiniAction(context, icon: Icons.emoji_events, label: 'Classement', onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ClientLeaderboardScreen()))),
                          _buildMiniAction(context, icon: Icons.casino, label: 'Roue', onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const WheelOfFortuneScreen()))),
                          _buildMiniAction(context, icon: Icons.restaurant, label: 'Composer', onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ComposerScreen()))),
                        ],
                      ),
                    ),
                    const SizedBox(height: 100), // Padding for bottom nav bar
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }

  Widget _buildMiniAction(BuildContext context, {required IconData icon, required String label, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(right: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
        ),
        child: Row(
          children: [
            Icon(icon, color: AppTheme.primaryRed, size: 20),
            const SizedBox(width: 8),
            Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomNavigationBar() {
    return Container(
      margin: const EdgeInsets.fromLTRB(24, 0, 24, 24),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: AppTheme.primaryRed,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(color: AppTheme.primaryRed.withOpacity(0.3), blurRadius: 20, offset: const Offset(0, 10)),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _buildNavItem(0, Icons.home_filled),
          _buildNavItem(1, Icons.favorite_border_rounded),
          _buildNavItem(2, Icons.shopping_cart_outlined),
          _buildNavItem(3, Icons.person_outline_rounded),
        ],
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon) {
    final isSelected = _selectedIndex == index;
    return GestureDetector(
      onTap: () {
        setState(() => _selectedIndex = index);
        if (index == 3) {
           Navigator.push(context, MaterialPageRoute(builder: (_) => const ClientSettingsScreen()));
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white.withOpacity(0.2) : Colors.transparent,
          shape: BoxShape.circle,
        ),
        child: Icon(
          icon,
          color: Colors.white,
          size: 28,
        ),
      ),
    );
  }
}
