import 'dart:convert';

import 'package:archive/archive.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:openimis_claim_policy_app/data/local/csu_master_data_cache.dart';
import 'package:openimis_claim_policy_app/data/remote/api/service/http_service.dart';
import 'package:openimis_claim_policy_app/feature/shared/models/csu_master_data.dart';

const csuMasterDataEndpoint = 'api/tools/extracts/download_master_data';

class CsuMasterDataRepository {
  CsuMasterDataRepository(this._http, this._cache);

  final HttpService _http;
  final CsuMasterDataCache _cache;

  Future<CsuMasterData?> loadCached() async {
    final bytes = await _cache.read();
    if (bytes == null) return null;
    final json = await compute(decodeCsuMasterDataArchive, bytes);
    return CsuMasterData.fromJson(json);
  }

  Future<CsuMasterData> download({ProgressCallback? onReceiveProgress}) async {
    final response = await _http.get<List<int>>(
      csuMasterDataEndpoint,
      options: Options(
        responseType: ResponseType.bytes,
        headers: const {'Accept': 'application/zip'},
      ),
      onReceiveProgress: onReceiveProgress,
    );
    final bytes = response.data;
    if (bytes == null || bytes.isEmpty) {
      throw const FormatException('The master-data archive is empty.');
    }

    // Decode and parse off the UI isolate; large catalogs must not block entry.
    final json = await compute(decodeCsuMasterDataArchive, bytes);
    final masterData = CsuMasterData.fromJson(json);
    await _cache.write(bytes);
    return masterData;
  }
}

/// Isolate entry point for ZIP extraction and JSON decoding.
Map<String, dynamic> decodeCsuMasterDataArchive(List<int> bytes) {
  final archive = ZipDecoder().decodeBytes(
    Uint8List.fromList(bytes),
    verify: true,
    throwOnError: true,
  );

  ArchiveFile? masterDataFile;
  for (final entry in archive) {
    final leafName = entry.name.split('/').last.toLowerCase();
    if (entry.isFile && leafName == 'masterdata.txt') {
      masterDataFile = entry;
      break;
    }
  }
  if (masterDataFile == null) {
    throw const FormatException('The ZIP does not contain MasterData.txt.');
  }
  if (masterDataFile.size > 64 * 1024 * 1024) {
    throw const FormatException('MasterData.txt exceeds the 64 MB limit.');
  }

  final content = masterDataFile.readBytes();
  if (content == null || content.isEmpty) {
    throw const FormatException('MasterData.txt is empty.');
  }
  final decoded = jsonDecode(utf8.decode(content));
  if (decoded is! Map) {
    throw const FormatException('MasterData.txt must contain a JSON object.');
  }
  return {
    for (final entry in decoded.entries) entry.key.toString(): entry.value,
  };
}
