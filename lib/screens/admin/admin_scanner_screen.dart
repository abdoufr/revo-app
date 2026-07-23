import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../theme/app_theme.dart';
import '../../providers/admin_providers.dart';
import '../../providers/auth_providers.dart';

import '../../models/claimed_reward.dart';

class AdminScannerScreen extends ConsumerStatefulWidget {
  const AdminScannerScreen({super.key});

  @override
  ConsumerState<AdminScannerScreen> createState() => _AdminScannerScreenState();
}

class _AdminScannerScreenState extends ConsumerState<AdminScannerScreen> {
  final _amountController = TextEditingController();
  final _clientIdController = TextEditingController();
  final MobileScannerController _scannerController = MobileScannerController(
    detectionSpeed: DetectionSpeed.noDuplicates,
  );

  bool _isLoading = false;
  bool _torchEnabled = false;
  Map<String, dynamic>? _scannedUser;
  bool _isEligibleForReward = false;
  int _requiredPoints = 0;
  List<ClaimedReward> _pendingRewards = [];

  @override
  void dispose() {
    _amountController.dispose();
    _clientIdController.dispose();
    _scannerController.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) async {
    final List<Barcode> barcodes = capture.barcodes;
    for (final barcode in barcodes) {
      if (barcode.rawValue != null &&
          _clientIdController.text != barcode.rawValue!) {
        setState(() {
          _clientIdController.text = barcode.rawValue!;
        });
        await _fetchUserDetails(barcode.rawValue!);
        _scannerController.stop();
      }
    }
  }

