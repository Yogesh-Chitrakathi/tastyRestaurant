import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

class LocationResult {
  final double latitude;
  final double longitude;
  final String fullAddress;
  final Placemark? placemark;
  final String? errorMessage;

  LocationResult({
    required this.latitude,
    required this.longitude,
    required this.fullAddress,
    this.placemark,
    this.errorMessage,
  });
}

class LocationService {
  static Future<LocationResult?> getCurrentLocation(
    BuildContext context, {
    required Function(String) showMessage,
  }) async {
    try {
      // 1. Check if location services are enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        showMessage("Please enable location services in your device settings.");
        return null;
      }

      // 2. Check and handle location permission states
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          showMessage("Location permission denied. Please allow location access to auto-fill address.");
          return null;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        // Redirect permanently denied users to settings
        if (context.mounted) {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text("Location Permission Required"),
              content: const Text(
                "Location permissions are permanently denied. Please enable them in your device settings to use this feature.",
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("Cancel"),
                ),
                TextButton(
                  onPressed: () async {
                    Navigator.pop(context);
                    await Geolocator.openAppSettings();
                  },
                  child: const Text("Open Settings"),
                ),
              ],
            ),
          );
        }
        return null;
      }

      // 3. Fetch GPS coordinates with timeout
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      ).timeout(const Duration(seconds: 10), onTimeout: () {
        throw TimeoutException("GPS coordinates fetch timed out. Please try again in an open space.");
      });

      double lat = position.latitude;
      double lng = position.longitude;

      // 4. Reverse Geocoding with fallback
      List<Placemark> placemarks;
      try {
        placemarks = await placemarkFromCoordinates(lat, lng).timeout(
          const Duration(seconds: 8),
          onTimeout: () => throw TimeoutException("Reverse geocoding timed out. Check your internet connection."),
        );
      } catch (geocodingError) {
        // If geocoding fails (e.g. no internet), we still return coordinates with error msg!
        return LocationResult(
          latitude: lat,
          longitude: lng,
          fullAddress: "Coords: $lat, $lng (Address resolve failed)",
          errorMessage: "Could not resolve address details. Latitude and Longitude auto-filled. You can manually enter your address.",
        );
      }

      if (placemarks.isNotEmpty) {
        Placemark place = placemarks.first;

        List<String> addressParts = [];
        if (place.street != null && place.street!.isNotEmpty) addressParts.add(place.street!);
        if (place.subLocality != null && place.subLocality!.isNotEmpty) addressParts.add(place.subLocality!);
        if (place.locality != null && place.locality!.isNotEmpty) addressParts.add(place.locality!);
        if (place.administrativeArea != null && place.administrativeArea!.isNotEmpty) addressParts.add(place.administrativeArea!);
        if (place.postalCode != null && place.postalCode!.isNotEmpty) addressParts.add(place.postalCode!);
        if (place.country != null && place.country!.isNotEmpty) addressParts.add(place.country!);
        String fullAddress = addressParts.join(", ");

        return LocationResult(
          latitude: lat,
          longitude: lng,
          fullAddress: fullAddress,
          placemark: place,
        );
      } else {
        return LocationResult(
          latitude: lat,
          longitude: lng,
          fullAddress: "Coords: $lat, $lng",
          errorMessage: "No address data returned from GPS. Coordinates loaded.",
        );
      }
    } on TimeoutException catch (te) {
      showMessage(te.message ?? "Request timed out. Please try again.");
      return null;
    } catch (e) {
      showMessage("Failed to fetch location. Please check your internet/GPS connection and try again.");
      return null;
    }
  }
}
