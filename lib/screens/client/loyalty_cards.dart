import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../theme/app_theme.dart';
import '../../models/reward.dart';
import '../../providers/client_providers.dart'; // for ClientUser
import '../../providers/admin_providers.dart'; // for rewardConfigProvider
import '../../l10n/app_translations.dart';
import 'rewards_catalog_screen.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class LoyaltyCardsCarousel extends ConsumerStatefulWidget {
  final ClientUser user;

  const LoyaltyCardsCarousel({
    super.key,
    required this.user,
  });

  @override
  ConsumerState<LoyaltyCardsCarousel> createState() => _LoyaltyCardsCarouselState();
}

class _LoyaltyCardsCarouselState extends ConsumerState<LoyaltyCardsCarousel> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final configAsync = ref.watch(rewardConfigProvider);

    return configAsync.when(
      data: (config) {
        int userPoints = widget.user.loyaltyPoints;
        int lifetimePoints = widget.user.lifetimePoints;
        int pointsForReward = config.pointsRequiredForReward;
        double progress = pointsForReward > 0 ? userPoints / pointsForReward : 0;
        if (progress > 1.0) progress = 1.0;

        String vipTierName = 'Nouveau';
        Color vipColor = Colors.grey;
        if (lifetimePoints >= 2000) {
          vipTierName = 'Gold';
          vipColor = const Color(0xFFFFD700);
        } else if (lifetimePoints >= 500) {
          vipTierName = 'Silver';
          vipColor = const Color(0xFFC0C0C0);
        } else if (lifetimePoints >= 100) {
          vipTierName = 'Bronze';
          vipColor = const Color(0xFFCD7F32);
        } else {
          vipTierName = 'Membre';
          vipColor = AppTheme.primaryRed;
        }

    return Column(
      children: [
        SizedBox(
          height: 380, // Fixed height for the card
          child: PageView(
            controller: _pageController,
            onPageChanged: (int page) {
              setState(() {
                _currentPage = page;
              });
            },
              children: [
                _buildQrCard(progress, userPoints, pointsForReward, vipTierName, vipColor),
                _buildStatsCard(progress, userPoints, pointsForReward, vipColor),
                _buildVipCard(progress, userPoints, pointsForReward, vipTierName, vipColor, lifetimePoints, config),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(3, (index) {
              return AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                margin: const EdgeInsets.symmetric(horizontal: 4),
                height: 8,
                width: _currentPage == index ? 24 : 8,
                decoration: BoxDecoration(
                  color: _currentPage == index ? vipColor : vipColor.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(4),
                ),
              );
            }),
        ),
      ],
    );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, __) => const SizedBox(),
    );
  }

  Widget _buildCardBase({required List<Widget> children, required Color vipColor}) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        color: vipColor,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: vipColor.withOpacity(0.3),
            blurRadius: 25,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          children: children,
        ),
      ),
    );
  }

  // Card 1: QR Code
  Widget _buildQrCard(double progress, int userPoints, int pointsForReward, String vipTierName, Color vipColor) {
    return _buildCardBase(
      vipColor: vipColor,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(vipTierName, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        ),
        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 15, spreadRadius: 2),
            ],
          ),
          child: QrImageView(
            data: widget.user.id,
            version: QrVersions.auto,
            size: 130.0,
            backgroundColor: Colors.white,
            foregroundColor: Colors.black,
          ),
        ),
        const Spacer(),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('points'.tr(context), style: const TextStyle(color: Colors.white, fontSize: 18)),
            Text('$userPoints / $pointsForReward', style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
          ],
        ),
        const SizedBox(height: 16),
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: LinearProgressIndicator(
            value: progress,
            backgroundColor: Colors.white.withOpacity(0.3),
            valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
            minHeight: 12,
          ),
        ),
      ],
    );
  }

  // Card 2: Stats
  Widget _buildStatsCard(double progress, int userPoints, int pointsForReward, Color vipColor) {
    return _buildCardBase(
      vipColor: vipColor,
      children: [
        Text('stats'.tr(context), style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
        const SizedBox(height: 32),
        SizedBox(
          height: 140,
          width: 140,
          child: Stack(
            fit: StackFit.expand,
            children: [
              CircularProgressIndicator(
                value: progress,
                strokeWidth: 12,
                backgroundColor: Colors.white.withOpacity(0.2),
                valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
              ),
              Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('$userPoints', style: const TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.bold)),
                    Text('points'.tr(context), style: const TextStyle(color: Colors.white70, fontSize: 14)),
                  ],
                ),
              ),
            ],
          ),
        ),
        const Spacer(),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const RewardsCatalogScreen())),
            icon: const Icon(Icons.storefront_rounded),
            label: const Text('Boutique de Cadeaux', style: TextStyle(fontWeight: FontWeight.bold)),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: vipColor,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
          ),
        ),
      ],
    );
  }

  // Card 3: VIP Rank
  Widget _buildVipCard(double progress, int userPoints, int pointsForReward, String vipTierName, Color vipColor, int lifetimePoints, RewardConfig config) {
    return _buildCardBase(
      vipColor: vipColor,
      children: [
        const Icon(Icons.stars_rounded, color: Colors.white, size: 64),
        const SizedBox(height: 16),
        Text(vipTierName, style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Text('total_points_earned'.tr(context) + ': $lifetimePoints', style: const TextStyle(color: Colors.white70, fontSize: 16)),
        const Spacer(),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.card_giftcard_rounded, color: Colors.white),
              const SizedBox(width: 12),
              Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Avant prochain cadeau', style: TextStyle(color: Colors.white70, fontSize: 12)),
                  Text('${pointsForReward - userPoints} points', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}
