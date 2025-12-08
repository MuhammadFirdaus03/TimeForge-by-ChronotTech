import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';
import 'package:starter_architecture_flutter_firebase/src/features/jobs/domain/job.dart';

// Invoice Data Model
class InvoiceData {
  // Invoice Info
  final String invoiceNumber;
  final DateTime issueDate;
  final DateTime dueDate;
  
  // Your Company Info (Freelancer)
  final String yourName;
  final String yourEmail;
  final String yourPhone;
  final String? yourAddress;
  final String? yourWebsite;
  
  // Client Info
  final String clientName;
  final String clientCompany;
  final String clientEmail;
  final String? clientAddress;
  
  // Project Details
  final String projectName;
  final JobPricingType pricingType; // NEW: Track the job pricing type
  final List<InvoiceLineItem> lineItems;
  
  // Payment Details
  final double taxRate; // e.g., 0.0 for 0%, 0.1 for 10%
  final String paymentTerms;
  final String? bankName;
  final String? accountNumber;
  final String? notes;
  
  InvoiceData({
    required this.invoiceNumber,
    required this.issueDate,
    required this.dueDate,
    required this.yourName,
    required this.yourEmail,
    required this.yourPhone,
    this.yourAddress,
    this.yourWebsite,
    required this.clientName,
    required this.clientCompany,
    required this.clientEmail,
    this.clientAddress,
    required this.projectName,
    required this.pricingType, // NEW
    required this.lineItems,
    this.taxRate = 0.0,
    this.paymentTerms = 'Payment due within 14 days',
    this.bankName,
    this.accountNumber,
    this.notes,
  });
  
  // Calculate totals
  double get subtotal => lineItems.fold(0, (sum, item) => sum + item.total);
  double get tax => subtotal * taxRate;
  double get total => subtotal + tax;
}

// Line Item (Each time entry or fixed price item)
class InvoiceLineItem {
  final DateTime date;
  final String description;
  final double hours;
  final double ratePerHour;
  final bool isFixedPriceItem; // NEW: Flag for fixed price items
  
  InvoiceLineItem({
    required this.date,
    required this.description,
    required this.hours,
    required this.ratePerHour,
    this.isFixedPriceItem = false, // NEW
  });
  
  double get total => hours * ratePerHour;
}

