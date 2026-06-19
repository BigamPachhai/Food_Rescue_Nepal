import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/error_view.dart';
import '../providers/customer_orders_provider.dart';

class QrDisplayScreen extends ConsumerStatefulWidget {
  const QrDisplayScreen({super.key, required this.orderId});
  final String orderId;

  @override
  ConsumerState<QrDisplayScreen> createState() => _QrDisplayScreenState();
}

class _QrDisplayScreenState extends ConsumerState<QrDisplayScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _ringController;
  late Animation<double> _ringAnimation;
  Timer? _countdownTimer;
  Duration _timeLeft = Duration.zero;

  @override
  void initState() {
    super.initState();
    _ringController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
    _ringAnimation = Tween(begin: 0.85, end: 1.15).animate(
      CurvedAnimation(parent: _ringController, curve: Curves.easeInOut),
    );
    // Maximize brightness so the QR is easy to scan
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    _setBrightness(1.0);
    _startCountdown();
  }

  void _startCountdown() {
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      final order = ref.read(orderDetailProvider(widget.orderId)).value;
      final end = order?.listing?.pickupEnd;
      if (end == null) return;
      final left = end.difference(DateTime.now());
      setState(() => _timeLeft = left.isNegative ? Duration.zero : left);
    });
  }

  void _setBrightness(double value) {
    // Best-effort; no crash if platform channel is unavailable
    try {
      const channel = MethodChannel('flutter/platform');
      channel.invokeMethod<void>('Brightness.set', {'brightness': value});
    } catch (_) {}
  }

  @override
  void dispose() {
    _ringController.dispose();
    _countdownTimer?.cancel();
    _setBrightness(-1.0); // restore system brightness
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final orderAsync = ref.watch(orderDetailProvider(widget.orderId));

    return Scaffold(
      backgroundColor: AppColors.primary,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text('Pickup QR Code'),
      ),
      body: orderAsync.when(
        data: (order) {
          if (order.pickupCode == null) {
            return const Center(
              child: Text('No QR code available', style: TextStyle(color: Colors.white)),
            );
          }

          final isUrgent = _timeLeft.inMinutes <= 10 && _timeLeft.inSeconds > 0;
          final timeLabel = Formatters.formatTimeRemaining(_timeLeft);

          return LayoutBuilder(
            builder: (context, constraints) => SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Show this QR to the vendor',
                          style: AppTextStyles.h4.copyWith(color: Colors.white),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'They will scan it to confirm your pickup',
                          style: AppTextStyles.bodySmall.copyWith(color: Colors.white70),
                          textAlign: TextAlign.center,
                        ),
                        // Pickup countdown
                        if (_timeLeft.inSeconds > 0) ...[
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                            decoration: BoxDecoration(
                              color: isUrgent
                                  ? AppColors.error.withValues(alpha: 0.25)
                                  : Colors.white12,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: isUrgent ? AppColors.error : Colors.white30,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  isUrgent ? Icons.timer_off_rounded : Icons.timer_rounded,
                                  color: isUrgent ? AppColors.error : Colors.white,
                                  size: 14,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  'Pickup closes in $timeLabel',
                                  style: TextStyle(
                                    color: isUrgent ? AppColors.error : Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                        const SizedBox(height: 32),
                        AnimatedBuilder(
                          animation: _ringAnimation,
                          builder: (_, child) => Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: AppColors.primaryLight.withValues(alpha: 0.5),
                                width: 3 * _ringAnimation.value,
                              ),
                            ),
                            padding: EdgeInsets.all(12 * _ringAnimation.value),
                            child: child,
                          ),
                          child: Container(
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(24),
                            ),
                            child: QrImageView(
                              data: jsonEncode({'o': order.id, 'c': order.pickupCode}),
                              size: 200,
                              backgroundColor: Colors.white,
                              eyeStyle: const QrEyeStyle(
                                eyeShape: QrEyeShape.square,
                                color: AppColors.primaryMedium,
                              ),
                              dataModuleStyle: const QrDataModuleStyle(
                                dataModuleShape: QrDataModuleShape.square,
                                color: AppColors.primary,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 28),
                        // Vendor + listing info
                        if (order.vendor != null)
                          Text(
                            order.vendor!.businessName,
                            style: AppTextStyles.caption.copyWith(color: Colors.white60),
                          ),
                        if (order.listing != null) ...[
                          const SizedBox(height: 2),
                          Text(
                            order.listing!.name,
                            style: AppTextStyles.h5.copyWith(color: Colors.white),
                            textAlign: TextAlign.center,
                          ),
                        ],
                        const SizedBox(height: 4),
                        Text(
                          Formatters.formatNPR(order.totalAmount),
                          style: AppTextStyles.h4.copyWith(color: AppColors.accent),
                        ),
                        if (order.listing != null) ...[
                          const SizedBox(height: 6),
                          Text(
                            'Pickup: ${Formatters.formatPickupTime(order.listing!.pickupStart, order.listing!.pickupEnd)}',
                            style: AppTextStyles.caption.copyWith(color: Colors.white60),
                          ),
                        ],
                        const SizedBox(height: 16),
                        GestureDetector(
                          onTap: () {
                            Clipboard.setData(ClipboardData(text: order.pickupCode!));
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Pickup code copied to clipboard'),
                                duration: Duration(seconds: 2),
                              ),
                            );
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(
                              color: Colors.white12,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: Colors.white24),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  'Code: ${order.pickupCode}',
                                  style: AppTextStyles.caption.copyWith(
                                    color: Colors.white,
                                    letterSpacing: 2,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                const Icon(Icons.copy_rounded, color: Colors.white60, size: 14),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Tap code to copy',
                          style: AppTextStyles.caption.copyWith(color: Colors.white38, fontSize: 11),
                        ),
                        const SizedBox(height: 24),
                        OutlinedButton(
                          onPressed: () => context.pop(),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.white,
                            side: const BorderSide(color: Colors.white54),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: const Text('Go Back'),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        },
        loading: () => const Center(
          child: CircularProgressIndicator(color: Colors.white),
        ),
        error: (e, _) => ErrorView(
          error: e,
          onRetry: () => ref.invalidate(orderDetailProvider(widget.orderId)),
        ),
      ),
    );
  }
}
