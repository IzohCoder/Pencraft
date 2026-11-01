import 'dart:convert';
import 'dart:io';
import 'package:drift/drift.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import '../data/database.dart';
import '../data/providers/database_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Backup & Restore service.
/// Exports the entire database as a JSON file; imports back from that file.
/// Data stays on-device — no cloud, no network.
class BackupService {
  BackupService(this._db);

  final AppDatabase _db;

  // ---------------------------------------------------------------------------
  // Backup
  // ---------------------------------------------------------------------------

  /// Export all data as JSON and let the user save/share the file.
  Future<String?> exportBackup() async {
    try {
      final data = await _gatherData();
      final json = const JsonEncoder.withIndent('  ').convert(data);
      final bytes = utf8.encode(json);

      // Save to app documents directory
      final dir = await getApplicationDocumentsDirectory();
      final timestamp = DateTime.now().toIso8601String().replaceAll(':', '-').substring(0, 19);
      final file = File('${dir.path}/pencraft_backup_$timestamp.json');
      await file.writeAsBytes(bytes);
      return file.path;
    } catch (e) {
      return null;
    }
  }

  // ---------------------------------------------------------------------------
  // Restore
  // ---------------------------------------------------------------------------

  /// Pick a backup JSON file and restore the database from it.
  /// Returns true on success, false on failure.
  Future<bool> importBackup() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
        allowMultiple: false,
      );
      if (result == null || result.files.isEmpty) return false;

      final path = result.files.first.path;
      if (path == null) return false;

      final content = await File(path).readAsString();
      final data = jsonDecode(content) as Map<String, dynamic>;

      await _restoreData(data);
      return true;
    } catch (e) {
      return false;
    }
  }

  // ---------------------------------------------------------------------------
  // Internal
  // ---------------------------------------------------------------------------

  Future<Map<String, dynamic>> _gatherData() async {
    final profile = await _db.select(_db.businessProfiles).get();
    final clients = await _db.select(_db.clients).get();
    final items = await _db.select(_db.items).get();
    final documents = await _db.select(_db.documents).get();
    final lineItems = await _db.select(_db.lineItems).get();
    final payments = await _db.select(_db.payments).get();
    final settings = await _db.select(_db.appSettings).get();

    return {
      'version': 1,
      'exportedAt': DateTime.now().toIso8601String(),
      'app': 'pencraft',
      'businessProfiles': profile.map(_profileToJson).toList(),
      'clients': clients.map(_clientToJson).toList(),
      'items': items.map(_itemToJson).toList(),
      'documents': documents.map(_docToJson).toList(),
      'lineItems': lineItems.map(_lineItemToJson).toList(),
      'payments': payments.map(_paymentToJson).toList(),
      'settings': settings.map((s) => {'key': s.key, 'value': s.value}).toList(),
    };
  }

  Future<void> _restoreData(Map<String, dynamic> data) async {
    // Wipe existing data
    await _db.delete(_db.lineItems).go();
    await _db.delete(_db.payments).go();
    await _db.delete(_db.documents).go();
    await _db.delete(_db.items).go();
    await _db.delete(_db.clients).go();
    await _db.delete(_db.businessProfiles).go();
    await _db.delete(_db.appSettings).go();

    // Re-insert all data from backup
    for (final row in (data['businessProfiles'] as List? ?? [])) {
      await _db.into(_db.businessProfiles).insert(_jsonToProfile(row as Map<String, dynamic>));
    }
    for (final row in (data['clients'] as List? ?? [])) {
      await _db.into(_db.clients).insert(_jsonToClient(row as Map<String, dynamic>));
    }
    for (final row in (data['items'] as List? ?? [])) {
      await _db.into(_db.items).insert(_jsonToItem(row as Map<String, dynamic>));
    }
    for (final row in (data['documents'] as List? ?? [])) {
      await _db.into(_db.documents).insert(_jsonToDocument(row as Map<String, dynamic>));
    }
    for (final row in (data['lineItems'] as List? ?? [])) {
      await _db.into(_db.lineItems).insert(_jsonToLineItem(row as Map<String, dynamic>));
    }
    for (final row in (data['payments'] as List? ?? [])) {
      await _db.into(_db.payments).insert(_jsonToPayment(row as Map<String, dynamic>));
    }
    for (final row in (data['settings'] as List? ?? [])) {
      final s = row as Map<String, dynamic>;
      await _db.into(_db.appSettings).insertOnConflictUpdate(
        AppSettingsCompanion.insert(key: s['key'] as String, value: s['value'] as String),
      );
    }
  }

  // --- Serializers ---
  Map<String, dynamic> _profileToJson(BusinessProfile p) => {
        'id': p.id, 'name': p.name, 'ownerName': p.ownerName,
        'address': p.address, 'phone': p.phone, 'email': p.email,
        'taxId': p.taxId, 'logoPath': p.logoPath, 'signaturePath': p.signaturePath,
        'currencyCode': p.currencyCode, 'defaultTaxRateBps': p.defaultTaxRateBps,
        'taxInclusive': p.taxInclusive, 'paymentInstructions': p.paymentInstructions,
        'defaultNotes': p.defaultNotes, 'defaultTerms': p.defaultTerms,
        'createdAt': p.createdAt,
      };

  Map<String, dynamic> _clientToJson(Client c) => {
        'id': c.id, 'name': c.name, 'phone': c.phone, 'email': c.email,
        'address': c.address, 'taxId': c.taxId, 'notes': c.notes,
        'deletedAt': c.deletedAt, 'createdAt': c.createdAt,
      };

  Map<String, dynamic> _itemToJson(Item i) => {
        'id': i.id, 'name': i.name, 'description': i.description,
        'unit': i.unit, 'unitPriceMinor': i.unitPriceMinor,
        'taxRateBps': i.taxRateBps, 'currencyCode': i.currencyCode,
        'createdAt': i.createdAt,
      };

  Map<String, dynamic> _docToJson(Document d) => {
        'id': d.id, 'type': d.type, 'number': d.number, 'clientId': d.clientId,
        'currencyCode': d.currencyCode, 'taxMode': d.taxMode,
        'discountMode': d.discountMode, 'discountValue': d.discountValue,
        'globalTaxRateBps': d.globalTaxRateBps, 'depositMinor': d.depositMinor,
        'statusOverride': d.statusOverride, 'issueDate': d.issueDate,
        'dueDate': d.dueDate, 'notes': d.notes, 'terms': d.terms,
        'templateId': d.templateId, 'accentColour': d.accentColour,
        'createdAt': d.createdAt, 'updatedAt': d.updatedAt,
      };

  Map<String, dynamic> _lineItemToJson(LineItem li) => {
        'id': li.id, 'documentId': li.documentId, 'itemId': li.itemId,
        'description': li.description, 'unit': li.unit,
        'quantityX100': li.quantityX100, 'unitPriceMinor': li.unitPriceMinor,
        'taxRateBps': li.taxRateBps, 'sortOrder': li.sortOrder,
        'createdAt': li.createdAt,
      };

  Map<String, dynamic> _paymentToJson(Payment p) => {
        'id': p.id, 'documentId': p.documentId, 'amountMinor': p.amountMinor,
        'paymentDate': p.paymentDate, 'method': p.method,
        'reference': p.reference, 'notes': p.notes, 'createdAt': p.createdAt,
      };

  // --- Deserializers ---
  BusinessProfilesCompanion _jsonToProfile(Map<String, dynamic> j) =>
      BusinessProfilesCompanion.insert(
        name: j['name'] as String,
        ownerName: _v(j['ownerName'] as String? ?? ''),
        address: _v(j['address'] as String? ?? ''),
        phone: _v(j['phone'] as String? ?? ''),
        email: _v(j['email'] as String? ?? ''),
        taxId: _v(j['taxId'] as String? ?? ''),
        currencyCode: _v(j['currencyCode'] as String? ?? 'KES'),
        defaultTaxRateBps: _v(j['defaultTaxRateBps'] as int? ?? 1600),
        taxInclusive: _v(j['taxInclusive'] as bool? ?? false),
        paymentInstructions: _v(j['paymentInstructions'] as String? ?? '{}'),
        defaultNotes: _v(j['defaultNotes'] as String? ?? ''),
        defaultTerms: _v(j['defaultTerms'] as String? ?? ''),
        createdAt: j['createdAt'] as int,
      );

  ClientsCompanion _jsonToClient(Map<String, dynamic> j) =>
      ClientsCompanion.insert(
        name: j['name'] as String,
        phone: _v(j['phone'] as String? ?? ''),
        email: _v(j['email'] as String? ?? ''),
        address: _v(j['address'] as String? ?? ''),
        taxId: _v(j['taxId'] as String? ?? ''),
        notes: _v(j['notes'] as String? ?? ''),
        createdAt: j['createdAt'] as int,
      );

  ItemsCompanion _jsonToItem(Map<String, dynamic> j) =>
      ItemsCompanion.insert(
        name: j['name'] as String,
        description: _v(j['description'] as String? ?? ''),
        unit: _v(j['unit'] as String? ?? 'item'),
        unitPriceMinor: _v(j['unitPriceMinor'] as int? ?? 0),
        currencyCode: _v(j['currencyCode'] as String? ?? 'KES'),
        createdAt: j['createdAt'] as int,
      );

  DocumentsCompanion _jsonToDocument(Map<String, dynamic> j) =>
      DocumentsCompanion.insert(
        type: j['type'] as String,
        number: j['number'] as String,
        currencyCode: _v(j['currencyCode'] as String? ?? 'KES'),
        taxMode: _v(j['taxMode'] as int? ?? 0),
        discountMode: _v(j['discountMode'] as int? ?? 0),
        discountValue: _v(j['discountValue'] as int? ?? 0),
        globalTaxRateBps: _v(j['globalTaxRateBps'] as int? ?? 1600),
        depositMinor: _v(j['depositMinor'] as int? ?? 0),
        issueDate: j['issueDate'] as int,
        notes: _v(j['notes'] as String? ?? ''),
        terms: _v(j['terms'] as String? ?? ''),
        templateId: _v(j['templateId'] as int? ?? 1),
        createdAt: j['createdAt'] as int,
        updatedAt: j['updatedAt'] as int,
      );

  LineItemsCompanion _jsonToLineItem(Map<String, dynamic> j) =>
      LineItemsCompanion.insert(
        documentId: j['documentId'] as int,
        description: _v(j['description'] as String? ?? ''),
        unit: _v(j['unit'] as String? ?? 'item'),
        quantityX100: _v(j['quantityX100'] as int? ?? 100),
        unitPriceMinor: _v(j['unitPriceMinor'] as int? ?? 0),
        createdAt: j['createdAt'] as int,
      );

  PaymentsCompanion _jsonToPayment(Map<String, dynamic> j) =>
      PaymentsCompanion.insert(
        documentId: j['documentId'] as int,
        amountMinor: j['amountMinor'] as int,
        paymentDate: j['paymentDate'] as int,
        method: _v(j['method'] as String? ?? 'cash'),
        reference: _v(j['reference'] as String? ?? ''),
        notes: _v(j['notes'] as String? ?? ''),
        createdAt: j['createdAt'] as int,
      );

  /// Shorthand for Value() wrapper.
  Value<T> _v<T>(T val) => Value(val);
}

// ---------------------------------------------------------------------------
// Provider
// ---------------------------------------------------------------------------
final backupServiceProvider = Provider<BackupService>((ref) {
  return BackupService(ref.watch(databaseProvider));
});
