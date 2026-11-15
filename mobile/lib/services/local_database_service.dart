import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

import '../models/pending_sample.dart';

class LocalDatabaseService {
  LocalDatabaseService._();

  static final LocalDatabaseService instance = LocalDatabaseService._();

  static const String _databaseName = 'microplastia.db';
  static const int _databaseVersion = 1;
  static const String _tableName = 'pending_samples';

  Database? _database;

  Future<Database> get database async {
    if (_database != null) {
      return _database!;
    }

    final dbPath = await getDatabasesPath();
    final path = p.join(dbPath, _databaseName);

    _database = await openDatabase(
      path,
      version: _databaseVersion,
      onCreate: _onCreate,
    );

    return _database!;
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute(
      'CREATE TABLE $_tableName ('
      'id INTEGER PRIMARY KEY AUTOINCREMENT, '
      'client_uuid TEXT NOT NULL UNIQUE, '
      'sample_id TEXT NOT NULL, '
      'image_path TEXT NOT NULL, '
      'filename TEXT NOT NULL, '
      'status TEXT NOT NULL, '
      'created_at TEXT NOT NULL, '
      'updated_at TEXT NOT NULL, '
      'attempts INTEGER NOT NULL DEFAULT 0, '
      'last_error TEXT, '
      'result_json TEXT'
      ')',
    );

    await db.execute(
      'CREATE INDEX idx_pending_samples_status '
      'ON $_tableName(status)',
    );

    await db.execute(
      'CREATE INDEX idx_pending_samples_created_at '
      'ON $_tableName(created_at)',
    );
  }

  Future<int> insertSample(PendingSample sample) async {
    final db = await database;

    return db.insert(
      _tableName,
      sample.toMap()..remove('id'),
      conflictAlgorithm: ConflictAlgorithm.abort,
    );
  }

  Future<PendingSample?> getSampleByUuid(String clientUuid) async {
    final db = await database;

    final rows = await db.query(
      _tableName,
      where: 'client_uuid = ?',
      whereArgs: [clientUuid],
      limit: 1,
    );

    if (rows.isEmpty) {
      return null;
    }

    return PendingSample.fromMap(rows.first);
  }

  Future<List<PendingSample>> getPendingSamples() async {
    final db = await database;

    final rows = await db.query(
      _tableName,
      where: 'status IN (?, ?)',
      whereArgs: [
        PendingSample.pending,
        PendingSample.error,
      ],
      orderBy: 'created_at ASC',
    );

    return rows.map(PendingSample.fromMap).toList();
  }

  Future<List<PendingSample>> getAllSamples() async {
    final db = await database;

    final rows = await db.query(
      _tableName,
      orderBy: 'created_at DESC',
    );

    return rows.map(PendingSample.fromMap).toList();
  }

  Future<void> updateStatus({
    required String clientUuid,
    required String status,
    String? lastError,
    String? resultJson,
    int? attempts,
  }) async {
    final db = await database;

    final values = <String, dynamic>{
      'status': status,
      'updated_at': DateTime.now().toIso8601String(),
      'last_error': lastError,
    };

    if (resultJson != null) {
      values['result_json'] = resultJson;
    }

    if (attempts != null) {
      values['attempts'] = attempts;
    }

    await db.update(
      _tableName,
      values,
      where: 'client_uuid = ?',
      whereArgs: [clientUuid],
    );
  }

  Future<void> markAsSyncing(String clientUuid) async {
    final sample = await getSampleByUuid(clientUuid);

    await updateStatus(
      clientUuid: clientUuid,
      status: PendingSample.syncing,
      attempts: (sample?.attempts ?? 0) + 1,
    );
  }

  Future<void> markAsSynced({
    required String clientUuid,
    required String resultJson,
  }) {
    return updateStatus(
      clientUuid: clientUuid,
      status: PendingSample.synced,
      resultJson: resultJson,
    );
  }

  Future<void> markAsError({
    required String clientUuid,
    required String error,
  }) {
    return updateStatus(
      clientUuid: clientUuid,
      status: PendingSample.error,
      lastError: error,
    );
  }

  Future<void> recoverInterruptedSyncs() async {
    final db = await database;

    await db.update(
      _tableName,
      {
        'status': PendingSample.pending,
        'updated_at': DateTime.now().toIso8601String(),
      },
      where: 'status = ?',
      whereArgs: [PendingSample.syncing],
    );
  }
}
