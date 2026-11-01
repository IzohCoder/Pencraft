import 'dart:io';
import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import '../data/models/document_model.dart';
import '../core/currency_formatter.dart';

// ---------------------------------------------------------------------------
// Business profile data passed into PDF generation
// ---------------------------------------------------------------------------
class BusinessProfileData {
  const BusinessProfileData({
    required this.name,
    this.ownerName = '',
    this.address = '',
    this.phone = '',
    this.email = '',
    this.taxId = '',
    this.logoPath,
    this.signaturePath,
    this.paymentInstructions = '',
    this.defaultNotes = '',
    this.defaultTerms = '',
  });

  final String name;
  final String ownerName;
  final String address;
  final String phone;
  final String email;
  final String taxId;
  final String? logoPath;
  final String? signaturePath;
  final String paymentInstructions;
  final String defaultNotes;
  final String defaultTerms;
}

// ---------------------------------------------------------------------------
// PDF Service — 3 original templates
// ---------------------------------------------------------------------------
class PdfService {
  static PdfService? _instance;
  static PdfService get instance => _instance ??= PdfService._();
  PdfService._();

  // Shared font cache
  pw.Font? _bodyFont;
  pw.Font? _bodyFontBold;
  pw.Font? _headingFont;

  Future<void> _loadFonts() async {
    if (_bodyFont != null) return;
    final regular = await rootBundle.load('assets/fonts/Inter-Regular.ttf');
    final bold = await rootBundle.load('assets/fonts/Inter-Bold.ttf');
    final heading = await rootBundle.load('assets/fonts/DMSerifDisplay-Regular.ttf');
    _bodyFont = pw.Font.ttf(regular);
    _bodyFontBold = pw.Font.ttf(bold);
    _headingFont = pw.Font.ttf(heading);
  }

  /// Generate PDF bytes for a document. [templateId]: 1=Classic Ledger, 2=Print Studio, 3=Field Receipt.
  Future<Uint8List> generatePdf({
    required DocumentModel doc,
    required BusinessProfileData business,
    required int templateId,
    bool showFooter = false,   // "Made with Pencraft" — free tier
    String? logoPath,
    String? signaturePath,
  }) async {
    await _loadFonts();

    final theme = _templateTheme(templateId, doc.accentColour);

    switch (templateId) {
      case 2:
        return _buildPrintStudio(doc, business, theme, showFooter);
      case 3:
        return _buildFieldReceipt(doc, business, theme, showFooter);
      default:
        return _buildClassicLedger(doc, business, theme, showFooter);
    }
  }

  /// Save PDF to temp directory and return the file path.
  Future<String> savePdfToTemp({
    required DocumentModel doc,
    required BusinessProfileData business,
    int templateId = 1,
    bool showFooter = false,
  }) async {
    final bytes = await generatePdf(
      doc: doc,
      business: business,
      templateId: templateId,
      showFooter: showFooter,
    );
    final dir = await getTemporaryDirectory();
    final sanitized = doc.number.replaceAll(RegExp(r'[^\w\-]'), '_');
    final file = File('${dir.path}/$sanitized.pdf');
    await file.writeAsBytes(bytes, flush: true);
    return file.path;
  }

