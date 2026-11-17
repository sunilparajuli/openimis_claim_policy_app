import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:openimis_claim_policy_app/feature/policies/models/offline_policy_enrollment.dart';
import 'package:openimis_claim_policy_app/feature/policies/models/offline_insuree_update.dart';
import 'package:openimis_claim_policy_app/feature/policies/models/policy_enrollment.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart' as sqflite;

class PolicyEnrollmentDatabase {
  PolicyEnrollmentDatabase._();

  static final instance = PolicyEnrollmentDatabase._();
  static const _databaseName = 'openimis_policy_enrolments.db';
  static const _table = 'offline_policy_enrolments';
  static const _updateTable = 'offline_insuree_updates';
  static const statusEntered = 'Entered';
  static const statusError = 'Error';
  static const statusSynced = 'Synced';

  sqflite.Database? _database;
  Future<sqflite.Database?>? _opening;
  bool _useFallback = false;
  final Map<String, PolicyEnrollmentRecord> _fallback = {};
  final Map<String, InsureeUpdateRecord> _fallbackUpdates = {};

  Future<void> init() async {
    if (_database != null || _useFallback) return;
    _opening ??= _open();
    await _opening;
  }

  Future<sqflite.Database?> _open() async {
    try {
      final path = p.join(await sqflite.getDatabasesPath(), _databaseName);
      _database = await sqflite.openDatabase(
        path,
        version: 2,
        onCreate: (database, _) async {
          await database.execute('''
          CREATE TABLE $_table (
            EnrollmentId TEXT PRIMARY KEY,
            Application TEXT NOT NULL,
            HeadChfId TEXT NOT NULL,
            CreatedAt TEXT NOT NULL,
            UpdatedAt TEXT NOT NULL,
            SyncStatus TEXT NOT NULL,
            ErrorMessage TEXT,
            Payload TEXT NOT NULL
          )
        ''');
          await _createUpdateTable(database);
        },
        onUpgrade: (database, oldVersion, _) async {
          if (oldVersion < 2) await _createUpdateTable(database);
        },
      );
      return _database;
    } catch (error) {
      debugPrint('[PolicyEnrollmentDatabase] SQLite unavailable: $error');
      _useFallback = true;
      return null;
    } finally {
      _opening = null;
    }
  }

  Future<void> save(OfflinePolicyEnrollment enrollment) async {
    await init();
    final record = PolicyEnrollmentRecord(
      enrollment: enrollment,
      status: statusEntered,
    );
    if (_useFallback || _database == null) {
      _fallback[enrollment.id] = record;
      return;
    }
    final now = DateTime.now().toUtc().toIso8601String();
    await _database!.insert(_table, {
      'EnrollmentId': enrollment.id,
      'Application': enrollment.family.application.name,
      'HeadChfId': enrollment.family.head.chfId,
      'CreatedAt': enrollment.createdAt.toUtc().toIso8601String(),
      'UpdatedAt': now,
      'SyncStatus': statusEntered,
      'ErrorMessage': null,
      'Payload': jsonEncode(enrollment.toJson()),
    }, conflictAlgorithm: sqflite.ConflictAlgorithm.replace);
  }

  Future<List<PolicyEnrollmentRecord>> pending() async {
    await init();
    if (_useFallback || _database == null) {
      return _fallback.values
          .where((record) => record.status != statusSynced)
          .toList(growable: false);
    }
    final rows = await _database!.query(
      _table,
      where: 'SyncStatus != ?',
      whereArgs: [statusSynced],
      orderBy: 'CreatedAt ASC',
    );
    return rows.map(_fromRow).toList(growable: false);
  }

  Future<OfflinePolicyEnrollment> addMember(
    String enrollmentId,
    PolicyInsureeDraft member,
  ) async {
    await init();
    if (_useFallback || _database == null) {
      final current = _fallback[enrollmentId];
      if (current == null || current.status == statusSynced) {
        throw const FormatException('Pending family enrolment not found.');
      }
      final updated = current.enrollment.withMember(member);
      _fallback[enrollmentId] = PolicyEnrollmentRecord(
        enrollment: updated,
        status: statusEntered,
      );
      return updated;
    }
    final rows = await _database!.query(
      _table,
      where: 'EnrollmentId = ? AND SyncStatus != ?',
      whereArgs: [enrollmentId, statusSynced],
      limit: 1,
    );
    if (rows.isEmpty) {
      throw const FormatException('Pending family enrolment not found.');
    }
    final updated = _fromRow(rows.single).enrollment.withMember(member);
    await _database!.update(
      _table,
      {
        'Payload': jsonEncode(updated.toJson()),
        'SyncStatus': statusEntered,
        'ErrorMessage': null,
        'UpdatedAt': DateTime.now().toUtc().toIso8601String(),
      },
      where: 'EnrollmentId = ?',
      whereArgs: [enrollmentId],
    );
    return updated;
  }

