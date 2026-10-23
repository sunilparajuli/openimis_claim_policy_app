import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:openimis_claim_policy_app/feature/claims/models/claim_submission_model.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart' as sqflite;

/// SQLite storage compatible with the Java Claims app claim tables.
/// [RawPayload] is an additive Flutter field used for reliable retries.
class ClaimSqliteDatabase {
  ClaimSqliteDatabase._();
  static final ClaimSqliteDatabase instance = ClaimSqliteDatabase._();

  static const dbName = 'openimis_claims.db';
  static const dbVersion = 2;
  static const tblClaimDetails = 'tblClaimDetails';
  static const tblClaimItems = 'tblClaimItems';
  static const tblClaimServices = 'tblClaimServices';
  static const tblClaimUploadStatus = 'tblClaimUploadStatus';

  static const statusAccepted = 'Accepted';
  static const statusRejected = 'Rejected';
  static const statusError = 'Error';
  static const statusExported = 'Exported';
  static const statusEntered = 'Entered';
  static const statusArchived = 'Archived';

  sqflite.Database? _db;
  Future<sqflite.Database?>? _opening;
  bool _useFallback = false;
  final Map<String, Map<String, dynamic>> _fallbackStore = {};

  Future<void> init() async {
    if (_db != null || _useFallback) return;
    if (_opening != null) {
      await _opening;
      return;
    }
    _opening = _open();
    await _opening;
  }

  Future<sqflite.Database?> _open() async {
    try {
      final path = p.join(await sqflite.getDatabasesPath(), dbName);
      _db = await sqflite.openDatabase(
        path,
        version: dbVersion,
        onCreate: _onCreate,
        onUpgrade: _onUpgrade,
      );
      debugPrint('[ClaimSqliteDatabase] Connected at $path');
      return _db;
    } catch (error) {
      debugPrint('[ClaimSqliteDatabase] SQLite unavailable: $error');
      _useFallback = true;
      return null;
    } finally {
      _opening = null;
    }
  }

  Future<void> _onCreate(sqflite.Database db, int version) async {
    await _createTables(db);
    await _createIndexes(db);
  }

  Future<void> _onUpgrade(
    sqflite.Database db,
    int oldVersion,
    int newVersion,
  ) async {
    if (oldVersion >= 2) return;
    await db.transaction((txn) async {
      // v1 incorrectly allowed only one status. Java stores status history.
      await txn.execute(
        'ALTER TABLE $tblClaimUploadStatus RENAME TO _oldUploadStatus',
      );
      await txn.execute(_uploadStatusSql);
      await txn.execute('''
        INSERT INTO $tblClaimUploadStatus
          (ClaimUUID, UploadDate, UploadStatus, UploadMessage)
        SELECT ClaimUUID, UploadDate,
          CASE lower(UploadStatus)
            WHEN 'uploaded' THEN '$statusAccepted'
            WHEN 'accepted' THEN '$statusAccepted'
            WHEN 'rejected' THEN '$statusRejected'
            WHEN 'error' THEN '$statusError'
            ELSE '$statusError'
          END,
          UploadMessage
        FROM _oldUploadStatus
        WHERE lower(UploadStatus) != 'pending'
      ''');
      await txn.execute('DROP TABLE _oldUploadStatus');

      final columns = await txn.rawQuery(
        'PRAGMA table_info($tblClaimServices)',
      );
      final names = columns.map((row) => row['name']).toSet();
      if (!names.contains('ServicePackageType')) {
        await txn.execute(
          'ALTER TABLE $tblClaimServices ADD COLUMN ServicePackageType TEXT',
        );
      }
      if (!names.contains('SubServicesItems')) {
        await txn.execute(
          'ALTER TABLE $tblClaimServices ADD COLUMN SubServicesItems TEXT',
        );
      }
      await _createIndexes(txn);
    });
  }

  static const _uploadStatusSql =
      '''
    CREATE TABLE IF NOT EXISTS $tblClaimUploadStatus (
      ClaimUUID TEXT, UploadDate TEXT, UploadStatus TEXT, UploadMessage TEXT
    )
  ''';

