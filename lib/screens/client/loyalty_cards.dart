import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../theme/app_theme.dart';
import '../../models/reward.dart';
import '../../providers/client_providers.dart'; // for ClientUser
import '../../l10n/app_translations.dart';
import 'rewards_catalog_screen.dart';

class LoyaltyCardsCarousel extends StatefulWidget {
  final ClientUser user;
  final RewardConfig config;
  final Color vipColor;
  final int lifetimePoints;
  final String vipTierName;

  const LoyaltyCardsCarousel({
    super.key,
    required this.user,
    required this.config,
    required this.vipColor,
    required this.lifetimePoints,
    required this.vipTierName,
  });

  @override
  State<LoyaltyCardsCarousel> createState() => _LoyaltyCardsCarouselState();
}

class _LoyaltyCardsCarouselState extends State<LoyaltyCardsCarousel> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    int userPoints = widget.user.loyaltyPoints;
    int pointsForReward = widget.config.pointsRequiredForReward;
    double progress = pointsForReward > 0 ? userPoints / pointsForReward : 0;
    if (progress > 1.0) progress = 1.0;

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
              _buildQrCard(progress, userPoints, pointsForReward),
              _buildStatsCard(progress, userPoints, pointsForReward),
              _buildVipCard(progress, userPoints, pointsForReward),
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
                color: _currentPage == index ? widget.vipColor : widget.vipColor.withOpacity(0.3),
                borderRadius: BorderRadius.circular(4),
              ),
            );
          }),
        ),
      ],
    );
  }

  Widget _buildCardBase({required List<Widget> children}) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        color: widget.vipColor,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: widget.vipColor.withOpacity(0.3),
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
  Widget _buildQrCard(double progress, int userPoints, int pointsForReward) {
    return _buildCardBase(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(widget.vipTierName, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
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
  Widget _buildStatsCard(double progress, int userPoints, int pointsForReward) {
    return _buildCardBase(
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
              foregroundColor: widget.vipColor,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
          ),
        ),
      ],
    );
  }

  // Card 3: VIP Rank
  Widget _buildVipCard(double progress, int userPoints, int pointsForReward) {
    return _buildCardBase(
      children: [
        const Icon(Icons.stars_rounded, color: Colors.white, size: 64),
        const SizedBox(height: 16),
        Text(widget.vipTierName, style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Text('total_points_earned'.tr(context) + ': ${widget.lifetimePoints}', style: const TextStyle(color: Colors.white70, fontSize: 16)),
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
              const Icon(Icons.account_balance_wallet_rounded, color: Colors.white),
              const SizedBox(width: 12),
              Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('total_spent'.tr(context), style: const TextStyle(color: Colors.white70, fontSize: 12)),
                  Text('${(widget.lifetimePoints * widget.config.spendingPerPoint).toStringAsFixed(0)} DA', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}
