import 'dart:async';
import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:google_mlkit_barcode_scanning/google_mlkit_barcode_scanning.dart';
import '../models/order_record.dart';
import '../services/database_service.dart';
import '../services/storage_service.dart';
import '../services/tts_service.dart';
import '../utils/mlkit_utils.dart';

enum RecorderState {
  uninitialized,
  standby,
  starting,
  recording,
  saving,
}

class RecorderProvider with ChangeNotifier {
  final DatabaseService _dbService = DatabaseService();
  final StorageService _storageService = StorageService();
  final TtsService _ttsService = TtsService();

  CameraController? _cameraController;
  List<CameraDescription> _availableCameras = [];
  int _selectedCameraIndex = 0;
  bool _isFlashOn = false;

  RecorderState _state = RecorderState.uninitialized;
  String _orderType = 'PACKING'; // 'PACKING' or 'RETURN'
  String _platformMode = 'AUTO'; // 'AUTO', 'SHOPEE', 'TIKTOK', 'LAZADA', 'TIKI', 'OTHER'
  String _activePlatform = 'SHOPEE';
  String _currentOrderCode = '';
  int _recordingDuration = 0; // seconds
  Timer? _recordingTimer;

  // ML Kit Scanner
  BarcodeScanner? _barcodeScanner;
  bool _isProcessingFrame = false;
  String? _lastScannedCode;
  DateTime? _lastScanTime;

  String? _errorMessage;

  // Getters
  CameraController? get cameraController => _cameraController;
  RecorderState get state => _state;
  bool get isRecording => _state == RecorderState.recording;
  bool get isStandby => _state == RecorderState.standby;
  bool get isSaving => _state == RecorderState.saving;
  String get orderType => _orderType;
  String get platformMode => _platformMode;
  String get activePlatform => _activePlatform;

  String get activePlatformLabel {
    switch (_activePlatform.toUpperCase()) {
      case 'SHOPEE':
        return 'Shopee';
      case 'TIKTOK':
        return 'TikTok Shop';
      case 'LAZADA':
        return 'Lazada';
      case 'TIKI':
        return 'Tiki';
      default:
        return 'Khác';
    }
  }

  String get currentOrderCode => _currentOrderCode;
  int get recordingDuration => _recordingDuration;
  bool get isFlashOn => _isFlashOn;
  String? get errorMessage => _errorMessage;

