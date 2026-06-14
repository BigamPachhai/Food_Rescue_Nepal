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
}
