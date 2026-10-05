import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/order_provider.dart';
import '../providers/theme_provider.dart';
import '../services/storage_service.dart';
import '../services/tts_service.dart';
import '../widgets/donate_dialog.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final TtsService _ttsService = TtsService();
  final StorageService _storageService = StorageService();
  int _storageBytes = 0;
  bool _isLoadingStorage = true;

  @override
  void initState() {
    super.initState();
    _loadStorageSize();
  }

  Future<void> _loadStorageSize() async {
    setState(() => _isLoadingStorage = true);
    final bytes = await _storageService.getTotalVideoStorageBytes();
    if (mounted) {
      setState(() {
        _storageBytes = bytes;
        _isLoadingStorage = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? const Color(0xFF1E232B) : Colors.white;
    final cardBorder = isDark ? Colors.white.withValues(alpha: 0.08) : const Color(0xFFE2E8F0);
    final textTitleColor = isDark ? Colors.white : const Color(0xFF0F172A);
    final textSubColor = isDark ? Colors.grey.shade400 : const Color(0xFF64748B);
    final dividerColor = isDark ? Colors.white10 : const Color(0xFFE2E8F0);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Cài Đặt & Hướng Dẫn', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Theme Section
          Text(
            'CHẾ ĐỘ GIAO DIỆN (SÁNG / TỐI)',
            style: TextStyle(
              color: isDark ? const Color(0xFF00E676) : const Color(0xFF00C853),
              fontSize: 12,
              fontWeight: FontWeight.bold,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: cardBorder),
              boxShadow: [
                BoxShadow(
                  color: isDark ? Colors.black.withValues(alpha: 0.2) : Colors.black.withValues(alpha: 0.03),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.dark_mode_rounded, color: Color(0xFF00E676)),
                  title: Text('Giao diện Tối (OLED Dark)', style: TextStyle(color: textTitleColor, fontWeight: FontWeight.w600, fontSize: 14)),
                  subtitle: Text('Tiết kiệm pin, bảo vệ mắt khi làm việc', style: TextStyle(color: textSubColor, fontSize: 12)),
                  trailing: themeProvider.themeMode == ThemeMode.dark
                      ? const Icon(Icons.check_circle_rounded, color: Color(0xFF00E676))
                      : const Icon(Icons.radio_button_unchecked, color: Colors.grey),
                  onTap: () => themeProvider.setThemeMode(ThemeMode.dark),
                ),
                Divider(color: dividerColor, height: 1),
                ListTile(
                  leading: const Icon(Icons.light_mode_rounded, color: Color(0xFFFFB300)),
                  title: Text('Giao diện Sáng (Light Mode)', style: TextStyle(color: textTitleColor, fontWeight: FontWeight.w600, fontSize: 14)),
                  subtitle: Text('Rõ ràng, trực quan nơi có ánh sáng mạnh', style: TextStyle(color: textSubColor, fontSize: 12)),
                  trailing: themeProvider.themeMode == ThemeMode.light
                      ? const Icon(Icons.check_circle_rounded, color: Color(0xFF00E676))
                      : const Icon(Icons.radio_button_unchecked, color: Colors.grey),
                  onTap: () => themeProvider.setThemeMode(ThemeMode.light),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Voice & Audio Section
          Text(
            'ÂM THANH & GIỌNG NÓI',
            style: TextStyle(
              color: isDark ? const Color(0xFF00E676) : const Color(0xFF00C853),
              fontSize: 12,
              fontWeight: FontWeight.bold,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: cardBorder),
              boxShadow: [
                BoxShadow(
                  color: isDark ? Colors.black.withValues(alpha: 0.2) : Colors.black.withValues(alpha: 0.03),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              children: [
                SwitchListTile(
                  activeThumbColor: const Color(0xFF00E676),
                  title: Text('Giọng nói tiếng Việt thông báo', style: TextStyle(color: textTitleColor, fontWeight: FontWeight.w600)),
                  subtitle: Text(
                    'Tự động đọc "Bắt đầu quay video" khi nhận diện mã đơn',
                    style: TextStyle(color: textSubColor, fontSize: 12),
                  ),
                  value: _ttsService.isEnabled,
                  onChanged: (val) {
                    setState(() {
                      _ttsService.isEnabled = val;
                    });
                  },
                ),
                Divider(color: dividerColor, height: 1),
                ListTile(
                  leading: const Icon(Icons.volume_up_outlined, color: Color(0xFF00E676)),
                  title: Text('Thử nghiệm giọng nói', style: TextStyle(color: textTitleColor)),
                  subtitle: Text('Nhấn để nghe mẫu thông báo', style: TextStyle(color: textSubColor, fontSize: 12)),
                  trailing: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isDark ? const Color(0xFF2E3846) : const Color(0xFFE2E8F0),
                      foregroundColor: isDark ? Colors.white : const Color(0xFF0F172A),
                    ),
                    onPressed: () {
                      _ttsService.speakStartRecording(orderCode: 'SPX-8899');
                    },
                    child: const Text('Nghe thử'),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Storage Section
          Text(
            'BỘ NHỚ & DUNG LƯỢNG VIDEO',
            style: TextStyle(
              color: isDark ? const Color(0xFF00E676) : const Color(0xFF00C853),
              fontSize: 12,
              fontWeight: FontWeight.bold,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: cardBorder),
              boxShadow: [
                BoxShadow(
                  color: isDark ? Colors.black.withValues(alpha: 0.2) : Colors.black.withValues(alpha: 0.03),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Dung lượng video đã lưu:', style: TextStyle(color: textTitleColor, fontSize: 14)),
                    _isLoadingStorage
                        ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                        : Text(
                            _storageService.formatBytes(_storageBytes),
                            style: const TextStyle(color: Color(0xFF00E676), fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  'Video được lưu trực tiếp trong bộ nhớ máy để đảm bảo tốc độ cao và hoạt động offline khi kho hàng mất mạng.',
                  style: TextStyle(color: textSubColor, fontSize: 12),
                ),
                const SizedBox(height: 14),
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: textTitleColor,
                    side: BorderSide(color: isDark ? Colors.white24 : const Color(0xFFCBD5E1)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: () async {
                    await context.read<OrderProvider>().loadOrders();
                    await _loadStorageSize();
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Đã làm mới thông tin bộ nhớ')),
                      );
                    }
                  },
                  icon: const Icon(Icons.refresh, size: 18),
                  label: const Text('Làm mới dung lượng'),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Warehouse Workflow Tips
          Text(
            'HƯỚNG DẪN DÀNH CHO NHÂN VIÊN KHO',
            style: TextStyle(
              color: isDark ? const Color(0xFF00E676) : const Color(0xFF00C853),
              fontSize: 12,
              fontWeight: FontWeight.bold,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: cardBorder),
              boxShadow: [
                BoxShadow(
                  color: isDark ? Colors.black.withValues(alpha: 0.2) : Colors.black.withValues(alpha: 0.03),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              children: [
                _buildTipItem(
                  context: context,
                  icon: Icons.qr_code_scanner,
                  title: 'Quét mã vạch tự động',
                  desc: 'Chỉ cần đưa phiếu giao hàng / mã vận đơn trước ống kính, hệ thống sẽ phát âm thông báo và tự động ghi hình.',
                ),
                Divider(color: dividerColor),
                _buildTipItem(
                  context: context,
                  icon: Icons.flash_auto,
                  title: 'Quay liên tục nhiều đơn',
                  desc: 'Khi gói xong 1 kiện hàng, đưa trực tiếp mã đơn tiếp theo vào máy để lưu video cũ và quay tiếp đơn mới mà không cần chạm tay.',
                ),
                Divider(color: dividerColor),
                _buildTipItem(
                  context: context,
                  icon: Icons.barcode_reader,
                  title: 'Hỗ trợ súng bắn mã vạch',
                  desc: 'Có thể cắm súng quét barcode qua cổng Type-C (OTG) hoặc kết nối Bluetooth để bắn mã siêu tốc.',
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Donate / Support Section
          Text(
            'ỦNG HỘ TÁC GIẢ (MỜI DEV LY CÀ PHÊ ☕)',
            style: TextStyle(
              color: isDark ? const Color(0xFF00E676) : const Color(0xFF00C853),
              fontSize: 12,
              fontWeight: FontWeight.bold,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 8),
          _buildDonateCard(
            context: context,
            isDark: isDark,
            cardBg: cardBg,
            cardBorder: cardBorder,
            textTitleColor: textTitleColor,
            textSubColor: textSubColor,
            dividerColor: dividerColor,
          ),

          const SizedBox(height: 28),
          Center(
            child: Column(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Image.asset(
                    'assets/icon/app_logo.png',
                    width: 36,
                    height: 36,
                    fit: BoxFit.cover,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'OrderBanBom',
                  style: TextStyle(
                    color: textTitleColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Phiên bản 2.0.0',
                  style: TextStyle(
                    color: textSubColor,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTipItem({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String desc,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textTitleColor = isDark ? Colors.white : const Color(0xFF0F172A);
    final textSubColor = isDark ? Colors.grey.shade400 : const Color(0xFF64748B);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF00E676).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: const Color(0xFF00E676), size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(color: textTitleColor, fontWeight: FontWeight.bold, fontSize: 14)),
                const SizedBox(height: 4),
                Text(desc, style: TextStyle(color: textSubColor, fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDonateCard({
    required BuildContext context,
    required bool isDark,
    required Color cardBg,
    required Color cardBorder,
    required Color textTitleColor,
    required Color textSubColor,
    required Color dividerColor,
  }) {
    const momoColor = Color(0xFFA50064);

    return Container(
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? const Color(0xFF00E676).withValues(alpha: 0.3) : const Color(0xFF00C853).withValues(alpha: 0.3),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: isDark ? Colors.black.withValues(alpha: 0.25) : Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header banner
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF16231C) : const Color(0xFFE8F5E9),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(15),
                topRight: Radius.circular(15),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF00E676).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text('☕', style: TextStyle(fontSize: 18)),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Mời Dev Ly Cà Phê',
                        style: TextStyle(
                          color: textTitleColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Ủng hộ để ứng dụng ngày càng hoàn thiện hơn',
                        style: TextStyle(color: textSubColor, fontSize: 11),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: momoColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.favorite, color: Colors.white, size: 12),
                      SizedBox(width: 4),
                      Text('MoMo', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11)),
                    ],
                  ),
                ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Heartfelt thank you message
                Text(
                  'OrderBanBom được xây dựng hoàn toàn miễn phí nhằm giúp các chủ shop và kho đóng hàng chuẩn chỉ, quay video bằng chứng rõ nét để tránh bị bom đơn hay khiếu nại. Nếu ứng dụng mang lại giá trị cho bạn, hãy gửi chút động lực cho dev nhé! ❤️',
                  style: TextStyle(
                    color: textSubColor,
                    fontSize: 12.5,
                    height: 1.45,
                  ),
                  textAlign: TextAlign.justify,
                ),

                const SizedBox(height: 16),

                // QR Code Display
                Center(
                  child: GestureDetector(
                    onTap: () => QrDonateDialog.show(context),
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: Colors.grey.shade300, width: 1.5),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.08),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.asset(
                              'assets/icon/donate_qr.png',
                              width: 160,
                              height: 160,
                              fit: BoxFit.contain,
                              errorBuilder: (context, error, stackTrace) => Container(
                                width: 160,
                                height: 160,
                                color: Colors.grey.shade100,
                                child: const Center(
                                  child: Icon(Icons.qr_code_2, size: 60, color: Colors.grey),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.zoom_in, size: 14, color: Colors.grey.shade700),
                              const SizedBox(width: 4),
                              Text(
                                'Chạm để phóng to mã QR',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey.shade700,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // Bank / MoMo Account Info Box
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF141920) : const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: cardBorder),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 1. SĐT / STK MoMo
                      Row(
                        children: [
                          const Icon(Icons.phone_android_rounded, size: 16, color: momoColor),
                          const SizedBox(width: 6),
                          Text(
                            'Số điện thoại / STK MoMo:',
                            style: TextStyle(color: textSubColor, fontSize: 12, fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),
                      const SizedBox(height: 5),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            '09219337975',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              letterSpacing: 1.0,
                            ),
                          ),
                          InkWell(
                            onTap: () => _copyToClipboard('09219337975', 'Đã sao chép số điện thoại / STK MoMo: 09219337975'),
                            borderRadius: BorderRadius.circular(6),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                              decoration: BoxDecoration(
                                color: momoColor.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.copy_rounded, size: 13, color: momoColor),
                                  SizedBox(width: 4),
                                  Text(
                                    'Sao chép',
                                    style: TextStyle(
                                      color: momoColor,
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 10),
                      Divider(color: dividerColor, height: 1),
                      const SizedBox(height: 10),

                      // 2. Chủ tài khoản
                      Row(
                        children: [
                          const Icon(Icons.person_outline_rounded, size: 16, color: Color(0xFF00E676)),
                          const SizedBox(width: 6),
                          Text(
                            'Chủ tài khoản:',
                            style: TextStyle(color: textSubColor, fontSize: 12, fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'LE DUY KHANH',
                        style: TextStyle(
                          color: textTitleColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          letterSpacing: 0.8,
                        ),
                      ),

                      const SizedBox(height: 10),
                      Divider(color: dividerColor, height: 1),
                      const SizedBox(height: 10),

                      // 3. Nội dung chuyển khoản
                      Row(
                        children: [
                          const Icon(Icons.chat_bubble_outline_rounded, size: 16, color: Color(0xFF29B6F6)),
                          const SizedBox(width: 6),
                          Text(
                            'Nội dung chuyển khoản (giữ nguyên):',
                            style: TextStyle(color: textSubColor, fontSize: 12, fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),
                      const SizedBox(height: 5),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Expanded(
                            child: Text(
                              'Ung ho OrderBanBom',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                                letterSpacing: 0.3,
                              ),
                            ),
                          ),
                          InkWell(
                            onTap: () => _copyToClipboard('Ung ho OrderBanBom', 'Đã sao chép nội dung: Ung ho OrderBanBom'),
                            borderRadius: BorderRadius.circular(6),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                              decoration: BoxDecoration(
                                color: const Color(0xFF29B6F6).withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.copy_rounded, size: 13, color: Color(0xFF0288D1)),
                                  SizedBox(width: 4),
                                  Text(
                                    'Sao chép',
                                    style: TextStyle(
                                      color: Color(0xFF0288D1),
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 14),

                // Friendly Suggestion Chips
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  alignment: WrapAlignment.center,
                  children: [
                    _buildCheerChip('🥤 10k Trà đá', isDark),
                    _buildCheerChip('☕ 25k Cafe', isDark),
                    _buildCheerChip('🍜 50k Bát phở', isDark),
                    _buildCheerChip('✨ Tùy tâm', isDark),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCheerChip(String label, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF222B36) : const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? Colors.white12 : const Color(0xFFE2E8F0),
        ),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w500,
          color: isDark ? Colors.grey.shade300 : const Color(0xFF475569),
        ),
      ),
    );
  }

  void _copyToClipboard(String text, String successMessage) {
    Clipboard.setData(ClipboardData(text: text));
    HapticFeedback.lightImpact();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle_rounded, color: Color(0xFF00E676), size: 18),
              const SizedBox(width: 8),
              Expanded(child: Text(successMessage, style: const TextStyle(fontSize: 13))),
            ],
          ),
          backgroundColor: const Color(0xFF1E232B),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    }
  }
}
