import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../theme/app_theme.dart';
import '../../providers/admin_providers.dart';

// ─── Mobile-only scanner import (conditional) ────────────────────────────────
// On Web, mobile_scanner is not available, so we guard with kIsWeb at runtime.
// The import is still needed for type references, but the widget is never built on Web.
import 'package:mobile_scanner/mobile_scanner.dart'
    if (dart.library.html) 'scanner_stub.dart';

class AdminScannerScreen extends ConsumerStatefulWidget {
  const AdminScannerScreen({super.key});

  @override
  ConsumerState<AdminScannerScreen> createState() => _AdminScannerScreenState();
}

class _AdminScannerScreenState extends ConsumerState<AdminScannerScreen> {
  final _amountController = TextEditingController();
  final _clientIdController = TextEditingController();
  MobileScannerController? _scannerController;
  bool _isLoading = false;
  Map<String, dynamic>? _scannedUser;
  bool _isEligibleForReward = false;
  int _requiredPoints = 0;

  @override
  void initState() {
    super.initState();
    if (!kIsWeb) {
      _scannerController = MobileScannerController();
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _clientIdController.dispose();
    _scannerController?.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) async {
    final List<Barcode> barcodes = capture.barcodes;
    for (final barcode in barcodes) {
      if (barcode.rawValue != null && _clientIdController.text != barcode.rawValue!) {
        setState(() {
          _clientIdController.text = barcode.rawValue!;
        });
        await _fetchUserDetails(barcode.rawValue!);
        _scannerController?.stop();
      }
    }
  }

  Future<void> _fetchUserDetails(String userId) async {
    setState(() => _isLoading = true);
    try {
      final doc = await FirebaseFirestore.instance.collection('users').doc(userId).get();
      if (doc.exists && doc.data() != null) {
        final data = doc.data()!;
        final configDoc = await FirebaseFirestore.instance.collection('config').doc('rewards').get();
        int reqPoints = 50;
        if (configDoc.exists && configDoc.data() != null) {
          reqPoints = configDoc.data()!['pointsRequiredForReward'] ?? 50;
        }
        setState(() {
          _scannedUser = data;
          _requiredPoints = reqPoints;
          _isEligibleForReward = (data['loyalty_points'] ?? 0) >= reqPoints;
        });
      }
    } catch (e) {
      // Ignore
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
          const SnackBar(content: Text('Cadeau validé! Points déduits.'), backgroundColor: AppTheme.success),
        );
        _clientIdController.clear();
        setState(() {
          _scannedUser = null;
          _isEligibleForReward = false;
        });
        _scannerController?.start();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur: $e'), backgroundColor: AppTheme.error));
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
        const SnackBar(content: Text('Veuillez entrer un montant valide et un ID Client.')),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      await ref.read(adminActionsProvider).addPointsToUser(clientId, amount);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Points ajoutés avec succès!', style: TextStyle(color: Colors.white)), backgroundColor: AppTheme.success),
        );
        _amountController.clear();
        _clientIdController.clear();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e', style: const TextStyle(color: Colors.white)), backgroundColor: AppTheme.error),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Scanner & Ajouter Points', style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ─── Camera Scanner (Mobile only) ─────────────────────────────
            if (!kIsWeb) ...[
              Container(
                height: 300,
                decoration: BoxDecoration(
                  color: Colors.black,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: AppTheme.primaryOrange.withOpacity(0.5), width: 2),
                ),
                clipBehavior: Clip.hardEdge,
                child: MobileScanner(
                  controller: _scannerController!,
                  onDetect: _onDetect,
                ),
              ),
              const SizedBox(height: 32),
            ] else ...[
              // ─── Web alternative: info banner ──────────────────────────
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppTheme.primaryOrange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: AppTheme.primaryOrange.withOpacity(0.4), width: 1.5),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline_rounded, color: AppTheme.primaryOrange, size: 32),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Mode Web',
                            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: AppTheme.primaryOrange,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Utilisez l\'application mobile pour scanner les QR codes. Sur Web, entrez l\'ID client manuellement.',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
            ],

            // ─── Manual Input ─────────────────────────────────────────────
            Text(
              kIsWeb ? 'Entrer l\'ID Client' : 'Ajout Manuel',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _clientIdController,
              style: Theme.of(context).textTheme.bodyLarge,
              onSubmitted: (_) => _fetchUserDetails(_clientIdController.text.trim()),
              decoration: InputDecoration(
                hintText: 'ID du Client (ex: USER_ID_12345)',
                prefixIcon: const Icon(Icons.person, color: AppTheme.primaryOrange),
                suffixIcon: kIsWeb
                    ? IconButton(
                        icon: const Icon(Icons.search_rounded, color: AppTheme.primaryOrange),
                        onPressed: () => _fetchUserDetails(_clientIdController.text.trim()),
                      )
                    : null,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _amountController,
              keyboardType: TextInputType.number,
              style: Theme.of(context).textTheme.bodyLarge,
              decoration: const InputDecoration(
                hintText: 'Montant de l\'achat (DA)',
                prefixIcon: Icon(Icons.attach_money, color: AppTheme.primaryOrange),
              ),
            ),
            const SizedBox(height: 32),

            // ─── Scanned User Info ────────────────────────────────────────
            if (_scannedUser != null) ...[
              SoftCard(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Text('Client: ${_scannedUser!['name']}', style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontSize: 18)),
                    Text('Points: ${_scannedUser!['loyalty_points']}', style: const TextStyle(color: AppTheme.primaryOrange, fontSize: 24, fontWeight: FontWeight.bold)),
                    if (_isEligibleForReward) ...[
                      const SizedBox(height: 16),
                      const Text('🎉 Éligible pour un CADEAU !', style: TextStyle(color: AppTheme.primaryOrange, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      PrimaryButton(
                        onPressed: _isLoading ? () {} : _claimReward,
                        text: 'Valider le Cadeau',
                        isLoading: _isLoading,
                      ),
                    ]
                  ],
                ),
              ),
              const SizedBox(height: 32),
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
