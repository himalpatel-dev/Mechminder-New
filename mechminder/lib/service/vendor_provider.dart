import 'package:flutter/material.dart';
import '../models/reminder_vendor.dart';
import '../service/api_service.dart';

class VendorProvider extends ChangeNotifier {
  List<Vendor> _vendors = [];
  bool _isLoading = false;

  List<Vendor> get vendors => _vendors;
  bool get isLoading => _isLoading;

  Future<void> refreshVendors() async {
    _isLoading = true;
    notifyListeners();

    try {
      final List<dynamic> data = await ApiService.getVendors();
      _vendors = data.map((m) => Vendor.fromMap(m)).toList();
    } catch (e) {
      debugPrint('Vendor Provider Refresh Error: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> createVendor(Map<String, dynamic> row) async {
    await ApiService.createVendor(row);
    await refreshVendors();
  }

  Future<void> updateVendor(Map<String, dynamic> row) async {
    final id = row['id'] ?? row['_id'];
    if (id != null) {
      await ApiService.updateVendor(id, row);
      await refreshVendors();
    }
  }

  Future<void> deleteVendor(int id) async {
    await ApiService.deleteVendor(id);
    await refreshVendors();
  }
}
