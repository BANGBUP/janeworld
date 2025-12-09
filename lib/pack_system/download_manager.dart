import 'dart:async';
import 'dart:io';

import 'package:dio/dio.dart';

import '../data/datasources/local/pack_file_manager.dart';

/// 다운로드 상태
enum DownloadStatus {
  pending,
  starting,
  downloading,
  paused,
  completed,
  cancelled,
  failed,
}

/// 다운로드 진행률
class DownloadProgress {
  final String packId;
  final DownloadStatus status;
  final int downloadedBytes;
  final int totalBytes;
  final String? error;

  const DownloadProgress({
    required this.packId,
    required this.status,
    required this.downloadedBytes,
    required this.totalBytes,
    this.error,
  });

  double get percentage =>
      totalBytes > 0 ? (downloadedBytes / totalBytes) * 100 : 0;

  String get formattedProgress =>
      '${(downloadedBytes / 1024 / 1024).toStringAsFixed(1)} / '
      '${(totalBytes / 1024 / 1024).toStringAsFixed(1)} MB';

  DownloadProgress copyWith({
    String? packId,
    DownloadStatus? status,
    int? downloadedBytes,
    int? totalBytes,
    String? error,
  }) {
    return DownloadProgress(
      packId: packId ?? this.packId,
      status: status ?? this.status,
      downloadedBytes: downloadedBytes ?? this.downloadedBytes,
      totalBytes: totalBytes ?? this.totalBytes,
      error: error ?? this.error,
    );
  }
}

/// 다운로드 관리자
class DownloadManager {
  final Dio _dio;
  final PackFileManager _fileManager;

  final Map<String, CancelToken> _activeDownloads = {};
  final Map<String, StreamController<DownloadProgress>> _progressStreams = {};

  DownloadManager({
    required Dio dio,
    required PackFileManager fileManager,
  })  : _dio = dio,
        _fileManager = fileManager;

  /// 다운로드 시작
  Stream<DownloadProgress> download({
    required String url,
    required String packId,
    required int expectedSize,
  }) async* {
    // 이미 다운로드 중이면 기존 스트림 반환
    if (_activeDownloads.containsKey(packId)) {
      if (_progressStreams.containsKey(packId)) {
        yield* _progressStreams[packId]!.stream;
        return;
      }
    }

    final controller = StreamController<DownloadProgress>.broadcast();
    _progressStreams[packId] = controller;

    final cancelToken = CancelToken();
    _activeDownloads[packId] = cancelToken;

    final tempPath = _fileManager.getDownloadTempPath(packId);

    try {
      yield DownloadProgress(
        packId: packId,
        status: DownloadStatus.starting,
        downloadedBytes: 0,
        totalBytes: expectedSize,
      );

      controller.add(DownloadProgress(
        packId: packId,
        status: DownloadStatus.starting,
        downloadedBytes: 0,
        totalBytes: expectedSize,
      ));

      int downloadedBytes = 0;

      await _dio.download(
        url,
        tempPath,
        cancelToken: cancelToken,
        onReceiveProgress: (received, total) {
          downloadedBytes = received;
          final progress = DownloadProgress(
            packId: packId,
            status: DownloadStatus.downloading,
            downloadedBytes: received,
            totalBytes: total > 0 ? total : expectedSize,
          );
          controller.add(progress);
        },
        options: Options(
          headers: {
            'Accept-Encoding': 'identity',
          },
        ),
      );

      // 다운로드 완료
      final finalProgress = DownloadProgress(
        packId: packId,
        status: DownloadStatus.completed,
        downloadedBytes: downloadedBytes,
        totalBytes: downloadedBytes,
      );
      controller.add(finalProgress);
      yield finalProgress;

    } on DioException catch (e) {
      DownloadProgress errorProgress;

      if (CancelToken.isCancel(e)) {
        errorProgress = DownloadProgress(
          packId: packId,
          status: DownloadStatus.cancelled,
          downloadedBytes: 0,
          totalBytes: expectedSize,
        );
      } else {
        errorProgress = DownloadProgress(
          packId: packId,
          status: DownloadStatus.failed,
          downloadedBytes: 0,
          totalBytes: expectedSize,
          error: e.message ?? 'Download failed',
        );
      }

      controller.add(errorProgress);
      yield errorProgress;

    } catch (e) {
      final errorProgress = DownloadProgress(
        packId: packId,
        status: DownloadStatus.failed,
        downloadedBytes: 0,
        totalBytes: expectedSize,
        error: e.toString(),
      );
      controller.add(errorProgress);
      yield errorProgress;

    } finally {
      _activeDownloads.remove(packId);
      _progressStreams.remove(packId);
      await controller.close();
    }
  }

  /// 다운로드 취소
  void cancel(String packId) {
    _activeDownloads[packId]?.cancel();
  }

  /// 다운로드 중인지 확인
  bool isDownloading(String packId) {
    return _activeDownloads.containsKey(packId);
  }

  /// 다운로드 진행률 스트림
  Stream<DownloadProgress>? getProgressStream(String packId) {
    return _progressStreams[packId]?.stream;
  }

  /// 임시 파일 정리
  Future<void> cleanup(String packId) async {
    await _fileManager.cleanupDownload(packId);
  }

  /// 다운로드 경로
  String getDownloadPath(String packId) {
    return _fileManager.getDownloadTempPath(packId);
  }

  /// 다운로드 파일 존재 확인
  Future<bool> hasDownloadedFile(String packId) async {
    final path = _fileManager.getDownloadTempPath(packId);
    return await File(path).exists();
  }
}
