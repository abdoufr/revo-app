// ignore_for_file: avoid_classes_with_only_static_members
// Web stub for mobile_scanner — provides empty classes so the code compiles on Web.
// The real mobile_scanner is used only on mobile platforms.

class MobileScannerController {
  void dispose() {}
  void stop() {}
  void start() {}
}

class MobileScanner extends Object {
  final MobileScannerController? controller;
  final dynamic onDetect;
  const MobileScanner({this.controller, this.onDetect});
}

class BarcodeCapture {
  final List<Barcode> barcodes = [];
}

class Barcode {
  final String? rawValue = null;
}
