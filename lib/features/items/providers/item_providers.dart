import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/database.dart';
import '../../../data/providers/database_provider.dart';
import '../../../data/models/item_model.dart';

class ItemRepository {
  ItemRepository(this._db);
  final AppDatabase _db;

  Stream<List<ItemModel>> watchItems() {
    return (_db.select(_db.items)
          ..orderBy([(i) => OrderingTerm.asc(i.name)]))
        .watch()
        .map((rows) => rows.map(_toModel).toList());
  }

  Future<ItemModel?> getItem(int id) async {
    final row = await (_db.select(_db.items)..where((i) => i.id.equals(id))).getSingleOrNull();
    return row == null ? null : _toModel(row);
  }

  Future<int> createItem(ItemModel item) {
    return _db.into(_db.items).insert(ItemsCompanion.insert(
      name: item.name,
      description: Value(item.description),
      unit: Value(item.unit),
      unitPriceMinor: Value(item.unitPriceMinor),
      taxRateBps: Value(item.taxRateBps),
      currencyCode: Value(item.currencyCode),
      createdAt: item.createdAt,
    ));
  }

  Future<void> updateItem(ItemModel item) {
    return (_db.update(_db.items)..where((i) => i.id.equals(item.id))).write(
      ItemsCompanion(
        name: Value(item.name),
        description: Value(item.description),
        unit: Value(item.unit),
        unitPriceMinor: Value(item.unitPriceMinor),
        taxRateBps: Value(item.taxRateBps),
        currencyCode: Value(item.currencyCode),
      ),
    );
  }

  Future<void> deleteItem(int id) {
    return (_db.delete(_db.items)..where((i) => i.id.equals(id))).go();
  }

  ItemModel _toModel(Item row) => ItemModel(
        id: row.id,
        name: row.name,
        description: row.description,
        unit: row.unit,
        unitPriceMinor: row.unitPriceMinor,
        taxRateBps: row.taxRateBps,
        currencyCode: row.currencyCode,
        createdAt: row.createdAt,
      );
}

final itemRepositoryProvider = Provider<ItemRepository>((ref) {
  return ItemRepository(ref.watch(databaseProvider));
});

final itemListProvider = StreamProvider<List<ItemModel>>((ref) {
  return ref.watch(itemRepositoryProvider).watchItems();
});
