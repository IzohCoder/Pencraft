import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../data/models/document_model.dart';
import '../core/currency_formatter.dart';

/// CSV export service — exports all documents and line items.
/// Pro feature only.
class CsvExportService {

  Future<String?> exportDocumentsCsv(List<DocumentModel> docs) async {
    try {
      final buf = StringBuffer();
      // Header
      buf.writeln(
          'Document Number,Type,Client,Currency,Issue Date,Due Date,Status,'
          'Subtotal,Tax,Discount,Total,Paid,Balance');

      for (final doc in docs) {
        final issued = DateTime.fromMillisecondsSinceEpoch(doc.issueDate * 1000);
        final due = doc.dueDate != null
            ? DateTime.fromMillisecondsSinceEpoch(doc.dueDate! * 1000)
            : null;
        final currency = doc.currencyCode;
        buf.writeln([
          _q(doc.number),
          _q(doc.type),
          _q(doc.clientName ?? ''),
          _q(currency),
          _q('${issued.day}/${issued.month}/${issued.year}'),
          _q(due != null ? '${due.day}/${due.month}/${due.year}' : ''),
          _q(doc.derivedStatus),
          _q(CurrencyFormatter.formatAmount(doc.subtotalMinor, currency)),
          _q(CurrencyFormatter.formatAmount(doc.taxMinor, currency)),
          _q(CurrencyFormatter.formatAmount(doc.discountMinor, currency)),
          _q(CurrencyFormatter.formatAmount(doc.totalMinor, currency)),
          _q(CurrencyFormatter.formatAmount(doc.totalPaidMinor, currency)),
          _q(CurrencyFormatter.formatAmount(doc.balanceDue, currency)),
        ].join(','));
      }

      final dir = await getApplicationDocumentsDirectory();
      final timestamp =
          DateTime.now().toIso8601String().replaceAll(':', '-').substring(0, 19);
      final file = File('${dir.path}/pencraft_invoices_$timestamp.csv');
      await file.writeAsString(buf.toString());
      return file.path;
    } catch (_) {
      return null;
    }
  }

  Future<void> shareAsCsv(List<DocumentModel> docs) async {
    final path = await exportDocumentsCsv(docs);
    if (path == null) return;
    final xFile = XFile(path, mimeType: 'text/csv');
    await Share.shareXFiles([xFile], subject: 'Pencraft — Invoice Export');
  }

  String _q(String s) =>
      '"${s.replaceAll('"', '""')}"'; // CSV-quote the value
}
