// Web QR Scanner — uses dart:html camera + jsQR JavaScript library
// This file is ONLY compiled on web (dart.library.html)
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;
// ignore: avoid_web_libraries_in_flutter
import 'dart:js' as js;
import 'dart:async';
import 'package:flutter/material.dart';
// ignore: avoid_web_libraries_in_flutter
import 'dart:ui_web' as ui_web;
import '../../theme/app_theme.dart';

class QrScannerWidget extends StatefulWidget {
  final void Function(String value) onScan;

  const QrScannerWidget({super.key, required this.onScan});

  @override
  State<QrScannerWidget> createState() => QrScannerWidgetState();
}

class QrScannerWidgetState extends State<QrScannerWidget> {
  late final String _viewId;
  html.VideoElement? _video;
  html.CanvasElement? _canvas;
  html.MediaStream? _stream;
  Timer? _timer;
  bool _scanning = true;
  bool _permissionDenied = false;
  bool _cameraError = false;

  @override
  void initState() {
    super.initState();
    _viewId = 'revo-qr-cam-${DateTime.now().millisecondsSinceEpoch}';
    _initCamera();
  }

  Future<void> _initCamera() async {
    _video = html.VideoElement()
      ..autoplay = true
      ..muted = true
      ..setAttribute('playsinline', 'true')
      ..style.width = '100%'
      ..style.height = '100%'
      ..style.objectFit = 'cover';

    _canvas = html.CanvasElement(width: 480, height: 360);

    // Register video element as Flutter platform view
    ui_web.platformViewRegistry.registerViewFactory(
      _viewId,
      (int id) => _video!,
    );

    try {
      _stream = await html.window.navigator.mediaDevices?.getUserMedia({
        'video': {
          'facingMode': 'environment', // rear camera on mobile
          'width': {'ideal': 640},
          'height': {'ideal': 480},
        },
        'audio': false,
      });

      if (_stream != null) {
        _video!.srcObject = _stream;
        await _video!.play();

        // Start scanning loop
        _timer = Timer.periodic(
          const Duration(milliseconds: 350),
          (_) => _scanFrame(),
        );

        if (mounted) setState(() {});
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          final msg = e.toString().toLowerCase();
          if (msg.contains('notallowed') || msg.contains('permission')) {
            _permissionDenied = true;
          } else {
            _cameraError = true;
          }
        });
      }
    }
  }

  void _scanFrame() {
    if (!_scanning) return;
    final video = _video;
    final canvas = _canvas;
    if (video == null || canvas == null) return;
    if (video.readyState < 2) return; // HAVE_CURRENT_DATA not reached yet

    try {
      // Draw current video frame onto canvas
      final ctx = canvas.context2D;
      ctx.drawImageScaled(video, 0, 0, canvas.width!, canvas.height!);

      // Extract pixel data
      final imageData = ctx.getImageData(0, 0, canvas.width!, canvas.height!);
      final pixelData = imageData.data;

      // Call jsQR via the bridge defined in index.html
      final result = js.context.callMethod('revoScanQR', [
        pixelData,
        canvas.width,
        canvas.height,
      ]);

      if (result != null) {
        final text = result.toString().trim();
        if (text.isNotEmpty) {
          _scanning = false; // stop scanning until reset
          _timer?.cancel();
          widget.onScan(text);
        }
      }
    } catch (_) {
      // Ignore frame processing errors silently
    }
  }

  /// Called by parent to resume scanning after a result was processed
  void resetScan() {
    if (!_scanning) {
      _scanning = true;
      _timer = Timer.periodic(
        const Duration(milliseconds: 350),
        (_) => _scanFrame(),
      );
    }
  }

  /// Pause scanning
  void stopScan() {
    _scanning = false;
    _timer?.cancel();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _stream?.getTracks().forEach((t) => t.stop());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_permissionDenied) {
      return _buildError(
        icon: Icons.no_photography_rounded,
        title: 'Permission refusée',
        subtitle: 'Autorisez l\'accès à la caméra\ndans les paramètres du navigateur.',
      );
    }

    if (_cameraError) {
      return _buildError(
        icon: Icons.videocam_off_rounded,
        title: 'Caméra indisponible',
        subtitle: 'Votre navigateur ne peut pas\naccéder à la caméra.',
      );
    }

    // Show video stream
    return HtmlElementView(viewType: _viewId);
  }

  Widget _buildError({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Container(
      color: Colors.black,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: AppTheme.primaryOrange, size: 52),
            const SizedBox(height: 16),
            Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }
}
