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
    try {
      final result = await Connectivity().checkConnectivity();
      _update(result);
    } catch (_) {
      state = true; // assume online if plugin not yet registered
    }
  }

  void _update(List<ConnectivityResult> results) {
    try {
      state = results.any((r) => r != ConnectivityResult.none);
    } catch (_) {
      state = true;
    }
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
