import 'package:share_plus/share_plus.dart';
import '../data/models/document_model.dart';
import '../core/currency_formatter.dart';
import 'pdf_service.dart';

/// WhatsApp sharing service.
/// Generates a PDF, saves to temp, then triggers a share sheet pre-filled
/// with a warm, human message. On Android this will offer WhatsApp directly
/// in the share sheet; on most devices with WhatsApp installed, it rises to top.
class WhatsAppService {
  static WhatsAppService? _instance;
  static WhatsAppService get instance => _instance ??= WhatsAppService._();
  WhatsAppService._();

  /// Share a document as PDF, with a pre-written message.
  /// [business] is the business profile data.
  /// [templateId] is the PDF template (1–3).
  /// [showFooter] should be true for free-tier users.
  Future<void> shareDocument({
    required DocumentModel doc,
    required BusinessProfileData business,
    int templateId = 1,
    bool showFooter = false,
  }) async {
    // 1. Generate and save PDF
    final pdfPath = await PdfService.instance.savePdfToTemp(
      doc: doc,
      business: business,
      templateId: templateId,
      showFooter: showFooter,
    );

    // 2. Build pre-written message
    final message = _buildMessage(doc, business);

    // 3. Share — on Android this opens the share sheet; WhatsApp is usually prominent
    final file = XFile(pdfPath, mimeType: 'application/pdf');
    await Share.shareXFiles(
      [file],
      text: message,
      subject: _subject(doc, business),
    );
  }

  /// Share PDF only (no pre-written text) — for generic share actions.
  Future<void> sharePdfOnly({
    required DocumentModel doc,
    required BusinessProfileData business,
    int templateId = 1,
    bool showFooter = false,
  }) async {
    final pdfPath = await PdfService.instance.savePdfToTemp(
      doc: doc,
      business: business,
      templateId: templateId,
      showFooter: showFooter,
    );
    final file = XFile(pdfPath, mimeType: 'application/pdf');
    await Share.shareXFiles(
      [file],
      subject: _subject(doc, business),
    );
  }

  String _subject(DocumentModel doc, BusinessProfileData biz) {
    final label = doc.type == 'estimate' ? 'Estimate' : 'Invoice';
    return '$label ${doc.number} from ${biz.name}';
  }

  String _buildMessage(DocumentModel doc, BusinessProfileData biz) {
    final isEstimate = doc.type == 'estimate';
    final label = isEstimate ? 'estimate' : 'invoice';
    final total = CurrencyFormatter.format(doc.totalMinor, doc.currencyCode);
    final clientName = doc.clientName ?? 'there';

    final buffer = StringBuffer();
    buffer.writeln('Hi $clientName 👋');
    buffer.writeln();

    if (isEstimate) {
      buffer.writeln(
          'Please find attached your estimate ${doc.number} from ${biz.name}.');
      buffer.writeln();
      buffer.writeln('Estimate total: *$total*');
    } else {
      buffer.writeln(
          'Please find attached your invoice ${doc.number} from ${biz.name}.');
      buffer.writeln();
      buffer.writeln('Amount due: *$total*');
      if (doc.dueDate != null) {
        final due =
            DateTime.fromMillisecondsSinceEpoch(doc.dueDate! * 1000);
        buffer.writeln(
            'Due date: ${due.day}/${due.month}/${due.year}');
      }
    }

    // Add payment instructions hint if available
    if (biz.paymentInstructions.isNotEmpty) {
      buffer.writeln();
      buffer.writeln('Payment details are included in the $label.');
    }

    buffer.writeln();
    buffer.writeln('Thank you for your business! 🙏');
    buffer.writeln();
    buffer.write('– ${biz.name}');

    return buffer.toString();
  }
}
