import 'package:flutter/material.dart';
import 'package:ministock/models/sale.dart';
import 'package:ministock/models/article.dart';
import 'package:intl/intl.dart';
import 'package:printing/printing.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

class ReceiptScreen extends StatelessWidget {
  final List<Sale> sales;
  final String invoiceNumber;
  final String cashierName;
  final String paymentMethod;
  final DateTime date;
  final double total;

  ReceiptScreen({
    required this.sales,
    required this.invoiceNumber,
    required this.cashierName,
    required this.paymentMethod,
    required this.date,
    required this.total,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Receipt')),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            _buildReceiptContent(),
            SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                  onPressed: () => _printReceipt(context),
                  child: Text('Print Receipt'),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text('Back to Sales'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReceiptContent() {
    double subtotal = sales.fold(0, (sum, sale) => sum + sale.priceWT);
    double totalTax = sales.fold(0, (sum, sale) => sum + (sale.priceTTC - sale.priceWT));
    double totalDiscounts = sales.fold(0, (sum, sale) {
      return sum + sale.discounts.fold(0, (discSum, disc) => discSum + disc.amount);
    });

    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Text('YOUR COMPANY NAME', 
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ),
            SizedBox(height: 5),
            Center(child: Text('123 Business Street, City')),
            Center(child: Text('Tax ID: 123456789')),
            SizedBox(height: 10),
            Center(
              child: Text('INVOICE', 
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ),
            Center(child: Text('No: $invoiceNumber')),
            Center(child: Text(DateFormat('yyyy-MM-dd HH:mm').format(date))),
            Divider(thickness: 2),
            
            // Cashier and payment info
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Cashier: $cashierName'),
                Text('Payment: $paymentMethod'),
              ],
            ),
            SizedBox(height: 10),
            
            // Item details header
            const Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  flex: 3,
                  child: Text('Description', style: TextStyle(fontWeight: FontWeight.bold))),
                Expanded(
                  child: Text('Qty', 
                      style: TextStyle(fontWeight: FontWeight.bold), 
                      textAlign: TextAlign.center),
                ),
                Expanded(
                  child: Text('Price', 
                      style: TextStyle(fontWeight: FontWeight.bold), 
                      textAlign: TextAlign.right),
                ),
              ],
            ),
            Divider(),
            
