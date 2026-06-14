import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/utils/extensions.dart';

class QrScannerScreen extends ConsumerStatefulWidget {
  const QrScannerScreen({super.key});

  @override
  ConsumerState<QrScannerScreen> createState() => _QrScannerScreenState();
}

class _QrScannerScreenState extends ConsumerState<QrScannerScreen> {
  final MobileScannerController _controller = MobileScannerController();
  bool _processing = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _onDetect(BarcodeCapture capture) async {
    if (_processing) return;
    final barcode = capture.barcodes.firstOrNull;
    if (barcode?.rawValue == null) return;

    setState(() => _processing = true);
    await _controller.stop();

    final code = barcode!.rawValue!;
    try {
      // The QR contains the pickupCode; we look up the order by code
      final dio = ref.read(dioClientProvider);
      // POST to a pickup-verify endpoint — server matches code to order
      await dio.post('/orders/verify-pickup', data: {'pickupCode': code});
      if (mounted) {
        context.showSnackBar('Pickup confirmed successfully! ✓');
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        context.showErrorSnackBar('Invalid QR code: ${e.toString()}');
        setState(() => _processing = false);
        await _controller.start();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scan Pickup QR'),
        actions: [
          IconButton(
            icon: const Icon(Icons.flash_on),
            onPressed: () => _controller.toggleTorch(),
            tooltip: 'Toggle flash',
          ),
        ],
      ),
      body: Stack(
        children: [
          MobileScanner(
            controller: _controller,
            onDetect: _onDetect,
          ),
          // Scanning frame overlay
          Center(
            child: CustomPaint(
              size: const Size(240, 240),
              painter: _ScanFramePainter(),
            ),
          ),
          // Bottom instruction
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              color: Colors.black54,
              padding: EdgeInsets.fromLTRB(
                  24, 20, 24, MediaQuery.of(context).padding.bottom + 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_processing)
                    const CircularProgressIndicator(
                        color: AppColors.primaryLight)
                  else
                    const Icon(Icons.qr_code_scanner,
                        color: Colors.white, size: 32),
                  const SizedBox(height: 12),
                  Text(
                    _processing
                        ? 'Verifying pickup...'
                        : 'Point at the customer\'s QR code',
                    style: AppTextStyles.bodyMedium
                        .copyWith(color: Colors.white),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ScanFramePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    const cornerLength = 32.0;
    const strokeWidth = 4.0;
    const radius = 8.0;
    final paint = Paint()
      ..color = AppColors.primaryLight
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    // Top-left
    canvas.drawLine(
        const Offset(0, radius), const Offset(0, cornerLength), paint);
    canvas.drawLine(
        const Offset(radius, 0), const Offset(cornerLength, 0), paint);
    // Top-right
    canvas.drawLine(Offset(size.width - cornerLength, 0),
        Offset(size.width, 0), paint);
    canvas.drawLine(Offset(size.width, radius),
        Offset(size.width, cornerLength), paint);
    // Bottom-left
    canvas.drawLine(Offset(0, size.height - cornerLength),
        Offset(0, size.height), paint);
    canvas.drawLine(Offset(radius, size.height),
        Offset(cornerLength, size.height), paint);
    // Bottom-right
    canvas.drawLine(Offset(size.width - cornerLength, size.height),
        Offset(size.width, size.height), paint);
    canvas.drawLine(Offset(size.width, size.height - cornerLength),
        Offset(size.width, size.height), paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
