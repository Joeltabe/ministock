class StockLocation {
  final String id;
  final String name;
  final String address;
  final double latitude;
  final double longitude;

  StockLocation({
    required this.id,
    required this.name,
    required this.address,
    required this.latitude,
    required this.longitude,
  });

factory StockLocation.fromMap(Map<String, dynamic> map) {
  return StockLocation(
    id: map['id']?.toString() ?? '',
    name: map['name']?.toString() ?? '',
    address: map['address']?.toString() ?? '',
    latitude: (map['latitude'] as num?)?.toDouble() ?? 0.0,
    longitude: (map['longitude'] as num?)?.toDouble() ?? 0.0,
  );
}

  Map<String, dynamic> toMap() => {
    'id': id,
    'name': name,
    'address': address,
    'latitude': latitude,
    'longitude': longitude,
  };
}
// Add this extension to your StockLocation class
extension StockLocationCopyWith on StockLocation {
  StockLocation copyWith({
    String? id,
    String? name,
    String? address,
    double? latitude,
    double? longitude,
  }) {
    return StockLocation(
      id: id ?? this.id,
      name: name ?? this.name,
      address: address ?? this.address,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
    );
  }
}