// models/supplier.dart
class Supplier {
  final String id;
  final String name;
  final String contact;
  final String? taxId;
  final double? creditLimit;
  final String? paymentTerms;

  Supplier({
    required this.id,
    required this.name,
    required this.contact,
    this.taxId,
    this.creditLimit,
    this.paymentTerms, String? paymentPaymentTerms,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'contact': contact,
      'taxId': taxId,
      'creditLimit': creditLimit,
      'paymentTerms': paymentTerms,
    };
  }

  factory Supplier.fromMap(Map<String, dynamic> map) {
    return Supplier(
      id: map['id'],
      name: map['name'],
      contact: map['contact'],
      taxId: map['taxId'],
      creditLimit: map['creditLimit']?.toDouble(),
      paymentTerms: map['paymentTerms'],
    );
  }

  Supplier copyWith({
    String? id,
    String? name,
    String? contact,
    String? taxId,
    double? creditLimit,
    String? paymentTerms,
  }) {
    return Supplier(
      id: id ?? this.id,
      name: name ?? this.name,
      contact: contact ?? this.contact,
      taxId: taxId ?? this.taxId,
      creditLimit: creditLimit ?? this.creditLimit,
      paymentPaymentTerms: paymentTerms ?? this.paymentTerms,
    );
  }

  @override
  String toString() {
    return 'Supplier(id: $id, name: $name, contact: $contact)';
  }
}