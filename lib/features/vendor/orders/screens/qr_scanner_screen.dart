import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../../../core/constants/api_endpoints.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/utils/extensions.dart';
import '../../../../core/utils/formatters.dart';
import '../providers/vendor_orders_provider.dart';

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
    final raw = capture.barcodes.firstOrNull?.rawValue;
    if (raw == null) return;

    setState(() => _processing = true);
    await _controller.stop();

    try {
      final Map<String, dynamic> payload = jsonDecode(raw) as Map<String, dynamic>;
      final orderId = payload['o'] as String?;
      final pickupCode = payload['c'] as String?;

      if (orderId == null || pickupCode == null) {
        throw const FormatException('Invalid QR code format');
      }

      if (!mounted) return;
      final confirmed = await _showConfirmSheet(orderId, pickupCode);
      if (confirmed != true) {
        setState(() => _processing = false);
        await _controller.start();
        return;
      }

      await _confirmPickup(orderId, pickupCode);
    } on FormatException {
      if (mounted) {
        context.showErrorSnackBar('Invalid QR code — not a Food Rescue Nepal code');
        setState(() => _processing = false);
        await _controller.start();
      }
    } catch (e) {
      if (mounted) {
        context.showErrorSnackBar(e.toString());
        setState(() => _processing = false);
        await _controller.start();
      }
    }
  }

  Future<bool?> _showConfirmSheet(String orderId, String pickupCode) async {
    final orderAsync = ref.read(vendorOrderDetailProvider(orderId));

    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _ConfirmPickupSheet(
        orderId: orderId,
        pickupCode: pickupCode,
        orderAsync: orderAsync,
      ),
    );
  }

  Future<void> _confirmPickup(String orderId, String pickupCode) async {
    try {
      final dio = ref.read(dioClientProvider);
      await dio.patch(
        ApiEndpoints.orderPickup(orderId),
        data: {'pickupCode': pickupCode},
      );
      ref.invalidate(vendorOrdersProvider);
      if (!mounted) return;
      await _showSuccessSheet();
      // Wait for the sheet's exit animation before popping the scanner,
      // so we never call pop() while another navigation is in progress.
      await Future.delayed(const Duration(milliseconds: 300));
      if (mounted) context.pop();
    } catch (e) {
      if (mounted) {
        context.showErrorSnackBar(e.toString());
        setState(() => _processing = false);
        await _controller.start();
      }
    }
  }

  Future<void> _showSuccessSheet() async {
    await showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => const _SuccessSheet(),
    );
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
          // Bottom instruction panel
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
                    const CircularProgressIndicator(color: AppColors.primaryLight)
                  else
                    const Icon(Icons.qr_code_scanner,
                        color: Colors.white, size: 32),
                  const SizedBox(height: 12),
                  Text(
                    _processing
                        ? 'Verifying pickup...'
                        : "Point at the customer's QR code",
                    style: AppTextStyles.bodyMedium.copyWith(color: Colors.white),
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

// ─── Confirmation bottom sheet ─────────────────────────────────────────────

class _ConfirmPickupSheet extends ConsumerWidget {
  const _ConfirmPickupSheet({
    required this.orderId,
    required this.pickupCode,
    required this.orderAsync,
  });
  final String orderId;
  final String pickupCode;
  final AsyncValue<VendorOrder> orderAsync;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Re-watch in case it wasn't loaded yet
    final order = ref.watch(vendorOrderDetailProvider(orderId));

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(
          24, 20, 24, MediaQuery.of(context).padding.bottom + 24),
      child: order.when(
        data: (o) => Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.neutral300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.success.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.qr_code_scanner,
                      color: AppColors.success, size: 28),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Confirm Pickup', style: AppTextStyles.h4),
                      Text('Review order before confirming',
                          style: AppTextStyles.caption
                              .copyWith(color: AppColors.textSecondary)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            const Divider(),
            const SizedBox(height: 12),
            if (o.listing != null)
              _Row('Item', o.listing!.name),
            _Row('Quantity', '×${o.quantity}'),
            _Row('Total', Formatters.formatNPR(o.totalAmount)),
            _Row('Code', pickupCode,
                valueStyle: AppTextStyles.bodyMedium.copyWith(
                  fontFamily: 'monospace',
                  letterSpacing: 2,
                  color: AppColors.primaryMedium,
                )),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context, false),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                    ),
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context, true),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.success,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                    ),
                    child: const Text('Complete Pickup',
                        style: TextStyle(color: Colors.white,
                            fontWeight: FontWeight.w600)),
                  ),
                ),
              ],
            ),
          ],
        ),
        loading: () => const Padding(
          padding: EdgeInsets.all(40),
          child: Center(
              child: CircularProgressIndicator(color: AppColors.primaryMedium)),
        ),
        error: (_, __) => Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, color: AppColors.error, size: 48),
              const SizedBox(height: 12),
              const Text('Could not load order details'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Confirm anyway'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row(this.label, this.value, {this.valueStyle});
  final String label;
  final String value;
  final TextStyle? valueStyle;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          Text(label,
              style: AppTextStyles.bodySmall
                  .copyWith(color: AppColors.textSecondary)),
          const Spacer(),
          Text(value,
              style: valueStyle ??
                  AppTextStyles.bodyMedium
                      .copyWith(fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}

// ─── Success sheet ─────────────────────────────────────────────────────────

class _SuccessSheet extends StatefulWidget {
  const _SuccessSheet();

  @override
  State<_SuccessSheet> createState() => _SuccessSheetState();
}

class _SuccessSheetState extends State<_SuccessSheet>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 400));
    _scale = CurvedAnimation(parent: _ctrl, curve: Curves.elasticOut);
    _ctrl.forward();
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) Navigator.of(context).maybePop();
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(
          24, 32, 24, MediaQuery.of(context).padding.bottom + 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ScaleTransition(
            scale: _scale,
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppColors.success.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check_circle_rounded,
                  color: AppColors.success, size: 52),
            ),
          ),
          const SizedBox(height: 20),
          Text('Pickup Confirmed!', style: AppTextStyles.h3),
          const SizedBox(height: 8),
          Text('Order has been marked as picked up.',
              style:
                  AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
              textAlign: TextAlign.center),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

// ─── Scan frame painter ────────────────────────────────────────────────────

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

    canvas.drawLine(
        const Offset(0, radius), const Offset(0, cornerLength), paint);
    canvas.drawLine(
        const Offset(radius, 0), const Offset(cornerLength, 0), paint);
    canvas.drawLine(Offset(size.width - cornerLength, 0),
        Offset(size.width, 0), paint);
    canvas.drawLine(Offset(size.width, radius),
        Offset(size.width, cornerLength), paint);
    canvas.drawLine(Offset(0, size.height - cornerLength),
        Offset(0, size.height), paint);
    canvas.drawLine(Offset(radius, size.height),
        Offset(cornerLength, size.height), paint);
    canvas.drawLine(Offset(size.width - cornerLength, size.height),
        Offset(size.width, size.height), paint);
    canvas.drawLine(Offset(size.width, size.height - cornerLength),
        Offset(size.width, size.height), paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
