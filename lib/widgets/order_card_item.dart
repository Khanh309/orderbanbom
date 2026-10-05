import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/order_record.dart';

class OrderCardItem extends StatelessWidget {
  final OrderRecord order;
  final VoidCallback onTap;
  final VoidCallback onShare;
  final VoidCallback onDelete;

  const OrderCardItem({
    super.key,
    required this.order,
    required this.onTap,
    required this.onShare,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final isPacking = order.isPacking;
    final primaryColor = isPacking ? const Color(0xFF00E676) : const Color(0xFFFF5722);

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? const Color(0xFF141923) : Colors.white;
    final cardBorder = isDark ? Colors.white.withValues(alpha: 0.07) : const Color(0xFFCBD5E1);
    final textTitleColor = isDark ? Colors.white : const Color(0xFF0F172A);
    final pillBg = isDark ? Colors.white.withValues(alpha: 0.06) : const Color(0xFFE2E8F0);
    final pillTextColor = isDark ? Colors.grey.shade300 : const Color(0xFF1E293B);
    final subMetaColor = isDark ? Colors.grey.shade400 : const Color(0xFF475569);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: cardBorder,
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: isDark ? Colors.black.withValues(alpha: 0.25) : Colors.black.withValues(alpha: 0.06),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            HapticFeedback.lightImpact();
            onTap();
          },
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Left Icon Badge
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: primaryColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: primaryColor.withValues(alpha: 0.3),
                      width: 1,
                    ),
                  ),
                  child: Center(
                    child: Icon(
                      isPacking ? Icons.inventory_2_rounded : Icons.assignment_return_rounded,
                      color: primaryColor,
                      size: 22,
                    ),
                  ),
                ),
                const SizedBox(width: 12),

                // Center Information Column
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Line 1: Badges Row (Wrapped in flexible/safe row)
                      Row(
                        children: [
                          // Type badge (Đóng đơn / Hoàn đơn)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6.5, vertical: 2),
                            decoration: BoxDecoration(
                              color: primaryColor.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(5),
                            ),
                            child: Text(
                              order.typeLabel,
                              style: TextStyle(
                                color: primaryColor,
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          // Platform badge (Shopee / TikTok Shop / Lazada)
                          Flexible(
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6.5, vertical: 2),
                              decoration: BoxDecoration(
                                color: order.platformColor.withValues(alpha: 0.14),
                                borderRadius: BorderRadius.circular(5),
                                border: Border.all(
                                  color: order.platformColor.withValues(alpha: 0.35),
                                  width: 0.8,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(order.platformIcon, size: 10, color: order.platformColor),
                                  const SizedBox(width: 3.5),
                                  Flexible(
                                    child: Text(
                                      order.platformLabel,
                                      style: TextStyle(
                                        color: order.platformColor,
                                        fontSize: 10,
                                        fontWeight: FontWeight.w700,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          // Time tag (compact HH:mm)
                          Text(
                            order.formattedTime,
                            style: TextStyle(
                              color: subMetaColor,
                              fontSize: 10.5,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 5),

                      // Line 2: Tracking Order Code
                      Text(
                        order.orderCode,
                        style: TextStyle(
                          color: textTitleColor,
                          fontSize: 14.5,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.3,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),

                      const SizedBox(height: 5),

                      // Line 3: Meta pills (Duration, Size, Date)
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 5.5, vertical: 1.5),
                            decoration: BoxDecoration(
                              color: pillBg,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.timer_outlined, size: 11, color: subMetaColor),
                                const SizedBox(width: 3),
                                Text(
                                  order.formattedDuration,
                                  style: TextStyle(
                                    color: pillTextColor,
                                    fontSize: 10.5,
                                    fontFamily: 'monospace',
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 5.5, vertical: 1.5),
                            decoration: BoxDecoration(
                              color: pillBg,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.sd_storage_outlined, size: 11, color: subMetaColor),
                                const SizedBox(width: 3),
                                Text(
                                  order.formattedFileSize,
                                  style: TextStyle(
                                    color: pillTextColor,
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            order.formattedDateOnly,
                            style: TextStyle(
                              color: subMetaColor,
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: 6),

                // Right Actions Column/Buttons
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Play button
                    Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF1E2634) : const Color(0xFFE2E8F0),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isDark ? Colors.white.withValues(alpha: 0.1) : const Color(0xFFCBD5E1),
                        ),
                      ),
                      child: IconButton(
                        padding: EdgeInsets.zero,
                        icon: Icon(
                          Icons.play_arrow_rounded,
                          color: isDark ? const Color(0xFF00E676) : const Color(0xFF008945),
                          size: 20,
                        ),
                        onPressed: () {
                          HapticFeedback.lightImpact();
                          onTap();
                        },
                      ),
                    ),
                    // More menu button
                    PopupMenuButton<String>(
                      padding: EdgeInsets.zero,
                      icon: Icon(Icons.more_vert_rounded, color: isDark ? Colors.grey.shade400 : const Color(0xFF475569), size: 18),
                      color: isDark ? const Color(0xFF1E2634) : Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(color: isDark ? Colors.white12 : const Color(0xFFCBD5E1)),
                      ),
                      onSelected: (value) {
                        HapticFeedback.lightImpact();
                        if (value == 'play') onTap();
                        if (value == 'share') onShare();
                        if (value == 'delete') onDelete();
                      },
                      itemBuilder: (context) => [
                        PopupMenuItem(
                          value: 'play',
                          child: Row(
                            children: [
                              Icon(Icons.play_circle_outline, color: isDark ? const Color(0xFF00E676) : const Color(0xFF008945), size: 18),
                              const SizedBox(width: 10),
                              Text('Xem lại video', style: TextStyle(color: textTitleColor, fontSize: 13)),
                            ],
                          ),
                        ),
                        PopupMenuItem(
                          value: 'share',
                          child: Row(
                            children: [
                              const Icon(Icons.share_outlined, color: Colors.blueAccent, size: 18),
                              const SizedBox(width: 10),
                              Text('Chia sẻ Zalo/Drive', style: TextStyle(color: textTitleColor, fontSize: 13)),
                            ],
                          ),
                        ),
                        const PopupMenuItem(
                          value: 'delete',
                          child: Row(
                            children: [
                              Icon(Icons.delete_outline, color: Colors.redAccent, size: 18),
                              SizedBox(width: 10),
                              Text('Xóa video', style: TextStyle(color: Colors.redAccent, fontSize: 13)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
