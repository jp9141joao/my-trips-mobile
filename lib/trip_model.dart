import 'package:latlong2/latlong.dart';

/// Model class representing a Trip with various address components and coordinates.
class Trip {
  /// GPS coordinates of the trip location
  final LatLng coordinates;

  /// Custom name given to the location
  final String name;

  /// Street address (road and house number)
  final String address;

  /// City or equivalent (town/village)
  final String city;

  /// State or region
  final String state;

  /// Country name
  final String country;

  /// Postal code (ZIP)
  final String zip;

  /// Optional neighborhood or suburb
  final String? neighborhood;

  /// Optional reference such as an amenity or building name
  final String? reference;

  /// Constructor for Trip model. ‘neighborhood’ and ‘reference’ are optional.
  Trip({
    required this.coordinates,
    required this.name,
    required this.address,
    required this.city,
    required this.state,
    required this.country,
    required this.zip,
    this.neighborhood,
    this.reference,
  });

  /// Factory constructor to create a Trip instance from JSON data returned by a geocoding API.
  ///
  /// [json] should be a map containing latitude ('lat'), longitude ('lon'), and an 'address' object.
  /// [customName] is the name provided by the user to label this trip location.
  factory Trip.fromJson(Map<String, dynamic> json,
      {required String customName}) {
    // Extract the nested 'address' map from the JSON
    final addressData = json['address'];

    return Trip(
      // Parse latitude and longitude strings into double values
      coordinates: LatLng(
        double.parse(json['lat']),
        double.parse(json['lon']),
      ),
      // Use the user-provided name for this location
      name: customName,

      // Concatenate 'road' and 'house_number' fields for a street address
      address:
          '${addressData['road'] ?? ''}, ${addressData['house_number'] ?? ''}'
              .trim(),

      // Choose city, or fallback to town or village if city is not available
      city: addressData['city'] ??
          addressData['town'] ??
          addressData['village'] ??
          '',

      // Extract the state or region field; default to empty string if missing
      state: addressData['state'] ?? '',

      // Extract the country name; default to empty string if missing
      country: addressData['country'] ?? '',

      // Extract the postal code (ZIP); default to empty string if missing
      zip: addressData['postcode'] ?? '',

      // Optional: neighborhood or suburb if provided in the JSON
      neighborhood: addressData['suburb'] ?? addressData['neighbourhood'] ?? '',

      // Optional: reference such as an amenity or building name
      reference: addressData['amenity'] ?? addressData['building'] ?? '',
    );
  }
}
