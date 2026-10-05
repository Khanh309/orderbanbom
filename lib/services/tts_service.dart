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
      await _flutterTts!.setLanguage("vi-VN");
      await _flutterTts!.setSpeechRate(0.55); // natural speed
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

  /// Exact voice prompt: announce recording start with platform name and order code
  Future<void> speakStartRecording({String? orderCode, String? platformName}) async {
    if (orderCode != null && orderCode.isNotEmpty) {
      if (platformName != null && platformName.isNotEmpty) {
        await speak("Bắt đầu quay video đơn $platformName, mã $orderCode");
      } else {
        await speak("Bắt đầu quay video mã đơn $orderCode");
      }
    } else {
      await speak("Bắt đầu quay video");
    }
  }

  Future<void> speakOrderSwitched({required String previousOrder, required String newOrder, String? newPlatformName}) async {
    if (newPlatformName != null && newPlatformName.isNotEmpty) {
      await speak("Đã lưu đơn trước. Bắt đầu quay video đơn $newPlatformName $newOrder");
    } else {
      await speak("Đã lưu đơn trước. Bắt đầu quay video đơn mới $newOrder");
    }
  }

  Future<void> speakStopped() async {
    await speak("Đã dừng và lưu video");
  }

  Future<void> stop() async {
    try {
      await _flutterTts?.stop();
    } catch (_) {}
  }
}
