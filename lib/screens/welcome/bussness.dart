// Business Info Page
import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:latlong2/latlong.dart';
import 'package:ministock/models/StockLocation.dart';
import 'package:ministock/screens/MapPickerScreen.dart';
import 'package:ministock/screens/welcome/AppLogo.dart';
import 'package:uuid/uuid.dart';

class BusinessInfoPage extends StatefulWidget {
  final StockLocation location;
  final Function(StockLocation) onLocationUpdated;

  const BusinessInfoPage({super.key, 
    required this.location,
    required this.onLocationUpdated,
  });

  @override
  BusinessInfoPageState createState() => BusinessInfoPageState();
}

class BusinessInfoPageState extends State<BusinessInfoPage> {
  final _newLocationNameController = TextEditingController();
  final Uuid _uuid = Uuid();
  StockLocation? _selectedLocation;
  late StockLocation _businessLocation;

  @override
  void initState() {
    super.initState();
    _selectedLocation = widget.location;
   _businessLocation = widget.location;
    _newLocationNameController.text = _businessLocation.name;
  }
    @override
  void dispose() {
    _newLocationNameController.dispose();
    super.dispose();
  }
  Future<void> _selectLocation() async {
    final LatLng? pickedLocation = await Navigator.push(
      context,
      MaterialPageRoute(builder: (ctx) => OpenStreetMapPicker()),
    );

    if (pickedLocation != null) {
      String address = 'Address not available';
      
      try {
        final addresses = await placemarkFromCoordinates(
          pickedLocation.latitude,
          pickedLocation.longitude,
        ).timeout(Duration(seconds: 10), onTimeout: () => []);

        address = addresses.isNotEmpty 
            ? '${addresses.first.street ?? ''}, ${addresses.first.locality ?? ''}'
                .replaceAll(', ,', ', ')
                .trim()
            : 'Unknown location';
      } catch (e) {
        address = 'Coordinates: ${pickedLocation.latitude.toStringAsFixed(4)}, '
                  '${pickedLocation.longitude.toStringAsFixed(4)}';
      }

      setState(() {
        _businessLocation = _businessLocation.copyWith(
          latitude: pickedLocation.latitude,
          longitude: pickedLocation.longitude,
          address: address,
        );
        widget.onLocationUpdated(_businessLocation);
      });
    }
  }

  Future<void> _showCreateLocationDialog() async {
    final LatLng? pickedLocation = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => OpenStreetMapPicker()),
    );

    if (pickedLocation != null) {
      String address = 'Address not available';
      
      try {
        final addresses = await placemarkFromCoordinates(
          pickedLocation.latitude,
          pickedLocation.longitude,
        ).timeout(Duration(seconds: 10), onTimeout: () => []);

        address = addresses.isNotEmpty 
            ? '${addresses.first.street ?? ''}, ${addresses.first.locality ?? ''}'
                .replaceAll(', ,', ', ')
                .trim()
            : 'Unknown location';
      } catch (e) {
        address = 'Coordinates: ${pickedLocation.latitude.toStringAsFixed(4)}, '
                  '${pickedLocation.longitude.toStringAsFixed(4)}';
      }

      showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: Text('Business Location'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: _newLocationNameController,
                  decoration: InputDecoration(
                    labelText: 'Location Name',
                    errorText: _newLocationNameController.text.isEmpty 
                        ? 'Required' 
                        : null,
                  ),
                ),
                SizedBox(height: 16),
                Text('Latitude: ${pickedLocation.latitude.toStringAsFixed(4)}'),
                Text('Longitude: ${pickedLocation.longitude.toStringAsFixed(4)}'),
                SizedBox(height: 8),
                Text('Address: $address', 
                  style: TextStyle(fontSize: 12, color: Colors.grey)),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () async {
                  if (_newLocationNameController.text.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Location name is required'))
                    );
                    return;
                  }

                  final newLocation = StockLocation(
                    id: _uuid.v4(),
                    name: _newLocationNameController.text,
                    address: address,
                    latitude: pickedLocation.latitude,
                    longitude: pickedLocation.longitude,
                  );
                  
                  setState(() {
                    _selectedLocation = newLocation;
                    widget.onLocationUpdated(newLocation);
                  });
                  Navigator.pop(context);
                },
                child: Text('Save Location'),
              ),
            ],
          );
        },
      );
    }
  }

    Widget _buildLocationCard() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            ListTile(
              leading: Icon(Icons.location_on),
              title: Text(_businessLocation.name),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(_businessLocation.address),
                  SizedBox(height: 4),
                  Text(
                    'Lat: ${_businessLocation.latitude.toStringAsFixed(4)}, '
                    'Lng: ${_businessLocation.longitude.toStringAsFixed(4)}',
                    style: TextStyle(fontSize: 12),
                  ),
                ],
              ),
            ),
            ElevatedButton.icon(
              icon: Icon(Icons.map),
              label: Text(_businessLocation.latitude == 0.0 
                  ? 'Select Location' 
                  : 'Change Location'),
              onPressed: _selectLocation,
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(32),
      child: Column(
        children: [
          Text(
            'Business Information',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          SizedBox(height: 24),
          TextFormField(
            controller: _newLocationNameController,
            decoration: InputDecoration(
              labelText: 'Business Name',
              prefixIcon: Icon(Icons.business),
              hintText: 'My Awesome Store',
            ),
            onChanged: (value) {
              setState(() {
                _businessLocation = _businessLocation.copyWith(name: value);
                widget.onLocationUpdated(_businessLocation);
              });
            },
          ),
          SizedBox(height: 24),
          _buildLocationCard(),
        ],
      ),
    );
  }

}