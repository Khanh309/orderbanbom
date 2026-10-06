import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:gal/gal.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:intl/intl.dart';

class StorageService {
  static final StorageService _instance = StorageService._internal();
  factory StorageService() => _instance;
  StorageService._internal();

  /// Tự động đồng bộ và lưu video vào Bộ sưu tập / Thư viện ảnh (Gallery) của máy trong album "OrderBanBom"
  Future<bool> saveToGallery(String videoPath) async {
    try {
      final file = File(videoPath);
      if (!await file.exists()) return false;

      final hasAccess = await Gal.hasAccess();
      if (!hasAccess) {
        await Gal.requestAccess();
      }

      await Gal.putVideo(videoPath, album: 'OrderBanBom');
      debugPrint('Successfully saved video to phone Gallery album OrderBanBom: $videoPath');
      return true;
    } catch (e) {
      debugPrint('Error saving video to phone Gallery: $e');
      return false;
    }
  }

  Future<Directory> getVideoDirectory() async {
    final appDir = await getApplicationDocumentsDirectory();
    final videoDir = Directory(p.join(appDir.path, 'order_videos'));
    if (!await videoDir.exists()) {
      await videoDir.create(recursive: true);
    }
    return videoDir;
  }

  Future<String> generateVideoPath({
    required String orderType,
    required String orderCode,
  }) async {
    final dir = await getVideoDirectory();
    final cleanCode = orderCode.replaceAll(RegExp(r'[^a-zA-Z0-9_\-]'), '_');
    final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
    final fileName = '${orderType}_${cleanCode}_$timestamp.mp4';
    return p.join(dir.path, fileName);
  }

  Future<int> getFileSize(String filePath) async {
    try {
      final file = File(filePath);
      if (await file.exists()) {
        return await file.length();
      }
    } catch (_) {}
    return 0;
  }

  Future<bool> deleteVideoFile(String filePath) async {
    try {
      final file = File(filePath);
      if (await file.exists()) {
        await file.delete();
        return true;
      }
    } catch (_) {}
    return false;
  }

  Future<int> getTotalVideoStorageBytes() async {
    try {
      final dir = await getVideoDirectory();
      int total = 0;
      await for (final entity in dir.list(recursive: false, followLinks: false)) {
        if (entity is File) {
          total += await entity.length();
        }
      }
      return total;
    } catch (_) {
      return 0;
    }
  }

  String formatBytes(int bytes) {
    if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    } else if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    } else {
      return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
    }
  }
}