  String get formattedDuration {
    final minutes = _recordingDuration ~/ 60;
    final seconds = _recordingDuration % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  void setPlatformMode(String mode) {
    _platformMode = mode;
    if (mode != 'AUTO') {
      _activePlatform = mode;
    }
    notifyListeners();
  }

  void setOrderType(String type) {
    _orderType = type;
    notifyListeners();
  }

  bool _only1DBarcodes = false; // Mặc định quét cả mã vạch 1D và mã QR

  bool get only1DBarcodes => _only1DBarcodes;

  void toggleOnly1DBarcodes() {
    _only1DBarcodes = !_only1DBarcodes;
    _initBarcodeScanner();
    notifyListeners();
  }

  void _initBarcodeScanner() {
    _barcodeScanner?.close();
    if (_only1DBarcodes) {
      // Chỉ nhận diện các chuẩn mã vạch vận đơn 1D
      _barcodeScanner = BarcodeScanner(formats: [
        BarcodeFormat.code128,
        BarcodeFormat.code39,
        BarcodeFormat.ean13,
        BarcodeFormat.ean8,
        BarcodeFormat.upca,
        BarcodeFormat.upce,
      ]);
    } else {
      // Mặc định: Quét tất cả các định dạng mã vận đơn 1D và mã QR
      _barcodeScanner = BarcodeScanner(formats: [
        BarcodeFormat.all,
      ]);
    }
  }

  Future<void> initializeCameras({String type = 'PACKING'}) async {
    _orderType = type;
    _state = RecorderState.uninitialized;
    _errorMessage = null;
    notifyListeners();

    try {
      await _ttsService.init();
      _availableCameras = await availableCameras();
      if (_availableCameras.isEmpty) {
        _errorMessage = 'Không tìm thấy camera trên thiết bị.';
        notifyListeners();
        return;
      }

      _initBarcodeScanner();
      await _initController(_selectedCameraIndex);
    } catch (e) {
      _errorMessage = 'Lỗi khởi tạo camera: $e';
      notifyListeners();
    }
  }

  Future<void> _initController(int cameraIndex) async {
    if (_availableCameras.isEmpty) return;

    final camera = _availableCameras[cameraIndex];
    _cameraController = CameraController(
      camera,
      ResolutionPreset.high, // 720p or 1080p for clear packing details
      enableAudio: true,
      imageFormatGroup: Platform.isAndroid ? ImageFormatGroup.nv21 : ImageFormatGroup.bgra8888,
    );

    try {
      await _cameraController!.initialize();
      _state = RecorderState.standby;
      _isFlashOn = false;
      notifyListeners();

      // Start scanning in standby mode
      _startScanningStream();
    } catch (e) {
      _errorMessage = 'Không thể mở camera: $e';
      notifyListeners();
    }
  }

  void _startScanningStream() {
    if (_cameraController == null || !_cameraController!.value.isInitialized) return;
    if (_cameraController!.value.isStreamingImages) return;

    _cameraController!.startImageStream((CameraImage image) {
      if (_state != RecorderState.standby || _isProcessingFrame) return;
      _processCameraImage(image);
    });
  }

  Future<void> _stopScanningStream() async {
    try {
      if (_cameraController != null && _cameraController!.value.isStreamingImages) {
        await _cameraController!.stopImageStream();
      }
    } catch (e) {
      debugPrint('Error stopping image stream: $e');
    }
  }

  Future<void> _processCameraImage(CameraImage image) async {
    _isProcessingFrame = true;
    try {
      final camera = _availableCameras[_selectedCameraIndex];
      final inputImage = MLKitUtils.inputImageFromCameraImage(
        image,
        camera,
        DeviceOrientation.portraitUp,
      );

      if (inputImage == null || _barcodeScanner == null) return;

      final barcodes = await _barcodeScanner!.processImage(inputImage);
      if (barcodes.isNotEmpty) {
        final code = barcodes.first.rawValue;
        if (code != null && code.trim().isNotEmpty) {
          final cleanCode = code.trim();
          // Debounce scanning
          final now = DateTime.now();
          if (_lastScannedCode == cleanCode &&
              _lastScanTime != null &&
              now.difference(_lastScanTime!).inMilliseconds < 2500) {
            return;
          }

          _lastScannedCode = cleanCode;
          _lastScanTime = now;
          await handleScannedBarcode(cleanCode);
        }
      }
    } catch (e) {
      debugPrint('Error scanning barcode frame: $e');
    } finally {
      _isProcessingFrame = false;
    }
  }

  /// Handles when a barcode is scanned either from camera or external barcode scanner gun
  Future<void> handleScannedBarcode(String code) async {
    final cleanCode = code.trim();
    if (cleanCode.isEmpty) return;
    HapticFeedback.heavyImpact();
    SystemSound.play(SystemSoundType.click);

    if (_state == RecorderState.standby) {
      // Determine platform
      if (_platformMode == 'AUTO') {
        _activePlatform = OrderRecord.detectPlatform(cleanCode);
      } else {
        _activePlatform = _platformMode;
      }
      // START RECORDING
      await _startRecording(cleanCode);
    } else if (_state == RecorderState.recording) {
      // User presented another barcode while recording -> seamless switch to next order!
      if (cleanCode == _currentOrderCode) {
        // Same order code scanned again while recording, ignore
        return;
      }
      await _switchOrderAndContinueRecording(cleanCode);
    }
  }

  Future<void> _startRecording(String orderCode) async {
    if (_cameraController == null || !_cameraController!.value.isInitialized) return;

    _state = RecorderState.starting;
    _currentOrderCode = orderCode;
    notifyListeners();

    // 1. Stop scanning stream first to release camera pipeline
    await _stopScanningStream();

    // 2. Play immediate sound and vibration
    HapticFeedback.heavyImpact();
    SystemSound.play(SystemSoundType.click);

    // 3. TTS Voice announcement in background (non-blocking)
    _ttsService.speakStartRecording(
      orderCode: orderCode,
      platformName: activePlatformLabel,
    );

    try {
      // 3. Start recording
      await _cameraController!.startVideoRecording();
      _state = RecorderState.recording;
      _recordingDuration = 0;
      _startTimer();
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Không thể bắt đầu quay video: $e';
      _state = RecorderState.standby;
      notifyListeners();
      _startScanningStream();
    }
  }

  void _startTimer() {
    _recordingTimer?.cancel();
    _recordingTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _recordingDuration++;
      notifyListeners();
    });
  }

  void _stopTimer() {
    _recordingTimer?.cancel();
    _recordingTimer = null;
  }

  /// Stops current recording and saves video to SQLite and storage
  Future<OrderRecord?> stopAndSaveRecording() async {
    if (_state != RecorderState.recording || _cameraController == null) return null;

    _stopTimer();
    _state = RecorderState.saving;
    notifyListeners();

    try {
      final XFile rawVideoFile = await _cameraController!.stopVideoRecording();
      final destinationPath = await _storageService.generateVideoPath(
        orderType: _orderType,
        orderCode: _currentOrderCode,
      );

      // Move or copy file to permanent location
      final permanentFile = await File(rawVideoFile.path).copy(destinationPath);
      final fileSize = await permanentFile.length();

      // Clean temp file
      try {
        await File(rawVideoFile.path).delete();
      } catch (_) {}

      final newRecord = OrderRecord(
        orderCode: _currentOrderCode,
        type: _orderType,
        platform: _activePlatform,
        videoPath: destinationPath,
        fileSize: fileSize,
        durationSeconds: _recordingDuration,
        createdAt: DateTime.now(),
      );

      await _dbService.insertOrder(newRecord);
      await _ttsService.speakStopped();

      _state = RecorderState.standby;
      _currentOrderCode = '';
      _recordingDuration = 0;
      notifyListeners();

      // Re-enable camera scanning for the next order
      _startScanningStream();

      return newRecord;
    } catch (e) {
      _errorMessage = 'Lỗi khi lưu video: $e';
      _state = RecorderState.standby;
      notifyListeners();
      _startScanningStream();
      return null;
    }
  }

  /// Fast switch: Saves current order video and immediately begins recording next order video
  Future<void> _switchOrderAndContinueRecording(String nextOrderCode) async {
    if (_state != RecorderState.recording || _cameraController == null) return;

    _stopTimer();
    final previousCode = _currentOrderCode;
    final previousDuration = _recordingDuration;
    final previousPlatform = _activePlatform;

    _state = RecorderState.saving;
    notifyListeners();

    try {
      final XFile rawVideoFile = await _cameraController!.stopVideoRecording();
      final destinationPath = await _storageService.generateVideoPath(
        orderType: _orderType,
        orderCode: previousCode,
      );

      final permanentFile = await File(rawVideoFile.path).copy(destinationPath);
      final fileSize = await permanentFile.length();

      try {
        await File(rawVideoFile.path).delete();
      } catch (_) {}

      final oldRecord = OrderRecord(
        orderCode: previousCode,
        type: _orderType,
        platform: previousPlatform,
        videoPath: destinationPath,
        fileSize: fileSize,
        durationSeconds: previousDuration,
        createdAt: DateTime.now(),
      );

      await _dbService.insertOrder(oldRecord);

      // Announce and start new order
      _currentOrderCode = nextOrderCode;
      _recordingDuration = 0;
      if (_platformMode == 'AUTO') {
        _activePlatform = OrderRecord.detectPlatform(nextOrderCode);
      } else {
        _activePlatform = _platformMode;
      }
      await _ttsService.speakOrderSwitched(
        previousOrder: previousCode,
        newOrder: nextOrderCode,
        newPlatformName: activePlatformLabel,
      );

      // Start recording next video
      await _cameraController!.startVideoRecording();
      _state = RecorderState.recording;
      _startTimer();
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Lỗi chuyển đơn: $e';
      _state = RecorderState.standby;
      notifyListeners();
      _startScanningStream();
    }
  }

  Future<void> toggleFlash() async {
    if (_cameraController == null || !_cameraController!.value.isInitialized) return;
    try {
      if (_isFlashOn) {
        await _cameraController!.setFlashMode(FlashMode.off);
        _isFlashOn = false;
      } else {
        await _cameraController!.setFlashMode(FlashMode.torch);
        _isFlashOn = true;
      }
      notifyListeners();
    } catch (e) {
      debugPrint('Error toggling flash: $e');
    }
  }

  Future<void> switchCamera() async {
    if (_availableCameras.length < 2) return;
    if (_state == RecorderState.recording) return; // Do not switch during active recording

    await _stopScanningStream();
    _selectedCameraIndex = (_selectedCameraIndex + 1) % _availableCameras.length;
    await _initController(_selectedCameraIndex);
  }

  @override
  void dispose() {
    _stopTimer();
    _stopScanningStream();
    _barcodeScanner?.close();
    _cameraController?.dispose();
    super.dispose();
  }
}
