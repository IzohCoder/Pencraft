import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart';
import '../../../data/database.dart';
import '../../../data/providers/database_provider.dart';
import '../../../data/models/document_model.dart';

// ---------------------------------------------------------------------------
// Dashboard totals model
// ---------------------------------------------------------------------------
class DashboardTotals {
  const DashboardTotals({
    required this.outstandingMinor,
    required this.overdueMinor,
    required this.paidThisMonthMinor,
    required this.currency,
  });

  const DashboardTotals.zero()
      : outstandingMinor = 0,
        overdueMinor = 0,
        paidThisMonthMinor = 0,
        currency = 'KES';

  final int outstandingMinor;
  final int overdueMinor;
  final int paidThisMonthMinor;
  final String currency;
}

// ---------------------------------------------------------------------------
// Document repository
// ---------------------------------------------------------------------------
class DocumentRepository {
  DocumentRepository(this._db);

  final AppDatabase _db;

  /// Watch all documents filtered by type ('all'|'invoice'|'estimate').
  Stream<List<DocumentModel>> watchDocuments(String filter) {
    final query = _db.select(_db.documents).join([
      leftOuterJoin(_db.clients, _db.clients.id.equalsExp(_db.documents.clientId)),
    ]);

    if (filter != 'all') {
      query.where(_db.documents.type.equals(filter));
    }

    query.orderBy([OrderingTerm.desc(_db.documents.updatedAt)]);

    return query.watch().asyncMap((rows) async {
      final List<DocumentModel> result = [];
      for (final row in rows) {
        final doc = row.readTable(_db.documents);
        final client = row.readTableOrNull(_db.clients);
        final lineItems = await (_db.select(_db.lineItems)
              ..where((li) => li.documentId.equals(doc.id))
              ..orderBy([(li) => OrderingTerm.asc(li.sortOrder)]))
            .get();
        final payments = await (_db.select(_db.payments)
              ..where((p) => p.documentId.equals(doc.id)))
            .get();

        result.add(_toModel(doc, client, lineItems, payments));
      }
      return result;
    });
  }

  Future<DocumentModel?> getDocument(int id) async {
    final query = _db.select(_db.documents).join([
      leftOuterJoin(_db.clients, _db.clients.id.equalsExp(_db.documents.clientId)),
    ])..where(_db.documents.id.equals(id));

    final rows = await query.get();
    if (rows.isEmpty) return null;

    final row = rows.first;
    final doc = row.readTable(_db.documents);
    final client = row.readTableOrNull(_db.clients);
    final lineItems = await (_db.select(_db.lineItems)
          ..where((li) => li.documentId.equals(id))
          ..orderBy([(li) => OrderingTerm.asc(li.sortOrder)]))
        .get();
    final payments = await (_db.select(_db.payments)
          ..where((p) => p.documentId.equals(id)))
        .get();

    return _toModel(doc, client, lineItems, payments);
  }

  Future<int> createDocument(DocumentsCompanion companion) {
    return _db.into(_db.documents).insert(companion);
  }

  Future<void> updateDocument(DocumentsCompanion companion) {
    return _db.update(_db.documents).replace(companion);
  }

  Future<void> deleteDocument(int id) async {
    await (_db.delete(_db.lineItems)..where((li) => li.documentId.equals(id))).go();
    await (_db.delete(_db.payments)..where((p) => p.documentId.equals(id))).go();
    await (_db.delete(_db.documents)..where((d) => d.id.equals(id))).go();
  }

  Future<void> upsertLineItems(int documentId, List<LineItemsCompanion> items) async {
    await (_db.delete(_db.lineItems)..where((li) => li.documentId.equals(documentId))).go();
    for (final item in items) {
      await _db.into(_db.lineItems).insert(item);
    }
  }

  Future<int> addPayment(PaymentsCompanion companion) {
    return _db.into(_db.payments).insert(companion);
  }

