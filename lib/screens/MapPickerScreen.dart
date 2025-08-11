import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:location/location.dart';

class OpenStreetMapPicker extends StatefulWidget {
  @override
  _OpenStreetMapPickerState createState() => _OpenStreetMapPickerState();
}

class _OpenStreetMapPickerState extends State<OpenStreetMapPicker> {
  LatLng? _selectedLocation;
  final MapController _mapController = MapController();
  bool _isLoading = true;
  final Location _location = Location();

  @override
  void initState() {
    super.initState();
    _checkLocation();
  }

  Future<void> _checkLocation() async {
    bool serviceEnabled;
    PermissionStatus permission;

    serviceEnabled = await _location.serviceEnabled();
    if (!serviceEnabled) {
      serviceEnabled = await _location.requestService();
      if (!serviceEnabled) {
        _showLocationSettingsDialog();
        return;
      }
    }

    permission = await _location.hasPermission();
    if (permission == PermissionStatus.denied || permission == PermissionStatus.deniedForever) {
      permission = await _location.requestPermission();
    }

    if (permission == PermissionStatus.granted) {
      _getCurrentLocation();
    } else {
      _showPermissionDeniedDialog();
    }
  }

  Future<void> _getCurrentLocation() async {
    try {
      final position = await _location.getLocation();
      final userLatLng = LatLng(position.latitude ?? 0.0, position.longitude ?? 0.0);

      setState(() {
        _selectedLocation = userLatLng;
        _isLoading = false;
      });

      _mapController.move(userLatLng, 15.0);
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  void _showLocationSettingsDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        title: Text('Location Disabled'),
        content: Text('Enable location services to continue.'),
        actions: [
          TextButton(
            onPressed: () async {
              await _location.requestService();

              // Wait and check again every second
              bool enabled = false;
              while (!enabled) {
                await Future.delayed(Duration(seconds: 1));
                enabled = await _location.serviceEnabled();
              }

              Navigator.pop(context); // Close dialog
              _checkLocation(); // Retry location logic
            },
            child: Text('Open Settings'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() => _isLoading = false);
            },
            child: Text('Cancel'),
          ),
        ],
      ),
    );
  }

  void _showPermissionDeniedDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Permission Denied'),
        content: Text('This app needs location permission to work.'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _location.requestPermission();
            },
            child: Text('Grant Permission'),
          ),
        ],
      ),
    );
  }

  void _onMapTap(TapPosition tapPosition, LatLng point) {
    setState(() => _selectedLocation = point);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Select Location')),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                center: _selectedLocation ?? LatLng(0, 0),
                zoom: 15.0,
                onTap: _onMapTap,
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.example.app',
                ),
                if (_selectedLocation != null)
                  MarkerLayer(
                    markers: [
                      Marker(
                        width: 50,
                        height: 50,
                        point: _selectedLocation!,
                        builder: (ctx) => Icon(Icons.location_pin,
                            color: Colors.red, size: 40),
                      ),
                    ],
                  ),
              ],
            ),
      floatingActionButton: _selectedLocation != null
          ? FloatingActionButton(
              child: Icon(Icons.check),
              onPressed: () => Navigator.pop(context, _selectedLocation),
            )
          : null,
    );
  }
}