  // ---------------------------------------------------------------------------
  // Template 1: Classic Ledger
  // Warm cream background, ruled lines, serif headings, stamp-style status mark.
  // ---------------------------------------------------------------------------
  Future<Uint8List> _buildClassicLedger(
    DocumentModel doc,
    BusinessProfileData biz,
    _TemplateTheme t,
    bool showFooter,
  ) async {
    final pdf = pw.Document();
    final currency = doc.currencyCode;

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        theme: _buildTheme(t),
        footer: showFooter ? _footerBuilder : null,
        build: (context) => [
          // ── Header ──────────────────────────────────────────────
          _ledgerHeader(doc, biz, t, currency),
          pw.SizedBox(height: 24),
          // ── Bill To ─────────────────────────────────────────────
          _billToSection(doc, biz, t),
          pw.SizedBox(height: 20),
          // ── Line Items Table ────────────────────────────────────
          _lineItemsTable(doc, t, currency),
          pw.SizedBox(height: 16),
          // ── Totals ──────────────────────────────────────────────
          pw.Align(
            alignment: pw.Alignment.centerRight,
            child: _totalsBlock(doc, t, currency),
          ),
          pw.SizedBox(height: 20),
          // ── Payment instructions ─────────────────────────────────
          if (biz.paymentInstructions.isNotEmpty)
            _paymentInstructionsBlock(biz.paymentInstructions, t),
          pw.SizedBox(height: 16),
          // ── Notes & Terms ────────────────────────────────────────
          if (doc.notes.isNotEmpty) _notesBlock('Notes', doc.notes, t),
          if (doc.terms.isNotEmpty) _notesBlock('Terms & Conditions', doc.terms, t),
        ],
      ),
    );

    return pdf.save();
  }

  // ---------------------------------------------------------------------------
  // Template 2: Print Studio
  // Bold accent header band, clean white body, strong typography hierarchy.
  // ---------------------------------------------------------------------------
  Future<Uint8List> _buildPrintStudio(
    DocumentModel doc,
    BusinessProfileData biz,
    _TemplateTheme t,
    bool showFooter,
  ) async {
    final pdf = pw.Document();
    final currency = doc.currencyCode;

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: pw.EdgeInsets.zero,
        theme: _buildTheme(t),
        footer: showFooter ? _footerBuilder : null,
        build: (context) => [
          // ── Full-width accent header band ────────────────────────
          pw.Container(
            color: t.accent,
            padding: const pw.EdgeInsets.symmetric(horizontal: 40, vertical: 28),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      biz.name,
                      style: pw.TextStyle(
                        font: _headingFont,
                        fontSize: 22,
                        color: PdfColors.white,
                      ),
                    ),
                    if (biz.address.isNotEmpty)
                      pw.Text(biz.address,
                          style: pw.TextStyle(
                              font: _bodyFont,
                              fontSize: 9,
                              color: PdfColor.fromHex('FFEEDD'))),
                  ],
                ),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Text(
                      doc.type.toUpperCase(),
                      style: pw.TextStyle(
                          font: _bodyFontBold,
                          fontSize: 18,
                          color: PdfColors.white,
                          letterSpacing: 3),
                    ),
                    pw.Text(
                      doc.number,
                      style: pw.TextStyle(
                          font: _bodyFont,
                          fontSize: 10,
                          color: PdfColor.fromHex('FFEEDD')),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // ── Body ────────────────────────────────────────────────
          pw.Padding(
            padding: const pw.EdgeInsets.fromLTRB(40, 24, 40, 24),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                _billToSection(doc, biz, t),
                pw.SizedBox(height: 20),
                _lineItemsTable(doc, t, currency),
                pw.SizedBox(height: 16),
                pw.Align(
                  alignment: pw.Alignment.centerRight,
                  child: _totalsBlock(doc, t, currency),
                ),
                pw.SizedBox(height: 20),
                if (biz.paymentInstructions.isNotEmpty)
                  _paymentInstructionsBlock(biz.paymentInstructions, t),
                if (doc.notes.isNotEmpty) _notesBlock('Notes', doc.notes, t),
                if (doc.terms.isNotEmpty)
                  _notesBlock('Terms & Conditions', doc.terms, t),
              ],
            ),
          ),
        ],
      ),
    );

    return pdf.save();
  }

  // ---------------------------------------------------------------------------
  // Template 3: Field Receipt
  // Narrow, receipt-like, compact, great for tradespeople / mobile printing.
  // ---------------------------------------------------------------------------
  Future<Uint8List> _buildFieldReceipt(
    DocumentModel doc,
    BusinessProfileData biz,
    _TemplateTheme t,
    bool showFooter,
  ) async {
    final pdf = pw.Document();
    final currency = doc.currencyCode;
    // Narrow receipt-width format (~148mm wide, A6 landscape equivalent)
    final format = PdfPageFormat(
      PdfPageFormat.a4.width * 0.6,
      double.infinity,
      marginAll: 20,
    );

    pdf.addPage(
      pw.MultiPage(
        pageFormat: format,
        margin: const pw.EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        theme: _buildTheme(t),
        footer: showFooter ? _footerBuilder : null,
        build: (context) => [
          // ── Centred business name ────────────────────────────────
          pw.Center(
            child: pw.Text(
              biz.name,
              style: pw.TextStyle(
                font: _headingFont,
                fontSize: 18,
                color: t.inkColor,
              ),
            ),
          ),
          if (biz.phone.isNotEmpty)
            pw.Center(
              child: pw.Text(biz.phone,
                  style: pw.TextStyle(font: _bodyFont, fontSize: 8, color: t.mutedColor)),
            ),
          pw.SizedBox(height: 10),
          pw.Divider(color: t.borderColor, thickness: 0.5),
          pw.SizedBox(height: 6),
          // ── Doc info row ─────────────────────────────────────────
          _receiptInfoRow('No:', doc.number, t),
          _receiptInfoRow(
              'Date:',
              _formatDate(DateTime.fromMillisecondsSinceEpoch(doc.issueDate * 1000)),
              t),
          if (doc.clientName != null)
            _receiptInfoRow('Bill to:', doc.clientName!, t),
          pw.SizedBox(height: 8),
          pw.Divider(color: t.borderColor, thickness: 0.5),
          // ── Compact line items ───────────────────────────────────
          ...doc.lineItems.map((li) => _receiptLineItem(li, currency, t)),
          pw.Divider(color: t.borderColor, thickness: 0.5),
          pw.SizedBox(height: 4),
          // ── Totals ──────────────────────────────────────────────
          _receiptTotalsRow('Subtotal', doc.subtotalMinor, currency, t),
          if (doc.taxMinor > 0)
            _receiptTotalsRow(
                'Tax (${doc.globalTaxRateBps ~/ 100}%)', doc.taxMinor, currency, t),
          if (doc.discountMinor > 0)
            _receiptTotalsRow('Discount', -doc.discountMinor, currency, t),
          pw.SizedBox(height: 4),
          pw.Divider(color: t.borderColor, thickness: 1),
          _receiptTotalsRow('TOTAL', doc.totalMinor, currency, t, bold: true),
          if (doc.totalPaidMinor > 0) ...[
            _receiptTotalsRow('Paid', -doc.totalPaidMinor, currency, t),
            _receiptTotalsRow('Balance', doc.balanceDue, currency, t, bold: true),
          ],
          pw.SizedBox(height: 12),
          if (biz.paymentInstructions.isNotEmpty)
            _paymentInstructionsBlock(biz.paymentInstructions, t),
          if (doc.notes.isNotEmpty) ...[
            pw.SizedBox(height: 8),
            pw.Text(doc.notes,
                style: pw.TextStyle(font: _bodyFont, fontSize: 8, color: t.mutedColor)),
          ],
        ],
      ),
    );

    return pdf.save();
  }

  // ---------------------------------------------------------------------------
  // Shared PDF widget builders
  // ---------------------------------------------------------------------------

  pw.Widget _ledgerHeader(
    DocumentModel doc,
    BusinessProfileData biz,
    _TemplateTheme t,
    String currency,
  ) {
    final issueDate =
        DateTime.fromMillisecondsSinceEpoch(doc.issueDate * 1000);
    final dueDate =
        doc.dueDate != null ? DateTime.fromMillisecondsSinceEpoch(doc.dueDate! * 1000) : null;

    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        // Business info
        pw.Expanded(
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                biz.name,
                style: pw.TextStyle(
                  font: _headingFont,
                  fontSize: 20,
                  color: t.inkColor,
                ),
              ),
              pw.SizedBox(height: 4),
              if (biz.address.isNotEmpty)
                pw.Text(biz.address,
                    style: pw.TextStyle(font: _bodyFont, fontSize: 9, color: t.mutedColor)),
              if (biz.phone.isNotEmpty)
                pw.Text(biz.phone,
                    style: pw.TextStyle(font: _bodyFont, fontSize: 9, color: t.mutedColor)),
              if (biz.email.isNotEmpty)
                pw.Text(biz.email,
                    style: pw.TextStyle(font: _bodyFont, fontSize: 9, color: t.mutedColor)),
              if (biz.taxId.isNotEmpty)
                pw.Text('KRA PIN: ${biz.taxId}',
                    style: pw.TextStyle(font: _bodyFont, fontSize: 9, color: t.mutedColor)),
            ],
          ),
        ),
        // Document details
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.end,
          children: [
            pw.Text(
              doc.type == 'estimate' ? 'ESTIMATE' : 'INVOICE',
              style: pw.TextStyle(
                font: _headingFont,
                fontSize: 26,
                color: t.accent,
                letterSpacing: 2,
              ),
            ),
            pw.SizedBox(height: 4),
            _infoRowRight('No:', doc.number, t),
            _infoRowRight('Date:', _formatDate(issueDate), t),
            if (dueDate != null) _infoRowRight('Due:', _formatDate(dueDate), t),
            if (doc.derivedStatus == 'paid')
              pw.Container(
                margin: const pw.EdgeInsets.only(top: 8),
                padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: PdfColor.fromHex('1E7D45'), width: 2),
                  borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
                ),
                child: pw.Text(
                  'PAID',
                  style: pw.TextStyle(
                    font: _bodyFontBold,
                    fontSize: 13,
                    color: PdfColor.fromHex('1E7D45'),
                    letterSpacing: 3,
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }

  pw.Widget _billToSection(DocumentModel doc, BusinessProfileData biz, _TemplateTheme t) {
    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Expanded(
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text('Bill to',
                  style: pw.TextStyle(
                      font: _bodyFontBold, fontSize: 8, color: t.mutedColor,
                      letterSpacing: 1.2)),
              pw.SizedBox(height: 4),
              if (doc.clientName != null)
                pw.Text(doc.clientName!,
                    style: pw.TextStyle(font: _bodyFontBold, fontSize: 11, color: t.inkColor)),
            ],
          ),
        ),
      ],
    );
  }

  pw.Widget _lineItemsTable(DocumentModel doc, _TemplateTheme t, String currency) {
    final headerStyle = pw.TextStyle(
        font: _bodyFontBold, fontSize: 9, color: t.onAccent, letterSpacing: 0.5);
    final cellStyle = pw.TextStyle(font: _bodyFont, fontSize: 9, color: t.inkColor);
    final amountStyle = pw.TextStyle(
        font: _bodyFont, fontSize: 9, color: t.inkColor);

    return pw.Table(
      columnWidths: const {
        0: pw.FlexColumnWidth(4),
        1: pw.FixedColumnWidth(45),
        2: pw.FixedColumnWidth(65),
        3: pw.FixedColumnWidth(65),
      },
      border: pw.TableBorder(
        bottom: pw.BorderSide(color: t.borderColor, width: 0.5),
        horizontalInside: pw.BorderSide(color: t.borderColor, width: 0.3),
      ),
      children: [
        // Header row
        pw.TableRow(
          decoration: pw.BoxDecoration(color: t.accent),
          children: [
            _th('Description', headerStyle),
            _th('Qty', headerStyle, align: pw.Alignment.centerRight),
            _th('Unit Price', headerStyle, align: pw.Alignment.centerRight),
            _th('Amount', headerStyle, align: pw.Alignment.centerRight),
          ],
        ),
        // Data rows
        ...doc.lineItems.map((li) {
          final qty = li.quantityX100 / 100;
          final qtyStr = qty == qty.roundToDouble()
              ? qty.toInt().toString()
              : qty.toStringAsFixed(2);
          return pw.TableRow(
            children: [
              _td(li.description.isEmpty ? '—' : li.description, cellStyle),
              _td(qtyStr, amountStyle, align: pw.Alignment.centerRight),
              _td(CurrencyFormatter.format(li.unitPriceMinor, currency),
                  amountStyle, align: pw.Alignment.centerRight),
              _td(CurrencyFormatter.format(li.subtotalMinor, currency),
                  amountStyle, align: pw.Alignment.centerRight),
            ],
          );
        }),
      ],
    );
  }

  pw.Widget _totalsBlock(DocumentModel doc, _TemplateTheme t, String currency) {
    final labelStyle =
        pw.TextStyle(font: _bodyFont, fontSize: 9, color: t.mutedColor);
    final valueStyle = pw.TextStyle(
        font: _bodyFont, fontSize: 9, color: t.inkColor);
    final boldStyle = pw.TextStyle(
        font: _bodyFontBold, fontSize: 11, color: t.inkColor);
    final paidStyle = pw.TextStyle(
        font: _bodyFontBold, fontSize: 11, color: PdfColor.fromHex('1E7D45'));

    return pw.SizedBox(
      width: 200,
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.end,
        children: [
          _totalsLine('Subtotal', doc.subtotalMinor, currency, labelStyle, valueStyle),
          if (doc.taxMinor > 0)
            _totalsLine(
              'VAT ${doc.globalTaxRateBps ~/ 100}%',
              doc.taxMinor,
              currency,
              labelStyle,
              valueStyle,
            ),
          if (doc.discountMinor > 0)
            _totalsLine('Discount', -doc.discountMinor, currency, labelStyle, valueStyle),
          pw.SizedBox(height: 4),
          pw.Divider(color: t.borderColor, thickness: 0.5),
          pw.SizedBox(height: 4),
          _totalsLine('Total', doc.totalMinor, currency, boldStyle, boldStyle),
          if (doc.totalPaidMinor > 0) ...[
            pw.SizedBox(height: 4),
            _totalsLine('Paid', -doc.totalPaidMinor, currency, labelStyle, paidStyle),
            pw.Divider(color: t.borderColor, thickness: 0.3),
            _totalsLine('Balance Due', doc.balanceDue, currency, boldStyle,
                pw.TextStyle(
                    font: _bodyFontBold,
                    fontSize: 11,
                    color: doc.balanceDue > 0
                        ? PdfColor.fromHex('C0392B')
                        : PdfColor.fromHex('1E7D45'))),
          ],
        ],
      ),
    );
  }

  pw.Widget _paymentInstructionsBlock(String instructions, _TemplateTheme t) {
    // instructions is a formatted string (JSON decoded in business profile screen)
    return pw.Container(
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: t.borderColor, width: 0.5),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
        color: PdfColor.fromHex('F8F4ED'),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text('Payment Instructions',
              style: pw.TextStyle(
                  font: _bodyFontBold,
                  fontSize: 9,
                  color: t.accent,
                  letterSpacing: 0.8)),
          pw.SizedBox(height: 6),
          pw.Text(instructions,
              style: pw.TextStyle(font: _bodyFont, fontSize: 9, color: t.inkColor)),
        ],
      ),
    );
  }

  pw.Widget _notesBlock(String label, String content, _TemplateTheme t) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.SizedBox(height: 12),
        pw.Text(label,
            style: pw.TextStyle(
                font: _bodyFontBold,
                fontSize: 8,
                color: t.mutedColor,
                letterSpacing: 1)),
        pw.SizedBox(height: 4),
        pw.Text(content,
            style: pw.TextStyle(font: _bodyFont, fontSize: 9, color: t.inkColor)),
      ],
    );
  }

  // Receipt-specific helpers
  pw.Widget _receiptInfoRow(String label, String value, _TemplateTheme t) {
    return pw.Row(
      children: [
        pw.SizedBox(
            width: 50,
            child: pw.Text(label,
                style:
                    pw.TextStyle(font: _bodyFont, fontSize: 8, color: t.mutedColor))),
        pw.Expanded(
          child: pw.Text(value,
              style: pw.TextStyle(font: _bodyFontBold, fontSize: 8, color: t.inkColor)),
        ),
      ],
    );
  }

  pw.Widget _receiptLineItem(LineItemModel li, String currency, _TemplateTheme t) {
    final qty = li.quantityX100 / 100;
    final qtyStr = qty == qty.roundToDouble()
        ? qty.toInt().toString()
        : qty.toStringAsFixed(2);
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 2),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Row(
            children: [
              pw.Expanded(
                child: pw.Text(
                    li.description.isEmpty ? '—' : li.description,
                    style: pw.TextStyle(font: _bodyFont, fontSize: 8, color: t.inkColor)),
              ),
              pw.Text(CurrencyFormatter.format(li.subtotalMinor, currency),
                  style: pw.TextStyle(font: _bodyFontBold, fontSize: 8, color: t.inkColor)),
            ],
          ),
          pw.Text('$qtyStr × ${CurrencyFormatter.format(li.unitPriceMinor, currency)}',
              style: pw.TextStyle(font: _bodyFont, fontSize: 7, color: t.mutedColor)),
        ],
      ),
    );
  }

  pw.Widget _receiptTotalsRow(
      String label, int amount, String currency, _TemplateTheme t,
      {bool bold = false}) {
    final style = bold
        ? pw.TextStyle(font: _bodyFontBold, fontSize: 9, color: t.inkColor)
        : pw.TextStyle(font: _bodyFont, fontSize: 8, color: t.mutedColor);
    final amtStr = amount < 0
        ? '−${CurrencyFormatter.format(-amount, currency)}'
        : CurrencyFormatter.format(amount, currency);
    return pw.Row(
      children: [
        pw.Expanded(child: pw.Text(label, style: style)),
        pw.Text(amtStr, style: style),
      ],
    );
  }

  // Utility widget builders
  pw.Widget _th(String text, pw.TextStyle style,
      {pw.Alignment align = pw.Alignment.centerLeft}) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 5),
      alignment: align,
      child: pw.Text(text, style: style),
    );
  }

  pw.Widget _td(String text, pw.TextStyle style,
      {pw.Alignment align = pw.Alignment.centerLeft}) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 5),
      alignment: align,
      child: pw.Text(text, style: style),
    );
  }

  pw.Widget _totalsLine(
      String label, int amount, String currency, pw.TextStyle labelStyle, pw.TextStyle valueStyle) {
    final amtStr = amount < 0
        ? '−${CurrencyFormatter.format(-amount, currency)}'
        : CurrencyFormatter.format(amount, currency);
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 2),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(label, style: labelStyle),
          pw.SizedBox(width: 16),
          pw.Text(amtStr, style: valueStyle),
        ],
      ),
    );
  }

  pw.Widget _infoRowRight(String label, String value, _TemplateTheme t) {
    return pw.Row(
      mainAxisSize: pw.MainAxisSize.min,
      children: [
        pw.Text('$label ',
            style: pw.TextStyle(font: _bodyFont, fontSize: 9, color: t.mutedColor)),
        pw.Text(value,
            style: pw.TextStyle(font: _bodyFontBold, fontSize: 9, color: t.inkColor)),
      ],
    );
  }

  pw.Widget Function(pw.Context) get _footerBuilder => (context) {
        return pw.Align(
          alignment: pw.Alignment.bottomCenter,
          child: pw.Text(
            'Made with Pencraft',
            style: pw.TextStyle(
              font: _bodyFont,
              fontSize: 7,
              color: PdfColor.fromHex('B0A090'),
            ),
          ),
        );
      };

  // ---------------------------------------------------------------------------
  // Theme
  // ---------------------------------------------------------------------------
  _TemplateTheme _templateTheme(int id, String? accentHex) {
    final accentColor = accentHex != null && accentHex.isNotEmpty
        ? PdfColor.fromHex(accentHex.replaceAll('#', ''))
        : PdfColor.fromHex('C0392B');

    return _TemplateTheme(
      accent: accentColor,
      inkColor: PdfColor.fromHex('1A1410'),
      mutedColor: PdfColor.fromHex('6B5E4E'),
      borderColor: PdfColor.fromHex('D4C9B8'),
      surfaceColor: id == 1 ? PdfColor.fromHex('FAF7F2') : PdfColors.white,
      onAccent: PdfColors.white,
    );
  }

  pw.ThemeData _buildTheme(_TemplateTheme t) {
    return pw.ThemeData.withFont(
      base: _bodyFont!,
      bold: _bodyFontBold!,
    );
  }

  String _formatDate(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
}

class _TemplateTheme {
  const _TemplateTheme({
    required this.accent,
    required this.inkColor,
    required this.mutedColor,
    required this.borderColor,
    required this.surfaceColor,
    required this.onAccent,
  });

  final PdfColor accent;
  final PdfColor inkColor;
  final PdfColor mutedColor;
  final PdfColor borderColor;
  final PdfColor surfaceColor;
  final PdfColor onAccent;
}
