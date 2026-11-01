import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:printing/printing.dart';
import '../../../data/models/document_model.dart';
import '../../../services/pdf_service.dart';
import '../../../services/whatsapp_service.dart';
import '../../../services/settings_service.dart';
import '../../../config/app_config.dart';
import '../../../features/settings/providers/business_profile_providers.dart';
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
      final business = _getBusiness();
      final showFooter = _showFooter();
      await WhatsAppService.instance.shareDocument(
        doc: doc,
        business: business,
        templateId: doc.templateId,
        showFooter: showFooter,
      );
    } finally {
      if (mounted) setState(() => _sharing = false);
    }
  }

  Future<void> _shareGeneric(DocumentModel doc) async {
    if (_sharing) return;
    setState(() => _sharing = true);
    try {
      final business = _getBusiness();
      final showFooter = _showFooter();
      await WhatsAppService.instance.sharePdfOnly(
        doc: doc,
        business: business,
        templateId: doc.templateId,
        showFooter: showFooter,
      );
    } finally {
      if (mounted) setState(() => _sharing = false);
    }
  }

  Future<void> _print(DocumentModel doc) async {
    final business = _getBusiness();
    final showFooter = _showFooter();
    final bytes = await PdfService.instance.generatePdf(
      doc: doc,
      business: business,
      templateId: doc.templateId,
      showFooter: showFooter,
    );
    await Printing.layoutPdf(onLayout: (_) async => bytes);
  }

  /// Returns true when the "Made with Pencraft" footer should be shown
  /// (free tier only).
  bool _showFooter() {
    if (!enablePaywall) return false;
    final settings = ref.read(settingsProvider).valueOrNull;
    return settings?.isProMock != true;
  }

  /// Load business profile from DB, fall back to stub if not yet set.
  BusinessProfileData _getBusiness() {
    final profile = ref.read(businessProfileProvider).valueOrNull;
    if (profile == null) {
      return const BusinessProfileData(name: 'My Business', paymentInstructions: '');
    }
    return BusinessProfileData(
      name: profile.name,
      ownerName: profile.ownerName,
      address: profile.address,
      phone: profile.phone,
      email: profile.email,
      taxId: profile.taxId,
      logoPath: profile.logoPath,
      signaturePath: profile.signaturePath,
      paymentInstructions: profile.paymentInstructions,
      defaultNotes: profile.defaultNotes,
      defaultTerms: profile.defaultTerms,
    );
  }
}

/// PDF viewer widget using the `printing` package's PdfPreview.
class _PdfViewer extends ConsumerWidget {
  const _PdfViewer({required this.doc});

  final DocumentModel doc;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(businessProfileProvider);
    final settings = ref.watch(settingsProvider).valueOrNull;
    final isPro = settings?.isProMock == true;
    final showFooter = enablePaywall && !isPro;

    final business = profileAsync.when(
      data: (profile) => profile == null
          ? const BusinessProfileData(name: 'My Business', paymentInstructions: '')
          : BusinessProfileData(
              name: profile.name,
              ownerName: profile.ownerName,
              address: profile.address,
              phone: profile.phone,
              email: profile.email,
              taxId: profile.taxId,
              logoPath: profile.logoPath,
              signaturePath: profile.signaturePath,
              paymentInstructions: profile.paymentInstructions,
              defaultNotes: profile.defaultNotes,
              defaultTerms: profile.defaultTerms,
            ),
      loading: () => const BusinessProfileData(name: 'My Business', paymentInstructions: ''),
      error: (_, __) => const BusinessProfileData(name: 'My Business', paymentInstructions: ''),
    );

    return PdfPreview(
      build: (_) => PdfService.instance.generatePdf(
        doc: doc,
        business: business,
        templateId: doc.templateId,
        showFooter: showFooter,
      ),
      allowPrinting: false,  // handled by AppBar button
      allowSharing: false,   // handled by AppBar button
      canChangePageFormat: false,
      canChangeOrientation: false,
      pdfFileName: '${doc.number}.pdf',
      scrollViewDecoration: const BoxDecoration(color: Color(0xFF2A2520)),
      previewPageMargin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    );
  }
}
