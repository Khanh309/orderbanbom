import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import '../providers/order_provider.dart';
import '../providers/theme_provider.dart';
import '../services/donate_service.dart';
import '../widgets/order_card_item.dart';
import 'order_list_screen.dart';
import 'recorder_screen.dart';
import 'settings_screen.dart';
import 'video_player_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentTabIndex = 0;

  @override
  void initState() {
    super.initState();
    _checkPermissions();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await context.read<OrderProvider>().loadOrders();
      if (mounted) {
        final total = context.read<OrderProvider>().orders.length;
        DonateService.checkAndShowMilestone(context: context, totalOrders: total);
      }
    });
  }

  Future<void> _checkPermissions() async {
    await [
      Permission.camera,
      Permission.microphone,
    ].request();
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Chào buổi sáng!';
    if (hour < 18) return 'Chào buổi chiều!';
    return 'Chào buổi tối!';
  }

  void _startRecording(BuildContext context, String type) async {
    HapticFeedback.mediumImpact();
    final cameraStatus = await Permission.camera.status;
    final micStatus = await Permission.microphone.status;

    if (!cameraStatus.isGranted || !micStatus.isGranted) {
      final statuses = await [
        Permission.camera,
        Permission.microphone,
      ].request();

      if (statuses[Permission.camera] != PermissionStatus.granted ||
          statuses[Permission.microphone] != PermissionStatus.granted) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Vui lòng cấp quyền Camera và Microphone để quay video đơn hàng.'),
            ),
          );
        }
        return;
      }
    }

    if (context.mounted) {
      await Navigator.push(
        context,
        PageRouteBuilder(
          pageBuilder: (_, animation, secondaryAnimation) => RecorderScreen(initialType: type),
          transitionsBuilder: (_, animation, secondaryAnimation, child) {
            return FadeTransition(opacity: animation, child: child);
          },
        ),
      );
      if (context.mounted) {
        await context.read<OrderProvider>().loadOrders();
        if (context.mounted) {
          final total = context.read<OrderProvider>().orders.length;
          DonateService.checkAndShowMilestone(context: context, totalOrders: total);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> pages = [
      _buildDashboard(context),
      const OrderListScreen(),
      const SettingsScreen(),
    ];

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
        statusBarBrightness: isDark ? Brightness.dark : Brightness.light,
        systemNavigationBarColor: isDark ? const Color(0xFF111620) : Colors.white,
        systemNavigationBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: isDark ? const Color(0xFF0B0E14) : const Color(0xFFF1F5F9),
        body: IndexedStack(
          index: _currentTabIndex,
          children: pages,
        ),
        bottomNavigationBar: Container(
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF111620) : Colors.white,
            border: Border(
              top: BorderSide(
                color: isDark ? Colors.white.withValues(alpha: 0.08) : const Color(0xFFCBD5E1),
                width: 1.2,
              ),
            ),
            boxShadow: [
              BoxShadow(
                color: isDark ? Colors.black.withValues(alpha: 0.3) : Colors.black.withValues(alpha: 0.07),
                blurRadius: 10,
                offset: const Offset(0, -3),
              ),
            ],
          ),
          child: NavigationBar(
            backgroundColor: isDark ? const Color(0xFF111620) : Colors.white,
            surfaceTintColor: Colors.transparent,
            indicatorColor: isDark
                ? const Color(0xFF00E676).withValues(alpha: 0.18)
                : const Color(0xFF00A859).withValues(alpha: 0.15),
            selectedIndex: _currentTabIndex,
            height: 65,
            labelTextStyle: WidgetStateProperty.resolveWith((states) {
              if (states.contains(WidgetState.selected)) {
                return TextStyle(
                  color: isDark ? const Color(0xFF00E676) : const Color(0xFF008945),
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                );
              }
              return TextStyle(
                color: isDark ? Colors.grey.shade400 : const Color(0xFF334155),
                fontWeight: FontWeight.w700,
                fontSize: 12,
              );
            }),
            onDestinationSelected: (index) {
              HapticFeedback.selectionClick();
              setState(() {
                _currentTabIndex = index;
              });
            },
            destinations: [
              NavigationDestination(
                icon: Icon(Icons.home_outlined, color: isDark ? Colors.grey : const Color(0xFF64748B)),
                selectedIcon: Icon(Icons.home_rounded, color: isDark ? const Color(0xFF00E676) : const Color(0xFF008945)),
                label: 'Trang chủ',
              ),
              NavigationDestination(
                icon: Icon(Icons.receipt_long_outlined, color: isDark ? Colors.grey : const Color(0xFF64748B)),
                selectedIcon: Icon(Icons.receipt_long_rounded, color: isDark ? const Color(0xFF00E676) : const Color(0xFF008945)),
                label: 'Đơn hàng',
              ),
              NavigationDestination(
                icon: Icon(Icons.settings_outlined, color: isDark ? Colors.grey : const Color(0xFF64748B)),
                selectedIcon: Icon(Icons.settings_rounded, color: isDark ? const Color(0xFF00E676) : const Color(0xFF008945)),
                label: 'Cài đặt',
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDashboard(BuildContext context) {
    final orderProvider = context.watch<OrderProvider>();
    final stats = orderProvider.stats;
    final recentOrders = orderProvider.orders.take(5).toList();

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? const Color(0xFF141923) : Colors.white;
    final cardBorder = isDark ? Colors.white.withValues(alpha: 0.06) : const Color(0xFFCBD5E1);
    final textTitleColor = isDark ? Colors.white : const Color(0xFF0F172A);
    final textSubColor = isDark ? Colors.grey.shade400 : const Color(0xFF475569);

    return SafeArea(
      child: RefreshIndicator(
        color: const Color(0xFF00E676),
        backgroundColor: isDark ? const Color(0xFF151A23) : Colors.white,
        onRefresh: () => orderProvider.loadOrders(),
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          children: [
            // Top Welcome Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.asset(
                          'assets/icon/app_logo.png',
                          width: 42,
                          height: 42,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => Container(
                            width: 42,
                            height: 42,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFF00E676), Color(0xFF008945)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(Icons.videocam_rounded, color: Colors.black, size: 24),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _getGreeting(),
                              style: TextStyle(
                                color: textSubColor,
                                fontSize: 11.5,
                                fontWeight: FontWeight.w500,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'OrderBanBom',
                              style: TextStyle(
                                color: textTitleColor,
                                fontWeight: FontWeight.w800,
                                fontSize: 18,
                                letterSpacing: -0.3,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 6),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                      decoration: BoxDecoration(
                        color: const Color(0xFF00E676).withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: const Color(0xFF00E676).withValues(alpha: 0.3)),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.fiber_manual_record, size: 8, color: Color(0xFF00E676)),
                          SizedBox(width: 4),
                          Text(
                            'SẴN SÀNG',
                            style: TextStyle(
                              color: Color(0xFF00E676),
                              fontSize: 9.5,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 6),
                    // Theme Toggle Button (Light / Dark)
                    GestureDetector(
                      onTap: () {
                        HapticFeedback.lightImpact();
                        context.read<ThemeProvider>().toggleTheme();
                      },
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: isDark ? Colors.white.withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: isDark ? Colors.white.withValues(alpha: 0.12) : const Color(0xFFCBD5E1),
                          ),
                        ),
                        child: Icon(
                          isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
                          size: 15,
                          color: isDark ? const Color(0xFFFFD54F) : const Color(0xFF334155),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 18),

            // Statistics Row (Glass Cards)
            Row(
              children: [
                Expanded(
                  child: _buildModernStatBox(
                    title: 'Đóng hôm nay',
                    value: '${stats['todayPacking'] ?? 0}',
                    icon: Icons.inventory_2_rounded,
                    color: const Color(0xFF00E676),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildModernStatBox(
                    title: 'Hoàn hôm nay',
                    value: '${stats['todayReturn'] ?? 0}',
                    icon: Icons.assignment_return_rounded,
                    color: const Color(0xFFFF5722),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildModernStatBox(
                    title: 'Tổng video',
                    value: '${stats['totalOrders'] ?? 0}',
                    icon: Icons.video_collection_rounded,
                    color: const Color(0xFF3D82F6),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 14),

            // Platform Distribution Section (Sàn TMĐT)
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.circular(16),
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
                      Text(
                        'PHÂN LOẠI THEO SÀN TMĐT',
                        style: TextStyle(
                          color: textSubColor,
                          fontWeight: FontWeight.w700,
                          fontSize: 11,
                          letterSpacing: 0.8,
                        ),
                      ),
                      Text(
                        'Hôm nay',
                        style: TextStyle(color: textSubColor, fontSize: 11),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: _buildPlatformCard(
                          name: 'Shopee',
                          count: '${stats['shopeeCount'] ?? 0}',
                          color: const Color(0xFFEE4D2D),
                          icon: Icons.shopping_bag_rounded,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildPlatformCard(
                          name: 'TikTok',
                          count: '${stats['tiktokCount'] ?? 0}',
                          color: const Color(0xFFFE2C55),
                          icon: Icons.music_note_rounded,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildPlatformCard(
                          name: 'Lazada',
                          count: '${stats['lazadaCount'] ?? 0}',
                          color: const Color(0xFF1E88E5),
                          icon: Icons.local_mall_rounded,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Section: Bắt đầu quay video mới
            Text(
              'BẮT ĐẦU QUAY VIDEO MỚI',
              style: TextStyle(
                color: isDark ? Colors.grey.shade400 : const Color(0xFF334155),
                fontWeight: FontWeight.w800,
                fontSize: 11.5,
                letterSpacing: 0.8,
              ),
            ),
            const SizedBox(height: 10),

            // 1. Packing Action Card (Emerald Lush Gradient)
            _buildActionCard(
              title: 'ĐÓNG GÓI ĐƠN HÀNG',
              subtitle: 'Đưa mã đơn trước camera -> Tự động quay video đóng gói bằng chứng',
              badge: 'CHẾ ĐỘ ĐÓNG HÀNG',
              badgeColor: const Color(0xFF00E676),
              icon: Icons.inventory_2_rounded,
              gradientColors: [const Color(0xFF00A859), const Color(0xFF005826)],
              onTap: () => _startRecording(context, 'PACKING'),
            ),

            const SizedBox(height: 12),

            // 2. Return Action Card (Coral Sunset Gradient)
            _buildActionCard(
              title: 'KIỂM HÀNG HOÀN VỀ',
              subtitle: 'Quét mã đơn trả về -> Tự động quay video khui kiện bồi hoàn',
              badge: 'CHẾ ĐỘ HOÀN ĐƠN',
              badgeColor: const Color(0xFFFF7043),
              icon: Icons.assignment_return_rounded,
              gradientColors: [const Color(0xFFE64A19), const Color(0xFF8C2200)],
              onTap: () => _startRecording(context, 'RETURN'),
            ),

            const SizedBox(height: 24),

            // Section: Đơn vừa quay gần đây
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'ĐƠN VỪA QUAY GẦN ĐÂY',
                  style: TextStyle(
                    color: isDark ? Colors.grey.shade400 : const Color(0xFF334155),
                    fontWeight: FontWeight.w800,
                    fontSize: 11.5,
                    letterSpacing: 0.8,
                  ),
                ),
                if (recentOrders.isNotEmpty)
                  GestureDetector(
                    onTap: () {
                      HapticFeedback.selectionClick();
                      setState(() {
                        _currentTabIndex = 1;
                      });
                    },
                    child: const Text(
                      'Xem tất cả ➔',
                      style: TextStyle(
                        color: Color(0xFF00E676),
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 10),

            // Recent Orders List
            if (recentOrders.isEmpty)
              Container(
                padding: const EdgeInsets.all(28),
                decoration: BoxDecoration(
                  color: cardBg,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: cardBorder),
                ),
                child: Center(
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: isDark ? Colors.white.withValues(alpha: 0.03) : Colors.black.withValues(alpha: 0.03),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.videocam_outlined, size: 40, color: textSubColor),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Chưa có video đơn hàng nào',
                        style: TextStyle(color: textTitleColor, fontSize: 14, fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Chọn "Đóng gói đơn hàng" ở trên để bắt đầu ghi hình',
                        style: TextStyle(color: textSubColor, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              )
            else
              ...recentOrders.map(
                (order) => OrderCardItem(
                  order: order,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => VideoPlayerScreen(order: order)),
                    );
                  },
                  onShare: () {},
                  onDelete: () => orderProvider.deleteOrder(order),
                ),
              ),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildModernStatBox({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF141923) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Colors.white.withValues(alpha: 0.07) : const Color(0xFFCBD5E1),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: isDark ? Colors.black.withValues(alpha: 0.2) : Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(6.5),
            decoration: BoxDecoration(
              color: isDark ? color.withValues(alpha: 0.14) : color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w900,
              fontSize: 21,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 2),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              title,
              style: TextStyle(
                color: isDark ? Colors.grey.shade400 : const Color(0xFF334155),
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlatformCard({
    required String name,
    required String count,
    required Color color,
    required IconData icon,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: isDark ? color.withValues(alpha: 0.08) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? color.withValues(alpha: 0.25) : const Color(0xFFCBD5E1),
          width: 1.2,
        ),
        boxShadow: isDark
            ? null
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 7),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: TextStyle(
                    color: isDark ? Colors.grey.shade300 : const Color(0xFF1E293B),
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '$count đơn',
                  style: TextStyle(color: color, fontSize: 12.5, fontWeight: FontWeight.w800),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionCard({
    required String title,
    required String subtitle,
    required String badge,
    required Color badgeColor,
    required IconData icon,
    required List<Color> gradientColors,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: gradientColors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: gradientColors.first.withValues(alpha: 0.35),
            blurRadius: 14,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.35),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          badge,
                          style: TextStyle(
                            color: badgeColor,
                            fontSize: 9.5,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 17,
                          letterSpacing: 0.3,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        subtitle,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.85),
                          fontSize: 12,
                          height: 1.3,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.22),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
                  ),
                  child: Icon(icon, color: Colors.white, size: 28),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