            // Items list
            ...sales.map((sale) {
              return Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        flex: 3,
                        child: Text(sale.title),
                      ),
                      Expanded(
                        child: Text(sale.quantitySold.toString(), 
                            textAlign: TextAlign.center),
                      ),
                      Expanded(
                        child: Text('${sale.priceTTC.toStringAsFixed(2)}', 
                            textAlign: TextAlign.right),
                      ),
                    ],
                  ),
                  if (sale.discounts.isNotEmpty) ...[
                    ...sale.discounts.map((discount) => Padding(
                      padding: EdgeInsets.only(left: 20),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Discount (${discount.discountId})', 
                              style: TextStyle(fontStyle: FontStyle.italic)),
                          Text('-${discount.amount.toStringAsFixed(2)}', 
                              style: TextStyle(color: Colors.red)),
                        ],
                      ),
                    )),
                  ],
                  Divider(),
                ],
              );
            }).toList(),
            
            // Totals
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: [
                  _buildTotalRow('Subtotal:', subtotal),
                  _buildTotalRow('Tax:', totalTax),
                  if (totalDiscounts > 0) 
                    _buildTotalRow('Discounts:', -totalDiscounts, isDiscount: true),
                  Divider(),
                  _buildTotalRow('TOTAL:', total, isTotal: true),
                ],
              ),
            ),
            
            SizedBox(height: 20),
            Center(
              child: Text('Thank you for your business!', 
                  style: TextStyle(fontStyle: FontStyle.italic)),
            ),
            Center(
              child: Text('Returns accepted within 7 days with receipt'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTotalRow(String label, double amount, {bool isTotal = false, bool isDiscount = false}) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(
            fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
          )),
          Text(
            '${amount.toStringAsFixed(2)} CFA', 
            style: TextStyle(
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
              color: isDiscount ? Colors.red : null,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _printReceipt(BuildContext context) async {
    final pdf = pw.Document();
    
    double subtotal = sales.fold(0, (sum, sale) => sum + sale.priceWT);
    double totalTax = sales.fold(0, (sum, sale) => sum + (sale.priceTTC - sale.priceWT));
    double totalDiscounts = sales.fold(0, (sum, sale) {
      return sum + sale.discounts.fold(0, (discSum, disc) => discSum + disc.amount);
    });

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat(58 * PdfPageFormat.mm, double.infinity),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Center(
                child: pw.Text('YOUR COMPANY NAME', 
                    style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
              ),
              pw.SizedBox(height: 4),
              pw.Center(child: pw.Text('123 Business Street, City', style: pw.TextStyle(fontSize: 10))),
              pw.Center(child: pw.Text('Tax ID: 123456789', style: pw.TextStyle(fontSize: 10))),
              pw.SizedBox(height: 8),
              pw.Center(
                child: pw.Text('INVOICE', 
                    style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold)),
              ),
              pw.Center(child: pw.Text('No: $invoiceNumber', style: pw.TextStyle(fontSize: 10))),
              pw.Center(child: pw.Text(DateFormat('yyyy-MM-dd HH:mm').format(date), style: pw.TextStyle(fontSize: 10))),
              pw.Divider(thickness: 1),
              
              // Cashier and payment info
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('Cashier: $cashierName', style: pw.TextStyle(fontSize: 10)),
                  pw.Text('Payment: $paymentMethod', style: pw.TextStyle(fontSize: 10)),
                ],
              ),
              pw.SizedBox(height: 8),
              
              // Item details header
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Expanded(
                    flex: 3,
                    child: pw.Text('Description', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
                  ),
                  pw.Expanded(
                    child: pw.Text('Qty', 
                        style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold), 
                        textAlign: pw.TextAlign.center),
                  ),
                  pw.Expanded(
                    child: pw.Text('Price', 
                        style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold), 
                        textAlign: pw.TextAlign.right),
                  ),
                ],
              ),
              pw.Divider(thickness: 1),
              
              // Items list
              ...sales.map((sale) {
                return pw.Column(
                  children: [
                    pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Expanded(
                          flex: 3,
                          child: pw.Text(sale.title, style: pw.TextStyle(fontSize: 10)),
                        ),
                        pw.Expanded(
                          child: pw.Text(sale.quantitySold.toString(), 
                              textAlign: pw.TextAlign.center, style: pw.TextStyle(fontSize: 10)),
                        ),
                        pw.Expanded(
                          child: pw.Text('${sale.priceTTC.toStringAsFixed(2)}', 
                              textAlign: pw.TextAlign.right, style: pw.TextStyle(fontSize: 10)),
                        ),
                      ],
                    ),
                    if (sale.discounts.isNotEmpty) ...[
                      ...sale.discounts.map((discount) => pw.Padding(
                        padding: pw.EdgeInsets.only(left: 10),
                        child: pw.Row(
                          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                          children: [
                            pw.Text('Discount (${discount.discountId})', 
                                style: pw.TextStyle(fontSize: 9, fontStyle: pw.FontStyle.italic)),
                            pw.Text('-${discount.amount.toStringAsFixed(2)}', 
                                style: pw.TextStyle(fontSize: 9, color: PdfColors.red)),
                          ],
                        ),
                      )),
                    ],
                    pw.Divider(thickness: 0.5),
                  ],
                );
              }).toList(),
              
              // Totals
              pw.Padding(
                padding: pw.EdgeInsets.symmetric(horizontal: 8),
                child: pw.Column(
                  children: [
                    _buildPdfTotalRow('Subtotal:', subtotal, 10),
                    _buildPdfTotalRow('Tax:', totalTax, 10),
                    if (totalDiscounts > 0) 
                      _buildPdfTotalRow('Discounts:', -totalDiscounts, 10, isDiscount: true),
                    pw.Divider(thickness: 1),
                    _buildPdfTotalRow('TOTAL:', total, 11, isTotal: true),
                  ],
                ),
              ),
              
              pw.SizedBox(height: 10),
              pw.Center(
                child: pw.Text('Thank you for your business!', 
                    style: pw.TextStyle(fontSize: 10, fontStyle: pw.FontStyle.italic)),
              ),
              pw.Center(
                child: pw.Text('Returns accepted within 7 days with receipt', 
                    style: pw.TextStyle(fontSize: 9)),
              ),
            ],
          );
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
    );
  }

  pw.Widget _buildPdfTotalRow(String label, double amount, double fontSize, 
                             {bool isTotal = false, bool isDiscount = false}) {
    return pw.Padding(
      padding: pw.EdgeInsets.symmetric(vertical: 2),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(label, style: pw.TextStyle(
            fontSize: fontSize,
            fontWeight: isTotal ? pw.FontWeight.bold : pw.FontWeight.normal,
          )),
          pw.Text(
            '${amount.toStringAsFixed(2)} CFA', 
            style: pw.TextStyle(
              fontSize: fontSize,
              fontWeight: isTotal ? pw.FontWeight.bold : pw.FontWeight.normal,
              color: isDiscount ? PdfColors.red : PdfColors.black,
            ),
          ),
        ],
      ),
    );
  }
}