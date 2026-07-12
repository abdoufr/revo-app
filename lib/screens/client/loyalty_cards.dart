import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../theme/app_theme.dart';
import '../../models/reward.dart';
import '../../providers/client_providers.dart'; // for ClientUser
import '../../providers/admin_providers.dart'; // for rewardConfigProvider
import '../../l10n/app_translations.dart';
import '../../services/vip_tier_service.dart';
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
  bool _isStampView = true;

  @override
  Widget build(BuildContext context) {
    final configAsync = ref.watch(rewardConfigProvider);

    return configAsync.when(
      data: (config) {
        int userPoints = widget.user.loyaltyPoints;
        int lifetimePoints = widget.user.lifetimePoints;
        int pointsForReward = config.pointsRequiredForReward;

        String vipTierName = VipTierService.getTierName(lifetimePoints);
        Color vipColor = VipTierService.getTierColor(lifetimePoints);

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildPrivilegeCard(vipTierName, vipColor, lifetimePoints),
              const SizedBox(height: 24),
              _buildStampCard(userPoints, pointsForReward, vipColor),
              const SizedBox(height: 24),
              _buildRewardsButton(vipColor),
            ],
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, __) => const SizedBox(),
    );
  }

  Widget _buildPrivilegeCard(String vipTierName, Color vipColor, int lifetimePoints) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [vipColor.withValues(alpha: 0.9), vipColor.withValues(alpha: 0.5)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: vipColor.withValues(alpha: 0.3), blurRadius: 15, offset: const Offset(0, 8)),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('CARTE PRIVILÈGE', style: TextStyle(color: Colors.white70, fontSize: 10, letterSpacing: 1.5, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text('Membre $vipTierName', style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                ],
              ),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(20)),
                    child: Row(
                      children: [
                        const Icon(Icons.stars_rounded, color: Colors.white, size: 16),
                        const SizedBox(width: 4),
                        Text(vipTierName.toUpperCase(), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () => _showVipTiersInfo(context),
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), shape: BoxShape.circle),
                      child: const Icon(Icons.info_outline_rounded, color: Colors.white, size: 20),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 32),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Avantage Niveau', style: TextStyle(color: Colors.white70, fontSize: 10)),
                  SizedBox(height: 4),
                  Text('Épargnez vos points', style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600)),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Text('Points Cumulés', style: TextStyle(color: Colors.white70, fontSize: 10)),
                  const SizedBox(height: 4),
                  Text('$lifetimePoints PTS', style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStampCard(int userPoints, int pointsForReward, Color vipColor) {
    const int totalStamps = 10;
    final int completedRewards = pointsForReward > 0 ? (userPoints / pointsForReward).floor() : 0;
    final int currentCyclePoints = pointsForReward > 0 ? userPoints % pointsForReward : userPoints;
    final int pointsPerStamp = pointsForReward > 0 ? (pointsForReward / totalStamps).ceil() : 1;
    final int activeStamps = pointsPerStamp > 0 ? (currentCyclePoints / pointsPerStamp).floor() : 0;
    final int displayStamps = activeStamps > totalStamps ? totalStamps : activeStamps;

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 5)),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Text('Ma Carte de Tampons', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      IconButton(
                        icon: Icon(_isStampView ? Icons.swap_horiz_rounded : Icons.grid_view_rounded, size: 20, color: Colors.grey),
                        onPressed: () => setState(() => _isStampView = !_isStampView),
                      ),
                    ],
                  ),
                  if (completedRewards > 0)
                    Text('🎁 $completedRewards cadeau${completedRewards > 1 ? 'x' : ''} disponible${completedRewards > 1 ? 's' : ''} !', style: TextStyle(color: vipColor, fontSize: 13, fontWeight: FontWeight.bold))
                  else
                    Text('$displayStamps / $totalStamps tampons actifs', style: const TextStyle(color: Colors.grey, fontSize: 12)),
                ],
              ),
              ElevatedButton.icon(
                onPressed: () => _showQrScannerSheet(context),
                icon: const Icon(Icons.qr_code_scanner_rounded, size: 16),
                label: const Text('Scanner'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: vipColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          if (_isStampView)
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 5,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
              ),
              itemCount: totalStamps,
              itemBuilder: (context, index) {
                final isActive = index < displayStamps;
                return Container(
                  decoration: BoxDecoration(
                    color: isActive ? vipColor : Colors.grey.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: isActive
                        ? const Icon(Icons.check, color: Colors.white, size: 20)
                        : Text('${index + 1}', style: const TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.bold)),
                  ),
                );
              },
            )
          else
            Column(
              children: [
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Points actuels', style: TextStyle(fontSize: 14)),
                    Text('$currentCyclePoints / $pointsForReward', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: vipColor)),
                  ],
                ),
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: LinearProgressIndicator(
                    value: pointsForReward > 0 ? (currentCyclePoints / pointsForReward).clamp(0.0, 1.0) : 0,
                    backgroundColor: Colors.grey.withValues(alpha: 0.2),
                    valueColor: AlwaysStoppedAnimation<Color>(vipColor),
                    minHeight: 12,
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildRewardsButton(Color vipColor) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const RewardsCatalogScreen())),
        icon: const Icon(Icons.storefront_rounded),
        label: const Text('Boutique de Cadeaux', style: TextStyle(fontWeight: FontWeight.bold)),
        style: ElevatedButton.styleFrom(
          backgroundColor: vipColor.withValues(alpha: 0.1),
          foregroundColor: vipColor,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          elevation: 0,
        ),
      ),
    );
  }

  void _showQrScannerSheet(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Votre Code Personnel', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                const Text('Présentez ce code à la caisse pour gagner des points.', textAlign: TextAlign.center, style: TextStyle(color: Colors.grey)),
                const SizedBox(height: 32),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 15, spreadRadius: 2),
                    ],
                  ),
                  child: QrImageView(
                    data: widget.user.id,
                    version: QrVersions.auto,
                    size: 200.0,
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.black,
                  ),
                ),
                const SizedBox(height: 24),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Fermer', style: TextStyle(fontSize: 16)),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
  void _showVipTiersInfo(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
          ),
          padding: EdgeInsets.only(bottom: MediaQuery.of(context).padding.bottom),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 12),
              Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.withOpacity(0.3), borderRadius: BorderRadius.circular(2))),
              const SizedBox(height: 24),
              Text('Paliers VIP', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900, letterSpacing: 1.2)),
              const SizedBox(height: 8),
              const Text('Découvrez les avantages de chaque niveau', style: TextStyle(color: Colors.grey)),
              const SizedBox(height: 24),
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                  child: Column(
                    children: List.generate(VipTierService.allTiers.length, (index) {
                      final tier = VipTierService.allTiers[index];
                      final color = tier['color'] as Color;
                      final minPoints = tier['minPoints'] as int;
                      
                      return Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [color.withOpacity(0.9), color.withOpacity(0.6)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(color: color.withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 4)),
                          ],
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: const BoxDecoration(color: Colors.white24, shape: BoxShape.circle),
                              child: const Icon(Icons.workspace_premium_rounded, color: Colors.white, size: 28),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(tier['name'] as String, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold, letterSpacing: 1.1)),
                                  const SizedBox(height: 4),
                                  Text(minPoints == 0 ? 'Niveau de départ' : 'À partir de $minPoints PTS', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        );
      },
    );
  }
}
