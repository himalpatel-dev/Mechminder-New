import 'package:flutter/material.dart';
import '../models/service_template.dart';
import '../service/api_service.dart';

class TemplateProvider extends ChangeNotifier {
  List<ServiceTemplate> _templates = [];
  bool _isLoading = false;

  List<ServiceTemplate> get templates => _templates;
  bool get isLoading => _isLoading;

  Future<void> refreshTemplates() async {
    _isLoading = true;
    notifyListeners();

    try {
      final List<dynamic> data = await ApiService.getTemplates();
      _templates = data.map((m) => ServiceTemplate.fromMap(m)).toList();
    } catch (e) {
      debugPrint('Template Provider Refresh Error: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> createTemplate(Map<String, dynamic> row) async {
    await ApiService.createTemplate(row);
    await refreshTemplates();
  }

  Future<void> updateTemplate(Map<String, dynamic> row) async {
    final id = row['id'] ?? row['_id'];
    if (id != null) {
      await ApiService.updateTemplate(id, row);
      await refreshTemplates();
    }
  }

  Future<void> deleteTemplate(int id) async {
    await ApiService.deleteTemplate(id);
    await refreshTemplates();
  }
}
