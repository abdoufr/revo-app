import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../theme/app_theme.dart';
import '../../providers/admin_providers.dart';

class AdminScannerScreen extends ConsumerStatefulWidget {
  const AdminScannerScreen({super.key});

  @override
  ConsumerState<AdminScannerScreen> createState() => _AdminScannerScreenState();
}

class _AdminScannerScreenState extends ConsumerState<AdminScannerScreen> {
  final _amountController = TextEditingController();
  final _clientIdController = TextEditingController();
  final MobileScannerController _scannerController = MobileScannerController();
  bool _isLoading = false;
  Map<String, dynamic>? _scannedUser;
  bool _isEligibleForReward = false;
  int _requiredPoints = 0;

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
      if (barcode.rawValue != null && _clientIdController.text != barcode.rawValue!) {
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
        _scannerController.start();
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
        // Optional: resume scanning if it was stopped
        // _scannerController.start();
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
            // Real Camera Scanner
            Container(
              height: 300,
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: AppTheme.primaryOrange.withOpacity(0.5), width: 2),
              ),
              clipBehavior: Clip.hardEdge,
              child: MobileScanner(
                controller: _scannerController,
                onDetect: _onDetect,
              ),
            ),
            
            const SizedBox(height: 32),
            Text(
              'Ajout Manuel (Test)',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _clientIdController,
              style: Theme.of(context).textTheme.bodyLarge,
              decoration: const InputDecoration(
                hintText: 'ID du Client (ex: USER_ID_12345)',
                prefixIcon: Icon(Icons.person, color: AppTheme.primaryOrange),
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
