// Web QR Scanner — calls JavaScript overlay (no HtmlElementView, works with CanvasKit)
// ignore: avoid_web_libraries_in_flutter
import 'dart:js' as js;
import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

class QrScannerWidget extends StatefulWidget {
  final void Function(String value) onScan;
  const QrScannerWidget({super.key, required this.onScan});

  @override
  State<QrScannerWidget> createState() => QrScannerWidgetState();
}

class QrScannerWidgetState extends State<QrScannerWidget> {
  bool _isReady = true; // waiting for user to press button

  @override
  void dispose() {
    // Stop camera if widget is disposed while scanning
    js.context.callMethod('revoStopScanner', []);
    super.dispose();
  }

  void _openScanner() {
    setState(() => _isReady = false);

    js.context.callMethod('revoStartScanner', [
      js.allowInterop((String result) {
        if (mounted) {
          setState(() => _isReady = true);
          widget.onScan(result);
        }
      }),
    ]);
  }

  /// Called by parent to re-open the scanner after result is processed
  void resetScan() {
    if (_isReady) _openScanner();
  }

  /// Stop the scanner (called on dispose or reset)
  void stopScan() {
    js.context.callMethod('revoStopScanner', []);
    if (mounted) setState(() => _isReady = true);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black,
      child: Center(
        child: _isReady
            ? _buildScanButton()
            : _buildScanningState(),
      ),
    );
  }

  Widget _buildScanButton() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: AppTheme.primaryOrange.withOpacity(0.15),
            shape: BoxShape.circle,
            border: Border.all(color: AppTheme.primaryOrange, width: 2),
          ),
          child: const Icon(
            Icons.qr_code_scanner_rounded,
            color: AppTheme.primaryOrange,
            size: 56,
          ),
        ),
        const SizedBox(height: 20),
        const Text(
          'Appuyez pour scanner',
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'La caméra s\'ouvrira dans un popup',
          style: TextStyle(
            color: Colors.white.withOpacity(0.6),
            fontSize: 13,
          ),
        ),
        const SizedBox(height: 24),
        ElevatedButton.icon(
          onPressed: _openScanner,
          icon: const Icon(Icons.camera_alt_rounded),
          label: const Text('Ouvrir la caméra'),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.primaryOrange,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            textStyle: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildScanningState() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const CircularProgressIndicator(color: AppTheme.primaryOrange),
        const SizedBox(height: 16),
        const Text(
          'Scanner actif...',
          style: TextStyle(color: Colors.white, fontSize: 15),
        ),
        const SizedBox(height: 16),
        TextButton.icon(
          onPressed: stopScan,
          icon: const Icon(Icons.close_rounded, color: Colors.white54),
          label: const Text(
            'Annuler',
            style: TextStyle(color: Colors.white54),
          ),
        ),
      ],
    );
  }
}
