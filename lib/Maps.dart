import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';

/// Screen that displays a map, shows the user's current location,
/// and allows selecting a point on the map to return back.
class MapScreen extends StatefulWidget {
  const MapScreen({Key? key}) : super(key: key);

  @override
  _MapScreenState createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  // Controller to programmatically move the map camera
  final MapController _mapController = MapController();

  // Holds the user's current GPS coordinates when fetched
  LatLng? _currentLocation;

  // Holds the location the user tapped/selected on the map
  LatLng? _selectedLocation;

  // Indicates whether we are still fetching location or checking permissions
  bool _isLoading = true;

  // Any error message to display if something goes wrong
  String _errorMessage = '';

  // Tracks if the map widget has finished initializing
  bool _mapInitialized = false;

  @override
  void initState() {
    super.initState();
    // On initialization, immediately start fetching the current location
    _getCurrentLocation();
  }

  /// Checks if location services are enabled and permissions are granted.
  /// Updates _errorMessage and _isLoading accordingly if something is wrong.
  Future<bool> _checkPermissions() async {
    // 1. Verify if device location services are enabled
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      setState(() {
        _errorMessage = 'Location services are disabled';
        _isLoading = false;
      });
      return false;
    }

    // 2. Check current permission status
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      // 3. Request permission if denied
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        setState(() {
          _errorMessage = 'Location permission denied';
          _isLoading = false;
        });
        return false;
      }
    }

    // 4. Handle permanent denial
    if (permission == LocationPermission.deniedForever) {
      setState(() {
        _errorMessage =
            'Location permission permanently denied. Enable it in settings.';
        _isLoading = false;
      });
      return false;
    }

    // All good if we get here
    return true;
  }

  /// Requests the current GPS position of the device, updates state,
  /// and, if the map is already ready, moves the camera to the location.
  Future<void> _getCurrentLocation() async {
    // First, ensure permissions/service are OK
    if (!await _checkPermissions()) return;

    try {
      // Fetch the current position with the best accuracy
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.best,
      );

      // Store the coordinates and mark loading as finished
      setState(() {
        _currentLocation = LatLng(position.latitude, position.longitude);
        _isLoading = false;
      });

      // If the map has already initialized, immediately move to current location
      if (_mapInitialized) {
        _mapController.move(_currentLocation!, 16);
      }
    } catch (e) {
      // If an error occurs, stop loading and record the message
      setState(() {
        _isLoading = false;
        _errorMessage = 'Error getting location: ${e.toString()}';
      });
    }
  }

  /// Callback whenever the user taps on the map.
  /// Stores the tapped LatLng in _selectedLocation to show a marker.
  void _handleTap(TapPosition tapPosition, LatLng latLng) {
    setState(() {
      _selectedLocation = latLng;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        // Title at the top of the screen
        title: const Text("Select a Location"),
        actions: [
          // If the user has tapped somewhere, show a check icon to confirm selection
          if (_selectedLocation != null)
            IconButton(
              icon: const Icon(Icons.check),
              onPressed: () {
                // Return the selected location back to the previous screen
                Navigator.pop(context, _selectedLocation);
              },
            ),
        ],
      ),
      // Build the body according to loading state or errors
      body: _buildMapContent(),
      // If user has tapped and _selectedLocation is set, show a FAB to center on that point
      floatingActionButton: _selectedLocation != null
          ? FloatingActionButton(
              child: const Icon(Icons.my_location),
              onPressed: () {
                // Move the map camera to the selected location at zoom level 16
                _mapController.move(_selectedLocation!, 16);
              },
            )
          : null,
    );
  }

  /// Returns the appropriate widget for the map screen:
  /// - Loading indicator while fetching location or permissions.
  /// - Error message with retry/settings buttons if something went wrong.
  /// - Otherwise, the actual FlutterMap widget with markers.
  Widget _buildMapContent() {
    // 1. Still loading: show spinner
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    // 2. An error occurred: show error layout
    if (_errorMessage.isNotEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Display the error message
            Text(_errorMessage),
            const SizedBox(height: 20),
            // Button to retry fetching location
            ElevatedButton(
              onPressed: _getCurrentLocation,
              child: const Text('Try Again'),
            ),
            // If the error mentions permanent denial, provide a button to open app settings
            if (_errorMessage.contains('permanently'))
              TextButton(
                onPressed: () => Geolocator.openAppSettings(),
                child: const Text('Open Settings'),
              ),
          ],
        ),
      );
    }

    // 3. No errors and not loading → display the map
    return FlutterMap(
      mapController: _mapController,
      options: MapOptions(
        // Center initially at current location or (0,0) if somehow null
        initialCenter: _currentLocation ?? const LatLng(0, 0),
        initialZoom: 16,
        // Hook up tap callback to store selected location
        onTap: _handleTap,
        // When the map finishes rendering, mark it initialized and move to current location
        onMapReady: () {
          setState(() => _mapInitialized = true);
          if (_currentLocation != null) {
            _mapController.move(_currentLocation!, 16);
          }
        },
      ),
      children: [
        // Base tile layer from OpenStreetMap
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'com.example.app',
        ),

        // If we have the current location, show a blue marker at that point
        if (_currentLocation != null)
          MarkerLayer(
            markers: [
              Marker(
                point: _currentLocation!,
                child: const Icon(
                  Icons.person_pin_circle,
                  size: 50,
                  color: Colors.blue,
                ),
              ),
            ],
          ),

        // If the user has tapped a location, show a red pin at the selected LatLng
        if (_selectedLocation != null)
          MarkerLayer(
            markers: [
              Marker(
                point: _selectedLocation!,
                child: const Icon(
                  Icons.location_pin,
                  size: 50,
                  color: Colors.red,
                ),
              ),
            ],
          ),
      ],
    );
  }
}
