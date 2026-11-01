import '../../core/invoice_math.dart';

/// A read model for a document with computed fields.
/// Populated by the repository from a Drift join query.
class DocumentModel {
  const DocumentModel({
    required this.id,
    required this.type,
    required this.number,
    required this.clientId,
    required this.clientName,
    required this.currencyCode,
    required this.taxMode,
    required this.discountMode,
    required this.discountValue,
    required this.globalTaxRateBps,
    required this.depositMinor,
    required this.statusOverride,
    required this.issueDate,
    required this.dueDate,
    required this.notes,
    required this.terms,
    required this.templateId,
    required this.accentColour,
    required this.createdAt,
    required this.updatedAt,
    required this.lineItems,
    required this.payments,
  });

  final int id;
  final String type;
  final String number;
  final int? clientId;
  final String? clientName;
  final String currencyCode;
  final int taxMode; // 0=exclusive 1=inclusive
  final int discountMode; // 0=percent 1=flat
  final int discountValue;
  final int globalTaxRateBps;
  final int depositMinor;
  final String? statusOverride;
  final int issueDate;
  final int? dueDate;
  final String notes;
  final String terms;
  final int templateId;
  final String? accentColour;
  final int createdAt;
  final int updatedAt;
  final List<LineItemModel> lineItems;
  final List<PaymentModel> payments;

  // ---------------------------------------------------------------------------
  // Computed properties
  // ---------------------------------------------------------------------------

  int get subtotalMinor {
    return InvoiceMath.subtotal(
      lineItems.map((li) => InvoiceMath.lineSubtotal(
        quantityX100: li.quantityX100,
        unitPriceMinor: li.unitPriceMinor,
      )).toList(),
    );
  }

  int get taxMinor {
    if (taxMode == 1) {
      // inclusive
      return InvoiceMath.taxInclusive(
          priceIncludingTaxMinor: subtotalMinor, taxRateBps: globalTaxRateBps);
    }
    return InvoiceMath.taxExclusive(
        subtotalMinor: subtotalMinor, taxRateBps: globalTaxRateBps);
  }

  int get discountMinor => InvoiceMath.discountAmount(
        subtotalMinor: subtotalMinor,
        discountMode: discountMode,
        discountValue: discountValue,
      );

  int get totalMinor => InvoiceMath.total(
        subtotalMinor: subtotalMinor,
        taxMinor: taxMinor,
        discountMinor: discountMinor,
      );

  int get balanceDue => InvoiceMath.balanceDue(
        totalMinor: totalMinor,
        paymentAmounts: payments.map((p) => p.amountMinor).toList(),
      );

  int get totalPaidMinor =>
      payments.fold(0, (sum, p) => sum + p.amountMinor);

  String get derivedStatus => InvoiceMath.derivedStatus(
        statusOverride: statusOverride,
        totalMinor: totalMinor,
        paymentAmounts: payments.map((p) => p.amountMinor).toList(),
        dueDateEpoch: dueDate,
      );
}

class LineItemModel {
  const LineItemModel({
    required this.id,
    required this.documentId,
    this.itemId,
    required this.description,
    required this.unit,
    required this.quantityX100,
    required this.unitPriceMinor,
    this.taxRateBps,
    required this.sortOrder,
  });

  final int id;
  final int documentId;
  final int? itemId;
  final String description;
  final String unit;
  final int quantityX100;
  final int unitPriceMinor;
  final int? taxRateBps;
  final int sortOrder;

  int get subtotalMinor => InvoiceMath.lineSubtotal(
      quantityX100: quantityX100, unitPriceMinor: unitPriceMinor);
}

class PaymentModel {
  const PaymentModel({
    required this.id,
    required this.documentId,
    required this.amountMinor,
    required this.paymentDate,
    required this.method,
    required this.reference,
    required this.notes,
  });

  final int id;
  final int documentId;
  final int amountMinor;
  final int paymentDate;
  final String method;
  final String reference;
  final String notes;
}
