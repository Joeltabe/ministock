import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:ministock/models/sale.dart';
import 'package:pdf/widgets.dart' as pw;

class ReceiptScreen extends StatelessWidget {
  final Sale sale;

  ReceiptScreen({required this.sale});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Receipt')),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            // Company header
            Center(
              child: Column(
                children: [
                  Text('Your Company Name', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  Text('123 Business St, City', style: TextStyle(fontSize: 14)),
                  Text('Tax ID: 123456789', style: TextStyle(fontSize: 14)),
                  SizedBox(height: 10),
                  Text('RECEIPT', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  Text('Date: ${DateFormat('yyyy-MM-dd HH:mm').format(DateTime.now())}'),
                ],
              ),
            ),
            
            Divider(thickness: 2),
            
            // Sale items
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Item', style: TextStyle(fontWeight: FontWeight.bold)),
                Text('Qty', style: TextStyle(fontWeight: FontWeight.bold)),
                Text('Price', style: TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
            
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(sale.title),
                Text(sale.quantitySold.toString()),
                Text('${sale.priceTTC}'),
              ],
            ),
            
            Divider(),
            
            // Totals
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Subtotal:'),
                Text('${sale.priceWT}'),
              ],
            ),
            
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('VAT (${sale.vatCategory}%):'),
                Text('${sale.priceTTC - sale.priceWT}'),
              ],
            ),
            
            Divider(),
            
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('TOTAL:', style: TextStyle(fontWeight: FontWeight.bold)),
                Text('${sale.priceTTC}', style: TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
            
            SizedBox(height: 20),
            Text('Thank you for your business!', style: TextStyle(fontStyle: FontStyle.italic)),
            
            SizedBox(height: 30),
            ElevatedButton(
              onPressed: () async {
                // Print receipt
              },
              child: Text('Print Receipt'),
            ),
          ],
        ),
      ),
    );
  }

  Future<Uint8List> generateReceiptPdf(Sale sale) async {
    final pdf = pw.Document();
    
    pdf.addPage(
      pw.Page(
        build: (pw.Context context) {
          return pw.Column(
            children: [
              pw.Text('Your Company Name', style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold)),
              pw.Text('123 Business St, City', style: pw.TextStyle(fontSize: 14)),
              pw.Text('Tax ID: 123456789', style: pw.TextStyle(fontSize: 14)),
              pw.SizedBox(height: 10),
              pw.Text('RECEIPT', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
              pw.Text('Date: ${DateFormat('yyyy-MM-dd HH:mm').format(DateTime.now())}'),
              pw.Divider(thickness: 2),
              
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('Item', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                  pw.Text('Qty', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                  pw.Text('Price', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                ],
              ),
              
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(sale.title),
                  pw.Text(sale.quantitySold.toString()),
                  pw.Text('${sale.priceTTC}'),
                ],
              ),
              
              pw.Divider(),
              
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('Subtotal:'),
                  pw.Text('${sale.priceWT}'),
                ],
              ),
              
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('VAT (${sale.vatCategory}%):'),
                  pw.Text('${sale.priceTTC - sale.priceWT}'),
                ],
              ),
              
              pw.Divider(),
              
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('TOTAL:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                  pw.Text('${sale.priceTTC}', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                ],
              ),
              
              pw.SizedBox(height: 20),
              pw.Text('Thank you for your business!', style: pw.TextStyle(fontStyle: pw.FontStyle.italic)),
            ],
          );
        },
      ),
    );
    
    return pdf.save();
  }
}