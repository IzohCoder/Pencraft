import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

part 'database.g.dart';

// ---------------------------------------------------------------------------
// Tables
// ---------------------------------------------------------------------------

class BusinessProfiles extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text()();
  TextColumn get ownerName => text().withDefault(const Constant(''))();
  TextColumn get address => text().withDefault(const Constant(''))();
  TextColumn get phone => text().withDefault(const Constant(''))();
  TextColumn get email => text().withDefault(const Constant(''))();
  TextColumn get taxId => text().withDefault(const Constant(''))();
  TextColumn get logoPath => text().nullable()();
  TextColumn get signaturePath => text().nullable()();
  TextColumn get currencyCode => text().withDefault(const Constant('KES'))();
  IntColumn get defaultTaxRateBps => integer().withDefault(const Constant(1600))();
  BoolColumn get taxInclusive => boolean().withDefault(const Constant(false))();
  TextColumn get paymentInstructions => text().withDefault(const Constant('{}'))();
  TextColumn get defaultNotes => text().withDefault(const Constant(''))();
  TextColumn get defaultTerms => text().withDefault(const Constant(''))();
  IntColumn get createdAt => integer()();
}

class Clients extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text()();
  TextColumn get phone => text().withDefault(const Constant(''))();
  TextColumn get email => text().withDefault(const Constant(''))();
  TextColumn get address => text().withDefault(const Constant(''))();
  TextColumn get taxId => text().withDefault(const Constant(''))();
  TextColumn get notes => text().withDefault(const Constant(''))();
  IntColumn get deletedAt => integer().nullable()();
  IntColumn get createdAt => integer()();
}

class Items extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text()();
  TextColumn get description => text().withDefault(const Constant(''))();
  TextColumn get unit => text().withDefault(const Constant('item'))();
  IntColumn get unitPriceMinor => integer().withDefault(const Constant(0))();
  IntColumn get taxRateBps => integer().nullable()();
  TextColumn get currencyCode => text().withDefault(const Constant('KES'))();
  IntColumn get createdAt => integer()();
}

class Documents extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get type => text()(); // 'invoice' | 'estimate'
  TextColumn get number => text().unique()();
  IntColumn get clientId => integer().nullable().references(Clients, #id)();
  TextColumn get currencyCode => text().withDefault(const Constant('KES'))();
  IntColumn get taxMode => integer().withDefault(const Constant(0))(); // 0=exclusive 1=inclusive
  IntColumn get discountMode => integer().withDefault(const Constant(0))(); // 0=percent 1=flat
  IntColumn get discountValue => integer().withDefault(const Constant(0))();
  IntColumn get globalTaxRateBps => integer().withDefault(const Constant(1600))();
  IntColumn get depositMinor => integer().withDefault(const Constant(0))();
  TextColumn get statusOverride => text().nullable()(); // null|draft|sent|paid|void
  IntColumn get issueDate => integer()();
  IntColumn get dueDate => integer().nullable()();
  TextColumn get notes => text().withDefault(const Constant(''))();
  TextColumn get terms => text().withDefault(const Constant(''))();
  IntColumn get templateId => integer().withDefault(const Constant(1))();
  TextColumn get accentColour => text().nullable()();
  IntColumn get createdAt => integer()();
  IntColumn get updatedAt => integer()();
}

class LineItems extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get documentId => integer().references(Documents, #id)();
  IntColumn get itemId => integer().nullable().references(Items, #id)();
  TextColumn get description => text().withDefault(const Constant(''))();
  TextColumn get unit => text().withDefault(const Constant('item'))();
  IntColumn get quantityX100 => integer().withDefault(const Constant(100))(); // stored ×100
  IntColumn get unitPriceMinor => integer().withDefault(const Constant(0))();
  IntColumn get taxRateBps => integer().nullable()(); // null = use doc global
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();
  IntColumn get createdAt => integer()();
}

class Payments extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get documentId => integer().references(Documents, #id)();
  IntColumn get amountMinor => integer()();
  IntColumn get paymentDate => integer()();
  TextColumn get method => text().withDefault(const Constant('cash'))();
  TextColumn get reference => text().withDefault(const Constant(''))();
  TextColumn get notes => text().withDefault(const Constant(''))();
  IntColumn get createdAt => integer()();
}

class AppSettings extends Table {
  TextColumn get key => text()();
  TextColumn get value => text()();

  @override
  Set<Column> get primaryKey => {key};
}

// ---------------------------------------------------------------------------
// Database
// ---------------------------------------------------------------------------

@DriftDatabase(tables: [
  BusinessProfiles,
  Clients,
  Items,
  Documents,
  LineItems,
  Payments,
  AppSettings,
])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) => m.createAll(),
        onUpgrade: (m, from, to) async {
          // Future migrations go here
        },
      );

  static QueryExecutor _openConnection() {
    return driftDatabase(name: 'pencraft_db');
  }
}
