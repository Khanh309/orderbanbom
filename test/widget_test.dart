import 'package:flutter_test/flutter_test.dart';
import 'package:order_packer_app/models/order_record.dart';

void main() {
  test('OrderRecord model test', () {
    final record = OrderRecord(
      id: 1,
      orderCode: 'SPX-VN019283',
      type: 'PACKING',
      platform: 'SHOPEE',
      videoPath: '/path/to/video.mp4',
      fileSize: 1048576 * 5, // 5 MB
      durationSeconds: 95,
      createdAt: DateTime(2026, 10, 5, 10, 30),
      note: 'Hàng dễ vỡ',
    );

    expect(record.isPacking, true);
    expect(record.isReturn, false);
    expect(record.platform, 'SHOPEE');
    expect(record.platformLabel, 'Shopee');
    expect(record.typeLabel, 'Đóng đơn');
    expect(record.formattedDuration, '01:35');
    expect(record.formattedFileSize, '5.0 MB');
    expect(record.orderCode, 'SPX-VN019283');

    // Test platform detection
    expect(OrderRecord.detectPlatform('SPX123456'), 'SHOPEE');
    expect(OrderRecord.detectPlatform('TTS987654'), 'TIKTOK');
    expect(OrderRecord.detectPlatform('LEX888888'), 'LAZADA');

    final map = record.toMap();
    expect(map['order_code'], 'SPX-VN019283');
    expect(map['type'], 'PACKING');
    expect(map['platform'], 'SHOPEE');

    final reconstructed = OrderRecord.fromMap(map);
    expect(reconstructed.orderCode, record.orderCode);
    expect(reconstructed.platform, 'SHOPEE');
    expect(reconstructed.fileSize, record.fileSize);
  });
}
