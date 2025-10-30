// lib/data/local/app_db.dart
import 'dart:async';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

class AppDb {
  static final AppDb _instance = AppDb._internal();
  factory AppDb() => _instance;
  AppDb._internal();

  Database? _db;

  Future<Database> get db async {
    if (_db != null) return _db!;

    final dir = await getApplicationDocumentsDirectory();
    final dbPath = p.join(dir.path, 'seettu.db');

    _db = await openDatabase(
      dbPath,
      version: 5, // bump to force onUpgrade for clean schema
      onCreate: (Database db, int version) async {
        await _createAll(db);
      },
      onUpgrade: (Database db, int oldV, int newV) async {
        // Simple strategy: drop & recreate (OK for student app)
        await db.execute('DROP TABLE IF EXISTS contribution');
        await db.execute('DROP TABLE IF EXISTS seettu_member');
        await db.execute('DROP TABLE IF EXISTS seettu');
        await _createAll(db);
      },
    );

    return _db!;
  }

  Future<void> _createAll(Database db) async {
  await db.execute('''
    CREATE TABLE seettu (
      id TEXT PRIMARY KEY,
      name TEXT NOT NULL,
      rotation_mode TEXT NOT NULL,
      amount_lkr INTEGER NOT NULL,
      frequency TEXT NOT NULL,
      status TEXT NOT NULL,          -- draft | active | completed
      updated_at INTEGER NOT NULL,
      current_index INTEGER NOT NULL,
      next_due_at INTEGER NOT NULL,
      planned_users INTEGER NOT NULL -- NEW: total members planned
    )
  ''');

    await db.execute('''
      CREATE TABLE seettu_member (
        seettu_id TEXT NOT NULL,
        user_name TEXT NOT NULL,
        join_order INTEGER NOT NULL,
        role TEXT NOT NULL             -- Organizer | Member
      )
    ''');

    await db.execute('''
      CREATE TABLE contribution (
        id TEXT PRIMARY KEY,
        seettu_id TEXT NOT NULL,
        member_name TEXT NOT NULL,
        amount_lkr INTEGER NOT NULL,
        paid INTEGER NOT NULL,
        paid_at INTEGER
      )
    ''');
  }
}
