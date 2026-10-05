import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/recorder_provider.dart';
import '../providers/order_provider.dart';
import '../widgets/barcode_reticle.dart';
import 'video_player_screen.dart';

class RecorderScreen extends StatefulWidget {
  final String initialType; // 'PACKING' or 'RETURN'

  const RecorderScreen({super.key, this.initialType = 'PACKING'});

  @override
  State<RecorderScreen> createState() => _RecorderScreenState();
}

class _RecorderScreenState extends State<RecorderScreen> with SingleTickerProviderStateMixin {
  final TextEditingController _manualCodeController = TextEditingController();
  final FocusNode _keyboardFocusNode = FocusNode();
  String _hardwareScanBuffer = '';
  DateTime _lastHardwareScanKeyTime = DateTime.now();

  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 0.8, end: 1.2).animate(_pulseController);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final recorder = context.read<RecorderProvider>();
      recorder.initializeCameras(type: widget.initialType);
      _keyboardFocusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _manualCodeController.dispose();
    _keyboardFocusNode.dispose();
    super.dispose();
  }

  /// Handles hardware barcode scanner gun input (USB/Bluetooth HID keyboard emulation)
  void _handleHardwareKey(KeyEvent event) {
    if (event is KeyDownEvent) {
      final now = DateTime.now();
      // Hardware scanners typically type characters within 50ms intervals
      if (now.difference(_lastHardwareScanKeyTime).inMilliseconds > 200) {
        _hardwareScanBuffer = '';
      }
      _lastHardwareScanKeyTime = now;

      if (event.logicalKey == LogicalKeyboardKey.enter) {
        if (_hardwareScanBuffer.trim().isNotEmpty) {
          final scannedCode = _hardwareScanBuffer.trim();
          _hardwareScanBuffer = '';
          HapticFeedback.heavyImpact();
          context.read<RecorderProvider>().handleScannedBarcode(scannedCode);
        }
      } else if (event.character != null && event.character!.isNotEmpty) {
        _hardwareScanBuffer += event.character!;
      }
    }
  }

  void _showManualInputDialog(BuildContext context) {
    _manualCodeController.clear();
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: const Color(0xFF1E232B),
        title: const Text('Nhập mã đơn hàng', style: TextStyle(color: Colors.white, fontSize: 18)),
        content: TextField(
          controller: _manualCodeController,
          autofocus: true,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: 'VD: SPX-VN89382910',
            hintStyle: TextStyle(color: Colors.grey.shade600),
            filled: true,
            fillColor: const Color(0xFF121418),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Color(0xFF00E676)),
            ),
          ),
          onSubmitted: (value) {
            Navigator.pop(dialogCtx);
            if (value.trim().isNotEmpty) {
              context.read<RecorderProvider>().handleScannedBarcode(value.trim());
            }
          },
        ),
        actions: [
          TextButton(
            child: const Text('Hủy', style: TextStyle(color: Colors.grey)),
            onPressed: () => Navigator.pop(dialogCtx),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF00E676)),
            child: const Text('Bắt đầu quay', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
            onPressed: () {
              final code = _manualCodeController.text.trim();
              Navigator.pop(dialogCtx);
              if (code.isNotEmpty) {
                context.read<RecorderProvider>().handleScannedBarcode(code);
              }
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final recorder = context.watch<RecorderProvider>();
    final isPacking = recorder.orderType == 'PACKING';
    final themeColor = isPacking ? const Color(0xFF00E676) : const Color(0xFFFF5722);

    return KeyboardListener(
      focusNode: _keyboardFocusNode,
      onKeyEvent: _handleHardwareKey,
      child: Scaffold(
        backgroundColor: Colors.black,
        body: Stack(
          children: [
            // 1. Camera Preview
            if (recorder.cameraController != null && recorder.cameraController!.value.isInitialized)
              Positioned.fill(
                child: FittedBox(
                  fit: BoxFit.cover,
                  child: SizedBox(
                    width: recorder.cameraController!.value.previewSize?.height ?? 1080,
                    height: recorder.cameraController!.value.previewSize?.width ?? 1920,
                    child: CameraPreview(recorder.cameraController!),
                  ),
                ),
              )
            else
              Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const CircularProgressIndicator(color: Color(0xFF00E676)),
                    const SizedBox(height: 16),
                    Text(
                      recorder.errorMessage ?? 'Đang khởi động Camera & Máy quét...',
                      style: const TextStyle(color: Colors.white, fontSize: 14),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),

            // 2. Barcode Reticle (Overlay scan frame in standby)
            Positioned.fill(
              child: BarcodeReticle(
                isRecording: recorder.isRecording,
                orderCode: recorder.currentOrderCode,
              ),
            ),

            // 3. Top Status & Controls Bar
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Close / Back button
                        IconButton(
                          style: IconButton.styleFrom(
                            backgroundColor: Colors.black54,
                          ),
                          icon: const Icon(Icons.arrow_back, color: Colors.white),
                          onPressed: () async {
                            if (recorder.isRecording) {
                              final confirm = await showDialog<bool>(
                                context: context,
                                builder: (ctx) => AlertDialog(
                                  backgroundColor: const Color(0xFF1E232B),
                                  title: const Text('Đang quay video!', style: TextStyle(color: Colors.white)),
                                  content: const Text('Bạn có muốn dừng và lưu video trước khi thoát?'),
                                  actions: [
                                    TextButton(
                                      child: const Text('Hủy bỏ', style: TextStyle(color: Colors.grey)),
                                      onPressed: () => Navigator.pop(ctx, false),
                                    ),
                                    ElevatedButton(
                                      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF00E676)),
                                      child: const Text('Lưu & Thoát', style: TextStyle(color: Colors.black)),
                                      onPressed: () => Navigator.pop(ctx, true),
                                    ),
                                  ],
                                ),
                              );
                              if (confirm == true && context.mounted) {
                                final saved = await recorder.stopAndSaveRecording();
                                if (saved != null && context.mounted) {
                                  context.read<OrderProvider>().loadOrders();
                                }
                                if (context.mounted) Navigator.pop(context);
                              }
                            } else {
                              Navigator.pop(context);
                            }
                          },
                        ),

                        // Mode Selector / Indicator
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.black87,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: themeColor, width: 1.5),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                isPacking ? Icons.inventory_2_rounded : Icons.assignment_return_rounded,
                                color: themeColor,
                                size: 18,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                isPacking ? 'ĐÓNG ĐƠN HÀNG' : 'KIỂM HÀNG HOÀN',
                                style: TextStyle(
                                  color: themeColor,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Flash, 1D/QR barcode toggle & Camera flip buttons
                        Row(
                          children: [
                            IconButton(
                              style: IconButton.styleFrom(backgroundColor: Colors.black54),
                              tooltip: recorder.only1DBarcodes ? 'Đang bật: Chỉ quét mã vạch 1D vận đơn' : 'Đang bật: Quét cả mã QR',
                              icon: Icon(
                                recorder.only1DBarcodes ? Icons.barcode_reader : Icons.qr_code,
                                color: recorder.only1DBarcodes ? const Color(0xFF00E676) : Colors.white,
                              ),
                              onPressed: recorder.toggleOnly1DBarcodes,
                            ),
                            const SizedBox(width: 8),
                            IconButton(
                              style: IconButton.styleFrom(backgroundColor: Colors.black54),
                              icon: Icon(
                                recorder.isFlashOn ? Icons.flash_on : Icons.flash_off,
                                color: recorder.isFlashOn ? Colors.amber : Colors.white,
                              ),
                              onPressed: recorder.toggleFlash,
                            ),
                            const SizedBox(width: 8),
                            if (!recorder.isRecording)
                              IconButton(
                                style: IconButton.styleFrom(backgroundColor: Colors.black54),
                                icon: const Icon(Icons.flip_camera_android, color: Colors.white),
                                onPressed: recorder.switchCamera,
                              ),
                          ],
                        ),
                      ],
                    ),

                    const SizedBox(height: 10),

                    // Platform Selector (When in standby)
                    if (!recorder.isRecording)
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            _buildPlatformPill('⚡ Tự động sàn', 'AUTO', recorder),
                            const SizedBox(width: 6),
                            _buildPlatformPill('Shopee', 'SHOPEE', recorder, color: const Color(0xFFEE4D2D)),
                            const SizedBox(width: 6),
                            _buildPlatformPill('TikTok Shop', 'TIKTOK', recorder, color: const Color(0xFFFE2C55)),
                            const SizedBox(width: 6),
                            _buildPlatformPill('Lazada', 'LAZADA', recorder, color: const Color(0xFF1E88E5)),
                            const SizedBox(width: 6),
                            _buildPlatformPill('Tiki', 'TIKI', recorder, color: const Color(0xFF0D5CB6)),
                            const SizedBox(width: 6),
                            _buildPlatformPill('Khác', 'OTHER', recorder, color: const Color(0xFF9E9E9E)),
                          ],
                        ),
                      ),

                    const SizedBox(height: 10),

                    // Active Recording Banner
                    if (recorder.isRecording)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        decoration: BoxDecoration(
                          color: Colors.black87,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.redAccent, width: 1.5),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                ScaleTransition(
                                  scale: _pulseAnimation,
                                  child: Container(
                                    width: 14,
                                    height: 14,
                                    decoration: const BoxDecoration(
                                      color: Colors.redAccent,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Text(
                                  'REC  ${recorder.formattedDuration}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18,
                                    fontFamily: 'monospace',
                                  ),
                                ),
                              ],
                            ),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF1E232B),
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(color: Colors.white24),
                                  ),
                                  child: Text(
                                    recorder.activePlatform,
                                    style: const TextStyle(
                                      color: Colors.amberAccent,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 11,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Flexible(
                                  child: Text(
                                    recorder.currentOrderCode,
                                    style: const TextStyle(
                                      color: Color(0xFF00E676),
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),

            // 4. Bottom Prompts & Actions
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Prompt message
                      if (recorder.isStandby)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          decoration: BoxDecoration(
                            color: Colors.black87,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.qr_code_scanner, color: Color(0xFF00E676), size: 20),
                              SizedBox(width: 8),
                              Flexible(
                                child: Text(
                                  'Đưa mã vạch vào khung để tự động bắt đầu quay',
                                  style: TextStyle(color: Colors.white, fontSize: 13),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ],
                          ),
                        )
                      else if (recorder.isRecording)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.black87,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Text(
                            '💡 Mẹo: Quét mã đơn khác để lưu & tự động quay đơn mới!',
                            style: TextStyle(color: Colors.amberAccent, fontSize: 12),
                          ),
                        ),

                      const SizedBox(height: 16),

                      // Action buttons
                      if (recorder.isStandby)
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF1E232B),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                side: const BorderSide(color: Colors.white24),
                              ),
                              onPressed: () => _showManualInputDialog(context),
                              icon: const Icon(Icons.keyboard_outlined, size: 20),
                              label: const Text('Nhập mã thủ công / Bắn mã'),
                            ),
                          ],
                        )
                      else if (recorder.isRecording)
                        Row(
                          children: [
                            // Next Order button
                            Expanded(
                              flex: 1,
                              child: ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF242A35),
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                    side: const BorderSide(color: Colors.white24),
                                  ),
                                ),
                                onPressed: () => _showManualInputDialog(context),
                                icon: const Icon(Icons.skip_next_rounded, color: Colors.amberAccent),
                                label: const Text('Đơn kế tiếp'),
                              ),
                            ),
                            const SizedBox(width: 12),
                            // Stop & Save button
                            Expanded(
                              flex: 2,
                              child: ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.redAccent,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                  elevation: 6,
                                ),
                                onPressed: () async {
                                  final order = await recorder.stopAndSaveRecording();
                                  if (order != null && context.mounted) {
                                    context.read<OrderProvider>().loadOrders();
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        backgroundColor: const Color(0xFF00E676),
                                        content: Text(
                                          'Đã lưu video đơn ${order.orderCode} (${order.formattedDuration})',
                                          style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
                                        ),
                                        action: SnackBarAction(
                                          label: 'Xem lại',
                                          textColor: Colors.black,
                                          onPressed: () {
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (_) => VideoPlayerScreen(order: order),
                                              ),
                                            );
                                          },
                                        ),
                                      ),
                                    );
                                  }
                                },
                                icon: const Icon(Icons.stop_circle_rounded, size: 26),
                                label: const Text(
                                  'DỪNG & LƯU ĐƠN',
                                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                ),
                              ),
                            ),
                          ],
                        )
                      else if (recorder.isSaving)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                          decoration: BoxDecoration(
                            color: Colors.black87,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              CircularProgressIndicator(color: Color(0xFF00E676)),
                              SizedBox(width: 16),
                              Text('Đang lưu video...', style: TextStyle(color: Colors.white, fontSize: 16)),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlatformPill(String label, String mode, RecorderProvider recorder, {Color? color}) {
    final isSelected = recorder.platformMode == mode;
    final activeColor = color ?? const Color(0xFF00E676);

    return GestureDetector(
      onTap: () {
        recorder.setPlatformMode(mode);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: isSelected ? activeColor : Colors.black54,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? activeColor : Colors.white24,
            width: 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.black : Colors.white,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            fontSize: 11,
          ),
        ),
      ),
    );
  }
}
