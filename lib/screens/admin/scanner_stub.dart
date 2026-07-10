// Web stub for mobile_scanner.
// Provides Flutter-compatible empty classes so the code compiles on Web.
// These classes are NEVER actually used at runtime on Web (guarded by kIsWeb).

import 'package:flutter/material.dart';

class MobileScannerController {
  void dispose() {}
  void stop() {}
  void start() {}
}

class BarcodeCapture {
  List<Barcode> get barcodes => [];
}

class Barcode {
  String? get rawValue => null;
}

class MobileScanner extends StatelessWidget {
  final MobileScannerController? controller;
  final void Function(BarcodeCapture)? onDetect;

  const MobileScanner({
    super.key,
    this.controller,
    this.onDetect,
  });

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}
