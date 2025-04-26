import 'dart:typed_data';
import 'package:flutter/foundation.dart';

class Article {
  final String reference;
  final String title;
  final String? type;
  final String? category;
  final double priceWT;
  final double vat;
  final double priceTTC;
  final Uint8List? image;
  final String? observations;
  final String barcode;
  final String? manufacturer;
  final DateTime? expiryDate;
  final String? batchNumber;
  final List<String> alternativeCodes;

  Article({
    required this.reference,
    required this.title,
    required this.barcode,
    this.type,
    this.category,
    required this.priceWT,
    required this.vat,
    required this.priceTTC,
    this.image,
    this.observations,
    this.manufacturer,
    this.expiryDate,
    this.batchNumber,
    List<String>? alternativeCodes,
  }) : alternativeCodes = alternativeCodes ?? [];

  Map<String, dynamic> toMap() {
    return {
      'reference': reference,
      'title': title,
      'barcode': barcode,
      'type': type,
      'category': category,
      'priceWT': priceWT,
      'vat': vat,
      'priceTTC': priceTTC,
      'image': image,
      'observations': observations,
      'manufacturer': manufacturer,
      'expiryDate': expiryDate?.toIso8601String(),
      'batchNumber': batchNumber,
      'alternativeCodes': alternativeCodes.join(','),
    };
  }

  factory Article.fromMap(Map<String, dynamic> map) {
    return Article(
      reference: map['reference'],
      title: map['title'],
      barcode: map['barcode'],
      type: map['type'],
      category: map['category'],
      priceWT: map['priceWT'],
      vat: map['vat'],
      priceTTC: map['priceTTC'],
      image: map['image'],
      observations: map['observations'],
      manufacturer: map['manufacturer'],
      expiryDate: map['expiryDate'] != null 
          ? DateTime.parse(map['expiryDate']) 
          : null,
      batchNumber: map['batchNumber'],
      alternativeCodes: map['alternativeCodes']?.toString().split(',') ?? [],
    );
  }

  Article copyWith({
    String? reference,
    String? title,
    String? barcode,
    String? type,
    String? category,
    double? priceWT,
    double? vat,
    double? priceTTC,
    Uint8List? image,
    String? observations,
    String? manufacturer,
    DateTime? expiryDate,
    String? batchNumber,
    List<String>? alternativeCodes,
  }) {
    return Article(
      reference: reference ?? this.reference,
      title: title ?? this.title,
      barcode: barcode ?? this.barcode,
      type: type ?? this.type,
      category: category ?? this.category,
      priceWT: priceWT ?? this.priceWT,
      vat: vat ?? this.vat,
      priceTTC: priceTTC ?? this.priceTTC,
      image: image ?? this.image,
      observations: observations ?? this.observations,
      manufacturer: manufacturer ?? this.manufacturer,
      expiryDate: expiryDate ?? this.expiryDate,
      batchNumber: batchNumber ?? this.batchNumber,
      alternativeCodes: alternativeCodes ?? this.alternativeCodes,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Article &&
        other.reference == reference &&
        other.title == title &&
        other.barcode == barcode &&
        other.type == type &&
        other.category == category &&
        other.priceWT == priceWT &&
        other.vat == vat &&
        other.priceTTC == priceTTC &&
        listEquals(other.alternativeCodes, alternativeCodes);
  }

  @override
  int get hashCode {
    return reference.hashCode ^
        title.hashCode ^
        barcode.hashCode ^
        priceWT.hashCode ^
        vat.hashCode;
  }
}