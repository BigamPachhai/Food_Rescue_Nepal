import 'package:intl/intl.dart';
import 'package:timeago/timeago.dart' as timeago;

class Formatters {
  Formatters._();

  static String formatNPR(int paisa) {
    final amount = paisa / 100;
    return 'NPR ${amount.toStringAsFixed(0)}';
  }

  static String formatNPRDouble(double amount) {
    return 'NPR ${amount.toStringAsFixed(0)}';
  }

  static String formatDate(DateTime date) {
    return DateFormat('MMM dd, yyyy').format(date);
  }

  static String formatDateTime(DateTime date) {
    return DateFormat('MMM dd, yyyy hh:mm a').format(date);
  }

  static String formatTime(DateTime date) {
    return DateFormat('hh:mm a').format(date);
  }

  static String formatDistance(double distanceInMeters) {
    if (distanceInMeters < 1000) {
      return '${distanceInMeters.toStringAsFixed(0)} m';
    }
    final km = distanceInMeters / 1000;
    return '${km.toStringAsFixed(1)} km';
  }

  static String timeAgo(DateTime date) {
    return timeago.format(date);
  }

  static String formatPickupTime(DateTime start, DateTime end) {
    return '${formatTime(start)} - ${formatTime(end)}';
  }

  static int discountPercent(int originalPaisa, int discountedPaisa) {
    if (originalPaisa == 0) return 0;
    return (((originalPaisa - discountedPaisa) / originalPaisa) * 100).round();
  }

  static String formatMonthYear(DateTime date) {
    return DateFormat('MMM yyyy').format(date);
  }

  static String formatShortDate(DateTime date) {
    return DateFormat('dd MMM').format(date);
  }

  // "2h 30m", "45m", "< 1m", or "Closed" when duration is negative/zero
  static String formatTimeRemaining(Duration d) {
    if (d.isNegative || d.inSeconds <= 0) return 'Closed';
    if (d.inSeconds < 60) return '< 1m';
    if (d.inHours >= 1) {
      final m = d.inMinutes.remainder(60);
      return m > 0 ? '${d.inHours}h ${m}m' : '${d.inHours}h';
    }
    return '${d.inMinutes}m';
  }

  // "1.2K", "5K", "999" — compact count display
  static String formatCompactNumber(int n) {
    if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}M';
    if (n >= 1000) {
      final k = n / 1000;
      return k == k.roundToDouble() ? '${k.toInt()}K' : '${k.toStringAsFixed(1)}K';
    }
    return '$n';
  }

  // Duration from now until a given DateTime (positive = future)
  static Duration timeUntil(DateTime dt) => dt.difference(DateTime.now());
}
