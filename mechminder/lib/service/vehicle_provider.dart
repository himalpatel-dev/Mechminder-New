import 'package:flutter/material.dart';
import '../models/vehicle.dart';
import '../service/api_service.dart';

class VehicleProvider extends ChangeNotifier {
  List<Vehicle> _vehicles = [];
  bool _isLoading = false;

  List<Vehicle> get vehicles => _vehicles;
  bool get isLoading => _isLoading;

  Future<void> refreshVehicles() async {
    _isLoading = true;
    notifyListeners();

    try {
      final List<dynamic> data = await ApiService.getVehicles();
      _vehicles = data.map((json) {
        // Here we map the API list to our Vehicle models
        return Vehicle.fromMap(json as Map<String, dynamic>);
      }).toList();
    } catch (e) {
      debugPrint('Vehicle Provider Refresh Error: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> deleteVehicle(int id) async {
    await ApiService.deleteVehicle(id);
    await refreshVehicles();
  }

  Future<void> updateOdometer(int id, int odometer) async {
    await ApiService.updateOdometer(id, odometer);
    await refreshVehicles();
  }
}
