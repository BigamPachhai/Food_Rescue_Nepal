import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../constants/app_colors.dart';
import '../network/connectivity_provider.dart';

class OfflineBanner extends ConsumerStatefulWidget {
  const OfflineBanner({super.key});

  @override
  ConsumerState<OfflineBanner> createState() => _OfflineBannerState();
}

class _OfflineBannerState extends ConsumerState<OfflineBanner> {
  bool _wasOffline = false;
  bool _showReconnected = false;

  @override
  Widget build(BuildContext context) {
    final isOnline = ref.watch(connectivityProvider);

    if (!isOnline) {
      _wasOffline = true;
      _showReconnected = false;
    } else if (_wasOffline && !_showReconnected) {
      _wasOffline = false;
      _showReconnected = true;
      Future.delayed(const Duration(seconds: 3), () {
        if (mounted) setState(() => _showReconnected = false);
      });
    }

    if (isOnline && !_showReconnected) return const SizedBox.shrink();

    return Material(
      color: Colors.transparent,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        width: double.infinity,
        color: isOnline ? AppColors.success : AppColors.error,
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isOnline ? Icons.wifi_rounded : Icons.wifi_off,
              color: Colors.white,
              size: 16,
            ),
            const SizedBox(width: 8),
            Text(
              isOnline ? 'Back online' : 'No internet connection',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
