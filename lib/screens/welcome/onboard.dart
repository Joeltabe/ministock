// onboarding_flow.dart
import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:latlong2/latlong.dart';
import 'package:ministock/models/StockLocation.dart';
import 'package:ministock/models/User.dart';
import 'package:ministock/models/article.dart';
import 'package:ministock/models/supplier.dart';
import 'package:ministock/services/DatabaseHelper.dart';
import 'package:uuid/uuid.dart';
import 'package:ministock/screens/MapPickerScreen.dart';

import 'package:ministock/screens/welcome/WelcomePage.dart';
import 'package:ministock/screens/welcome/artfact.dart';
import 'package:ministock/screens/welcome/bussness.dart';
import 'package:ministock/screens/welcome/onboard.dart';
import 'package:ministock/screens/welcome/supplyandstocpages.dart';
import 'package:ministock/screens/welcome/usernfo.dart';

class OnboardingFlow extends StatefulWidget {
  final VoidCallback onComplete;

  const OnboardingFlow({required this.onComplete});

  @override
  _OnboardingFlowState createState() => _OnboardingFlowState();
}

class _OnboardingFlowState extends State<OnboardingFlow> {
  int _currentStep = 0;
  final _pageController = PageController();
  final _formKey = GlobalKey<FormState>();
  late StockLocation _businessLocation;

  // Onboarding Data
  User _user = User(
    id: const Uuid().v4(),
    username: '',
    passwordHash: '',
    fullName: '',
    role: 'owner',
    isActive: true,
  );

  StockLocation _updateStockLocation(StockLocation location, double lat, double lng) {
    return StockLocation(
      id: location.id,
      name: location.name,
      address: location.address,
      latitude: lat,
      longitude: lng,
    );
  }
  List<Supplier> _suppliers = [];
  List<Article> _inventory = [];

late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();
        _businessLocation = StockLocation(
      id: const Uuid().v4(),
      name: 'Main Location',
      address: '',
      latitude: 0,
      longitude: 0,
    );
    // Load any existing locations
    _loadExistingLocations();
    _pages = [
      WelcomePage(onNext: _nextPage),
      UserInfoPage(formKey: _formKey, user: _user, onSave: _saveUser),
      BusinessInfoPage(
        location: _businessLocation,
        onLocationUpdated: (location) => setState(() => _businessLocation = location),
      ),
      SuppliersPage(suppliers: _suppliers, onSupplierAdded: _addSupplier),
      InventoryPage(inventory: _inventory, onInventoryAdded: _addInventory),
      CompletionPage(onComplete: _completeSetup),
    ];
  }

  void _nextPage() {
    if (_currentStep < _pages.length - 1) {
      _pageController.nextPage(
        duration: Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      setState(() => _currentStep++);
    }
  }

  void _previousPage() {
    if (_currentStep > 0) {
      _pageController.previousPage(
        duration: Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      setState(() => _currentStep--);
    }
  }
  final Color _errorColor = Color(0xFFF44336); // Red

  void _saveUser(User user) => _user = user;
  void _addSupplier(Supplier s) => setState(() => _suppliers.add(s));
  void _addInventory(Article a) => setState(() => _inventory.add(a));
    void _showErrorMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: _errorColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }

  Future<void> _loadExistingLocations() async {
    try {
      final locations = await DatabaseHelper.instance.getAllStockLocations();
      if (locations.isNotEmpty) {
        setState(() => _businessLocation = locations.first);
      }
    } catch (e) {
      _showErrorMessage('Failed to load locations: ${e.toString()}');
    }
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
      });
    }
  }

Future<void> _completeSetup() async {
  final db = DatabaseHelper.instance;
  await db.createUser(_user);
  await db.createStockLocation(_businessLocation);
  await db.bulkInsertArticles(_inventory);
  for (final supplier in _suppliers) {
    await db.createSupplier(supplier);
  }
  
  // Call the completion callback before navigation
  widget.onComplete();
  
  // Then navigate to dashboard
  Navigator.pushReplacementNamed(context, '/dashboard');
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Business Setup'),
        actions: [
          Text('Step ${_currentStep + 1} of ${_pages.length}'),
          SizedBox(width: 16),
        ],
      ),
      body: Column(
        children: [
          LinearProgressIndicator(
            value: (_currentStep + 1) / _pages.length,
          ),
          Expanded(
            child: PageView.builder(
              controller: _pageController,
              physics: NeverScrollableScrollPhysics(),
              itemCount: _pages.length,
              itemBuilder: (ctx, index) => _pages[index],
            ),
          ),
          _NavigationControls(
            currentStep: _currentStep,
            totalSteps: _pages.length,
            onNext: _nextPage,
            onBack: _previousPage,
          ),
        ],
      ),
    );
  }
}

// Welcome Page




// Navigation Controls
class _NavigationControls extends StatelessWidget {
  final int currentStep;
  final int totalSteps;
  final VoidCallback onNext;
  final VoidCallback onBack;

  const _NavigationControls({
    required this.currentStep,
    required this.totalSteps,
    required this.onNext,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          if (currentStep > 0)
            OutlinedButton.icon(
              icon: Icon(Icons.arrow_back),
              label: Text('Back'),
              onPressed: onBack,
            ),
          if (currentStep < totalSteps - 1)
            ElevatedButton.icon(
              icon: Icon(Icons.arrow_forward),
              label: Text('Continue'),
              onPressed: onNext,
            ),
          if (currentStep == totalSteps - 1)
            ElevatedButton.icon(
              icon: Icon(Icons.check),
              label: Text('Finish Setup'),
              onPressed: onNext,
            ),
        ],
      ),
    );
  }
}
