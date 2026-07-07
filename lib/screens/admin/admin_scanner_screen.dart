import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
  bool _isLoading = false;

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
        title: const Text('Scanner & Ajouter Points', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Placeholder for real camera scanner
            Container(
              height: 250,
              decoration: BoxDecoration(
                color: AppTheme.bgLighter,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: AppTheme.accentCyan.withOpacity(0.5), width: 2),
              ),
              child: const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.qr_code_scanner, size: 64, color: AppTheme.textGrey),
                    SizedBox(height: 16),
                    Text('Caméra (Scanner QR)', style: TextStyle(color: AppTheme.textGrey)),
                    Text('(Disponible sur mobile)', style: TextStyle(color: AppTheme.textGrey, fontSize: 12)),
                  ],
                ),
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