// Invoice Generator
class InvoiceGenerator {
  static Future<void> generateAndShareInvoice(InvoiceData invoice) async {
    final pdf = pw.Document();
    
    // Add page with invoice content
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: pw.EdgeInsets.all(32),
        build: (context) => [
          _buildHeader(invoice),
          pw.SizedBox(height: 20),
          _buildParties(invoice),
          pw.SizedBox(height: 20),
          _buildProjectInfo(invoice),
          pw.SizedBox(height: 10),
          // CHANGED: Different table based on pricing type
          _buildLineItemsTable(invoice),
          pw.SizedBox(height: 20),
          _buildTotals(invoice),
          pw.SizedBox(height: 30),
          _buildPaymentTerms(invoice),
          pw.SizedBox(height: 20),
          if (invoice.notes != null) _buildNotes(invoice),
          pw.Spacer(),
          _buildSignature(invoice),
        ],
      ),
    );
    
    // Share the PDF
    await Printing.sharePdf(
      bytes: await pdf.save(),
      filename: 'Invoice_${invoice.invoiceNumber}.pdf',
    );
  }
  
  // Header with logo and invoice details
  static pw.Widget _buildHeader(InvoiceData invoice) {
    final dateFormat = DateFormat('MMM dd, yyyy');
    
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        // Left side - Logo and company name
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            // TimeForge Logo (using icon as placeholder)
            pw.Container(
              width: 50,
              height: 50,
              decoration: pw.BoxDecoration(
                color: PdfColors.blue700,
                borderRadius: pw.BorderRadius.circular(12),
              ),
              child: pw.Center(
                child: pw.Text(
                  'TF',
                  style: pw.TextStyle(
                    color: PdfColors.white,
                    fontSize: 24,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ),
            ),
            pw.SizedBox(height: 8),
            pw.Text(
              'TimeForge',
              style: pw.TextStyle(
                fontSize: 20,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.blue700,
              ),
            ),
          ],
        ),
        // Right side - Invoice details
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.end,
          children: [
            pw.Text(
              'INVOICE',
              style: pw.TextStyle(
                fontSize: 32,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.blue700,
              ),
            ),
            pw.SizedBox(height: 8),
            pw.Text('Invoice #: ${invoice.invoiceNumber}',
              style: pw.TextStyle(fontSize: 12)),
            pw.Text('Date: ${dateFormat.format(invoice.issueDate)}',
              style: pw.TextStyle(fontSize: 12)),
            pw.Text('Due: ${dateFormat.format(invoice.dueDate)}',
              style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
          ],
        ),
      ],
    );
  }
  
  // From and Bill To sections
  static pw.Widget _buildParties(InvoiceData invoice) {
    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        // FROM section
        pw.Expanded(
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text('FROM',
                style: pw.TextStyle(
                  fontSize: 12,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.grey700,
                )),
              pw.SizedBox(height: 4),
              pw.Text(invoice.yourName,
                style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
              pw.Text(invoice.yourEmail, style: pw.TextStyle(fontSize: 10)),
              pw.Text(invoice.yourPhone, style: pw.TextStyle(fontSize: 10)),
              if (invoice.yourAddress != null)
                pw.Text(invoice.yourAddress!, style: pw.TextStyle(fontSize: 10)),
              if (invoice.yourWebsite != null)
                pw.Text(invoice.yourWebsite!, style: pw.TextStyle(fontSize: 10)),
            ],
          ),
        ),
        pw.SizedBox(width: 20),
        // BILL TO section
        pw.Expanded(
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text('BILL TO',
                style: pw.TextStyle(
                  fontSize: 12,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.grey700,
                )),
              pw.SizedBox(height: 4),
              pw.Text(invoice.clientName,
                style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
              pw.Text(invoice.clientCompany,
                style: pw.TextStyle(fontSize: 11)),
              pw.Text(invoice.clientEmail, style: pw.TextStyle(fontSize: 10)),
              if (invoice.clientAddress != null)
                pw.Text(invoice.clientAddress!, style: pw.TextStyle(fontSize: 10)),
            ],
          ),
        ),
      ],
    );
  }
  
  // Project name with pricing type badge
  static pw.Widget _buildProjectInfo(InvoiceData invoice) {
    String pricingLabel;
    PdfColor badgeColor;
    
    switch (invoice.pricingType) {
      case JobPricingType.hourly:
        pricingLabel = 'HOURLY RATE';
        badgeColor = PdfColors.green700;
        break;
      case JobPricingType.fixedPrice:
        pricingLabel = 'FIXED PRICE';
        badgeColor = PdfColors.purple700;
        break;
      case JobPricingType.unpaid:
        pricingLabel = 'DOCUMENTATION ONLY';
        badgeColor = PdfColors.grey700;
        break;
    }
    
    return pw.Container(
      padding: pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        color: PdfColors.grey200,
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Expanded(
            child: pw.Text(
              'PROJECT: ${invoice.projectName}',
              style: pw.TextStyle(
                fontSize: 14,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
          ),
          pw.Container(
            padding: pw.EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: pw.BoxDecoration(
              color: badgeColor,
              borderRadius: pw.BorderRadius.circular(4),
            ),
            child: pw.Text(
              pricingLabel,
              style: pw.TextStyle(
                color: PdfColors.white,
                fontSize: 9,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  // UPDATED: Line items table that adapts to pricing type
  static pw.Widget _buildLineItemsTable(InvoiceData invoice) {
    final dateFormat = DateFormat('MMM dd');
    final currencyFormat = NumberFormat.currency(symbol: '\$');
    
    // Different table headers based on pricing type
    if (invoice.pricingType == JobPricingType.fixedPrice) {
      // Fixed price: Simple table
      return pw.Table(
        border: pw.TableBorder.all(color: PdfColors.grey400),
        children: [
          // Header row
          pw.TableRow(
            decoration: pw.BoxDecoration(color: PdfColors.purple700),
            children: [
              _tableHeader('DESCRIPTION'),
              _tableHeader('HOURS TRACKED'),
              _tableHeader('FIXED AMOUNT'),
            ],
          ),
          // Single data row for fixed price
          ...invoice.lineItems.map((item) => pw.TableRow(
            children: [
              _tableCell(item.description),
              _tableCell('${item.hours.toStringAsFixed(1)}h'),
              _tableCell(currencyFormat.format(item.total)),
            ],
          )),
        ],
      );
    } else if (invoice.pricingType == JobPricingType.unpaid) {
      // Unpaid: No amounts, just tracking
      return pw.Table(
        border: pw.TableBorder.all(color: PdfColors.grey400),
        children: [
          // Header row
          pw.TableRow(
            decoration: pw.BoxDecoration(color: PdfColors.grey700),
            children: [
              _tableHeader('DATE'),
              _tableHeader('DESCRIPTION'),
              _tableHeader('HOURS TRACKED'),
            ],
          ),
          // Data rows
          ...invoice.lineItems.map((item) => pw.TableRow(
            children: [
              _tableCell(dateFormat.format(item.date)),
              _tableCell(item.description),
              _tableCell('${item.hours.toStringAsFixed(1)}h'),
            ],
          )),
        ],
      );
    } else {
      // Hourly: Full detailed table (original)
      return pw.Table(
        border: pw.TableBorder.all(color: PdfColors.grey400),
        children: [
          // Header row
          pw.TableRow(
            decoration: pw.BoxDecoration(color: PdfColors.green700),
            children: [
              _tableHeader('DATE'),
              _tableHeader('DESCRIPTION'),
              _tableHeader('HOURS'),
              _tableHeader('RATE'),
              _tableHeader('AMOUNT'),
            ],
          ),
          // Data rows
          ...invoice.lineItems.map((item) => pw.TableRow(
            children: [
              _tableCell(dateFormat.format(item.date)),
              _tableCell(item.description),
              _tableCell('${item.hours.toStringAsFixed(1)}h'),
              _tableCell(currencyFormat.format(item.ratePerHour)),
              _tableCell(currencyFormat.format(item.total)),
            ],
          )),
        ],
      );
    }
  }
  
  static pw.Widget _tableHeader(String text) {
    return pw.Padding(
      padding: pw.EdgeInsets.all(8),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontWeight: pw.FontWeight.bold,
          color: PdfColors.white,
          fontSize: 10,
        ),
      ),
    );
  }
  
  static pw.Widget _tableCell(String text) {
    return pw.Padding(
      padding: pw.EdgeInsets.all(8),
      child: pw.Text(text, style: pw.TextStyle(fontSize: 10)),
    );
  }
  
  // UPDATED: Totals section (hide for unpaid)
  static pw.Widget _buildTotals(InvoiceData invoice) {
    // Don't show totals for unpaid invoices
    if (invoice.pricingType == JobPricingType.unpaid) {
      return pw.Align(
        alignment: pw.Alignment.centerRight,
        child: pw.Container(
          width: 200,
          padding: pw.EdgeInsets.all(12),
          decoration: pw.BoxDecoration(
            color: PdfColors.grey200,
            borderRadius: pw.BorderRadius.circular(8),
          ),
          child: pw.Text(
            'DOCUMENTATION ONLY\nNo payment required',
            style: pw.TextStyle(
              fontSize: 12,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.grey700,
            ),
            textAlign: pw.TextAlign.center,
          ),
        ),
      );
    }
    
    final currencyFormat = NumberFormat.currency(symbol: '\$');
    
    return pw.Align(
      alignment: pw.Alignment.centerRight,
      child: pw.Container(
        width: 200,
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            _totalRow('SUBTOTAL', currencyFormat.format(invoice.subtotal)),
            if (invoice.taxRate > 0)
              _totalRow('TAX (${(invoice.taxRate * 100).toStringAsFixed(0)}%)', 
                currencyFormat.format(invoice.tax)),
            pw.Divider(thickness: 2),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text('TOTAL',
                  style: pw.TextStyle(
                    fontSize: 16,
                    fontWeight: pw.FontWeight.bold,
                  )),
                pw.Text(currencyFormat.format(invoice.total),
                  style: pw.TextStyle(
                    fontSize: 16,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.blue700,
                  )),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  static pw.Widget _totalRow(String label, String amount) {
    return pw.Padding(
      padding: pw.EdgeInsets.symmetric(vertical: 4),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(label, style: pw.TextStyle(fontSize: 12)),
          pw.Text(amount, style: pw.TextStyle(fontSize: 12)),
        ],
      ),
    );
  }
  
  // UPDATED: Payment terms (adjusted for unpaid)
  static pw.Widget _buildPaymentTerms(InvoiceData invoice) {
    // Different message for unpaid
    if (invoice.pricingType == JobPricingType.unpaid) {
      return pw.Container(
        padding: pw.EdgeInsets.all(12),
        decoration: pw.BoxDecoration(
          border: pw.Border.all(color: PdfColors.grey400),
          borderRadius: pw.BorderRadius.circular(8),
        ),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text('NOTES',
              style: pw.TextStyle(
                fontSize: 12,
                fontWeight: pw.FontWeight.bold,
              )),
            pw.SizedBox(height: 4),
            pw.Text(
              'This is a time tracking document only. No payment is required for this work.',
              style: pw.TextStyle(fontSize: 10),
            ),
          ],
        ),
      );
    }
    
    return pw.Container(
      padding: pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey400),
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text('PAYMENT TERMS',
            style: pw.TextStyle(
              fontSize: 12,
              fontWeight: pw.FontWeight.bold,
            )),
          pw.SizedBox(height: 4),
          pw.Text(invoice.paymentTerms, style: pw.TextStyle(fontSize: 10)),
          if (invoice.bankName != null) ...[
            pw.SizedBox(height: 4),
            pw.Text('Bank: ${invoice.bankName}', style: pw.TextStyle(fontSize: 10)),
          ],
          if (invoice.accountNumber != null)
            pw.Text('Account: ${invoice.accountNumber}', style: pw.TextStyle(fontSize: 10)),
        ],
      ),
    );
  }
  
  // Notes section
  static pw.Widget _buildNotes(InvoiceData invoice) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text('NOTES',
          style: pw.TextStyle(
            fontSize: 12,
            fontWeight: pw.FontWeight.bold,
          )),
        pw.SizedBox(height: 4),
        pw.Text(invoice.notes!, style: pw.TextStyle(fontSize: 10)),
      ],
    );
  }
  
  // Signature line
  static pw.Widget _buildSignature(InvoiceData invoice) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Container(
          width: 200,
          height: 60,
          decoration: pw.BoxDecoration(
            border: pw.Border(bottom: pw.BorderSide(width: 1)),
          ),
          child: pw.Align(
            alignment: pw.Alignment.bottomLeft,
            child: pw.Padding(
              padding: pw.EdgeInsets.only(bottom: 4),
              child: pw.Text(
                invoice.yourName,
                style: pw.TextStyle(
                  fontSize: 16,
                  fontStyle: pw.FontStyle.italic,
                ),
              ),
            ),
          ),
        ),
        pw.SizedBox(height: 4),
        pw.Text('Authorized Signature',
          style: pw.TextStyle(fontSize: 10, color: PdfColors.grey600)),
      ],
    );
  }
}