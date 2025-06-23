import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:my_trips/Maps.dart';
import 'package:my_trips/trip_model.dart';
import 'geocoding_service.dart';
import 'trip_model.dart';

/// Home screen where the user can add, view, and delete saved trips.
class Home extends StatefulWidget {
  @override
  _HomeState createState() => _HomeState();
}

class _HomeState extends State<Home> {
  /// Internal list holding all added Trip objects.
  final List<Trip> _tripList = [];

  /// Opens the Maps screen so the user can pick a location.
  /// When a LatLng is returned, it calls _addTripFromLocation().
  Future<void> _addLocation() async {
    final selectedLocation = await Navigator.push<LatLng>(
      context,
      MaterialPageRoute(builder: (context) => const MapScreen()),
    );

    // If the user selected a valid location (not null), add it to our list.
    if (selectedLocation != null) {
      await _addTripFromLocation(selectedLocation);
    }
  }

  /// Given a LatLng, performs reverse geocoding to fetch address data,
  /// shows a confirmation dialog for the user to edit the location name,
  /// and finally adds a new Trip to _tripList.
  Future<void> _addTripFromLocation(LatLng location) async {
    try {
      // 1. Call GeocodingService to get address details (JSON) from the coordinates.
      final locationData =
          await GeocodingService.getAddressFromCoordinates(location);

      // 2. Initialize a TextEditingController with either:
      //    - the 'name' field from the response
      //    - or the 'amenity' within 'address'
      //    - or a default value "New Location" if neither is present.
      final nameController = TextEditingController(
        text: locationData['name'] ??
            locationData['address']['amenity'] ??
            'New Location',
      );

      // 3. Display a confirmation dialog showing the full “display_name” (if available)
      //    and allowing the user to edit or accept the default name.
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Confirm Location'),
          content: SingleChildScrollView(
            child: Column(
              children: [
                // Show the human-readable address or fallback text
                Text(
                  'Address: ${locationData['display_name'] ?? 'Not identified'}',
                ),
                const SizedBox(height: 16),
                // Allow user to customize the location name
                TextFormField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Name for this location',
                  ),
                ),
              ],
            ),
          ),
          actions: [
            // If “Cancel” is pressed, return false
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            // If “Save” is pressed, return true
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Save'),
            ),
          ],
        ),
      );

      // 4. If user clicked “Save” (confirmed == true), create a new Trip
      //    from the JSON data and add it to the list.
      if (confirmed == true) {
        final newTrip = Trip.fromJson(
          locationData,
          customName: nameController.text,
        );

        setState(() => _tripList.add(newTrip));
      }
    } catch (e) {
      // If reverse geocoding fails (for example, due to network error),
      // show a fallback dialog prompting the user for a manual name.
      final name = await _showManualDialog(location);
      if (name != null) {
        setState(() {
          _tripList.add(
            Trip(
              coordinates: location,
              name: name,
              // Use coordinates directly as the “address” since API data failed
              address:
                  'Coordinates: ${location.latitude.toStringAsFixed(6)}, ${location.longitude.toStringAsFixed(6)}',
              city: 'Not identified',
              state: '',
              country: '',
              zip: '',
              neighborhood: '',
              reference: '',
            ),
          );
        });
      }
    }
  }

  /// Shows a dialog with a TextField, allowing the user to manually type
  /// a name for the location if automatic geocoding failed.
  Future<String?> _showManualDialog(LatLng location) async {
    final controller = TextEditingController();

    return await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Location Manually'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'Location name',
            hintText: 'E.g., My favorite spot',
          ),
        ),
        actions: [
          // If “Cancel” is pressed, return null
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          // If “Save” is pressed, return the entered text
          TextButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  /// Deletes a trip from _tripList at the given index and rebuilds the UI.
  void _deleteTrip(int index) {
    setState(() {
      _tripList.removeAt(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("My Trips"),
        actions: [
          // If there is at least one trip in the list, show a sort button.
          if (_tripList.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.sort),
              onPressed: () async {
                try {
                  // 1. Get the device’s current GPS position
                  final position = await Geolocator.getCurrentPosition();

                  // 2. Sort _tripList by distance from current position
                  setState(() {
                    _tripList.sort((a, b) {
                      final distanceA = const Distance().as(
                        LengthUnit.Kilometer,
                        LatLng(position.latitude, position.longitude),
                        a.coordinates,
                      );
                      final distanceB = const Distance().as(
                        LengthUnit.Kilometer,
                        LatLng(position.latitude, position.longitude),
                        b.coordinates,
                      );
                      return distanceA.compareTo(distanceB);
                    });
                  });
                } catch (e) {
                  // If location access or sorting fails, show a SnackBar with the error.
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error sorting trips: ${e.toString()}'),
                    ),
                  );
                }
              },
            ),
        ],
      ),
      // Floating action button to add a new location
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.add),
        onPressed: _addLocation,
      ),
      // Main content: if no trips exist, show a placeholder message;
      // otherwise, display the list of trips.
      body: _tripList.isEmpty
          ? const Center(
              child: Text(
                'No trips added\nClick the + to start',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 18),
              ),
            )
          : ListView.builder(
              itemCount: _tripList.length,
              itemBuilder: (context, index) {
                final trip = _tripList[index];
                return Card(
                  margin: const EdgeInsets.all(8),
                  child: ListTile(
                    // Title displays the custom or fetched name
                    title: Text(
                      trip.name,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    // Subtitle shows address, city/state, country, ZIP, and coordinates
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (trip.address.isNotEmpty) Text(trip.address),
                        if (trip.city.isNotEmpty)
                          Text('${trip.city}, ${trip.state}'),
                        if (trip.country.isNotEmpty) Text(trip.country),
                        if (trip.zip.isNotEmpty) Text('ZIP: ${trip.zip}'),
                        Text(
                          'Coordinates: '
                          '${trip.coordinates.latitude.toStringAsFixed(4)}, '
                          '${trip.coordinates.longitude.toStringAsFixed(4)}',
                          style: const TextStyle(fontSize: 12),
                        ),
                      ],
                    ),
                    // Red delete icon button to remove this trip
                    trailing: IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () => _deleteTrip(index),
                    ),
                    onTap: () {
                      // Tapping the list item reopens the Maps screen
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => const MapScreen()),
                      );
                    },
                  ),
                );
              },
            ),
    );
  }
}
