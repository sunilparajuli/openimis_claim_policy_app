import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod_template/feature/claims/models/claim_submission_model.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart' as sqflite;

/// Offline SQLite Database handler mirroring openIMIS tblClaimDetails schema
class ClaimSqliteDatabase {
  ClaimSqliteDatabase._();
  static final ClaimSqliteDatabase instance = ClaimSqliteDatabase._();

  static const String dbName = 'openimis_claims.db';
  static const int dbVersion = 1;

  // Table names matching openIMIS claims_android_app_java SQLHandler
  static const String tblClaimDetails = 'tblClaimDetails';
  static const String tblClaimItems = 'tblClaimItems';
  static const String tblClaimServices = 'tblClaimServices';
  static const String tblClaimUploadStatus = 'tblClaimUploadStatus';

  sqflite.Database? _db;
  bool _useFallback = false;
  final Map<String, Map<String, dynamic>> _fallbackStore = {};

  Future<void> init() async {
    if (_db != null || _useFallback) return;

    try {
      final databasesPath = await sqflite.getDatabasesPath();
      final path = p.join(databasesPath, dbName);

      _db = await sqflite.openDatabase(
        path,
        version: dbVersion,
        onCreate: _onCreate,
      );
      debugPrint(
        '📦 [ClaimSqliteDatabase] Connected to SQLite database at $path',
      );
    } catch (e) {
      debugPrint(
        '⚠️ [ClaimSqliteDatabase] SQLite platform channel unavailable ($e). Utilizing structured resilient fallback store.',
      );
      _useFallback = true;
    }
  }

  Future<void> _onCreate(sqflite.Database db, int version) async {
    // 1. Claim Details table
    await db.execute('''
      CREATE TABLE IF NOT EXISTS $tblClaimDetails (
        ClaimUUID TEXT PRIMARY KEY,
        ClaimDate TEXT,
        HFCode TEXT,
        ClaimAdmin TEXT,
        ClaimCode TEXT,
        GuaranteeNumber TEXT,
        InsureeNumber TEXT,
        StartDate TEXT,
        EndDate TEXT,
        ICDCode TEXT,
        Comment TEXT,
        Total REAL,
        ICDCode1 TEXT,
        ICDCode2 TEXT,
        ICDCode3 TEXT,
        ICDCode4 TEXT,
        VisitType TEXT,
        ReferalHF TEXT,
        PatientCondition TEXT,
        PreAuthorization INTEGER,
        RawPayload TEXT
      );
    ''');

    // 2. Claim Items table
    await db.execute('''
      CREATE TABLE IF NOT EXISTS $tblClaimItems (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        ClaimUUID TEXT,
        ItemCode TEXT,
        ItemName TEXT,
        ItemPrice REAL,
        ItemQuantity INTEGER
      );
    ''');

    // 3. Claim Services table
    await db.execute('''
      CREATE TABLE IF NOT EXISTS $tblClaimServices (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        ClaimUUID TEXT,
        ServiceCode TEXT,
        ServiceName TEXT,
        ServicePrice REAL,
        ServiceQuantity INTEGER
      );
    ''');

    // 4. Claim Upload Status table
    await db.execute('''
      CREATE TABLE IF NOT EXISTS $tblClaimUploadStatus (
        ClaimUUID TEXT PRIMARY KEY,
        UploadDate TEXT,
        UploadStatus TEXT,
        UploadMessage TEXT
      );
    ''');
  }

