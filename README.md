# Ứng Dụng Quay Video Đóng Hàng & Hoàn Hàng Tự Động (Order Packer Pro)

Ứng dụng Android APK viết bằng **Flutter (Dart)** với giao diện **Dark Mode** cao cấp, chuyên dụng cho chủ shop và nhân viên kho hàng (Shopee, TikTok Shop, Lazada, sàn TMĐT).

---

## 🚀 Các Tính Năng Đã Triển Khai Hoàn Tất

1. **Quét mã vạch tự động & Khởi động quay tức thì**:
   - Tích hợp nhận diện mã vạch đa định dạng qua camera (Code 128, Code 39, QR Code, EAN-13, v.v.).
   - Hỗ trợ thêm súng quét barcode (USB OTG / Bluetooth) hoặc nhập mã thủ công.
2. **Phát âm thanh & giọng nói Tiếng Việt (Text-to-Speech)**:
   - Khi nhận diện mã đơn thành công: Tự động phát âm thanh tiếng Việt *"Bắt đầu quay video [mã đơn]"* hoặc *"Bắt đầu quay video"*.
   - Thông báo khi dừng hoặc chuyển đơn: *"Đã lưu đơn trước. Bắt đầu quay video đơn mới"*.
3. **Luồng quay video rảnh tay & Chuyển đơn liên tục (Continuous Packing Flow)**:
   - **Đóng xong 1 đơn**: Người dùng có thể nhấn nút **Dừng & Lưu Đơn** HOẶC **quét mã đơn tiếp theo**.
   - Khi quét mã đơn mới trong lúc đang quay: Hệ thống tự động lưu video đơn cũ vào máy, thông báo giọng nói và quay ngay đơn mới mà không cần thao tác bấm nút.
4. **2 Chế độ chuyên biệt**:
   - 📦 **Đóng đơn (Packing)**: Lưu video gói hàng làm bằng chứng gửi hàng chuẩn.
   - 🔄 **Hàng hoàn (Return)**: Lưu video khui kiện hàng hoàn về làm bằng chứng khiếu nại bồi hoàn.
5. **Quản lý đơn hàng & Video (SQLite Database)**:
   - Tìm kiếm nhanh theo mã vận đơn.
   - Bộ lọc theo loại đơn (Đóng đơn / Hàng hoàn).
   - Xem lại video trực tiếp với trình phát video tích hợp.
   - Thêm ghi chú sự cố (hàng móp, đóng seal 2 lớp,...).
   - Chia sẻ video nhanh qua Zalo, Messenger, Telegram, Google Drive.
6. **Thống kê & Quản lý bộ nhớ**:
   - Thống kê số lượng đơn đóng trong ngày, số đơn hoàn trong ngày, tổng dung lượng bộ nhớ video.
   - Dark Theme tối ưu bảo vệ mắt nhân viên kho và tiết kiệm pin.

---

## 🛠️ Hướng Dẫn Build File APK

Để xuất file `.apk` cài đặt trực tiếp lên điện thoại Android:

```bash
# Build APK Release (Khuyến nghị để cài lên điện thoại)
flutter build apk --release
```

Sau khi build xong, file APK sẽ nằm tại đường dẫn:
`build/app/outputs/flutter-apk/app-release.apk`

---

## 📱 Cấu Trúc Mã Nguồn

```
lib/
├── main.dart                          # Khởi tạo App, Theme Dark Mode & Providers
├── models/
│   └── order_record.dart              # Model dữ liệu đơn hàng & video
├── services/
│   ├── database_service.dart          # SQLite quản lý lịch sử đơn và file video
│   ├── tts_service.dart               # Text-to-Speech phát giọng nói Tiếng Việt
│   ├── storage_service.dart           # Quản lý đường dẫn lưu file video mp4 và bộ nhớ
├── providers/
│   ├── order_provider.dart            # Quản lý state danh sách đơn, tìm kiếm, lọc
│   └── recorder_provider.dart         # Quản lý camera, quét mã vạch, tự động quay & chuyển đơn
├── screens/
│   ├── home_screen.dart               # Dashboard chính, thống kê, thẻ chọn Đóng/Hoàn đơn
│   ├── recorder_screen.dart           # Màn hình Camera quay video + quét mã vạch tự động
│   ├── order_list_screen.dart         # Danh sách quản lý đơn hàng & tìm kiếm mã vận đơn
│   ├── video_player_screen.dart       # Trình xem lại video + ghi chú + chia sẻ Zalo/Drive
│   └── settings_screen.dart           # Cài đặt âm thanh giọng nói, dung lượng bộ nhớ
├── widgets/
│   ├── barcode_reticle.dart           # Khung ngắm laser quét mã vạch chuyên nghiệp
│   └── order_card_item.dart           # Thẻ hiển thị đơn hàng trong danh sách
└── utils/
    └── mlkit_utils.dart               # Tiện ích chuyển đổi khung hình camera sang ML Kit
```
