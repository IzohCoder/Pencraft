import 'package:drift/drift.dart';
import './database.dart';

/// Seeds realistic Kenyan business data for M1 demonstration.
/// Runs once on first app launch (checks if DB is empty).
class SeedData {
  static Future<void> seedIfEmpty(AppDatabase db) async {
    final docCount = await db.select(db.documents).get().then((r) => r.length);
    if (docCount > 0) return; // Already seeded

    final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;

    // -----------------------------------------------------------------------
    // Business profile
    // -----------------------------------------------------------------------
    await db.into(db.businessProfiles).insert(BusinessProfilesCompanion.insert(
      name: 'Kariuki Creative Studio',
      ownerName: Value('James Kariuki'),
      address: Value('Westlands, Nairobi\nP.O. Box 12345-00100'),
      phone: Value('+254 722 345 678'),
      email: Value('james@kariukistudio.co.ke'),
      taxId: Value('A123456789B'),
      currencyCode: Value('KES'),
      defaultTaxRateBps: Value(1600),
      paymentInstructions: Value(
        '{"mpesa":"Paybill 247247, Account: KARIUKI","bank":"Equity Bank\\nAcc: 0234567890\\nBranch: Westlands","paypal":"james@kariukistudio.co.ke"}',
      ),
      defaultNotes: Value('Thank you for your business!'),
      defaultTerms: Value('Payment is due within 30 days of invoice date.'),
      createdAt: now,
    ));

    // -----------------------------------------------------------------------
    // Clients
    // -----------------------------------------------------------------------
    final c1 = await db.into(db.clients).insert(ClientsCompanion.insert(
      name: 'Savannah Tech Solutions',
      phone: Value('+254 733 100 200'),
      email: Value('accounts@savannahtech.co.ke'),
      address: Value('Upper Hill, Nairobi'),
      taxId: Value('B987654321C'),
      createdAt: now,
    ));

    final c2 = await db.into(db.clients).insert(ClientsCompanion.insert(
      name: 'Mama Pima Boutique',
      phone: Value('+254 700 555 777'),
      email: Value('mamapima@gmail.com'),
      address: Value('Gikomba Market, Nairobi'),
      createdAt: now,
    ));

    final c3 = await db.into(db.clients).insert(ClientsCompanion.insert(
      name: 'Green Valley Farms Ltd',
      phone: Value('+254 721 888 999'),
      email: Value('info@greenvalleyfarms.co.ke'),
      address: Value('Nakuru, Kenya'),
      taxId: Value('C112233445D'),
      createdAt: now,
    ));

    // -----------------------------------------------------------------------
    // Saved items
    // -----------------------------------------------------------------------
    await db.into(db.items).insert(ItemsCompanion.insert(
      name: 'Logo Design',
      description: Value('Custom vector logo with 3 revision rounds'),
      unit: Value('project'),
      unitPriceMinor: Value(2500000), // KES 25,000
      createdAt: now,
    ));
    await db.into(db.items).insert(ItemsCompanion.insert(
      name: 'Web Design (per page)',
      unit: Value('page'),
      unitPriceMinor: Value(800000), // KES 8,000
      createdAt: now,
    ));
    await db.into(db.items).insert(ItemsCompanion.insert(
      name: 'Social Media Post',
      description: Value('Designed graphic for Instagram / Facebook'),
      unit: Value('post'),
      unitPriceMinor: Value(150000), // KES 1,500
      createdAt: now,
    ));
    await db.into(db.items).insert(ItemsCompanion.insert(
      name: 'Consultation (hourly)',
      unit: Value('hour'),
      unitPriceMinor: Value(500000), // KES 5,000
      createdAt: now,
    ));
    await db.into(db.items).insert(ItemsCompanion.insert(
      name: 'Brand Identity Package',
      description: Value('Logo, business card, letterhead, brand guide'),
      unit: Value('package'),
      unitPriceMinor: Value(6500000), // KES 65,000
      createdAt: now,
    ));
    await db.into(db.items).insert(ItemsCompanion.insert(
      name: 'Monthly Social Media Management',
      description: Value('12 posts/month, scheduling and analytics'),
      unit: Value('month'),
      unitPriceMinor: Value(1800000), // KES 18,000
      createdAt: now,
    ));
    await db.into(db.items).insert(ItemsCompanion.insert(
      name: 'Print Design',
      description: Value('Flyer, brochure or banner design'),
      unit: Value('item'),
      unitPriceMinor: Value(350000), // KES 3,500
      createdAt: now,
    ));
    await db.into(db.items).insert(ItemsCompanion.insert(
      name: 'Photography Session',
      description: Value('2-hour product or portrait session + editing'),
      unit: Value('session'),
      unitPriceMinor: Value(1200000), // KES 12,000
      createdAt: now,
    ));

    // -----------------------------------------------------------------------
    // Documents (6 across all statuses)
    // -----------------------------------------------------------------------

    // 1. PAID invoice — Savannah Tech (2 weeks ago)
    final pastPaid = DateTime.now().subtract(const Duration(days: 14));
    final d1 = await db.into(db.documents).insert(DocumentsCompanion.insert(
      type: 'invoice',
      number: 'INV-2026-001',
      clientId: Value(c1),
      currencyCode: Value('KES'),
      globalTaxRateBps: Value(1600),
      statusOverride: Value('paid'),
      issueDate: pastPaid.millisecondsSinceEpoch ~/ 1000,
      dueDate: Value(pastPaid.add(const Duration(days: 14)).millisecondsSinceEpoch ~/ 1000),
      notes: Value('Thank you for your business!'),
      terms: Value('Payment due within 14 days.'),
      createdAt: pastPaid.millisecondsSinceEpoch ~/ 1000,
      updatedAt: pastPaid.millisecondsSinceEpoch ~/ 1000,
    ));
    await db.into(db.lineItems).insert(LineItemsCompanion.insert(
      documentId: d1,
      description: Value('Brand Identity Package'),
      unit: Value('package'),
      quantityX100: Value(100),
      unitPriceMinor: Value(6500000),
      sortOrder: Value(0),
      createdAt: now,
    ));
    await db.into(db.lineItems).insert(LineItemsCompanion.insert(
      documentId: d1,
      description: Value('Brand guide printing (digital)'),
      unit: Value('item'),
      quantityX100: Value(100),
      unitPriceMinor: Value(300000),
      sortOrder: Value(1),
      createdAt: now,
    ));
    // Payment recorded
    await db.into(db.payments).insert(PaymentsCompanion.insert(
      documentId: d1,
      amountMinor: 7888000, // full amount with 16% tax
      paymentDate: pastPaid.add(const Duration(days: 10)).millisecondsSinceEpoch ~/ 1000,
      method: Value('mpesa'),
      reference: Value('PBN1234ABC5'),
      createdAt: now,
    ));

    // 2. SENT invoice — Mama Pima (4 days ago)
    final recentSent = DateTime.now().subtract(const Duration(days: 4));
    final d2 = await db.into(db.documents).insert(DocumentsCompanion.insert(
      type: 'invoice',
      number: 'INV-2026-002',
      clientId: Value(c2),
      currencyCode: Value('KES'),
      globalTaxRateBps: Value(1600),
      statusOverride: Value('sent'),
      issueDate: recentSent.millisecondsSinceEpoch ~/ 1000,
      dueDate: Value(recentSent.add(const Duration(days: 30)).millisecondsSinceEpoch ~/ 1000),
      notes: Value('Thank you, Mama Pima!'),
      createdAt: recentSent.millisecondsSinceEpoch ~/ 1000,
      updatedAt: recentSent.millisecondsSinceEpoch ~/ 1000,
    ));
    await db.into(db.lineItems).insert(LineItemsCompanion.insert(
      documentId: d2,
      description: Value('Social Media Post'),
      unit: Value('post'),
      quantityX100: Value(800),
      unitPriceMinor: Value(150000),
      sortOrder: Value(0),
      createdAt: now,
    ));
    await db.into(db.lineItems).insert(LineItemsCompanion.insert(
      documentId: d2,
      description: Value('Monthly Social Media Management'),
      unit: Value('month'),
      quantityX100: Value(100),
      unitPriceMinor: Value(1800000),
      sortOrder: Value(1),
      createdAt: now,
    ));

    // 3. OVERDUE invoice — Green Valley (45 days ago, was due in 14)
    final overdueDate = DateTime.now().subtract(const Duration(days: 45));
    final d3 = await db.into(db.documents).insert(DocumentsCompanion.insert(
      type: 'invoice',
      number: 'INV-2026-003',
      clientId: Value(c3),
      currencyCode: Value('KES'),
      globalTaxRateBps: Value(1600),
      issueDate: overdueDate.millisecondsSinceEpoch ~/ 1000,
      dueDate: Value(overdueDate.add(const Duration(days: 14)).millisecondsSinceEpoch ~/ 1000),
      createdAt: overdueDate.millisecondsSinceEpoch ~/ 1000,
      updatedAt: overdueDate.millisecondsSinceEpoch ~/ 1000,
    ));
    await db.into(db.lineItems).insert(LineItemsCompanion.insert(
      documentId: d3,
      description: Value('Logo Design'),
      unit: Value('project'),
      quantityX100: Value(100),
      unitPriceMinor: Value(2500000),
      sortOrder: Value(0),
      createdAt: now,
    ));
    await db.into(db.lineItems).insert(LineItemsCompanion.insert(
      documentId: d3,
      description: Value('Consultation'),
      unit: Value('hour'),
      quantityX100: Value(300),
      unitPriceMinor: Value(500000),
      sortOrder: Value(1),
      createdAt: now,
    ));

    // 4. DRAFT invoice — Savannah Tech
    final d4 = await db.into(db.documents).insert(DocumentsCompanion.insert(
      type: 'invoice',
      number: 'INV-2026-004',
      clientId: Value(c1),
      currencyCode: Value('KES'),
      globalTaxRateBps: Value(1600),
      statusOverride: Value('draft'),
      issueDate: now,
      createdAt: now,
      updatedAt: now,
    ));
    await db.into(db.lineItems).insert(LineItemsCompanion.insert(
      documentId: d4,
      description: Value('Web Design — 5 pages'),
      unit: Value('pages'),
      quantityX100: Value(500),
      unitPriceMinor: Value(800000),
      sortOrder: Value(0),
      createdAt: now,
    ));

    // 5. ESTIMATE — Mama Pima
    final d5 = await db.into(db.documents).insert(DocumentsCompanion.insert(
      type: 'estimate',
      number: 'EST-2026-001',
      clientId: Value(c2),
      currencyCode: Value('KES'),
      globalTaxRateBps: Value(1600),
      statusOverride: Value('sent'),
      issueDate: DateTime.now().subtract(const Duration(days: 2)).millisecondsSinceEpoch ~/ 1000,
      dueDate: Value(DateTime.now().add(const Duration(days: 28)).millisecondsSinceEpoch ~/ 1000),
      notes: Value('Valid for 30 days from date of issue.'),
      createdAt: now,
      updatedAt: now,
    ));
    await db.into(db.lineItems).insert(LineItemsCompanion.insert(
      documentId: d5,
      description: Value('Photography Session — Product shoot'),
      unit: Value('session'),
      quantityX100: Value(200),
      unitPriceMinor: Value(1200000),
      sortOrder: Value(0),
      createdAt: now,
    ));
    await db.into(db.lineItems).insert(LineItemsCompanion.insert(
      documentId: d5,
      description: Value('Print Design — Product catalogue'),
      unit: Value('item'),
      quantityX100: Value(100),
      unitPriceMinor: Value(350000),
      sortOrder: Value(1),
      createdAt: now,
    ));

    // 6. PARTIAL PAYMENT — Green Valley
    final d6 = await db.into(db.documents).insert(DocumentsCompanion.insert(
      type: 'invoice',
      number: 'INV-2026-005',
      clientId: Value(c3),
      currencyCode: Value('KES'),
      globalTaxRateBps: Value(1600),
      statusOverride: Value('sent'),
      issueDate: DateTime.now().subtract(const Duration(days: 7)).millisecondsSinceEpoch ~/ 1000,
      dueDate: Value(DateTime.now().add(const Duration(days: 23)).millisecondsSinceEpoch ~/ 1000),
      createdAt: now,
      updatedAt: now,
    ));
    await db.into(db.lineItems).insert(LineItemsCompanion.insert(
      documentId: d6,
      description: Value('Monthly Social Media Management'),
      unit: Value('month'),
      quantityX100: Value(300),
      unitPriceMinor: Value(1800000),
      sortOrder: Value(0),
      createdAt: now,
    ));
    // Partial payment recorded
    await db.into(db.payments).insert(PaymentsCompanion.insert(
      documentId: d6,
      amountMinor: 3000000, // partial: KES 30,000 of total
      paymentDate: DateTime.now().subtract(const Duration(days: 3)).millisecondsSinceEpoch ~/ 1000,
      method: Value('bank'),
      reference: Value('TXN-2026-4567'),
      createdAt: now,
    ));
  }
}
