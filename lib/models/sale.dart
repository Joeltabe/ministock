// Define supporting enums and classes first
enum PaymentMethod {
  cash,
  creditCard,
  mobileMoney,
  voucher,
  credit,
}

class AppliedDiscount {
  final String discountId;
  final double amount;

  AppliedDiscount({
    required this.discountId,
    required this.amount,
  });

  Map<String, dynamic> toMap() {
    return {
      'discountId': discountId,
      'amount': amount,
    };
  }

  factory AppliedDiscount.fromMap(Map<String, dynamic> map) {
    return AppliedDiscount(
      discountId: map['discountId'],
      amount: map['amount'],
    );
  }
}

class Sale {
  final int? id;
  final String salesType;
  final String reference;
  final String title;
  final double quantitySold;
  final double priceWT;
  final String vatCategory;
  final double priceTTC;
  final String sellingPrice;
  final DateTime saleDate;
  final String? observations;
  final String cashierId;
  final String terminalId;
  final String? invoiceNumber;
  late final List<AppliedDiscount> discounts;
  final PaymentMethod paymentMethod;

  Sale({
    this.id,
    required this.salesType,
    required this.reference,
    required this.title,
    required this.quantitySold,
    required this.priceWT,
    required this.vatCategory,
    required this.priceTTC,
    required this.sellingPrice,
    this.observations,
    DateTime? saleDate,
    required this.cashierId,
    required this.terminalId,
    this.invoiceNumber,
    required this.discounts,
    required this.paymentMethod,
  }) : saleDate = saleDate ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'salesType': salesType,
      'reference': reference,
      'title': title,
      'quantitySold': quantitySold,
      'priceWT': priceWT,
      'C_WAT': vatCategory,
      'priceTTC': priceTTC,
      'selling_price': sellingPrice,
      'sale_date': saleDate.toIso8601String(),
      'observations': observations,
      'cashierId': cashierId,
      'terminalId': terminalId,
      'invoiceNumber': invoiceNumber,
      'discounts': discounts.map((d) => d.toMap()).toList(),
      'paymentMethod': paymentMethod.name,
    };
  }

  factory Sale.fromMap(Map<String, dynamic> map) {
    return Sale(
      id: map['id'],
      salesType: map['salesType'],
      reference: map['reference'],
      title: map['title'],
      quantitySold: map['quantitySold'],
      priceWT: map['priceWT'],
      vatCategory: map['C_WAT'],
      priceTTC: map['priceTTC'],
      sellingPrice: map['selling_price'],
      observations: map['observations'],
      saleDate: DateTime.parse(map['sale_date']),
      cashierId: map['cashierId'],
      terminalId: map['terminalId'],
      invoiceNumber: map['invoiceNumber'],
      discounts: List<AppliedDiscount>.from(
        map['discounts'].map((d) => AppliedDiscount.fromMap(d)),
      ),
      paymentMethod: PaymentMethod.values.firstWhere(
        (e) => e.name == map['paymentMethod'],
        orElse: () => PaymentMethod.cash,
      ),
    );
  }

  Sale copyWith({
    int? id,
    String? salesType,
    String? reference,
    String? title,
    double? quantitySold,
    double? priceWT,
    String? vatCategory,
    double? priceTTC,
    String? sellingPrice,
    String? observations,
    DateTime? saleDate,
    String? cashierId,
    String? terminalId,
    String? invoiceNumber,
    List<AppliedDiscount>? discounts,
    PaymentMethod? paymentMethod,
  }) {
    return Sale(
      id: id ?? this.id,
      salesType: salesType ?? this.salesType,
      reference: reference ?? this.reference,
      title: title ?? this.title,
      quantitySold: quantitySold ?? this.quantitySold,
      priceWT: priceWT ?? this.priceWT,
      vatCategory: vatCategory ?? this.vatCategory,
      priceTTC: priceTTC ?? this.priceTTC,
      sellingPrice: sellingPrice ?? this.sellingPrice,
      observations: observations ?? this.observations,
      saleDate: saleDate ?? this.saleDate,
      cashierId: cashierId ?? this.cashierId,
      terminalId: terminalId ?? this.terminalId,
      invoiceNumber: invoiceNumber ?? this.invoiceNumber,
      discounts: discounts ?? this.discounts,
      paymentMethod: paymentMethod ?? this.paymentMethod,
    );
  }
}