import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/database.dart';
import '../../../data/providers/database_provider.dart';
import '../../../data/models/client_model.dart';

class ClientRepository {
  ClientRepository(this._db);
  final AppDatabase _db;

  Stream<List<ClientModel>> watchClients() {
    return (_db.select(_db.clients)
          ..where((c) => c.deletedAt.isNull())
          ..orderBy([(c) => OrderingTerm.asc(c.name)]))
        .watch()
        .map((rows) => rows.map(_toModel).toList());
  }

  Future<ClientModel?> getClient(int id) async {
    final row = await (_db.select(_db.clients)..where((c) => c.id.equals(id))).getSingleOrNull();
    return row == null ? null : _toModel(row);
  }

  Future<int> createClient(ClientModel client) {
    return _db.into(_db.clients).insert(ClientsCompanion.insert(
      name: client.name,
      phone: Value(client.phone),
      email: Value(client.email),
      address: Value(client.address),
      taxId: Value(client.taxId),
      notes: Value(client.notes),
      createdAt: client.createdAt,
    ));
  }

  Future<void> updateClient(ClientModel client) {
    return (_db.update(_db.clients)..where((c) => c.id.equals(client.id))).write(
      ClientsCompanion(
        name: Value(client.name),
        phone: Value(client.phone),
        email: Value(client.email),
        address: Value(client.address),
        taxId: Value(client.taxId),
        notes: Value(client.notes),
      ),
    );
  }

  /// Soft-delete: keep client if they have documents, hard-delete otherwise.
  Future<void> deleteClient(int id) async {
    final hasDocuments = await (_db.select(_db.documents)
          ..where((d) => d.clientId.equals(id)))
        .get()
        .then((rows) => rows.isNotEmpty);

    if (hasDocuments) {
      await (_db.update(_db.clients)..where((c) => c.id.equals(id))).write(
        ClientsCompanion(
          deletedAt: Value(DateTime.now().millisecondsSinceEpoch ~/ 1000),
        ),
      );
    } else {
      await (_db.delete(_db.clients)..where((c) => c.id.equals(id))).go();
    }
  }

  ClientModel _toModel(Client row) => ClientModel(
        id: row.id,
        name: row.name,
        phone: row.phone,
        email: row.email,
        address: row.address,
        taxId: row.taxId,
        notes: row.notes,
        createdAt: row.createdAt,
        deletedAt: row.deletedAt,
      );
}

final clientRepositoryProvider = Provider<ClientRepository>((ref) {
  return ClientRepository(ref.watch(databaseProvider));
});

final clientListProvider = StreamProvider<List<ClientModel>>((ref) {
  return ref.watch(clientRepositoryProvider).watchClients();
});

final clientDetailProvider = FutureProvider.family<ClientModel?, int>((ref, id) {
  return ref.watch(clientRepositoryProvider).getClient(id);
});
