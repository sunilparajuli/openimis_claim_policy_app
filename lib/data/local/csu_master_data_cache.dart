import 'dart:io';

import 'package:path_provider/path_provider.dart';

/// Keeps the original backend ZIP so offline startup can parse the same
/// versioned source document that was downloaded.
class CsuMasterDataCache {
  CsuMasterDataCache({Future<Directory> Function()? directoryProvider})
    : _directoryProvider = directoryProvider ?? getApplicationSupportDirectory;

  static const _archiveFileName = 'csu_master_data.zip';

  final Future<Directory> Function() _directoryProvider;

  Future<List<int>?> read() async {
    final file = await _archiveFile();
    if (!await file.exists()) return null;
    return file.readAsBytes();
  }

  Future<void> write(List<int> bytes) async {
    final file = await _archiveFile();
    await file.parent.create(recursive: true);
    final temporary = File('${file.path}.download');
    await temporary.writeAsBytes(bytes, flush: true);
    await temporary.rename(file.path);
  }

  Future<File> _archiveFile() async {
    final directory = await _directoryProvider();
    return File('${directory.path}/$_archiveFileName');
  }
}
