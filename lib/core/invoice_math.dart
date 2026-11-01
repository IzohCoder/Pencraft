import 'dart:math' as math;

/// All money math for Pencraft.
/// Money is ALWAYS stored as integer minor units.
/// KES uses 2 decimal places (minor unit = 1 cent).
/// Rates are in basis points (bps): 16% = 1600 bps.
/// Quantities are stored ×100: 1.5 qty = 150.
abstract final class InvoiceMath {
  // ---------------------------------------------------------------------------
  // Line item calculations
  // ---------------------------------------------------------------------------

  /// Line item subtotal (before tax, before discount).
  /// quantityX100: quantity stored ×100
  /// unitPriceMinor: price per unit in minor units
  static int lineSubtotal({
    required int quantityX100,
    required int unitPriceMinor,
  }) {
    // (qty/100) * price, rounded to nearest minor unit
    return _round(quantityX100 * unitPriceMinor / 100);
  }

  // ---------------------------------------------------------------------------
  // Document-level calculations
  // ---------------------------------------------------------------------------

  /// Sum all line subtotals.
  static int subtotal(List<int> lineSubtotals) =>
      lineSubtotals.fold(0, (a, b) => a + b);

  /// Tax-exclusive: tax is added on top of the subtotal.
  /// taxRateBps: e.g. 1600 for 16%
  static int taxExclusive({
    required int subtotalMinor,
    required int taxRateBps,
  }) {
    return _round(subtotalMinor * taxRateBps / 10000);
  }

  /// Tax-inclusive: price already includes tax; extract tax amount.
  static int taxInclusive({
    required int priceIncludingTaxMinor,
    required int taxRateBps,
  }) {
    // tax = price_incl - price_excl
    // price_excl = price_incl * 10000 / (10000 + taxRateBps)
    final priceExcl =
        _round(priceIncludingTaxMinor * 10000 / (10000 + taxRateBps));
    return priceIncludingTaxMinor - priceExcl;
  }

  /// Subtotal excluding tax (from an inclusive price).
  static int subtotalFromInclusive({
    required int priceIncludingTaxMinor,
    required int taxRateBps,
  }) {
    return _round(priceIncludingTaxMinor * 10000 / (10000 + taxRateBps));
  }

  /// Discount amount.
  /// discountMode: 0 = percent (bps), 1 = flat minor units
  static int discountAmount({
    required int subtotalMinor,
    required int discountMode,
    required int discountValue,
  }) {
    if (discountValue <= 0) return 0;
    if (discountMode == 0) {
      // percent in bps
      return _round(subtotalMinor * discountValue / 10000);
    } else {
      // flat — capped at subtotal
      return math.min(discountValue, subtotalMinor);
    }
  }

  /// Final document total.
  static int total({
    required int subtotalMinor,
    required int taxMinor,
    required int discountMinor,
  }) {
    return math.max(0, subtotalMinor + taxMinor - discountMinor);
  }

  /// Balance due (total minus all recorded payments).
  static int balanceDue({
    required int totalMinor,
    required List<int> paymentAmounts,
  }) {
    final paid = paymentAmounts.fold(0, (a, b) => a + b);
    return math.max(0, totalMinor - paid);
  }

  /// Derived document status.
  /// statusOverride: null | 'draft' | 'sent' | 'paid' | 'void'
  static String derivedStatus({
    required String? statusOverride,
    required int totalMinor,
    required List<int> paymentAmounts,
    required int? dueDateEpoch,
  }) {
    if (statusOverride == 'paid') return 'paid';
    if (statusOverride == 'void') return 'void';
    if (statusOverride == 'draft') return 'draft';

    final balance = balanceDue(totalMinor: totalMinor, paymentAmounts: paymentAmounts);
    if (balance <= 0) return 'paid';

    // Check overdue
    if (dueDateEpoch != null) {
      final due = DateTime.fromMillisecondsSinceEpoch(dueDateEpoch * 1000);
      if (DateTime.now().isAfter(due)) return 'overdue';
    }

    // Sent (or draft if override says so)
    return statusOverride ?? 'sent';
  }

  // ---------------------------------------------------------------------------
  // Formatting helpers
  // ---------------------------------------------------------------------------

  /// Convert minor units to display double.
  static double toDisplay(int minorUnits, {int decimalPlaces = 2}) {
    return minorUnits / math.pow(10, decimalPlaces);
  }

  // ---------------------------------------------------------------------------
  // Internal
  // ---------------------------------------------------------------------------

  /// Standard commercial rounding (half-up).
  static int _round(double value) => (value + 0.5).floor();
}
