import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class QrDonateDialog extends StatelessWidget {
  const QrDonateDialog({super.key});

  static void show(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => const QrDonateDialog(),
    );
  }

  void _copy(BuildContext context, String text, String msg) {
    Clipboard.setData(ClipboardData(text: text));
    HapticFeedback.lightImpact();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_rounded, color: Color(0xFF00E676), size: 18),
            const SizedBox(width: 8),
            Expanded(child: Text(msg, style: const TextStyle(fontSize: 13))),
          ],
        ),
        backgroundColor: const Color(0xFF1E232B),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const momoColor = Color(0xFFA50064);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      backgroundColor: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(
                  children: [
                    Icon(Icons.qr_code_2_rounded, color: momoColor, size: 26),
                    SizedBox(width: 8),
                    Text(
                      'Ủng Hộ Qua MoMo',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.grey),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // QR Image
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE2E8F0)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Image.asset(
                  'assets/icon/donate_qr.png',
                  width: 230,
                  height: 230,
                  fit: BoxFit.contain,
                ),
              ),
            ),
            const SizedBox(height: 14),

            // Info Container with 2 lines per field
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. SĐT / STK MoMo
                  const Row(
                    children: [
                      Icon(Icons.phone_android_rounded, size: 15, color: momoColor),
                      SizedBox(width: 6),
                      Text(
                        'Số điện thoại / STK MoMo:',
                        style: TextStyle(fontSize: 11.5, color: Color(0xFF64748B), fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        '09219337975',
                        style: TextStyle(
                          fontSize: 15.5,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0F172A),
                          letterSpacing: 0.8,
                        ),
                      ),
                      InkWell(
                        onTap: () => _copy(context, '09219337975', 'Đã sao chép STK MoMo: 09219337975'),
                        borderRadius: BorderRadius.circular(6),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
                          decoration: BoxDecoration(
                            color: momoColor.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.copy_rounded, size: 12, color: momoColor),
                              SizedBox(width: 4),
                              Text(
                                'Sao chép',
                                style: TextStyle(
                                  color: momoColor,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 8),
                  const Divider(color: Color(0xFFE2E8F0), height: 1),
                  const SizedBox(height: 8),

                  // 2. Chủ tài khoản
                  const Row(
                    children: [
                      Icon(Icons.person_outline_rounded, size: 15, color: Color(0xFF00C853)),
                      SizedBox(width: 6),
                      Text(
                        'Chủ tài khoản:',
                        style: TextStyle(fontSize: 11.5, color: Color(0xFF64748B), fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  const Text(
                    'LE DUY KHANH',
                    style: TextStyle(
                      fontSize: 14.5,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0F172A),
                      letterSpacing: 0.5,
                    ),
                  ),

                  const SizedBox(height: 8),
                  const Divider(color: Color(0xFFE2E8F0), height: 1),
                  const SizedBox(height: 8),

                  // 3. Nội dung chuyển khoản
                  const Row(
                    children: [
                      Icon(Icons.chat_bubble_outline_rounded, size: 15, color: Color(0xFF0288D1)),
                      SizedBox(width: 6),
                      Text(
                        'Nội dung chuyển khoản (giữ nguyên):',
                        style: TextStyle(fontSize: 11.5, color: Color(0xFF64748B), fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Expanded(
                        child: Text(
                          'Ung ho OrderBanBom',
                          style: TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF0F172A),
                            letterSpacing: 0.2,
                          ),
                        ),
                      ),
                      InkWell(
                        onTap: () => _copy(context, 'Ung ho OrderBanBom', 'Đã sao chép nội dung: Ung ho OrderBanBom'),
                        borderRadius: BorderRadius.circular(6),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
                          decoration: BoxDecoration(
                            color: const Color(0xFF29B6F6).withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.copy_rounded, size: 12, color: Color(0xFF0288D1)),
                              SizedBox(width: 4),
                              Text(
                                'Sao chép',
                                style: TextStyle(
                                  color: Color(0xFF0288D1),
                                  fontSize: 11,
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

            const SizedBox(height: 12),
            Text(
              'Mở ứng dụng MoMo hoặc bất kỳ app ngân hàng nào để quét mã QR.',
              style: TextStyle(fontSize: 11.5, color: Colors.grey.shade600),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),

            // Action Buttons
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: momoColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  elevation: 0,
                ),
                onPressed: () {
                  _copy(context, '09219337975', 'Đã sao chép SĐT MoMo: 09219337975');
                },
                icon: const Icon(Icons.copy_rounded, size: 16),
                label: const Text('Sao Chép Số Điện Thoại MoMo'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class DonateMilestoneDialog extends StatelessWidget {
  final int orderCount;
  final VoidCallback onDonatePressed;
  final VoidCallback onLaterPressed;
  final VoidCallback onNeverRemindPressed;

  const DonateMilestoneDialog({
    super.key,
    required this.orderCount,
    required this.onDonatePressed,
    required this.onLaterPressed,
    required this.onNeverRemindPressed,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final dialogBg = isDark ? const Color(0xFF1E232B) : Colors.white;
    final titleColor = isDark ? Colors.white : const Color(0xFF0F172A);
    final subColor = isDark ? Colors.grey.shade300 : const Color(0xFF475569);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      backgroundColor: dialogBg,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(22, 26, 22, 18),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Cheerful Badge
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF00E676), Color(0xFF00B0FF)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF00E676).withValues(alpha: 0.35),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: const Center(
                child: Text('🎉', style: TextStyle(fontSize: 30)),
              ),
            ),
            const SizedBox(height: 16),

            // Title
            Text(
              'Cột Mốc Tuyệt Vời!',
              style: TextStyle(
                color: titleColor,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFF00E676).withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                'Đã đóng gói thành công $orderCount đơn hàng 📦',
                style: const TextStyle(
                  color: Color(0xFF00E676),
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ),
            const SizedBox(height: 14),

            // Message
            Text(
              'OrderBanBom được phát triển hoàn toàn miễn phí nhằm giúp các shop đóng hàng chuẩn xác, có video bằng chứng để tránh bị bom đơn hay khiếu nại.\n\nNếu app giúp bạn an tâm và tiết kiệm chi phí, bạn có thể mời dev 1 ly cà phê để tiếp thêm năng lượng duy trì nhé! ❤️',
              style: TextStyle(
                color: subColor,
                fontSize: 13,
                height: 1.45,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 22),

            // Donate Now button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFA50064),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  elevation: 4,
                  shadowColor: const Color(0xFFA50064).withValues(alpha: 0.4),
                ),
                onPressed: () {
                  Navigator.of(context).pop();
                  onDonatePressed();
                },
                icon: const Text('☕', style: TextStyle(fontSize: 18)),
                label: const Text(
                  'Mời Dev Ly Cà Phê (MoMo)',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                ),
              ),
            ),
            const SizedBox(height: 8),

            // Remind later button
            SizedBox(
              width: double.infinity,
              child: TextButton(
                style: TextButton.styleFrom(
                  foregroundColor: isDark ? Colors.grey.shade400 : const Color(0xFF64748B),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                ),
                onPressed: () {
                  Navigator.of(context).pop();
                  onLaterPressed();
                },
                child: const Text('Để lần sau', style: TextStyle(fontSize: 13)),
              ),
            ),

            // Never remind button
            InkWell(
              onTap: () {
                Navigator.of(context).pop();
                onNeverRemindPressed();
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Text(
                  'Đã ủng hộ / Không nhắc lại',
                  style: TextStyle(
                    fontSize: 11,
                    color: isDark ? Colors.grey.shade600 : Colors.grey.shade500,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
