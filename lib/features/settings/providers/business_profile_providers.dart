import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/database.dart';
import '../../../data/providers/database_provider.dart';

class BusinessProfileRepository {
  BusinessProfileRepository(this._db);
  final AppDatabase _db;

  Future<BusinessProfile?> getProfile() async {
    final rows = await _db.select(_db.businessProfiles).get();
    return rows.isEmpty ? null : rows.first;
  }

  Stream<BusinessProfile?> watchProfile() {
    return _db.select(_db.businessProfiles).watch().map(
          (rows) => rows.isEmpty ? null : rows.first,
        );
  }

  Future<void> upsertProfile(BusinessProfilesCompanion companion) async {
    final existing = await getProfile();
    if (existing == null) {
      await _db.into(_db.businessProfiles).insert(companion);
    } else {
      await (_db.update(_db.businessProfiles)
            ..where((p) => p.id.equals(existing.id)))
          .write(companion);
    }
  }
}

final businessProfileRepositoryProvider =
    Provider<BusinessProfileRepository>((ref) {
  return BusinessProfileRepository(ref.watch(databaseProvider));
});

final businessProfileProvider =
    StreamProvider<BusinessProfile?>((ref) {
  return ref.watch(businessProfileRepositoryProvider).watchProfile();
});
