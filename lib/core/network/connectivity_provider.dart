import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ConnectivityNotifier extends StateNotifier<bool> {
  ConnectivityNotifier() : super(true) {
    _subscription = Connectivity().onConnectivityChanged.listen(_update);
    _checkInitial();
  }

  late final StreamSubscription<List<ConnectivityResult>> _subscription;

  Future<void> _checkInitial() async {
    final result = await Connectivity().checkConnectivity();
    _update(result);
  }

  void _update(List<ConnectivityResult> results) {
    state = results.any((r) => r != ConnectivityResult.none);
  }

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}

final connectivityProvider =
    StateNotifierProvider<ConnectivityNotifier, bool>(
  (_) => ConnectivityNotifier(),
);
