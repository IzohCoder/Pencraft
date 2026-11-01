import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:printing/printing.dart';
import '../../../data/models/document_model.dart';
import '../../../services/pdf_service.dart';
import '../../../services/whatsapp_service.dart';
import '../providers/document_providers.dart';

/// Full-screen PDF preview — feels like handling real paper.
/// Shows the rendered PDF with share/print/WhatsApp actions.
class PdfPreviewScreen extends ConsumerStatefulWidget {
  const PdfPreviewScreen({super.key, required this.documentId});

  final int documentId;

  @override
  ConsumerState<PdfPreviewScreen> createState() => _PdfPreviewScreenState();
}

class _PdfPreviewScreenState extends ConsumerState<PdfPreviewScreen> {
  bool _sharing = false;

  @override
  Widget build(BuildContext context) {
    final docAsync = ref.watch(documentDetailProvider(widget.documentId));

    return Scaffold(
      backgroundColor: const Color(0xFF2A2520), // dark paper-holder bg
      appBar: AppBar(
        backgroundColor: const Color(0xFF1C1914),
        foregroundColor: Colors.white,
        title: docAsync.when(
          data: (doc) => Text(doc?.number ?? 'Preview',
              style: const TextStyle(color: Colors.white)),
          loading: () => const Text('Preview', style: TextStyle(color: Colors.white)),
          error: (_, __) => const Text('Preview', style: TextStyle(color: Colors.white)),
        ),
        actions: [
          docAsync.when(
            data: (doc) => doc != null
                ? Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.print_outlined, color: Colors.white70),
                        tooltip: 'Print',
                        onPressed: () => _print(doc),
                      ),
                      IconButton(
                        icon: const Icon(Icons.share_outlined, color: Colors.white70),
                        tooltip: 'Share PDF',
                        onPressed: _sharing ? null : () => _shareGeneric(doc),
                      ),
                      IconButton(
                        icon: const Icon(Icons.send_outlined, color: Color(0xFF64DD17)),
                        tooltip: 'Send via WhatsApp',
                        onPressed: _sharing ? null : () => _shareWhatsApp(doc),
                      ),
                    ],
                  )
                : const SizedBox.shrink(),
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
          ),
        ],
      ),
      body: docAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: Color(0xFFC0392B)),
        ),
        error: (e, _) => Center(
          child: Text('Error: $e', style: const TextStyle(color: Colors.white70)),
        ),
        data: (doc) {
          if (doc == null) {
            return const Center(
              child: Text('Document not found',
                  style: TextStyle(color: Colors.white70)),
            );
          }
          return _PdfViewer(doc: doc);
        },
      ),
    );
  }

  Future<void> _shareWhatsApp(DocumentModel doc) async {
    if (_sharing) return;
    setState(() => _sharing = true);
    try {
      await WhatsAppService.instance.shareDocument(
        doc: doc,
        business: _stubBusiness(), // TODO(m3): load from DB
        templateId: doc.templateId,
        showFooter: false, // TODO(m3): check free tier
      );
    } finally {
      if (mounted) setState(() => _sharing = false);
    }
  }

  Future<void> _shareGeneric(DocumentModel doc) async {
    if (_sharing) return;
    setState(() => _sharing = true);
    try {
      await WhatsAppService.instance.sharePdfOnly(
        doc: doc,
        business: _stubBusiness(),
        templateId: doc.templateId,
        showFooter: false,
      );
    } finally {
      if (mounted) setState(() => _sharing = false);
    }
  }

  Future<void> _print(DocumentModel doc) async {
    final bytes = await PdfService.instance.generatePdf(
      doc: doc,
      business: _stubBusiness(),
      templateId: doc.templateId,
      showFooter: false,
    );
    await Printing.layoutPdf(onLayout: (_) async => bytes);
  }

  /// Stub business profile until M3 wires the DB provider.
  BusinessProfileData _stubBusiness() {
    return const BusinessProfileData(
      name: 'My Business',
      paymentInstructions: '',
    );
  }
}

/// PDF viewer widget using the `printing` package's PdfPreview.
class _PdfViewer extends StatefulWidget {
  const _PdfViewer({required this.doc});

  final DocumentModel doc;

  @override
  State<_PdfViewer> createState() => _PdfViewerState();
}

class _PdfViewerState extends State<_PdfViewer> {
  @override
  Widget build(BuildContext context) {
    return PdfPreview(
      build: (_) => PdfService.instance.generatePdf(
        doc: widget.doc,
        business: const BusinessProfileData(
          name: 'My Business',
          paymentInstructions: '',
        ),
        templateId: widget.doc.templateId,
        showFooter: false,
      ),
      allowPrinting: false,  // handled by AppBar button
      allowSharing: false,   // handled by AppBar button
      canChangePageFormat: false,
      canChangeOrientation: false,
      pdfFileName: '${widget.doc.number}.pdf',
      scrollViewDecoration: const BoxDecoration(color: Color(0xFF2A2520)),
      previewPageMargin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    );
  }
}
