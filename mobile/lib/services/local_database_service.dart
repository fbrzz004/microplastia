
import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

import '../models/pending_sample.dart';

class LocalDatabaseService {
  LocalDatabaseService._();

  static final LocalDatabaseService instance =
      LocalDatabaseService._();

  static const String _databaseName = 'microplastia.db';
  static const int _databaseVersion = 1;
  static const String _tableName = 'pending_samples';

  Database? _database;

  // Inicializa la base de datos o reutiliza la conexión existente.
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

  // Crea la tabla local de muestras.
  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE $_tableName (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        client_uuid TEXT NOT NULL UNIQUE,
        sample_id TEXT NOT NULL,
        image_path TEXT NOT NULL,
        filename TEXT NOT NULL,
        status TEXT NOT NULL,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        attempts INTEGER NOT NULL DEFAULT 0,
        last_error TEXT,
        result_json TEXT
      )
    ''');

    await db.execute('''
      CREATE INDEX idx_pending_samples_status
      ON $_tableName(status)
    ''');

    await db.execute('''
      CREATE INDEX idx_pending_samples_created_at
      ON $_tableName(created_at)
    ''');
  }

  // Inserta una nueva muestra.
  Future<int> insertSample(PendingSample sample) async {
    final db = await database;

    return db.insert(
      _tableName,
      sample.toMap()..remove('id'),
      conflictAlgorithm: ConflictAlgorithm.abort,
    );
  }

  // Busca una muestra mediante su UUID.
  Future<PendingSample?> getSampleByUuid(
    String clientUuid,
  ) async {
    final db = await database;

    final maps = await db.query(
      _tableName,
      where: 'client_uuid = ?',
      whereArgs: [clientUuid],
      limit: 1,
    );

    if (maps.isEmpty) return null;

    return PendingSample.fromMap(maps.first);
  }

  // Recupera las muestras que necesitan sincronización.
  Future<List<PendingSample>> getPendingSamples() async {
    final db = await database;

    final maps = await db.query(
      _tableName,
      where: 'status IN (?, ?)',
      whereArgs: [
        PendingSample.pending,
        PendingSample.error,
      ],
      orderBy: 'created_at ASC',
    );

    return maps.map(PendingSample.fromMap).toList();
  }

  // Recupera todas las muestras almacenadas localmente.
  Future<List<PendingSample>> getAllSamples() async {
    final db = await database;

    final maps = await db.query(
      _tableName,
      orderBy: 'created_at DESC',
    );

    return maps.map(PendingSample.fromMap).toList();
  }

  // Actualiza el estado de una muestra.
  Future<int> updateStatus({
    required String clientUuid,
    required String status,
    String? lastError,
    String? resultJson,
    bool clearError = false,
    bool incrementAttempts = false,
  }) async {
    final db = await database;

    final values = <String, dynamic>{
      'status': status,
      'updated_at': DateTime.now().toIso8601String(),
    };

    if (lastError != null) {
      values['last_error'] = lastError;
    }

    if (clearError) {
      values['last_error'] = null;
    }

    if (resultJson != null) {
      values['result_json'] = resultJson;
    }

    if (incrementAttempts) {
      await db.rawUpdate(
        '''
        UPDATE $_tableName
        SET attempts = attempts + 1
        WHERE client_uuid = ?
        ''',
        [clientUuid],
      );
    }

    return db.update(
      _tableName,
      values,
      where: 'client_uuid = ?',
      whereArgs: [clientUuid],
    );
  }

  // Marca una muestra como enviada.
  Future<void> markAsSyncing(String clientUuid) async {
    await updateStatus(
      clientUuid: clientUuid,
      status: PendingSample.syncing,
      clearError: true,
      incrementAttempts: true,
    );
  }

  // Marca una muestra como sincronizada.
  Future<void> markAsSynced({
    required String clientUuid,
    required String resultJson,
  }) async {
    await updateStatus(
      clientUuid: clientUuid,
      status: PendingSample.synced,
      resultJson: resultJson,
      clearError: true,
    );
  }

  // Registra un error durante la sincronización.
  Future<void> markAsError({
    required String clientUuid,
    required String error,
  }) async {
    await updateStatus(
      clientUuid: clientUuid,
      status: PendingSample.error,
      lastError: error,
    );
  }

  // Recupera muestras que quedaron enviándose
  // cuando la aplicación se cerró inesperadamente.
  Future<int> recoverInterruptedSyncs() async {
    final db = await database;

    return db.update(
      _tableName,
      {
        'status': PendingSample.pending,
        'updated_at': DateTime.now().toIso8601String(),
        'last_error': 'Envío interrumpido. Pendiente de reintento.',
      },
      where: 'status = ?',
      whereArgs: [PendingSample.syncing],
    );
  }

  // Elimina una muestra local por UUID.
  Future<int> deleteSample(String clientUuid) async {
    final db = await database;

    return db.delete(
      _tableName,
      where: 'client_uuid = ?',
      whereArgs: [clientUuid],
    );
  }

  // Cierra la conexión con SQLite.
  Future<void> close() async {
    await _database?.close();
    _database = null;
  }
}
