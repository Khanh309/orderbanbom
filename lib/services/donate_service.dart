import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../widgets/donate_dialog.dart';

class DonateService {
  static const String _keyNeverShow = 'donate_never_show_again';
  static const String _keyNextThreshold = 'donate_next_threshold';
  static const String _keyLastPromptTime = 'donate_last_prompt_time';

  static const int initialMilestone = 10;
  static const int stepIncrement = 15; // Sau khi hoãn, 15 đơn tiếp theo mới nhắc lại

  /// Kiểm tra và hiển thị popup mừng cột mốc nếu thỏa mãn điều kiện
  static Future<void> checkAndShowMilestone({
    required BuildContext context,
    required int totalOrders,
  }) async {
    if (totalOrders < initialMilestone) return;

    try {
      final prefs = await SharedPreferences.getInstance();

      final bool neverShow = prefs.getBool(_keyNeverShow) ?? false;
      if (neverShow) return;

      final int nextThreshold = prefs.getInt(_keyNextThreshold) ?? initialMilestone;
      if (totalOrders < nextThreshold) return;

      final int lastPromptTime = prefs.getInt(_keyLastPromptTime) ?? 0;
      final int now = DateTime.now().millisecondsSinceEpoch;
      // Tránh hiện lại quá gần (tối thiểu cách nhau 24 giờ)
      if (lastPromptTime > 0 && (now - lastPromptTime) < 24 * 60 * 60 * 1000) {
        return;
      }

      if (!context.mounted) return;

      // Cập nhật thời điểm hiện popup
      await prefs.setInt(_keyLastPromptTime, now);

      if (!context.mounted) return;

      showDialog(
        context: context,
        barrierDismissible: true,
        builder: (dialogCtx) => DonateMilestoneDialog(
          orderCount: totalOrders,
          onDonatePressed: () async {
            // Mở dialog QR MoMo
            if (context.mounted) {
              QrDonateDialog.show(context);
            }
            // Tạm hoãn rất dài hoặc không làm phiền nữa
            await prefs.setInt(_keyNextThreshold, totalOrders + 50);
          },
          onLaterPressed: () async {
            // Nhắc lại sau 15 đơn tiếp theo
            await prefs.setInt(_keyNextThreshold, totalOrders + stepIncrement);
          },
          onNeverRemindPressed: () async {
            await prefs.setBool(_keyNeverShow, true);
          },
        ),
      );
    } catch (e) {
      debugPrint('Error in DonateService: $e');
    }
  }

  /// Đánh dấu vĩnh viễn không hiện popup
  static Future<void> setNeverShowAgain() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyNeverShow, true);
  }
}
