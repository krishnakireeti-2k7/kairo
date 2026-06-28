import 'dart:io';

import 'package:flutter/services.dart';
import 'package:kairo/features/reports/data/report_repository.dart';
import 'package:path_provider/path_provider.dart';

enum ReportSaveLocation { downloads, selectedLocation }

class ReportDownloadService {
  ReportDownloadService(this._repository, this._fileService);

  static const Duration _downloadTimeout = Duration(seconds: 60);

  final ReportRepository _repository;
  final ReportFileService _fileService;

  Future<ReportSaveLocation> download({
    required String url,
    required String fileName,
  }) async {
    final bytes = await _repository
        .downloadReport(url)
        .timeout(_downloadTimeout);
    return _fileService.savePdf(bytes: bytes, fileName: fileName);
  }
}

class ReportFileService {
  static const MethodChannel _downloadsChannel = MethodChannel(
    'com.example.kairo/report_downloads',
  );

  Future<ReportSaveLocation> savePdf({
    required Uint8List bytes,
    required String fileName,
  }) async {
    if (!Platform.isAndroid) {
      return ReportSaveLocation.selectedLocation;
    }

    final file = await _stagePdf(bytes, fileName);
    final savedToDownloads = await _saveToAndroidDownloads(file, fileName);

    return savedToDownloads
        ? ReportSaveLocation.downloads
        : ReportSaveLocation.selectedLocation;
  }

  Future<File> _stagePdf(Uint8List bytes, String fileName) async {
    final documentsDirectory = await getApplicationDocumentsDirectory();
    final reportsDirectory = Directory(
      '${documentsDirectory.path}${Platform.pathSeparator}reports',
    );
    await reportsDirectory.create(recursive: true);

    final file = File(
      '${reportsDirectory.path}${Platform.pathSeparator}$fileName',
    );
    return file.writeAsBytes(bytes, flush: true);
  }

  Future<bool> _saveToAndroidDownloads(File file, String fileName) async {
    try {
      return await _downloadsChannel.invokeMethod<bool>(
            'savePdfToDownloads',
            <String, String>{'sourcePath': file.path, 'fileName': fileName},
          ) ??
          false;
    } on MissingPluginException {
      return false;
    }
  }
}
