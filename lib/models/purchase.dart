class Purchase {
  final int? id;
  final String reference;
  final String title;
  final double quantity;
  final double Bprice;
  final double amount;
  final DateTime purchaseDate;
  final String? observations;
  final String supplierId;
  final String purchaseOrderNumber;
  final String deliveryNoteNumber;
  final String qualityCheckBy;


  Purchase({
    this.id,
    required this.reference,
    required this.title,
    required this.quantity,
    required this.Bprice,
    required this.amount,
    DateTime? purchaseDate,
    this.observations,
    required this.supplierId,
    required this.purchaseOrderNumber,
    required this.deliveryNoteNumber,
    required this.qualityCheckBy,

  }) : purchaseDate = purchaseDate ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'reference': reference,
      'title': title,
      'quantity': quantity,
      'Bprice': Bprice,
      'amount': amount,
      'purchase_date': purchaseDate.toIso8601String(),
      'observations': observations,
      'supplier_id': supplierId,
      'po_number': purchaseOrderNumber,
      'delivery_note': deliveryNoteNumber,
      'quality_check_by': qualityCheckBy,

    };
  }

  factory Purchase.fromMap(Map<String, dynamic> map) {
    return Purchase(
      id: map['id'],
      reference: map['reference'],
      title: map['title'],
      quantity: map['quantity'],
      Bprice: map['Bprice'],
      amount: map['amount'],
      purchaseDate: DateTime.parse(map['purchase_date']),
      observations: map['observations'],
      supplierId: map['supplier_id'],
      purchaseOrderNumber: map['po_number'],
      deliveryNoteNumber: map['delivery_note'],
      qualityCheckBy: map['quality_check_by'],

    );
  }

  Purchase copyWith({
    int? id,
    String? reference,
    String? title,
    double? quantity,
    double? Bprice,
    double? amount,
    DateTime? purchaseDate,
    String? observations,
    String? supplierId,
    String? purchaseOrderNumber,
    String? deliveryNoteNumber,
    String? qualityCheckBy,
    String? locationId,
  }) {
    return Purchase(
      id: id ?? this.id,
      reference: reference ?? this.reference,
      title: title ?? this.title,
      quantity: quantity ?? this.quantity,
      Bprice: Bprice ?? this.Bprice,
      amount: amount ?? this.amount,
      purchaseDate: purchaseDate ?? this.purchaseDate,
      observations: observations ?? this.observations,
      supplierId: supplierId ?? this.supplierId,
      purchaseOrderNumber: purchaseOrderNumber ?? this.purchaseOrderNumber,
      deliveryNoteNumber: deliveryNoteNumber ?? this.deliveryNoteNumber,
      qualityCheckBy: qualityCheckBy ?? this.qualityCheckBy,

    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Purchase &&
        other.reference == reference &&
        other.purchaseOrderNumber == purchaseOrderNumber &&
        other.supplierId == supplierId ;
  }

  @override
  int get hashCode {
    return reference.hashCode ^
        purchaseOrderNumber.hashCode ^
        supplierId.hashCode ;
  }
}