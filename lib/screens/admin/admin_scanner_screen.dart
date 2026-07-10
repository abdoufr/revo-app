import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../theme/app_theme.dart';
import '../../providers/admin_providers.dart';
import 'qr_scanner_widget.dart'; // conditional: web or mobile impl

class AdminScannerScreen extends ConsumerStatefulWidget {
  const AdminScannerScreen({super.key});

  @override
  ConsumerState<AdminScannerScreen> createState() => _AdminScannerScreenState();
}

class _AdminScannerScreenState extends ConsumerState<AdminScannerScreen> {
  final _amountController = TextEditingController();
  final _clientIdController = TextEditingController();
  final GlobalKey<QrScannerWidgetState> _scannerKey = GlobalKey();

  bool _isLoading = false;
  Map<String, dynamic>? _scannedUser;
  bool _isEligibleForReward = false;
  int _requiredPoints = 0;

  @override
  void dispose() {
    _amountController.dispose();
    _clientIdController.dispose();
    super.dispose();
  }

  // Called by the QrScannerWidget when a QR code is detected
  void _onQrDetected(String value) {
    if (_clientIdController.text == value) return;
    setState(() => _clientIdController.text = value);
    _fetchUserDetails(value);
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
        setState(() {
          _scannedUser = data;
          _requiredPoints = reqPoints;
          _isEligibleForReward = (data['loyalty_points'] ?? 0) >= reqPoints;
        });
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Client introuvable.'),
              backgroundColor: AppTheme.error,
            ),
          );
          setState(() => _scannedUser = null);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: $e'),
            backgroundColor: AppTheme.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
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
        _resetScan();
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
          content: Text('Veuillez entrer un montant valide et un ID Client.'),
        ),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      await ref.read(adminActionsProvider).addPointsToUser(clientId, amount);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Points ajoutés avec succès!',
                style: TextStyle(color: Colors.white)),
            backgroundColor: AppTheme.success,
          ),
        );
        _resetScan();
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
    _amountController.clear();
    setState(() {
      _scannedUser = null;
      _isEligibleForReward = false;
    });
    _scannerKey.currentState?.resetScan();
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
          if (_scannedUser != null || _clientIdController.text.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.refresh_rounded),
              tooltip: 'Nouveau scan',
              onPressed: _resetScan,
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ─── Camera Scanner (Web uses dart:html, Mobile uses mobile_scanner) ──
            Container(
              height: 280,
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: AppTheme.primaryOrange.withOpacity(0.6),
                  width: 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primaryOrange.withOpacity(0.15),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              clipBehavior: Clip.hardEdge,
              child: Stack(
                children: [
                  QrScannerWidget(
                    key: _scannerKey,
                    onScan: _onQrDetected,
                  ),
                  // Scan frame overlay
                  Center(
                    child: Container(
                      width: 180,
                      height: 180,
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: AppTheme.primaryOrange,
                          width: 2.5,
                        ),
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),
                  // Bottom label
                  Positioned(
                    bottom: 12,
                    left: 0,
                    right: 0,
                    child: Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 6),
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

            // ─── Manual Input ─────────────────────────────────────────────
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _clientIdController,
                    style: Theme.of(context).textTheme.bodyLarge,
                    decoration: InputDecoration(
                      hintText: 'ID Client (scan auto ou manuel)',
                      prefixIcon:
                          const Icon(Icons.person, color: AppTheme.primaryOrange),
                      suffixIcon: _clientIdController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.close_rounded),
                              onPressed: _resetScan,
                            )
                          : null,
                    ),
                    onChanged: (_) => setState(() {}),
                    onSubmitted: (val) {
                      if (val.trim().isNotEmpty) {
                        _fetchUserDetails(val.trim());
                      }
                    },
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: () {
                    final id = _clientIdController.text.trim();
                    if (id.isNotEmpty) _fetchUserDetails(id);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryOrange,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 16),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Icon(Icons.search_rounded),
                ),
              ],
            ),

            const SizedBox(height: 16),

            TextField(
              controller: _amountController,
              keyboardType: TextInputType.number,
              style: Theme.of(context).textTheme.bodyLarge,
              decoration: const InputDecoration(
                hintText: 'Montant de l\'achat (DA)',
                prefixIcon:
                    Icon(Icons.attach_money, color: AppTheme.primaryOrange),
              ),
            ),

            const SizedBox(height: 28),

            // ─── Loading ──────────────────────────────────────────────────
            if (_isLoading)
              const Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  child: CircularProgressIndicator(
                      color: AppTheme.primaryOrange),
                ),
              )

            // ─── Scanned User Info ────────────────────────────────────────
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
                            color: AppTheme.primaryOrange.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.person_rounded,
                              color: AppTheme.primaryOrange, size: 28),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _scannedUser!['name'] ?? 'Client',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyLarge
                                    ?.copyWith(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                              ),
                              Text(
                                '${_scannedUser!['loyalty_points'] ?? 0} points',
                                style: const TextStyle(
                                  color: AppTheme.primaryOrange,
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    if (_isEligibleForReward) ...[
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppTheme.success.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                              color: AppTheme.success.withOpacity(0.3)),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.card_giftcard,
                                color: AppTheme.success),
                            SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                '🎉 Éligible pour un CADEAU !',
                                style: TextStyle(
                                    color: AppTheme.success,
                                    fontWeight: FontWeight.bold),
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
