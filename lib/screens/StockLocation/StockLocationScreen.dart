// import 'package:flutter/material.dart';
// import 'package:ministock/models/StockLocation.dart';
// import 'package:ministock/services/DatabaseHelper.dart';
// import 'package:uuid/uuid.dart';

// class StockLocationScreen extends StatefulWidget {
//   @override
//   _StockLocationScreenState createState() => _StockLocationScreenState();
// }

// class _StockLocationScreenState extends State<StockLocationScreen> {
//   final _formKey = GlobalKey<FormState>();
//   late TextEditingController _nameController;
//   late TextEditingController _addressController;
//   List<StockLocation> _locations = [];
//   bool _isLoading = false;

//   @override
//   void initState() {
//     super.initState();
//     _nameController = TextEditingController();
//     _addressController = TextEditingController();
//     _loadLocations();
//   }

//   Future<void> _loadLocations() async {
//     setState(() => _isLoading = true);
//     try {
//       final locations = await DatabaseHelper.instance.getAllStockLocations();
//       setState(() {
//         _locations = locations;
//         _isLoading = false;
//       });
//     } catch (e) {
//       // Handle error
//       setState(() => _isLoading = false);
//     }
//   }

//   Future<void> _saveLocation() async {
//     if (!_formKey.currentState!.validate()) return;

//     final location = StockLocation(
//       id: Uuid().v4(),
//       name: _nameController.text,
//       address: _addressController.text,
//     );

//     await DatabaseHelper.instance.createStockLocation(location);
//     _loadLocations();
//     _nameController.clear();
//     _addressController.clear();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(title: Text('Stock Locations')),
//       body: _isLoading
//           ? Center(child: CircularProgressIndicator())
//           : Column(
//               children: [
//                 Padding(
//                   padding: const EdgeInsets.all(16.0),
//                   child: Form(
//                     key: _formKey,
//                     child: Column(
//                       children: [
//                         TextFormField(
//                           controller: _nameController,
//                           decoration: InputDecoration(labelText: 'Location Name'),
//                           validator: (value) => value!.isEmpty ? 'Required' : null,
//                         ),
//                         TextFormField(
//                           controller: _addressController,
//                           decoration: InputDecoration(labelText: 'Address'),
//                           validator: (value) => value!.isEmpty ? 'Required' : null,
//                         ),
//                         ElevatedButton(
//                           onPressed: _saveLocation,
//                           child: Text('Add Location'),
//                         ),
//                       ],
//                     ),
//                   ),
//                 ),
//                 Expanded(
//                   child: ListView.builder(
//                     itemCount: _locations.length,
//                     itemBuilder: (context, index) {
//                       final location = _locations[index];
//                       return ListTile(
//                         title: Text(location.name),
//                         subtitle: Text(location.address),
//                         trailing: IconButton(
//                           icon: Icon(Icons.delete),
//                           onPressed: () async {
//                             await DatabaseHelper.instance.deleteStockLocation(location.id);
//                             _loadLocations();
//                           },
//                         ),
//                       );
//                     },
//                   ),
//                 ),
//               ],
//             ),
//     );
//   }
// }