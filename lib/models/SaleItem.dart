import 'package:ministock/models/article.dart';
import 'package:ministock/models/sale.dart';

class SaleItem {
  final Article article;
  double quantity;
  double price;
  double vat;
  List<AppliedDiscount> discounts;

  SaleItem({
    required this.article,
    required this.quantity,
    required this.price,
    required this.vat,
    this.discounts = const [],
  });

  double get subtotal => quantity * price;
  double get taxAmount => subtotal * (vat / 100);
  double get total => subtotal + taxAmount;
}