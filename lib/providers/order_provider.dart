import 'package:flutter/foundation.dart';
import '../models/order_record.dart';
import '../services/database_service.dart';
import '../services/storage_service.dart';

class OrderProvider with ChangeNotifier {
  final DatabaseService _dbService = DatabaseService();
  final StorageService _storageService = StorageService();

  List<OrderRecord> _orders = [];
  bool _isLoading = false;
  String _searchQuery = '';
  String _selectedType = 'ALL'; // ALL, PACKING, RETURN
  String _selectedPlatform = 'ALL'; // ALL, SHOPEE, TIKTOK, LAZADA, TIKI, OTHER
  DateTime? _selectedFromDate;
  Map<String, dynamic> _stats = {
    'totalOrders': 0,
    'todayPacking': 0,
    'todayReturn': 0,
    'shopeeCount': 0,
    'tiktokCount': 0,
    'lazadaCount': 0,
    'totalBytes': 0,
  };

  List<OrderRecord> get orders => _orders;
  bool get isLoading => _isLoading;
  String get searchQuery => _searchQuery;
  String get selectedType => _selectedType;
  String get selectedPlatform => _selectedPlatform;
  DateTime? get selectedFromDate => _selectedFromDate;
  Map<String, dynamic> get stats => _stats;

  Future<void> loadOrders() async {
    _isLoading = true;
    notifyListeners();

    try {
      _orders = await _dbService.getOrders(
        searchQuery: _searchQuery,
        filterType: _selectedType,
        filterPlatform: _selectedPlatform,
        fromDate: _selectedFromDate,
      );
      _stats = await _dbService.getStatistics();
    } catch (e) {
      debugPrint('Error loading orders: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    loadOrders();
  }

  void setSelectedType(String type) {
    _selectedType = type;
    loadOrders();
  }

  void setSelectedPlatform(String platform) {
    _selectedPlatform = platform;
    loadOrders();
  }

  void setDateFilter(DateTime? date) {
    _selectedFromDate = date;
    loadOrders();
  }

  Future<void> addOrder(OrderRecord order) async {
    await _dbService.insertOrder(order);
    await loadOrders();
  }

  Future<void> deleteOrder(OrderRecord order) async {
    if (order.id != null) {
      await _dbService.deleteOrder(order.id!);
      await _storageService.deleteVideoFile(order.videoPath);
      await loadOrders();
    }
  }

  Future<void> updateOrderNote(int orderId, String note) async {
    await _dbService.updateNote(orderId, note);
    await loadOrders();
  }
}
