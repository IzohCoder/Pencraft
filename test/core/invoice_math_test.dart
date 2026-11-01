import 'package:flutter_test/flutter_test.dart';
import 'package:pencraft/core/invoice_math.dart';
import 'package:pencraft/core/document_numbering.dart';
import 'package:pencraft/core/currency_formatter.dart';

void main() {
  // ---------------------------------------------------------------------------
  // InvoiceMath tests
  // ---------------------------------------------------------------------------
  group('InvoiceMath', () {
    group('lineSubtotal', () {
      test('whole quantity and price', () {
        // 2 units × KES 1,500.00 = KES 3,000.00
        expect(
          InvoiceMath.lineSubtotal(quantityX100: 200, unitPriceMinor: 150000),
          equals(300000),
        );
      });

      test('fractional quantity', () {
        // 1.5 units × KES 1,000.00 = KES 1,500.00
        expect(
          InvoiceMath.lineSubtotal(quantityX100: 150, unitPriceMinor: 100000),
          equals(150000),
        );
      });

      test('zero quantity', () {
        expect(
          InvoiceMath.lineSubtotal(quantityX100: 0, unitPriceMinor: 100000),
          equals(0),
        );
      });
    });

    group('taxExclusive', () {
      test('16% VAT on KES 1,000', () {
        // 100000 minor * 1600 / 10000 = 16000
        expect(
          InvoiceMath.taxExclusive(subtotalMinor: 100000, taxRateBps: 1600),
          equals(16000),
        );
      });

      test('5% tax', () {
        expect(
          InvoiceMath.taxExclusive(subtotalMinor: 100000, taxRateBps: 500),
          equals(5000),
        );
      });

      test('rounding: 1/3 scenario', () {
        // 33333 * 1600 / 10000 = 5333.28 → rounds to 5333
        expect(
          InvoiceMath.taxExclusive(subtotalMinor: 33333, taxRateBps: 1600),
          equals(5333),
        );
      });
    });

    group('taxInclusive', () {
      test('extract 16% from inclusive price', () {
        // Price incl = 116000 (KES 1,160)
        // Tax = 116000 - (116000 * 10000 / 11600) = 116000 - 100000 = 16000
        expect(
          InvoiceMath.taxInclusive(
              priceIncludingTaxMinor: 116000, taxRateBps: 1600),
          equals(16000),
        );
      });

      test('subtotal from inclusive price', () {
        expect(
          InvoiceMath.subtotalFromInclusive(
              priceIncludingTaxMinor: 116000, taxRateBps: 1600),
          equals(100000),
        );
      });

      test('tax + subtotal = inclusive price', () {
        const incl = 116000;
        const bps = 1600;
        final tax = InvoiceMath.taxInclusive(
            priceIncludingTaxMinor: incl, taxRateBps: bps);
        final sub = InvoiceMath.subtotalFromInclusive(
            priceIncludingTaxMinor: incl, taxRateBps: bps);
        expect(tax + sub, equals(incl));
      });
    });

    group('discountAmount', () {
      test('percent discount 10% of KES 1,000', () {
        expect(
          InvoiceMath.discountAmount(
              subtotalMinor: 100000, discountMode: 0, discountValue: 1000),
          equals(10000),
        );
      });

      test('flat discount KES 500', () {
        expect(
          InvoiceMath.discountAmount(
              subtotalMinor: 100000, discountMode: 1, discountValue: 50000),
          equals(50000),
        );
      });

      test('flat discount capped at subtotal', () {
        expect(
          InvoiceMath.discountAmount(
              subtotalMinor: 100000, discountMode: 1, discountValue: 200000),
          equals(100000),
        );
      });

      test('zero discount', () {
        expect(
          InvoiceMath.discountAmount(
              subtotalMinor: 100000, discountMode: 0, discountValue: 0),
          equals(0),
        );
      });
    });

    group('total', () {
      test('basic: subtotal + tax - discount', () {
        expect(
          InvoiceMath.total(
              subtotalMinor: 100000, taxMinor: 16000, discountMinor: 5000),
          equals(111000),
        );
      });

      test('never negative', () {
        expect(
          InvoiceMath.total(
              subtotalMinor: 10000, taxMinor: 0, discountMinor: 20000),
          equals(0),
        );
      });
    });

    group('balanceDue', () {
      test('no payments', () {
        expect(
          InvoiceMath.balanceDue(totalMinor: 116000, paymentAmounts: []),
          equals(116000),
        );
      });

      test('partial payment', () {
        expect(
          InvoiceMath.balanceDue(
              totalMinor: 116000, paymentAmounts: [50000, 30000]),
          equals(36000),
        );
      });

      test('full payment', () {
        expect(
          InvoiceMath.balanceDue(
              totalMinor: 116000, paymentAmounts: [116000]),
          equals(0),
        );
      });

      test('overpayment clamped to 0', () {
        expect(
          InvoiceMath.balanceDue(
              totalMinor: 116000, paymentAmounts: [116000, 10000]),
          equals(0),
        );
      });
    });

    group('derivedStatus', () {
      final futureEpoch =
          DateTime.now().add(const Duration(days: 30)).millisecondsSinceEpoch ~/
              1000;
      final pastEpoch =
          DateTime.now().subtract(const Duration(days: 1)).millisecondsSinceEpoch ~/
              1000;

      test('paid override', () {
        expect(
          InvoiceMath.derivedStatus(
            statusOverride: 'paid',
            totalMinor: 100,
            paymentAmounts: [],
            dueDateEpoch: futureEpoch,
          ),
          equals('paid'),
        );
      });

      test('fully paid via payments', () {
        expect(
          InvoiceMath.derivedStatus(
            statusOverride: null,
            totalMinor: 100000,
            paymentAmounts: [100000],
            dueDateEpoch: futureEpoch,
          ),
          equals('paid'),
        );
      });

      test('overdue when past due date and balance > 0', () {
        expect(
          InvoiceMath.derivedStatus(
            statusOverride: null,
            totalMinor: 100000,
            paymentAmounts: [],
            dueDateEpoch: pastEpoch,
          ),
          equals('overdue'),
        );
      });

      test('sent when not overdue and no override', () {
        expect(
          InvoiceMath.derivedStatus(
            statusOverride: null,
            totalMinor: 100000,
            paymentAmounts: [],
            dueDateEpoch: futureEpoch,
          ),
          equals('sent'),
        );
      });

      test('draft override', () {
        expect(
          InvoiceMath.derivedStatus(
            statusOverride: 'draft',
            totalMinor: 100000,
            paymentAmounts: [],
            dueDateEpoch: null,
          ),
          equals('draft'),
        );
      });
    });
  });

  // ---------------------------------------------------------------------------
  // DocumentNumbering tests
  // ---------------------------------------------------------------------------
  group('DocumentNumbering', () {
    test('generate INV-2026-001', () {
      expect(
        DocumentNumbering.generate(prefix: 'INV', year: 2026, sequence: 1),
        equals('INV-2026-001'),
      );
    });

    test('generate EST-2026-042', () {
      expect(
        DocumentNumbering.generate(prefix: 'EST', year: 2026, sequence: 42),
        equals('EST-2026-042'),
      );
    });

    test('parse sequence from number', () {
      expect(DocumentNumbering.parseSequence('INV-2026-007'), equals(7));
    });

    test('parse sequence from non-standard returns null', () {
      expect(DocumentNumbering.parseSequence('PLAIN'), isNull);
    });
  });

  // ---------------------------------------------------------------------------
  // CurrencyFormatter tests
  // ---------------------------------------------------------------------------
  group('CurrencyFormatter', () {
    test('KES formatting', () {
      final result = CurrencyFormatter.format(150000, 'KES');
      expect(result, contains('1,500'));
      expect(result, contains('KES'));
    });

    test('parse KES amount', () {
      expect(CurrencyFormatter.parseToMinor('1,500.00', 'KES'), equals(150000));
    });

    test('parse plain number', () {
      expect(CurrencyFormatter.parseToMinor('500', 'KES'), equals(50000));
    });

    test('UGX zero decimal places', () {
      expect(CurrencyFormatter.decimalPlacesFor('UGX'), equals(0));
    });

    test('USD two decimal places', () {
      expect(CurrencyFormatter.decimalPlacesFor('USD'), equals(2));
    });
  });
}
