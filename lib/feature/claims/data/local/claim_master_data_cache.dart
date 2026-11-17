import 'dart:convert';
import 'dart:io';
import 'dart:isolate';

import 'package:openimis_claim_policy_app/feature/claims/models/claim_master_data.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

class ClaimMasterDataCache {
  const ClaimMasterDataCache({Future<Directory> Function()? directory})
    : _directory = directory;

  final Future<Directory> Function()? _directory;

  static const _fileName = 'claim_master_data.json';

  Future<void> save(ClaimMasterData data) async {
    final file = await _file();
    final temporary = File('${file.path}.download');
    final payload = data.toJson();
    final encoded = await Isolate.run(() => jsonEncode(payload));
    await temporary.writeAsString(encoded, flush: true);
    if (await file.exists()) await file.delete();
    await temporary.rename(file.path);
  }

  Future<ClaimMasterData?> load(String claimAdministratorCode) async {
    final file = await _file();
    if (!await file.exists()) return null;
    try {
      final source = await file.readAsString();
      final data = await Isolate.run(
        () => ClaimMasterData.fromJson(
          Map<String, dynamic>.from(jsonDecode(source) as Map),
        ),
      );
      return data.administrator.code.toLowerCase() ==
              claimAdministratorCode.trim().toLowerCase()
          ? data
          : null;
    } catch (_) {
      return null;
    }
  }

  Future<File> _file() async {
    final directory =
        await (_directory?.call() ?? getApplicationSupportDirectory());
    await directory.create(recursive: true);
    return File(p.join(directory.path, _fileName));
  }
}
