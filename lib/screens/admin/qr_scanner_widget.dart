// Conditional export: uses Web implementation on browsers, Mobile on iOS/Android
export 'qr_scanner_mobile.dart'
    if (dart.library.html) 'qr_scanner_web.dart';
