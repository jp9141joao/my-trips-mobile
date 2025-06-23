import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

/// A service class responsible for geocoding operations such as
/// reverse geocoding using OpenStreetMap (Nominatim) or Google Maps.
class GeocodingService {
  // Base URL for Nominatim (OpenStreetMap) reverse geocoding API
  static const String _nominatimUrl =
      'https://nominatim.openstreetmap.org/reverse';

  /// Returns a human-readable address from given latitude and longitude
  /// using OpenStreetMap (Nominatim).
  ///
  /// [coords] - a LatLng object containing latitude and longitude.
  /// Throws an exception if the request fails.
  static Future<Map<String, dynamic>> getAddressFromCoordinates(
      LatLng coords) async {
    final uri = Uri.parse(
      '$_nominatimUrl?format=jsonv2&lat=${coords.latitude}&lon=${coords.longitude}',
    );

    final response = await http.get(
      uri,
      headers: {
        // Required by Nominatim to identify the application
        'User-Agent': 'YourAppName/1.0',
      },
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to retrieve address from Nominatim');
    }
  }

  /// Returns a human-readable address from given latitude and longitude
  /// using Google Maps Geocoding API.
  ///
  /// [coords] - a LatLng object with latitude and longitude.
  /// [apiKey] - your Google Maps API key.
  /// Throws an exception if the request fails.
  static Future<Map<String, dynamic>> getGoogleAddress(
      LatLng coords, String apiKey) async {
    final uri = Uri.parse(
      'https://maps.googleapis.com/maps/api/geocode/json?'
      'latlng=${coords.latitude},${coords.longitude}&key=$apiKey',
    );

    final response = await http.get(uri);

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to retrieve address from Google');
    }
  }
}
