import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class OrderRecord {
  final int? id;
  final String orderCode;
  final String type; // 'PACKING' (Đóng đơn) or 'RETURN' (Hoàn đơn)
  final String platform; // 'SHOPEE', 'TIKTOK', 'LAZADA', 'TIKI', 'OTHER'
  final String videoPath;
  final int fileSize; // bytes
  final int durationSeconds; // seconds
  final DateTime createdAt;
  final String note;

  OrderRecord({
    this.id,
    required this.orderCode,
    required this.type,
    this.platform = 'SHOPEE',
    required this.videoPath,
    required this.fileSize,
    required this.durationSeconds,
    required this.createdAt,
    this.note = '',
  });

  bool get isPacking => type == 'PACKING';
  bool get isReturn => type == 'RETURN';

  String get typeLabel => isPacking ? 'Đóng đơn' : 'Hàng hoàn';

  String get platformLabel {
    switch (platform.toUpperCase()) {
      case 'SHOPEE':
        return 'Shopee';
      case 'TIKTOK':
        return 'TikTok Shop';
      case 'LAZADA':
        return 'Lazada';
      case 'TIKI':
        return 'Tiki';
      default:
        return 'Ngoài sàn / Khác';
    }
  }

  Color get platformColor {
    switch (platform.toUpperCase()) {
      case 'SHOPEE':
        return const Color(0xFFEE4D2D); // Shopee Orange
      case 'TIKTOK':
        return const Color(0xFFFE2C55); // TikTok Pink-Red
      case 'LAZADA':
        return const Color(0xFF1E88E5); // Lazada Blue
      case 'TIKI':
        return const Color(0xFF0D5CB6); // Tiki Blue
      default:
        return const Color(0xFF9E9E9E); // Grey
    }
  }

  IconData get platformIcon {
    switch (platform.toUpperCase()) {
      case 'SHOPEE':
        return Icons.shopping_bag_outlined;
      case 'TIKTOK':
        return Icons.music_note_rounded;
      case 'LAZADA':
        return Icons.local_mall_outlined;
      case 'TIKI':
        return Icons.storefront_outlined;
      default:
        return Icons.local_shipping_outlined;
    }
  }

  static String detectPlatform(String code) {
    final upper = code.trim().toUpperCase();
    if (upper.startsWith('SPX') ||
        upper.startsWith('SPS') ||
        upper.contains('SHOPEE') ||
        upper.startsWith('VN0') ||
        upper.startsWith('VNP')) {
      return 'SHOPEE';
    } else if (upper.startsWith('TTS') ||
        upper.startsWith('TT') ||
        upper.contains('TIKTOK') ||
        upper.startsWith('JNT') ||
        upper.startsWith('JT')) {
      return 'TIKTOK';
    } else if (upper.startsWith('LEX') ||
        upper.contains('LZD') ||
        upper.contains('LAZADA') ||
        upper.startsWith('NLV') ||
        upper.startsWith('MP')) {
      return 'LAZADA';
    } else if (upper.startsWith('TIKI') || upper.startsWith('TK')) {
      return 'TIKI';
    }
    return 'OTHER';
  }

  String get formattedDuration {
    final minutes = durationSeconds ~/ 60;
    final seconds = durationSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  String get formattedDate {
    return DateFormat('HH:mm - dd/MM/yyyy').format(createdAt);
  }

  String get formattedTime {
    return DateFormat('HH:mm').format(createdAt);
  }

  String get formattedDateOnly {
    return DateFormat('dd/MM/yyyy').format(createdAt);
  }

  String get formattedFileSize {
    if (fileSize < 1024 * 1024) {
      return '${(fileSize / 1024).toStringAsFixed(1)} KB';
    } else if (fileSize < 1024 * 1024 * 1024) {
      return '${(fileSize / (1024 * 1024)).toStringAsFixed(1)} MB';
    } else {
      return '${(fileSize / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
    }
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'order_code': orderCode,
      'type': type,
      'platform': platform,
      'video_path': videoPath,
      'file_size': fileSize,
      'duration_seconds': durationSeconds,
      'created_at': createdAt.toIso8601String(),
      'note': note,
    };
  }

  factory OrderRecord.fromMap(Map<String, dynamic> map) {
    return OrderRecord(
      id: map['id'] as int?,
      orderCode: map['order_code'] as String? ?? '',
      type: map['type'] as String? ?? 'PACKING',
      platform: map['platform'] as String? ?? 'SHOPEE',
      videoPath: map['video_path'] as String? ?? '',
      fileSize: (map['file_size'] as num?)?.toInt() ?? 0,
      durationSeconds: (map['duration_seconds'] as num?)?.toInt() ?? 0,
      createdAt: DateTime.tryParse(map['created_at'] as String? ?? '') ?? DateTime.now(),
      note: map['note'] as String? ?? '',
    );
  }

  OrderRecord copyWith({
    int? id,
    String? orderCode,
    String? type,
    String? platform,
    String? videoPath,
    int? fileSize,
    int? durationSeconds,
    DateTime? createdAt,
    String? note,
  }) {
    return OrderRecord(
      id: id ?? this.id,
      orderCode: orderCode ?? this.orderCode,
      type: type ?? this.type,
      platform: platform ?? this.platform,
      videoPath: videoPath ?? this.videoPath,
      fileSize: fileSize ?? this.fileSize,
      durationSeconds: durationSeconds ?? this.durationSeconds,
      createdAt: createdAt ?? this.createdAt,
      note: note ?? this.note,
    );
  }
}
