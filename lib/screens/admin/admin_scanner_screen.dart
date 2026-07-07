import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
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

  @override
  void dispose() {
    _amountController.dispose();
    _clientIdController.dispose();
    _scannerController.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) {
    final List<Barcode> barcodes = capture.barcodes;
    for (final barcode in barcodes) {
      if (barcode.rawValue != null) {
        setState(() {
          _clientIdController.text = barcode.rawValue!;
        });
        // Optional: stop scanning after successful read to prevent spam
        // _scannerController.stop(); 
      }
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
        title: const Text('Scanner & Ajouter Points', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.transparent,
        elevation: 0,
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
                border: Border.all(color: AppTheme.accentCyan.withOpacity(0.5), width: 2),
              ),
              clipBehavior: Clip.hardEdge,
              child: MobileScanner(
                controller: _scannerController,
                onDetect: _onDetect,
              ),
            ),
            
            const SizedBox(height: 32),
            const Text(
              'Ajout Manuel (Test)',
              style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _clientIdController,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                hintText: 'ID du Client (ex: USER_ID_12345)',
                prefixIcon: Icon(Icons.person, color: AppTheme.textGrey),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _amountController,
              keyboardType: TextInputType.number,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                hintText: 'Montant de l\'achat (DA)',
                prefixIcon: Icon(Icons.attach_money, color: AppTheme.textGrey),
              ),
            ),
            const SizedBox(height: 32),
            GradientButton(
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
