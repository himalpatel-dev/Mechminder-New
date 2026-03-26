import 'package:flutter/material.dart';
import '../service/api_service.dart';

class VehicleProvider with ChangeNotifier {
  List<dynamic> _vehicles = [];
  List<dynamic> _services = [];
  List<dynamic> _reminders = [];
  List<dynamic> _expenses = [];
  List<dynamic> _todolist = [];
  List<dynamic> _vendors = [];
  List<dynamic> _templates = [];
  List<dynamic> _papers = [];
  List<dynamic> _documents = [];
  List<dynamic> _photos = [];

  bool _isLoading = false;

  List<dynamic> get vehicles => _vehicles;
  List<dynamic> get services => _services;
  List<dynamic> get reminders => _reminders;
  List<dynamic> get expenses => _expenses;
  List<dynamic> get todolist => _todolist;
  List<dynamic> get vendors => _vendors;
  List<dynamic> get templates => _templates;
  List<dynamic> get papers => _papers;
  List<dynamic> get documents => _documents;
  List<dynamic> get photos => _photos;
  bool get isLoading => _isLoading;

  // --- Initial Full Sync (The "Restore") ---
  Future<void> syncAllData() async {
    _isLoading = true;
    notifyListeners();

    try {
      final data = await ApiService.fetchFullAppState();
      if (data != null) {
        _vehicles = data['vehicles'] ?? [];
        _services = data['services'] ?? [];
        _reminders = data['reminders'] ?? [];
        _expenses = data['expenses'] ?? [];
        _todolist = data['todolist'] ?? [];
        _vendors = data['vendors'] ?? [];
        _templates = data['service_templates'] ?? [];
        _papers = data['vehicle_papers'] ?? [];
        _documents = data['documents'] ?? [];
        _photos = data['photos'] ?? [];
      }
    } catch (e) {
      debugPrint("VehicleProvider Sync Error: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // --- CRUD Operations (Updating Cloud directly) ---

  Future<void> addVehicle(Map<String, String> fields, {String? photoName, List<int>? photoBytes}) async {
    final result = await ApiService.registerVehicle(fields, photoName: photoName, photoBytes: photoBytes);
    if (result != null) {
      await syncAllData(); 
    }
  }

  Future<void> deleteVehicle(int id) async {
    await ApiService.deleteVehicle(id);
    _vehicles.removeWhere((v) => v['id'] == id);
    notifyListeners();
  }

  // Helper to get vehicle by ID from local state
  Map<String, dynamic>? getVehicleById(int id) {
    try {
      return _vehicles.firstWhere((v) => v['id'] == id);
    } catch (_) {
      return null;
    }
  }

  // Highlights for home screen
  List<dynamic> get upcomingReminders {
    return _reminders.where((r) => r['status'] == 'pending').toList();
  }

  List<dynamic> get expiringPapers {
     // Filter papers where expiry_date is close
     // (Simplified logic for now)
     return _papers.toList();
  }

}
