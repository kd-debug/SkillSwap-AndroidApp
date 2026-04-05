import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class ScannerScreen extends StatefulWidget {
  const ScannerScreen({super.key});

  @override
  State<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends State<ScannerScreen> {
  MobileScannerController? _controller;
  bool _hasScanned = false;
  String? _lastResult;
  bool _isFlashOn = false;

  bool get _demoMode =>
      kIsWeb || defaultTargetPlatform == TargetPlatform.windows;

  final _demoController = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (!_demoMode) {
      _controller = MobileScannerController(
        detectionSpeed: DetectionSpeed.normal,
        facing: CameraFacing.back,
      );
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    _demoController.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) {
    if (_hasScanned) return;
    final barcodes = capture.barcodes;
    if (barcodes.isEmpty) return;
    final raw = barcodes.first.rawValue ?? '';
    if (raw.isEmpty) return;
    setState(() {
      _hasScanned = true;
      _lastResult = raw;
    });
    _showResultSheet(raw);
  }

  void _onDemoScan() {
    final val = _demoController.text.trim();
    if (val.isEmpty) return;
    setState(() {
      _hasScanned = true;
      _lastResult = val;
    });
    _showResultSheet(val);
  }

  void _showResultSheet(String value) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => _ResultSheet(
        value: value,
        onScanAgain: () {
          Navigator.pop(ctx);
          setState(() {
            _hasScanned = false;
            _lastResult = null;
            _demoController.clear();
          });
          _controller?.start();
        },
      ),
    );
  }

  void _toggleFlash() {
    _controller?.toggleTorch();
    setState(() => _isFlashOn = !_isFlashOn);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('QR / Barcode Scanner',
            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          if (!_demoMode)
            IconButton(
              icon: Icon(
                  _isFlashOn ? Icons.flash_on : Icons.flash_off,
                  color: Colors.white),
              onPressed: _toggleFlash,
            ),
        ],
      ),
      body: _demoMode ? _buildDemoMode() : _buildScannerView(),
    );
  }

  Widget _buildScannerView() {
    return Stack(
      children: [
        MobileScanner(controller: _controller!, onDetect: _onDetect),
        Container(
          decoration: ShapeDecoration(
            shape: _ScannerOverlayShape(
              borderColor: Colors.tealAccent,
              borderRadius: 16,
              borderLength: 32,
              borderWidth: 4,
              cutOutSize: 260,
            ),
          ),
        ),
        Positioned(
          bottom: 60,
          left: 0,
          right: 0,
          child: Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Text(
                'Point the camera at a QR code or barcode',
                style: TextStyle(color: Colors.white, fontSize: 13),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDemoMode() {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 160,
            height: 160,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.tealAccent, width: 3),
              borderRadius: BorderRadius.circular(20),
              color: Colors.white10,
            ),
            child: const Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.qr_code_scanner, size: 80, color: Colors.tealAccent),
                SizedBox(height: 8),
                Text('Demo Mode',
                    style: TextStyle(color: Colors.tealAccent, fontSize: 12)),
              ],
            ),
          ),
          const SizedBox(height: 32),
          const Text(
            'Camera not available on this platform.\nEnter a value to simulate a scan:',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white70, fontSize: 14),
          ),
          const SizedBox(height: 24),
          TextField(
            controller: _demoController,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: 'e.g. skillswap://skill/web-development',
              hintStyle: const TextStyle(color: Colors.white38),
              filled: true,
              fillColor: Colors.white12,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              prefixIcon: const Icon(Icons.qr_code, color: Colors.tealAccent),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton.icon(
              onPressed: _onDemoScan,
              icon: const Icon(Icons.search),
              label: const Text('Simulate Scan'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.tealAccent,
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
          if (_lastResult != null) ...[
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.teal.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
                border:
                    Border.all(color: Colors.tealAccent.withOpacity(0.4)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.check_circle,
                      color: Colors.tealAccent, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Last scan: $_lastResult',
                      style: const TextStyle(color: Colors.white, fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _ResultSheet extends StatelessWidget {
  final String value;
  final VoidCallback onScanAgain;

  const _ResultSheet({required this.value, required this.onScanAgain});

  String _interpretValue(String val) {
    if (val.startsWith('skillswap://skill/')) {
      final skill =
          val.replaceFirst('skillswap://skill/', '').replaceAll('-', ' ');
      return '🎓 Skill Found: $skill';
    }
    if (val.startsWith('http')) return '🌐 Web URL detected';
    if (val.contains('@')) return '📧 Email address detected';
    return '📋 Plain text content';
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),
          const Icon(Icons.check_circle_rounded, color: Colors.teal, size: 56),
          const SizedBox(height: 12),
          const Text('Scan Successful!',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text(_interpretValue(value),
              style: const TextStyle(
                  color: Colors.teal, fontWeight: FontWeight.w600),
              textAlign: TextAlign.center),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(value,
                style: const TextStyle(fontFamily: 'monospace'),
                textAlign: TextAlign.center),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: onScanAgain,
            icon: const Icon(Icons.qr_code_scanner),
            label: const Text('Scan Again'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.teal,
              foregroundColor: Colors.white,
              minimumSize: const Size.fromHeight(48),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

class _ScannerOverlayShape extends ShapeBorder {
  final Color borderColor;
  final double borderWidth;
  final Color overlayColor;
  final double borderRadius;
  final double borderLength;
  final double cutOutSize;

  const _ScannerOverlayShape({
    this.borderColor = Colors.white,
    this.borderWidth = 3.0,
    this.overlayColor = Colors.black54,
    this.borderRadius = 0,
    this.borderLength = 40,
    this.cutOutSize = 250,
  });

  @override
  EdgeInsetsGeometry get dimensions => EdgeInsets.zero;

  @override
  Path getInnerPath(Rect rect, {TextDirection? textDirection}) => Path();

  @override
  Path getOuterPath(Rect rect, {TextDirection? textDirection}) =>
      Path()..addRect(rect);

  @override
  void paint(Canvas canvas, Rect rect, {TextDirection? textDirection}) {
    final paint = Paint()
      ..color = overlayColor
      ..style = PaintingStyle.fill;

    final center = rect.center;
    final cutOut =
        Rect.fromCenter(center: center, width: cutOutSize, height: cutOutSize);
    final rRect =
        RRect.fromRectAndRadius(cutOut, Radius.circular(borderRadius));

    final path = Path()
      ..addRect(rect)
      ..addRRect(rRect)
      ..fillType = PathFillType.evenOdd;

    canvas.drawPath(path, paint);

    final borderPaint = Paint()
      ..color = borderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = borderWidth
      ..strokeCap = StrokeCap.round;

    final l = cutOut.left;
    final t = cutOut.top;
    final r = cutOut.right;
    final b = cutOut.bottom;
    final bl = borderLength;

    canvas.drawLine(Offset(l, t + bl), Offset(l, t + borderRadius), borderPaint);
    canvas.drawArc(Rect.fromLTWH(l, t, borderRadius * 2, borderRadius * 2),
        3.14159, 3.14159 / 2, false, borderPaint);
    canvas.drawLine(Offset(l + borderRadius, t), Offset(l + bl, t), borderPaint);
    canvas.drawLine(Offset(r - bl, t), Offset(r - borderRadius, t), borderPaint);
    canvas.drawArc(
        Rect.fromLTWH(r - borderRadius * 2, t, borderRadius * 2, borderRadius * 2),
        -3.14159 / 2, 3.14159 / 2, false, borderPaint);
    canvas.drawLine(Offset(r, t + borderRadius), Offset(r, t + bl), borderPaint);
    canvas.drawLine(Offset(r, b - bl), Offset(r, b - borderRadius), borderPaint);
    canvas.drawArc(
        Rect.fromLTWH(r - borderRadius * 2, b - borderRadius * 2,
            borderRadius * 2, borderRadius * 2),
        0, 3.14159 / 2, false, borderPaint);
    canvas.drawLine(Offset(r - borderRadius, b), Offset(r - bl, b), borderPaint);
    canvas.drawLine(Offset(l + bl, b), Offset(l + borderRadius, b), borderPaint);
    canvas.drawArc(
        Rect.fromLTWH(l, b - borderRadius * 2, borderRadius * 2, borderRadius * 2),
        3.14159 / 2, 3.14159 / 2, false, borderPaint);
    canvas.drawLine(Offset(l, b - borderRadius), Offset(l, b - bl), borderPaint);
  }

  @override
  ShapeBorder scale(double t) => this;
}