  Future<void> _fetchUserDetails(String userId) async {
    setState(() => _isLoading = true);
    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get();
      if (doc.exists && doc.data() != null) {
        final data = doc.data()!;
        final configDoc = await FirebaseFirestore.instance
            .collection('config')
            .doc('rewards')
            .get();
        int reqPoints = 50;
        if (configDoc.exists && configDoc.data() != null) {
          reqPoints = configDoc.data()!['pointsRequiredForReward'] ?? 50;
        }

        // Fetch pending claimed rewards
        final rewardsSnap = await FirebaseFirestore.instance
            .collection('claimed_rewards')
            .where('userId', isEqualTo: userId)
            .where('status', isEqualTo: 'pending')
            .get();

        final rewardsList = rewardsSnap.docs
            .map((d) => ClaimedReward.fromMap(d.id, d.data()))
            .toList();

        setState(() {
          _scannedUser = data;
          _requiredPoints = reqPoints;
          _isEligibleForReward = (data['loyalty_points'] ?? 0) >= reqPoints;
          _pendingRewards = rewardsList;
        });
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Client introuvable.'),
              backgroundColor: AppTheme.error,
            ),
          );
        }
        setState(() => _scannedUser = null);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e'), backgroundColor: AppTheme.error),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _markRewardAsClaimed(String rewardId) async {
    try {
      await FirebaseFirestore.instance.collection('claimed_rewards').doc(rewardId).update({
        'status': 'claimed',
        'claimedAt': DateTime.now().millisecondsSinceEpoch,
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Cadeau marqué comme remis au client !'), backgroundColor: AppTheme.success),
        );
      }
      if (_clientIdController.text.isNotEmpty) {
        _fetchUserDetails(_clientIdController.text.trim());
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e'), backgroundColor: AppTheme.error),
        );
      }
    }
  }

  Future<void> _claimReward() async {
    final clientId = _clientIdController.text.trim();
    if (clientId.isEmpty) return;

    setState(() => _isLoading = true);
    try {
      await ref.read(adminActionsProvider).claimReward(clientId, _requiredPoints);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Cadeau validé! Points déduits.'),
            backgroundColor: AppTheme.success,
          ),
        );
        _clientIdController.clear();
        setState(() {
          _scannedUser = null;
          _isEligibleForReward = false;
        });
        _scannerController.start();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e'), backgroundColor: AppTheme.error),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _submitPoints() async {
    final amount = double.tryParse(_amountController.text);
    final clientId = _clientIdController.text.trim();

    if (amount == null || amount <= 0 || clientId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Veuillez entrer un montant valide et un ID Client.')),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      final authUser = ref.read(authStateProvider).value;
      String adminName = 'Admin';
      if (authUser != null) {
        final adminDoc = await FirebaseFirestore.instance.collection('users').doc(authUser.uid).get();
        adminName = adminDoc.data()?['name'] ?? 'Admin';
      }
      await ref.read(adminActionsProvider).addPointsToUser(clientId, amount, adminName: adminName);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Points ajoutés avec succès!',
                style: TextStyle(color: Colors.white)),
            backgroundColor: AppTheme.success,
          ),
        );
        _amountController.clear();
        _clientIdController.clear();
        setState(() => _scannedUser = null);
        _scannerController.start();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: $e', style: const TextStyle(color: Colors.white)),
            backgroundColor: AppTheme.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _resetScan() {
    _clientIdController.clear();
    setState(() {
      _scannedUser = null;
      _isEligibleForReward = false;
    });
    _scannerController.start();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Scanner & Ajouter Points',
          style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color),
        ),
        actions: [
          IconButton(
            icon: Icon(
              _torchEnabled ? Icons.flash_on_rounded : Icons.flash_off_rounded,
              color: _torchEnabled ? Theme.of(context).primaryColor : null,
            ),
            onPressed: () {
              _scannerController.toggleTorch();
              setState(() => _torchEnabled = !_torchEnabled);
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ─── Camera Scanner ──────────────────────────────────────────
            Container(
              height: 280,
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: Theme.of(context).primaryColor.withOpacity(0.6),
                  width: 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Theme.of(context).primaryColor.withOpacity(0.15),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              clipBehavior: Clip.hardEdge,
              child: Stack(
                children: [
                  MobileScanner(
                    controller: _scannerController,
                    onDetect: _onDetect,
                  ),
                  // Scan overlay frame
                  Center(
                    child: Container(
                      width: 180,
                      height: 180,
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: Theme.of(context).primaryColor,
                          width: 2.5,
                        ),
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),
                  // "Scan QR" label
                  Positioned(
                    bottom: 16,
                    left: 0,
                    right: 0,
                    child: Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.black54,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Text(
                          'Pointez vers le QR Code du client',
                          style: TextStyle(color: Colors.white, fontSize: 12),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 28),

            // ─── Manual ID Input ─────────────────────────────────────────
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _clientIdController,
                    style: Theme.of(context).textTheme.bodyLarge,
                    decoration: InputDecoration(
                      hintText: 'ID Client (scan auto ou saisie manuelle)',
                      prefixIcon: Icon(Icons.person, color: Theme.of(context).primaryColor),
                      suffixIcon: _clientIdController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.close_rounded),
                              onPressed: _resetScan,
                            )
                          : null,
                    ),
                    onSubmitted: (val) {
                      if (val.trim().isNotEmpty) {
                        _fetchUserDetails(val.trim());
                      }
                    },
                    onChanged: (_) => setState(() {}),
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton.icon(
                  onPressed: () {
                    final id = _clientIdController.text.trim();
                    if (id.isNotEmpty) _fetchUserDetails(id);
                  },
                  icon: const Icon(Icons.search_rounded),
                  label: const Text('Chercher'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            TextField(
              controller: _amountController,
              keyboardType: TextInputType.number,
              style: Theme.of(context).textTheme.bodyLarge,
              decoration: InputDecoration(
                hintText: 'Montant de l\'achat (DA)',
                prefixIcon: Icon(Icons.attach_money, color: Theme.of(context).primaryColor),
              ),
            ),

            const SizedBox(height: 28),

            // ─── Scanned User Info ────────────────────────────────────────
            if (_isLoading)
              Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  child: CircularProgressIndicator(color: Theme.of(context).primaryColor),
                ),
              )
            else if (_scannedUser != null) ...[
              SoftCard(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Theme.of(context).primaryColor.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(Icons.person_rounded, color: Theme.of(context).primaryColor, size: 28),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _scannedUser!['name'] ?? 'Client',
                                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                '${_scannedUser!['loyalty_points'] ?? 0} points',
                                style: TextStyle(
                                  color: Theme.of(context).primaryColor,
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    if (_pendingRewards.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      const Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          '🎁 Cadeau(x) à remettre :',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Column(
                        children: _pendingRewards.map((reward) {
                          return Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFF9800).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: const Color(0xFFFF9800)),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.card_giftcard, color: Color(0xFFFF9800)),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(reward.rewardTitle, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                                      Text('Provenance: ${reward.source}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                                    ],
                                  ),
                                ),
                                ElevatedButton(
                                  onPressed: () => _markRewardAsClaimed(reward.id),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppTheme.success,
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                  ),
                                  child: const Text('Remettre', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                    if (_isEligibleForReward) ...[
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppTheme.success.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppTheme.success.withOpacity(0.3)),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.card_giftcard, color: AppTheme.success),
                            SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                '🎉 Éligible pour un CADEAU !',
                                style: TextStyle(
                                  color: AppTheme.success,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      PrimaryButton(
                        onPressed: _claimReward,
                        text: 'Valider le Cadeau',
                        isLoading: _isLoading,
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 20),
            ],

            PrimaryButton(
              text: 'Ajouter les Points',
              isLoading: _isLoading,
              onPressed: _submitPoints,
            ),
          ],
        ),
      ),
    );
  }
}