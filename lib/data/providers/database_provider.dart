import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../database.dart';

/// Global database provider — single instance for the app lifetime.
final databaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(db.close);
  return db;
});