  /// Inserts a newly recorded claim into offline SQLite tables
  Future<void> saveClaimOffline(
    ClaimSubmission submission, {
    String status = 'pending',
  }) async {
    await init();

    final claimUuid = submission.claimCode;
    final nowIso = DateTime.now().toIso8601String();

    if (_useFallback || _db == null) {
      _fallbackStore[claimUuid] = {
        'submission': submission,
        'status': status,
        'date': nowIso,
        'message': status == 'pending'
            ? 'Saved offline pending sync'
            : 'Synced',
      };
      return;
    }

    await _db!.transaction((txn) async {
      // Primary Diagnosis & Secondary Diagnoses
      final primaryIcd = submission.primaryDiagnosis.code;
      final sec1 = submission.secondaryDiagnoses.isNotEmpty
          ? submission.secondaryDiagnoses[0].code
          : null;
      final sec2 = submission.secondaryDiagnoses.length > 1
          ? submission.secondaryDiagnoses[1].code
          : null;
      final sec3 = submission.secondaryDiagnoses.length > 2
          ? submission.secondaryDiagnoses[2].code
          : null;
      final sec4 = submission.secondaryDiagnoses.length > 3
          ? submission.secondaryDiagnoses[3].code
          : null;

      // 1. Insert Claim Details
      await txn.insert(tblClaimDetails, {
        'ClaimUUID': claimUuid,
        'ClaimDate': nowIso,
        'HFCode': submission.healthFacilityName,
        'ClaimAdmin': submission.claimAdministrator,
        'ClaimCode': submission.claimCode,
        'GuaranteeNumber': submission.guaranteeNo ?? '',
        'InsureeNumber': submission.insureeChfId,
        'StartDate': submission.startDate.toIso8601String(),
        'EndDate': submission.endDate.toIso8601String(),
        'ICDCode': primaryIcd,
        'Comment': 'Mobile Claim Submission',
        'Total': submission.totalAmount,
        'ICDCode1': sec1,
        'ICDCode2': sec2,
        'ICDCode3': sec3,
        'ICDCode4': sec4,
        'VisitType': submission.visitType.name,
        'ReferalHF': '',
        'PatientCondition': '',
        'PreAuthorization': 0,
        'RawPayload': jsonEncode(submission.toJson()),
      }, conflictAlgorithm: sqflite.ConflictAlgorithm.replace);

      // 2. Insert Services
      for (final cs in submission.services) {
        await txn.insert(tblClaimServices, {
          'ClaimUUID': claimUuid,
          'ServiceCode': cs.service.code,
          'ServiceName': cs.service.name,
          'ServicePrice': cs.price,
          'ServiceQuantity': cs.quantity,
        });
      }

      // 3. Insert Items
      for (final ci in submission.items) {
        await txn.insert(tblClaimItems, {
          'ClaimUUID': claimUuid,
          'ItemCode': ci.item.code,
          'ItemName': ci.item.name,
          'ItemPrice': ci.price,
          'ItemQuantity': ci.quantity,
        });
      }

      // 4. Insert Upload Status
      await txn.insert(tblClaimUploadStatus, {
        'ClaimUUID': claimUuid,
        'UploadDate': nowIso,
        'UploadStatus': status,
        'UploadMessage': status == 'pending'
            ? 'Saved offline pending sync'
            : 'Synced',
      }, conflictAlgorithm: sqflite.ConflictAlgorithm.replace);
    });
  }

  /// Retrieve all claims waiting to be uploaded
  Future<List<OfflineClaimRecord>> getPendingClaims() async {
    await init();

    if (_useFallback || _db == null) {
      return _fallbackStore.entries
          .where((e) => e.value['status'] == 'pending')
          .map(
            (e) => OfflineClaimRecord(
              claimUuid: e.key,
              claimCode: (e.value['submission'] as ClaimSubmission).claimCode,
              insureeChfId:
                  (e.value['submission'] as ClaimSubmission).insureeChfId,
              totalAmount:
                  (e.value['submission'] as ClaimSubmission).totalAmount,
              uploadStatus: 'pending',
              date: e.value['date'] as String,
              submission: e.value['submission'] as ClaimSubmission,
            ),
          )
          .toList();
    }

    final results = await _db!.rawQuery('''
      SELECT d.*, s.UploadStatus, s.UploadMessage, s.UploadDate
      FROM $tblClaimDetails d
      INNER JOIN $tblClaimUploadStatus s ON d.ClaimUUID = s.ClaimUUID
      WHERE s.UploadStatus = 'pending'
      ORDER BY d.ClaimDate DESC
    ''');

    return results.map((row) {
      ClaimSubmission? submission;
      try {
        final raw = row['RawPayload'] as String?;
        if (raw != null) {
          submission = ClaimSubmission.fromJson(
            jsonDecode(raw) as Map<String, dynamic>,
          );
        }
      } catch (_) {}

      return OfflineClaimRecord(
        claimUuid: row['ClaimUUID'] as String,
        claimCode: row['ClaimCode'] as String? ?? row['ClaimUUID'] as String,
        insureeChfId: row['InsureeNumber'] as String? ?? '',
        totalAmount: (row['Total'] as num?)?.toDouble() ?? 0.0,
        uploadStatus: row['UploadStatus'] as String? ?? 'pending',
        date: row['ClaimDate'] as String? ?? '',
        submission: submission,
      );
    }).toList();
  }

  /// Update upload status after syncing
  Future<void> markClaimUploaded(
    String claimUuid, {
    String message = 'Synced successfully',
  }) async {
    await init();

    if (_useFallback || _db == null) {
      if (_fallbackStore.containsKey(claimUuid)) {
        _fallbackStore[claimUuid]!['status'] = 'uploaded';
        _fallbackStore[claimUuid]!['message'] = message;
      }
      return;
    }

    await _db!.update(
      tblClaimUploadStatus,
      {
        'UploadStatus': 'uploaded',
        'UploadMessage': message,
        'UploadDate': DateTime.now().toIso8601String(),
      },
      where: 'ClaimUUID = ?',
      whereArgs: [claimUuid],
    );
  }

  /// Get total count of pending offline claims
  Future<int> countPendingClaims() async {
    final pending = await getPendingClaims();
    return pending.length;
  }
}

/// Offline Claim summary model
class OfflineClaimRecord {
  final String claimUuid;
  final String claimCode;
  final String insureeChfId;
  final double totalAmount;
  final String uploadStatus;
  final String date;
  final ClaimSubmission? submission;

  const OfflineClaimRecord({
    required this.claimUuid,
    required this.claimCode,
    required this.insureeChfId,
    required this.totalAmount,
    required this.uploadStatus,
    required this.date,
    this.submission,
  });
}
