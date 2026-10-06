import 'dart:developer' as dev;
import 'package:flutter_tts/flutter_tts.dart';

class TtsService {
  static final TtsService _instance = TtsService._internal();
  factory TtsService() => _instance;
  TtsService._internal();

  FlutterTts? _flutterTts;
  bool _isInitialized = false;
  bool isEnabled = true;

  Future<void> init() async {
    if (_isInitialized) return;
    try {
      _flutterTts = FlutterTts();
      await _flutterTts!.awaitSpeakCompletion(false);
      try {
        await _flutterTts!.setLanguage("vi-VN");
      } catch (_) {
        try {
          await _flutterTts!.setLanguage("vi");
        } catch (_) {}
      }
      await _flutterTts!.setSpeechRate(0.58); // tốc độ dứt khoát, gọn gàng
      await _flutterTts!.setVolume(1.0);
      await _flutterTts!.setPitch(1.0);
      _isInitialized = true;
    } catch (e) {
      dev.log("Error initializing TTS: $e");
    }
  }

  Future<void> speak(String text) async {
    if (!isEnabled) return;
    try {
      if (!_isInitialized) await init();
      await _flutterTts?.stop();
      await _flutterTts?.speak(text);
    } catch (e) {
      dev.log("Error speaking: $e");
    }
  }

  /// Chuyển đổi mã vận đơn thành từng chữ số/ký tự rời rạc bằng tiếng Việt
  /// Ví dụ: "87214345" -> "tám bảy hai một bốn ba bốn năm"
  /// Tránh việc máy đọc thành "tám mươi bảy triệu..." hay "tám tỉ..."
  static String formatOrderCodeForSpeech(String code) {
    if (code.isEmpty) return '';

    // Làm sạch các dấu gạch ngang, khoảng trắng, dấu chấm
    String clean = code.trim().replaceAll(RegExp(r'[\-_.\s/]'), '');

    // Nếu mã quá dài (hơn 10 ký tự), lấy 8 ký tự cuối để đọc ngắn gọn, nhanh nhất cho thợ đóng hàng
    if (clean.length > 10) {
      clean = clean.substring(clean.length - 8);
    }

    final Map<String, String> digitMap = {
      '0': 'không',
      '1': 'một',
      '2': 'hai',
      '3': 'ba',
      '4': 'bốn',
      '5': 'năm',
      '6': 'sáu',
      '7': 'bảy',
      '8': 'tám',
      '9': 'chín',
    };

    final List<String> spokenWords = [];
    for (int i = 0; i < clean.length; i++) {
      final char = clean[i].toUpperCase();
      if (digitMap.containsKey(char)) {
        spokenWords.add(digitMap[char]!);
      } else {
        spokenWords.add(char);
      }
    }

    return spokenWords.join(' ');
  }

  /// Đọc thông báo bắt đầu quay: đọc từng số một gọn gàng
  Future<void> speakStartRecording({String? orderCode, String? platformName}) async {
    if (orderCode != null && orderCode.isNotEmpty) {
      final spokenDigits = formatOrderCodeForSpeech(orderCode);
      await speak("Bắt đầu quay mã $spokenDigits");
    } else {
      await speak("Bắt đầu quay");
    }
  }

  /// Khi đổi đơn liên tục trong ca đóng hàng
  Future<void> speakOrderSwitched({required String previousOrder, required String newOrder, String? newPlatformName}) async {
    final spokenDigits = formatOrderCodeForSpeech(newOrder);
    await speak("Đổi đơn, quay mã $spokenDigits");
  }

  Future<void> speakStopped() async {
    await speak("Đã lưu video");
  }

  Future<void> stop() async {
    try {
      await _flutterTts?.stop();
    } catch (_) {}
  }
}
