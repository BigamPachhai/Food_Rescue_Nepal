import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';

class LocationState {
  final AsyncValue<Position?> position;
  final String label;

  const LocationState({required this.position, required this.label});

  LocationState copyWith({AsyncValue<Position?>? position, String? label}) {
    return LocationState(
      position: position ?? this.position,
      label: label ?? this.label,
    );
  }
}

class LocationNotifier extends StateNotifier<LocationState> {
  LocationNotifier()
      : super(const LocationState(
          position: AsyncValue.data(null),
          label: 'Locating...',
        ));

  void setManualCity(String city) {
    state = LocationState(
      position: const AsyncValue.data(null),
      label: city,
    );
  }

  Future<void> getCurrentLocation() async {
    state = state.copyWith(
      position: const AsyncValue.loading(),
      label: 'Locating...',
    );
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        state = state.copyWith(
          position: const AsyncValue.data(null),
          label: 'Location unavailable',
        );
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          state = state.copyWith(
            position: const AsyncValue.data(null),
            label: 'Location denied',
          );
          return;
        }
      }
      if (permission == LocationPermission.deniedForever) {
        state = state.copyWith(
          position: const AsyncValue.data(null),
          label: 'Location denied',
        );
        return;
      }

      // Use last known position immediately so the UI is never stuck waiting
      final last = await Geolocator.getLastKnownPosition();
      if (last != null) {
        final lastLabel = await _reverseGeocode(last.latitude, last.longitude);
        state = LocationState(position: AsyncValue.data(last), label: lastLabel);
      }

      // Then get a fresh fix in the background (no hard timeout)
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.medium,
      );
      final label = await _reverseGeocode(position.latitude, position.longitude);
      state = LocationState(position: AsyncValue.data(position), label: label);
    } catch (e, st) {
      // If we already have a position from last known, keep it instead of erroring
      if (state.position.value != null) return;
      state = state.copyWith(
        position: AsyncValue.error(e, st),
        label: 'Location unavailable',
      );
    }
  }

  Future<String> _reverseGeocode(double lat, double lng) async {
    try {
      final placemarks = await placemarkFromCoordinates(lat, lng);
      if (placemarks.isEmpty) return 'Current Location';

      final place = placemarks.first;
      final city = place.locality ?? place.subAdministrativeArea ?? place.administrativeArea;
      final country = place.country;

      if (city != null && city.isNotEmpty && country != null && country.isNotEmpty) {
        return '$city, $country';
      } else if (city != null && city.isNotEmpty) {
        return city;
      }
      return 'Current Location';
    } catch (_) {
      return 'Current Location';
    }
  }
}

final locationProvider =
    StateNotifierProvider<LocationNotifier, LocationState>((ref) {
  return LocationNotifier();
});
