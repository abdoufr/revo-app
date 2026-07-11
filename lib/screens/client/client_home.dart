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
import 'plus_options_screen.dart';
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
                            _showNotificationsSheet(context, ref);
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
                    ClientMenuSection(showFavoritesOnly: _selectedIndex == 1),
                    
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

  void _showNotificationsSheet(BuildContext context, WidgetRef initialRef) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.7,
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
          ),
          child: Column(
            children: [
              const SizedBox(height: 16),
              Container(width: 50, height: 5, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(10))),
              const SizedBox(height: 16),
              Text('Notifications', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              Expanded(
                child: Consumer(
                  builder: (context, ref, child) {
                    final announcementsAsync = ref.watch(announcementsProvider);
                    return announcementsAsync.when(
                      data: (announcements) {
                    if (announcements.isEmpty) {
                      return Center(child: Text('Aucune notification', style: Theme.of(context).textTheme.bodyMedium));
                    }
                    return ListView.builder(
                      padding: const EdgeInsets.all(24),
                      itemCount: announcements.length,
                      itemBuilder: (context, index) {
                        final ann = announcements[index];
                        return Container(
                          margin: const EdgeInsets.only(bottom: 16),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.surface,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: AppTheme.primaryRed.withOpacity(0.3)),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(color: AppTheme.primaryRed.withOpacity(0.1), shape: BoxShape.circle),
                                child: const Icon(Icons.campaign, color: AppTheme.primaryRed),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(ann.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                    const SizedBox(height: 4),
                                    Text(ann.message, style: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color)),
                                    const SizedBox(height: 8),
                                    Text(
                                      _formatDate(ann.createdAt),
                                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    );
                  },
                      loading: () => const Center(child: CircularProgressIndicator(color: AppTheme.primaryRed)),
                      error: (err, stack) => Center(child: Text('Erreur de chargement: $err')),
                    );
                  }
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} à ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
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
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildNavItem(0, Icons.home_filled),
          _buildNavItem(1, Icons.favorite_border_rounded),
          _buildNavItem(2, Icons.explore_rounded),
        ],
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon) {
    final isSelected = _selectedIndex == index;
    return GestureDetector(
      onTap: () {
        if (index == 2) {
           Navigator.push(context, MaterialPageRoute(builder: (_) => const PlusOptionsScreen()));
        } else {
           setState(() => _selectedIndex = index);
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
