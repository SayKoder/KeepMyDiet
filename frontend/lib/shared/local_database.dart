import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

final localDatabaseProvider = Provider<LocalDatabase>((ref) => LocalDatabase());

// Base SQLite sur le téléphone : garde la dernière réponse de chaque lecture
// pour le mode hors ligne. SQLite n'existe pas sur le web : le cache y est
// simplement désactivé.
class LocalDatabase {
  Database? _database;

  Future<Database> _open() async {
    if (_database != null) return _database!;

    _database = await openDatabase(
      join(await getDatabasesPath(), 'keepmydiet.db'),
      version: 1,
      onCreate: (db, version) => db.execute('''
        CREATE TABLE cache (
          key TEXT PRIMARY KEY,
          json TEXT NOT NULL,
          saved_at INTEGER NOT NULL
        )
      '''),
    );
    return _database!;
  }

  Future<void> save(String key, String json) async {
    if (kIsWeb) return;
    final db = await _open();
    await db.insert('cache', {
      'key': key,
      'json': json,
      'saved_at': DateTime.now().millisecondsSinceEpoch,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<String?> read(String key) async {
    if (kIsWeb) return null;
    final db = await _open();
    final rows = await db.query('cache', where: 'key = ?', whereArgs: [key]);
    if (rows.isEmpty) return null;
    return rows.first['json'] as String;
  }

  Future<void> clear() async {
    if (kIsWeb) return;
    final db = await _open();
    await db.delete('cache');
  }
}
