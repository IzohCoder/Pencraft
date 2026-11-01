import 'package:flutter/material.dart';
import '../../../core/design/tokens.dart';
import '../../../core/currency_formatter.dart';
import '../../../data/models/document_model.dart';

/// Live paper preview card — sits below the document form in the creator
/// and updates as the user types. Tapping opens the full PDF preview.
///
/// Looks like a real sheet of paper with subtle depth (3-layer shadow).
class InvoicePreviewCard extends StatelessWidget {
  const InvoicePreviewCard({
    super.key,
    required this.doc,
    required this.businessName,
    required this.onTap,
  });

  final DocumentModel doc;
  final String businessName;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final currency = doc.currencyCode;

    // Paper colours — always warm/cream to evoke real paper
    final paperColor = isDark ? const Color(0xFFF5F0E8) : const Color(0xFFFAF7F2);
    final inkColor = const Color(0xFF1A1410);
    final mutedColor = const Color(0xFF6B5E4E);
    final accentColor = const Color(0xFFC0392B);
    final borderColor = const Color(0xFFD4C9B8);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: Spacing.md, vertical: Spacing.sm),
        child: Stack(
          children: [
            // Shadow layer 3 (deepest) — slightly larger, more offset
            _shadowSheet(offsetY: 6, width: null, color: const Color(0x14000000)),
            // Shadow layer 2
            _shadowSheet(offsetY: 3, width: null, color: const Color(0x1A000000)),
            // The paper itself
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: paperColor,
                borderRadius: Radii.cardBR,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.12),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
                border: Border.all(color: borderColor, width: 0.5),
              ),
              padding: const EdgeInsets.all(Spacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header row
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              businessName.isEmpty ? 'Your Business' : businessName,
                              style: TextStyle(
                                fontFamily: 'DMSerifDisplay',
                                fontSize: 13,
                                color: inkColor,
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            doc.type == 'estimate' ? 'ESTIMATE' : 'INVOICE',
                            style: TextStyle(
                              fontFamily: 'DMSerifDisplay',
                              fontSize: 11,
                              color: accentColor,
                              letterSpacing: 1.5,
                            ),
                          ),
                          Text(
                            doc.number,
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 9,
                              color: mutedColor,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),

                  const SizedBox(height: 8),
                  Divider(color: borderColor, height: 1, thickness: 0.5),
                  const SizedBox(height: 8),

                  // Bill to
                  if (doc.clientName != null) ...[
                    Text(
                      'Bill to',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 7,
                        color: mutedColor,
                        letterSpacing: 0.8,
                      ),
                    ),
                    Text(
                      doc.clientName!,
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 9,
                        color: inkColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],

                  // Line items preview (up to 5)
                  if (doc.lineItems.isNotEmpty) ...[
                    // Mini column headers
                    Row(
                      children: [
                        Expanded(
                          child: Text('Description',
                              style: TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: 7,
                                  color: mutedColor,
                                  letterSpacing: 0.6)),
                        ),
                        Text('Amount',
                            style: TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 7,
                                color: mutedColor,
                                letterSpacing: 0.6)),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Divider(color: borderColor, height: 1, thickness: 0.3),
                    ...doc.lineItems.take(5).map((li) => Padding(
                          padding: const EdgeInsets.symmetric(vertical: 2),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  li.description.isEmpty ? '(item)' : li.description,
                                  style: TextStyle(
                                      fontFamily: 'Inter',
                                      fontSize: 8,
                                      color: inkColor),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              Text(
                                CurrencyFormatter.format(li.subtotalMinor, currency),
                                style: TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: 8,
                                  color: inkColor,
                                  fontFeatures: const [FontFeature.tabularFigures()],
                                ),
                              ),
                            ],
                          ),
                        )),
                    if (doc.lineItems.length > 5)
                      Text(
                        '+${doc.lineItems.length - 5} more items',
                        style: TextStyle(
                            fontFamily: 'Inter', fontSize: 7, color: mutedColor),
                      ),
                    Divider(color: borderColor, height: 8, thickness: 0.5),
                  ],

                  // Totals
                  _PreviewTotalsRow(
                    label: 'Subtotal',
                    amount: doc.subtotalMinor,
                    currency: currency,
                    inkColor: inkColor,
                    mutedColor: mutedColor,
                    bold: false,
                  ),
                  if (doc.taxMinor > 0)
                    _PreviewTotalsRow(
                      label: 'Tax (${doc.globalTaxRateBps ~/ 100}%)',
                      amount: doc.taxMinor,
                      currency: currency,
                      inkColor: inkColor,
                      mutedColor: mutedColor,
                      bold: false,
                    ),
                  if (doc.discountMinor > 0)
                    _PreviewTotalsRow(
                      label: 'Discount',
                      amount: -doc.discountMinor,
                      currency: currency,
                      inkColor: inkColor,
                      mutedColor: mutedColor,
                      bold: false,
                    ),
                  Divider(color: borderColor, height: 8, thickness: 0.5),
                  _PreviewTotalsRow(
                    label: 'TOTAL',
                    amount: doc.totalMinor,
                    currency: currency,
                    inkColor: inkColor,
                    mutedColor: mutedColor,
                    bold: true,
                    accentColor: accentColor,
                  ),

                  const SizedBox(height: 10),

                  // Tap to preview hint
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.touch_app_outlined, size: 10, color: mutedColor),
                      const SizedBox(width: 4),
                      Text(
                        'Tap to preview full invoice',
                        style: TextStyle(
                            fontFamily: 'Inter', fontSize: 8, color: mutedColor),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _shadowSheet({double offsetY = 4, double? width, required Color color}) {
    return Positioned(
      left: 4,
      right: 4,
      top: offsetY,
      child: Container(
        height: 100,
        decoration: BoxDecoration(
          color: color,
          borderRadius: Radii.cardBR,
        ),
      ),
    );
  }
}

class _PreviewTotalsRow extends StatelessWidget {
  const _PreviewTotalsRow({
    required this.label,
    required this.amount,
    required this.currency,
    required this.inkColor,
    required this.mutedColor,
    required this.bold,
    this.accentColor,
  });

  final String label;
  final int amount;
  final String currency;
  final Color inkColor;
  final Color mutedColor;
  final bool bold;
  final Color? accentColor;

  @override
  Widget build(BuildContext context) {
    final textColor = bold ? (accentColor ?? inkColor) : mutedColor;
    final amtStr = amount < 0
        ? '−${CurrencyFormatter.format(-amount, currency)}'
        : CurrencyFormatter.format(amount, currency);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 1),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: bold ? 9 : 8,
                color: textColor,
                fontWeight: bold ? FontWeight.w700 : FontWeight.w400,
              ),
            ),
          ),
          Text(
            amtStr,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: bold ? 9 : 8,
              color: textColor,
              fontWeight: bold ? FontWeight.w700 : FontWeight.w400,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }
}
