// Mobile QR Scanner — uses mobile_scanner package (Android / iOS)
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

export 'package:mobile_scanner/mobile_scanner.dart'
    show MobileScannerController, DetectionSpeed;

class QrScannerWidget extends StatefulWidget {
  final void Function(String value) onScan;

  const QrScannerWidget({super.key, required this.onScan});

  @override
  State<QrScannerWidget> createState() => QrScannerWidgetState();
}

class QrScannerWidgetState extends State<QrScannerWidget> {
  final MobileScannerController _controller = MobileScannerController(
    detectionSpeed: DetectionSpeed.noDuplicates,
  );

  void resetScan() => _controller.start();
  void stopScan() => _controller.stop();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MobileScanner(
      controller: _controller,
      onDetect: (capture) {
        for (final barcode in capture.barcodes) {
          final value = barcode.rawValue;
          if (value != null && value.isNotEmpty) {
            _controller.stop();
            widget.onScan(value);
            break;
          }
        }
      },
    );
  }
}