  Future<void> markSynced(String id) => _setStatus(id, statusSynced);

  Future<void> markFailed(String id, Object error) =>
      _setStatus(id, statusError, error: error.toString());

  Future<void> saveInsureeUpdate(OfflineInsureeUpdate update) async {
    await init();
    final record = InsureeUpdateRecord(update: update, status: statusEntered);
    if (_useFallback || _database == null) {
      _fallbackUpdates[update.id] = record;
      return;
    }
    final now = DateTime.now().toUtc().toIso8601String();
    await _database!.insert(_updateTable, {
      'UpdateId': update.id,
      'Application': update.application.name,
      'ChfId': update.insuree.chfId,
      'CreatedAt': update.createdAt.toUtc().toIso8601String(),
      'UpdatedAt': now,
      'SyncStatus': statusEntered,
      'ErrorMessage': null,
      'Payload': jsonEncode(update.toJson()),
    }, conflictAlgorithm: sqflite.ConflictAlgorithm.replace);
  }

  Future<List<InsureeUpdateRecord>> pendingInsureeUpdates() async {
    await init();
    if (_useFallback || _database == null) {
      return _fallbackUpdates.values
          .where((record) => record.status != statusSynced)
          .toList(growable: false);
    }
    final rows = await _database!.query(
      _updateTable,
      where: 'SyncStatus != ?',
      whereArgs: [statusSynced],
      orderBy: 'CreatedAt ASC',
    );
    return rows
        .map(
          (row) => InsureeUpdateRecord(
            update: OfflineInsureeUpdate.fromJson(
              Map<String, dynamic>.from(
                jsonDecode(row['Payload'] as String) as Map,
              ),
            ),
            status: row['SyncStatus'] as String,
            error: row['ErrorMessage'] as String?,
          ),
        )
        .toList(growable: false);
  }

  Future<void> markInsureeUpdateSynced(String id) =>
      _setUpdateStatus(id, statusSynced);

  Future<void> markInsureeUpdateFailed(String id, Object error) =>
      _setUpdateStatus(id, statusError, error: error.toString());

  Future<void> _setStatus(String id, String status, {String? error}) async {
    await init();
    if (_useFallback || _database == null) {
      final current = _fallback[id];
      if (current != null) {
        _fallback[id] = PolicyEnrollmentRecord(
          enrollment: current.enrollment,
          status: status,
          error: error,
        );
      }
      return;
    }
    await _database!.update(
      _table,
      {
        'SyncStatus': status,
        'ErrorMessage': error,
        'UpdatedAt': DateTime.now().toUtc().toIso8601String(),
      },
      where: 'EnrollmentId = ?',
      whereArgs: [id],
    );
  }

  Future<void> _setUpdateStatus(
    String id,
    String status, {
    String? error,
  }) async {
    await init();
    if (_useFallback || _database == null) {
      final current = _fallbackUpdates[id];
      if (current != null) {
        _fallbackUpdates[id] = InsureeUpdateRecord(
          update: current.update,
          status: status,
          error: error,
        );
      }
      return;
    }
    await _database!.update(
      _updateTable,
      {
        'SyncStatus': status,
        'ErrorMessage': error,
        'UpdatedAt': DateTime.now().toUtc().toIso8601String(),
      },
      where: 'UpdateId = ?',
      whereArgs: [id],
    );
  }

  static Future<void> _createUpdateTable(sqflite.DatabaseExecutor database) =>
      database.execute('''
    CREATE TABLE IF NOT EXISTS $_updateTable (
      UpdateId TEXT PRIMARY KEY,
      Application TEXT NOT NULL,
      ChfId TEXT NOT NULL,
      CreatedAt TEXT NOT NULL,
      UpdatedAt TEXT NOT NULL,
      SyncStatus TEXT NOT NULL,
      ErrorMessage TEXT,
      Payload TEXT NOT NULL
    )
  ''');

  static PolicyEnrollmentRecord _fromRow(Map<String, Object?> row) =>
      PolicyEnrollmentRecord(
        enrollment: OfflinePolicyEnrollment.fromJson(
          Map<String, dynamic>.from(
            jsonDecode(row['Payload'] as String) as Map,
          ),
        ),
        status: row['SyncStatus'] as String,
        error: row['ErrorMessage'] as String?,
      );
}

class PolicyEnrollmentRecord {
  const PolicyEnrollmentRecord({
    required this.enrollment,
    required this.status,
    this.error,
  });

  final OfflinePolicyEnrollment enrollment;
  final String status;
  final String? error;
}

class InsureeUpdateRecord {
  const InsureeUpdateRecord({
    required this.update,
    required this.status,
    this.error,
  });

  final OfflineInsureeUpdate update;
  final String status;
  final String? error;
}