  Future<void> _createTables(sqflite.DatabaseExecutor db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS $tblClaimDetails (
        ClaimUUID TEXT PRIMARY KEY,
        ClaimDate TEXT, HFCode TEXT, ClaimAdmin TEXT, ClaimCode TEXT,
        GuaranteeNumber TEXT, InsureeNumber TEXT, StartDate TEXT, EndDate TEXT,
        ICDCode TEXT, Comment TEXT, Total TEXT, ICDCode1 TEXT, ICDCode2 TEXT,
        ICDCode3 TEXT, ICDCode4 TEXT, VisitType TEXT, ReferalHF TEXT,
        PatientCondition TEXT, PreAuthorization INTEGER, RawPayload TEXT
      )
    ''');
    await db.execute('''
      CREATE TABLE IF NOT EXISTS $tblClaimItems (
        ClaimUUID TEXT, ItemCode TEXT, ItemPrice TEXT, ItemQuantity TEXT
      )
    ''');
    await db.execute('''
      CREATE TABLE IF NOT EXISTS $tblClaimServices (
        ClaimUUID TEXT, ServiceCode TEXT, ServicePrice TEXT,
        ServiceQuantity TEXT, ServicePackageType TEXT, SubServicesItems TEXT
      )
    ''');
    await db.execute(_uploadStatusSql);
  }

  Future<void> _createIndexes(sqflite.DatabaseExecutor db) async {
    await db.execute(
      'CREATE UNIQUE INDEX IF NOT EXISTS idx_claim_code ON $tblClaimDetails(ClaimCode)',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_claim_items_uuid ON $tblClaimItems(ClaimUUID)',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_claim_services_uuid ON $tblClaimServices(ClaimUUID)',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_claim_status_uuid_date ON $tblClaimUploadStatus(ClaimUUID, UploadDate)',
    );
  }

  Future<void> saveClaimOffline(ClaimSubmission submission) async {
    await init();
    final claimUuid =
        await _claimUuidForCode(submission.claimCode) ?? _newUuid();
    final claimDate = submission.claimDate.toIso8601String();

    if (_useFallback || _db == null) {
      _fallbackStore[claimUuid] = {
        'submission': submission,
        'status': statusEntered,
        'date': claimDate,
      };
      return;
    }

    await _db!.transaction((txn) async {
      final secondary = submission.secondaryDiagnoses;
      await txn.insert(tblClaimDetails, {
        'ClaimUUID': claimUuid,
        'ClaimDate': claimDate,
        'HFCode': submission.healthFacility,
        'ClaimAdmin': submission.claimAdmin,
        'ClaimCode': submission.claimCode,
        'GuaranteeNumber': submission.guaranteeNo ?? '',
        'InsureeNumber': submission.insureeChfId,
        'StartDate': submission.startDate.toIso8601String(),
        'EndDate': submission.endDate.toIso8601String(),
        'ICDCode': submission.primaryDiagnosis.code,
        'Comment': 'Mobile Claim Submission',
        'Total': submission.totalAmount.toStringAsFixed(2),
        'ICDCode1': secondary.isNotEmpty ? secondary[0].code : null,
        'ICDCode2': secondary.length > 1 ? secondary[1].code : null,
        'ICDCode3': secondary.length > 2 ? secondary[2].code : null,
        'ICDCode4': secondary.length > 3 ? secondary[3].code : null,
        'VisitType': submission.visitType.code,
        'ReferalHF': '',
        'PatientCondition': '',
        'PreAuthorization': 0,
        'RawPayload': jsonEncode(submission.toJson()),
      }, conflictAlgorithm: sqflite.ConflictAlgorithm.replace);
      await txn.delete(
        tblClaimItems,
        where: 'ClaimUUID = ?',
        whereArgs: [claimUuid],
      );
      await txn.delete(
        tblClaimServices,
        where: 'ClaimUUID = ?',
        whereArgs: [claimUuid],
      );
      final batch = txn.batch();
      for (final item in submission.items) {
        batch.insert(tblClaimItems, {
          'ClaimUUID': claimUuid,
          'ItemCode': item.item.code,
          'ItemPrice': item.price.toString(),
          'ItemQuantity': item.quantity.toString(),
        });
      }
      for (final service in submission.services) {
        batch.insert(tblClaimServices, {
          'ClaimUUID': claimUuid,
          'ServiceCode': service.service.code,
          'ServicePrice': service.price.toString(),
          'ServiceQuantity': service.quantity.toString(),
          'ServicePackageType': service.service.category ?? '',
          'SubServicesItems': '[]',
        });
      }
      await batch.commit(noResult: true);
    });
  }

  Future<String?> _claimUuidForCode(String claimCode) async {
    if (_db == null) return null;
    final rows = await _db!.query(
      tblClaimDetails,
      columns: const ['ClaimUUID'],
      where: 'ClaimCode = ?',
      whereArgs: [claimCode],
      limit: 1,
    );
    return rows.isEmpty ? null : rows.first['ClaimUUID'] as String?;
  }

  Future<List<OfflineClaimRecord>> getPendingClaims() async {
    await init();
    if (_useFallback || _db == null) {
      return _fallbackStore.entries
          .where(
            (entry) =>
                entry.value['status'] == statusEntered ||
                entry.value['status'] == statusError,
          )
          .map((entry) => _fallbackRecord(entry.key, entry.value))
          .toList(growable: false);
    }

    // Same rule as Java SQLHandler.getAllPendingClaims: a claim remains
    // pending while it has no status except Error.
    final rows = await _db!.rawQuery('''
      SELECT d.*,
        COALESCE((SELECT s.UploadStatus FROM $tblClaimUploadStatus s
          WHERE s.ClaimUUID = d.ClaimUUID ORDER BY s.UploadDate DESC LIMIT 1),
          '$statusEntered') AS UploadStatus
      FROM $tblClaimDetails d
      WHERE NOT EXISTS (
        SELECT 1 FROM $tblClaimUploadStatus s
        WHERE s.ClaimUUID = d.ClaimUUID AND s.UploadStatus != '$statusError'
      )
      ORDER BY d.ClaimDate DESC
    ''');
    return rows.map(_recordFromRow).toList(growable: false);
  }

  OfflineClaimRecord _recordFromRow(Map<String, Object?> row) {
    ClaimSubmission? submission;
    try {
      final raw = row['RawPayload'] as String?;
      if (raw != null && raw.isNotEmpty) {
        submission = ClaimSubmission.fromJson(
          jsonDecode(raw) as Map<String, dynamic>,
        );
      }
    } catch (error) {
      debugPrint('[ClaimSqliteDatabase] Invalid retry payload: $error');
    }
    return OfflineClaimRecord(
      claimUuid: row['ClaimUUID'] as String,
      claimCode: row['ClaimCode'] as String? ?? row['ClaimUUID'] as String,
      insureeChfId: row['InsureeNumber'] as String? ?? '',
      totalAmount: double.tryParse(row['Total']?.toString() ?? '') ?? 0,
      uploadStatus: row['UploadStatus'] as String? ?? statusEntered,
      date: row['ClaimDate'] as String? ?? '',
      submission: submission,
    );
  }

  OfflineClaimRecord _fallbackRecord(String uuid, Map<String, dynamic> value) {
    final submission = value['submission'] as ClaimSubmission;
    return OfflineClaimRecord(
      claimUuid: uuid,
      claimCode: submission.claimCode,
      insureeChfId: submission.insureeChfId,
      totalAmount: submission.totalAmount,
      uploadStatus: value['status'] as String,
      date: value['date'] as String,
      submission: submission,
    );
  }

  Future<void> addUploadStatus(
    String claimUuid,
    String status, {
    String? message,
  }) async {
    await init();
    if (_useFallback || _db == null) {
      final record = _fallbackStore[claimUuid];
      if (record != null) record['status'] = status;
      return;
    }
    await _db!.insert(tblClaimUploadStatus, {
      'ClaimUUID': claimUuid,
      'UploadDate': DateTime.now().toUtc().toIso8601String(),
      'UploadStatus': status,
      'UploadMessage': message,
    });
  }

  Future<void> markClaimUploaded(
    String claimUuid, {
    String message = 'Synced successfully',
  }) => addUploadStatus(claimUuid, statusAccepted, message: message);

  Future<void> markClaimUploadFailed(String claimUuid, Object error) =>
      addUploadStatus(claimUuid, statusError, message: error.toString());

  Future<int> countPendingClaims() async {
    await init();
    if (_useFallback || _db == null) return (await getPendingClaims()).length;
    final result = await _db!.rawQuery('''
      SELECT COUNT(*) AS count FROM $tblClaimDetails d
      WHERE NOT EXISTS (
        SELECT 1 FROM $tblClaimUploadStatus s
        WHERE s.ClaimUUID = d.ClaimUUID AND s.UploadStatus != '$statusError'
      )
    ''');
    return sqflite.Sqflite.firstIntValue(result) ?? 0;
  }

  static String _newUuid() {
    final random = Random.secure();
    final bytes = List<int>.generate(16, (_) => random.nextInt(256));
    bytes[6] = (bytes[6] & 0x0f) | 0x40;
    bytes[8] = (bytes[8] & 0x3f) | 0x80;
    String hex(int value) => value.toRadixString(16).padLeft(2, '0');
    final value = bytes.map(hex).join();
    return '${value.substring(0, 8)}-${value.substring(8, 12)}-'
        '${value.substring(12, 16)}-${value.substring(16, 20)}-'
        '${value.substring(20)}';
  }
}

class OfflineClaimRecord {
  const OfflineClaimRecord({
    required this.claimUuid,
    required this.claimCode,
    required this.insureeChfId,
    required this.totalAmount,
    required this.uploadStatus,
    required this.date,
    this.submission,
  });

  final String claimUuid;
  final String claimCode;
  final String insureeChfId;
  final double totalAmount;
  final String uploadStatus;
  final String date;
  final ClaimSubmission? submission;
}
