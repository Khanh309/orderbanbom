import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:video_player/video_player.dart';
import '../models/order_record.dart';
import '../providers/order_provider.dart';

class VideoPlayerScreen extends StatefulWidget {
  final OrderRecord order;

  const VideoPlayerScreen({super.key, required this.order});

  @override
  State<VideoPlayerScreen> createState() => _VideoPlayerScreenState();
}

class _VideoPlayerScreenState extends State<VideoPlayerScreen> {
  VideoPlayerController? _controller;
  bool _isInitialized = false;
  bool _isPlaying = false;
  late TextEditingController _noteController;

  @override
  void initState() {
    super.initState();
    _noteController = TextEditingController(text: widget.order.note);
    _initVideoPlayer();
  }

  Future<void> _initVideoPlayer() async {
    final file = File(widget.order.videoPath);
    if (!await file.exists()) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('File video không tồn tại trên bộ nhớ máy.')),
        );
      }
      return;
    }

    _controller = VideoPlayerController.file(file);
    try {
      await _controller!.initialize();
      _controller!.addListener(() {
        if (mounted) {
          setState(() {
            _isPlaying = _controller!.value.isPlaying;
          });
        }
      });
      setState(() {
        _isInitialized = true;
      });
    } catch (e) {
      debugPrint('Error initializing video: $e');
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _shareVideo() async {
    final file = File(widget.order.videoPath);
    if (await file.exists()) {
      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(widget.order.videoPath)],
          text: 'Video bằng chứng ${widget.order.typeLabel} - Mã: ${widget.order.orderCode}',
        ),
      );
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Không tìm thấy file video để chia sẻ.')),
      );
    }
  }

  Future<void> _saveNote() async {
    if (widget.order.id != null) {
      await context.read<OrderProvider>().updateOrderNote(widget.order.id!, _noteController.text.trim());
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đã cập nhật ghi chú đơn hàng.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isPacking = widget.order.isPacking;
    final primaryColor = isPacking ? const Color(0xFF00E676) : const Color(0xFFFF5722);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? const Color(0xFF1E232B) : Colors.white;
    final cardBorder = isDark ? Colors.white.withValues(alpha: 0.08) : const Color(0xFFE2E8F0);
    final textTitleColor = isDark ? Colors.white : const Color(0xFF0F172A);
    final textSubColor = isDark ? Colors.grey.shade400 : const Color(0xFF64748B);
    final dividerColor = isDark ? Colors.white10 : const Color(0xFFE2E8F0);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.order.orderCode,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.share_rounded, color: Colors.blueAccent),
            tooltip: 'Chia sẻ video',
            onPressed: _shareVideo,
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
            tooltip: 'Xóa',
            onPressed: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (ctx) {
                  final isDark = Theme.of(ctx).brightness == Brightness.dark;
                  return AlertDialog(
                    backgroundColor: isDark ? const Color(0xFF1E232B) : Colors.white,
                    title: Text(
                      'Xác nhận xóa',
                      style: TextStyle(
                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    content: Text(
                      'Bạn có chắc chắn muốn xóa video và thông tin đơn hàng này?',
                      style: TextStyle(
                        color: isDark ? Colors.grey.shade300 : const Color(0xFF475569),
                      ),
                    ),
                    actions: [
                      TextButton(
                        child: Text(
                          'Hủy',
                          style: TextStyle(color: isDark ? Colors.grey : const Color(0xFF64748B)),
                        ),
                        onPressed: () => Navigator.pop(ctx, false),
                      ),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.redAccent,
                          foregroundColor: Colors.white,
                        ),
                        child: const Text('Xóa video'),
                        onPressed: () => Navigator.pop(ctx, true),
                      ),
                    ],
                  );
                },
              );

              if (confirm == true && context.mounted) {
                await context.read<OrderProvider>().deleteOrder(widget.order);
                if (context.mounted) Navigator.pop(context);
              }
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Video Player Area
            AspectRatio(
              aspectRatio: _isInitialized ? _controller!.value.aspectRatio : 16 / 9,
              child: Container(
                color: Colors.black,
                child: _isInitialized
                    ? Stack(
                        alignment: Alignment.center,
                        children: [
                          VideoPlayer(_controller!),
                          // Play/pause overlay
                          GestureDetector(
                            onTap: () {
                              setState(() {
                                _controller!.value.isPlaying ? _controller!.pause() : _controller!.play();
                              });
                            },
                            child: Container(
                              color: Colors.transparent,
                              child: Center(
                                child: AnimatedOpacity(
                                  opacity: _isPlaying ? 0.0 : 0.8,
                                  duration: const Duration(milliseconds: 200),
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: Colors.black54,
                                      shape: BoxShape.circle,
                                    ),
                                    padding: const EdgeInsets.all(16),
                                    child: Icon(
                                      _isPlaying ? Icons.pause : Icons.play_arrow,
                                      size: 48,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          // Video Progress indicator
                          Positioned(
                            bottom: 0,
                            left: 0,
                            right: 0,
                            child: VideoProgressIndicator(
                              _controller!,
                              allowScrubbing: true,
                              colors: VideoProgressColors(
                                playedColor: primaryColor,
                                bufferedColor: Colors.white24,
                                backgroundColor: Colors.black38,
                              ),
                            ),
                          ),
                        ],
                      )
                    : const Center(
                        child: CircularProgressIndicator(color: Color(0xFF00E676)),
                      ),
              ),
            ),

            // Order Information Card
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: primaryColor.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: primaryColor.withValues(alpha: 0.4)),
                            ),
                            child: Text(
                              widget.order.typeLabel.toUpperCase(),
                              style: TextStyle(
                                color: primaryColor,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                            decoration: BoxDecoration(
                              color: widget.order.platformColor.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: widget.order.platformColor.withValues(alpha: 0.4)),
                            ),
                            child: Row(
                              children: [
                                Icon(widget.order.platformIcon, size: 14, color: widget.order.platformColor),
                                const SizedBox(width: 4),
                                Text(
                                  widget.order.platformLabel,
                                  style: TextStyle(
                                    color: widget.order.platformColor,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      Text(
                        widget.order.formattedDate,
                        style: TextStyle(color: textSubColor, fontSize: 13),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: cardBg,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: cardBorder),
                    ),
                    child: Column(
                      children: [
                        _infoRow('Mã vận đơn', widget.order.orderCode, textColor: textTitleColor, subColor: textSubColor, isBold: true),
                        Divider(color: dividerColor),
                        _infoRow('Sàn thương mại', widget.order.platformLabel, textColor: textTitleColor, subColor: textSubColor),
                        Divider(color: dividerColor),
                        _infoRow('Thời lượng video', widget.order.formattedDuration, textColor: textTitleColor, subColor: textSubColor),
                        Divider(color: dividerColor),
                        _infoRow('Dung lượng lưu trữ', widget.order.formattedFileSize, textColor: textTitleColor, subColor: textSubColor),
                        Divider(color: dividerColor),
                        _infoRow('Đường dẫn file', widget.order.videoPath, textColor: textTitleColor, subColor: textSubColor, isSmall: true),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Note input
                  Text(
                    'Ghi chú đơn hàng / Sự cố:',
                    style: TextStyle(color: textTitleColor, fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _noteController,
                    maxLines: 3,
                    style: TextStyle(color: textTitleColor),
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: cardBg,
                      hintText: 'Nhập ghi chú (VD: Hàng móp hộp, đóng seal 2 lớp,...)',
                      hintStyle: TextStyle(color: textSubColor),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: cardBorder),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: cardBorder),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerRight,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isDark ? const Color(0xFF2E3846) : const Color(0xFFE2E8F0),
                        foregroundColor: textTitleColor,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      onPressed: _saveNote,
                      icon: const Icon(Icons.save_outlined, size: 18),
                      label: const Text('Lưu ghi chú'),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Share button
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColor,
                        foregroundColor: Colors.black,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      onPressed: _shareVideo,
                      icon: const Icon(Icons.share_rounded, size: 22),
                      label: const Text('Chia Sẻ Video Ngay'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(
    String title,
    String value, {
    required Color textColor,
    required Color subColor,
    bool isBold = false,
    bool isSmall = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: TextStyle(color: subColor, fontSize: 13)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: TextStyle(
                color: textColor,
                fontSize: isSmall ? 11 : 14,
                fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