  Future<DashboardTotals> getDashboardTotals() async {
    final docs = await (_db.select(_db.documents)).get();
    final now = DateTime.now();
    final monthStart = DateTime(now.year, now.month);

    int outstanding = 0;
    int overdue = 0;
    int paidThisMonth = 0;

    for (final doc in docs) {
      final lineItems = await (_db.select(_db.lineItems)
            ..where((li) => li.documentId.equals(doc.id)))
          .get();
      final payments = await (_db.select(_db.payments)
            ..where((p) => p.documentId.equals(doc.id)))
          .get();

      final model = _toModel(doc, null, lineItems, payments);
      final status = model.derivedStatus;

      if (status == 'sent' || status == 'overdue') {
        outstanding += model.balanceDue;
      }
      if (status == 'overdue') {
        overdue += model.balanceDue;
      }
      // Paid this month: payments made after monthStart
      for (final p in payments) {
        final pDate = DateTime.fromMillisecondsSinceEpoch(p.paymentDate * 1000);
        if (pDate.isAfter(monthStart)) {
          paidThisMonth += p.amountMinor;
        }
      }
    }

    return DashboardTotals(
      outstandingMinor: outstanding,
      overdueMinor: overdue,
      paidThisMonthMinor: paidThisMonth,
      currency: 'KES',
    );
  }

  /// Get next sequence number for a document type.
  Future<int> nextSequence(String type) async {
    final prefix = type == 'estimate' ? 'EST' : 'INV';
    final year = DateTime.now().year;
    final docs = await (_db.select(_db.documents)
          ..where((d) =>
              d.number.like('$prefix-$year-%') & d.type.equals(type)))
        .get();
    if (docs.isEmpty) return 1;
    final sequences = docs.map((d) {
      final parts = d.number.split('-');
      return int.tryParse(parts.last) ?? 0;
    }).toList();
    return (sequences.reduce((a, b) => a > b ? a : b)) + 1;
  }

  DocumentModel _toModel(
    Document doc,
    Client? client,
    List<LineItem> lineItems,
    List<Payment> payments,
  ) {
    return DocumentModel(
      id: doc.id,
      type: doc.type,
      number: doc.number,
      clientId: doc.clientId,
      clientName: client?.name,
      currencyCode: doc.currencyCode,
      taxMode: doc.taxMode,
      discountMode: doc.discountMode,
      discountValue: doc.discountValue,
      globalTaxRateBps: doc.globalTaxRateBps,
      depositMinor: doc.depositMinor,
      statusOverride: doc.statusOverride,
      issueDate: doc.issueDate,
      dueDate: doc.dueDate,
      notes: doc.notes,
      terms: doc.terms,
      templateId: doc.templateId,
      accentColour: doc.accentColour,
      createdAt: doc.createdAt,
      updatedAt: doc.updatedAt,
      lineItems: lineItems.map((li) => LineItemModel(
        id: li.id,
        documentId: li.documentId,
        itemId: li.itemId,
        description: li.description,
        unit: li.unit,
        quantityX100: li.quantityX100,
        unitPriceMinor: li.unitPriceMinor,
        taxRateBps: li.taxRateBps,
        sortOrder: li.sortOrder,
      )).toList(),
      payments: payments.map((p) => PaymentModel(
        id: p.id,
        documentId: p.documentId,
        amountMinor: p.amountMinor,
        paymentDate: p.paymentDate,
        method: p.method,
        reference: p.reference,
        notes: p.notes,
      )).toList(),
    );
  }
}

// ---------------------------------------------------------------------------
// Riverpod providers
// ---------------------------------------------------------------------------

final documentRepositoryProvider = Provider<DocumentRepository>((ref) {
  return DocumentRepository(ref.watch(databaseProvider));
});

final documentListProvider =
    StreamProvider.family<List<DocumentModel>, String>((ref, filter) {
  return ref.watch(documentRepositoryProvider).watchDocuments(filter);
});

final documentDetailProvider =
    FutureProvider.family<DocumentModel?, int>((ref, id) {
  return ref.watch(documentRepositoryProvider).getDocument(id);
});

final dashboardTotalsProvider = FutureProvider<DashboardTotals>((ref) {
  // Refresh whenever documents change
  ref.watch(documentListProvider('all'));
  return ref.watch(documentRepositoryProvider).getDashboardTotals();
});
