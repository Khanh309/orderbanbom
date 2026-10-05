import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import '../models/order_record.dart';
import '../providers/order_provider.dart';
import '../widgets/order_card_item.dart';
import 'video_player_screen.dart';

class OrderListScreen extends StatefulWidget {
  const OrderListScreen({super.key});

  @override
  State<OrderListScreen> createState() => _OrderListScreenState();
}

class _OrderListScreenState extends State<OrderListScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<OrderProvider>().loadOrders();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _openVideo(OrderRecord order) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => VideoPlayerScreen(order: order)),
    );
  }

  Future<void> _shareVideo(OrderRecord order) async {
    final file = File(order.videoPath);
    if (await file.exists()) {
      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(order.videoPath)],
          text: 'Video ${order.typeLabel} - Mã đơn: ${order.orderCode}',
        ),
      );
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('File video không tồn tại trên bộ nhớ máy.')),
      );
    }
  }

  Future<void> _deleteOrder(OrderRecord order) async {
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
            'Bạn có chắc muốn xóa video đơn ${order.orderCode}?',
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
              child: const Text('Xóa'),
              onPressed: () => Navigator.pop(ctx, true),
            ),
          ],
        );
      },
    );

    if (!mounted) return;
    if (confirm == true) {
      await context.read<OrderProvider>().deleteOrder(order);
    }
  }

  @override
  Widget build(BuildContext context) {
    final orderProvider = context.watch<OrderProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final headerBg = isDark ? const Color(0xFF111620) : Colors.white;
    final searchBg = isDark ? const Color(0xFF161C26) : const Color(0xFFF1F5F9);
    final borderColor = isDark ? Colors.white.withValues(alpha: 0.06) : const Color(0xFFE2E8F0);
    final textTitleColor = isDark ? Colors.white : const Color(0xFF0F172A);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Quản Lý Đơn Hàng & Video',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
      ),
      body: Column(
        children: [
          // Search & Filter header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: headerBg,
              border: Border(
                bottom: BorderSide(color: borderColor, width: 1),
              ),
            ),
            child: Column(
              children: [
                // Search bar
                TextField(
                  controller: _searchController,
                  style: TextStyle(color: textTitleColor, fontSize: 14),
                  decoration: InputDecoration(
                    hintText: 'Tìm kiếm mã vận đơn / mã kiện...',
                    hintStyle: TextStyle(color: Colors.grey.shade500, fontSize: 13),
                    prefixIcon: const Icon(Icons.search, color: Color(0xFF00E676), size: 20),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, color: Colors.grey, size: 18),
                            onPressed: () {
                              _searchController.clear();
                              orderProvider.setSearchQuery('');
                            },
                          )
                        : null,
                    filled: true,
                    fillColor: searchBg,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(color: borderColor),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(color: borderColor),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(color: Color(0xFF00E676), width: 1.5),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                  onChanged: (val) => orderProvider.setSearchQuery(val),
                ),

                const SizedBox(height: 12),

                // Filter chips: Type
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildFilterChip('Tất cả loại', 'ALL', orderProvider),
                      const SizedBox(width: 8),
                      _buildFilterChip('Đóng đơn (Packing)', 'PACKING', orderProvider, color: const Color(0xFF00E676)),
                      const SizedBox(width: 8),
                      _buildFilterChip('Hàng hoàn (Return)', 'RETURN', orderProvider, color: const Color(0xFFFF5722)),
                    ],
                  ),
                ),

                const SizedBox(height: 10),

                // Filter chips: Platform
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildPlatformChip('Tất cả sàn', 'ALL', orderProvider),
                      const SizedBox(width: 8),
                      _buildPlatformChip('Shopee', 'SHOPEE', orderProvider, color: const Color(0xFFEE4D2D)),
                      const SizedBox(width: 8),
                      _buildPlatformChip('TikTok Shop', 'TIKTOK', orderProvider, color: const Color(0xFFFE2C55)),
                      const SizedBox(width: 8),
                      _buildPlatformChip('Lazada', 'LAZADA', orderProvider, color: const Color(0xFF1E88E5)),
                      const SizedBox(width: 8),
                      _buildPlatformChip('Tiki', 'TIKI', orderProvider, color: const Color(0xFF0D5CB6)),
                      const SizedBox(width: 8),
                      _buildPlatformChip('Ngoài sàn / Khác', 'OTHER', orderProvider, color: const Color(0xFF9E9E9E)),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Total count header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Tổng số: ${orderProvider.orders.length} đơn',
                  style: TextStyle(color: Colors.grey.shade400, fontSize: 13, fontWeight: FontWeight.w600),
                ),
                Text(
                  orderProvider.selectedType == 'ALL'
                      ? 'Tất cả loại'
                      : (orderProvider.selectedType == 'PACKING' ? 'Chỉ đơn đóng' : 'Chỉ đơn hoàn'),
                  style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
                ),
              ],
            ),
          ),

          // List of orders
          Expanded(
            child: orderProvider.isLoading
                ? const Center(child: CircularProgressIndicator(color: Color(0xFF00E676)))
                : orderProvider.orders.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.inventory_2_outlined, size: 64, color: Colors.grey.shade700),
                            const SizedBox(height: 12),
                            Text(
                              _searchController.text.isNotEmpty
                                  ? 'Không tìm thấy đơn hàng phù hợp'
                                  : 'Chưa có video đơn hàng nào được lưu',
                              style: TextStyle(color: Colors.grey.shade400, fontSize: 15),
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        color: const Color(0xFF00E676),
                        onRefresh: () => orderProvider.loadOrders(),
                        child: ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                          itemCount: orderProvider.orders.length,
                          itemBuilder: (context, index) {
                            final order = orderProvider.orders[index];
                            return OrderCardItem(
                              order: order,
                              onTap: () => _openVideo(order),
                              onShare: () => _shareVideo(order),
                              onDelete: () => _deleteOrder(order),
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, String value, OrderProvider provider, {Color? color}) {
    final isSelected = provider.selectedType == value;
    final activeColor = color ?? const Color(0xFF3D82F6);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return FilterChip(
      selected: isSelected,
      label: Text(
        label,
        style: TextStyle(
          color: isSelected ? Colors.black : (isDark ? Colors.white70 : const Color(0xFF334155)),
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          fontSize: 12,
        ),
      ),
      backgroundColor: isDark ? const Color(0xFF161C26) : const Color(0xFFF1F5F9),
      selectedColor: activeColor,
      checkmarkColor: Colors.black,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: isSelected ? activeColor : (isDark ? Colors.white12 : const Color(0xFFE2E8F0)),
        ),
      ),
      onSelected: (selected) {
        if (selected) {
          provider.setSelectedType(value);
        }
      },
    );
  }

  Widget _buildPlatformChip(String label, String value, OrderProvider provider, {Color? color}) {
    final isSelected = provider.selectedPlatform == value;
    final activeColor = color ?? const Color(0xFF3D82F6);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return FilterChip(
      selected: isSelected,
      label: Text(
        label,
        style: TextStyle(
          color: isSelected ? Colors.white : (isDark ? Colors.white70 : const Color(0xFF334155)),
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          fontSize: 12,
        ),
      ),
      backgroundColor: isDark ? const Color(0xFF161C26) : const Color(0xFFF1F5F9),
      selectedColor: activeColor,
      checkmarkColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: isSelected ? activeColor : (isDark ? Colors.white12 : const Color(0xFFE2E8F0)),
        ),
      ),
      onSelected: (selected) {
        if (selected) {
          provider.setSelectedPlatform(value);
        }
      },
    );
  }
}
