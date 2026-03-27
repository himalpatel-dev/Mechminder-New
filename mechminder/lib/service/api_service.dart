import 'dart:convert';
import 'package:http/http.dart' as http;
import 'api_client.dart';
import '../core/api_constants.dart';

class ApiService {
  // --- Vehicles ---
  static Future<List<dynamic>> getVehicles() async {
    final res = await ApiClient.request(
      method: 'GET',
      path: ApiConstants.vehicles,
    );
    if (res.statusCode == 200) return json.decode(res.body);
    return [];
  }

  static Future<dynamic> getVehicleById(int id) async {
    final res = await ApiClient.request(
      method: 'GET',
      path: ApiConstants.vehicleDetails.replaceAll('{id}', id.toString()),
    );
    if (res.statusCode == 200) return json.decode(res.body);
    return null;
  }

  static Future<void> updateVehicle(
    int id,
    Map<String, String> fields, {
    String? photoName,
    List<int>? photoBytes,
  }) async {
    final path = ApiConstants.vehicleDetails.replaceAll('{id}', id.toString());

    if (photoBytes != null && photoName != null) {
      final file = http.MultipartFile.fromBytes(
        'photo',
        photoBytes,
        filename: photoName,
      );
      await ApiClient.multipartRequest(
        method: 'PUT',
        path: path,
        fields: fields,
        file: file,
      );
    } else {
      await ApiClient.request(method: 'PUT', path: path, body: fields);
    }
  }

  static Future<void> deleteVehicle(int id) async {
    await ApiClient.request(
      method: 'DELETE',
      path: ApiConstants.vehicleDetails.replaceAll('{id}', id.toString()),
    );
  }

  static Future<dynamic> registerVehicle(
    Map<String, String> fields, {
    String? photoPath,
    String? photoName,
    List<int>? photoBytes,
  }) async {
    http.MultipartFile? file;
    if (photoBytes != null && photoName != null) {
      file = http.MultipartFile.fromBytes(
        'photo',
        photoBytes,
        filename: photoName,
      );
    }

    final streamedRes = await ApiClient.multipartRequest(
      method: 'POST',
      path: ApiConstants.vehicles,
      fields: fields,
      file: file,
    );
    final res = await http.Response.fromStream(streamedRes);
    if (res.statusCode == 201) return json.decode(res.body);
    return null;
  }

  static Future<dynamic> uploadPhoto({
    required int parentId,
    required String parentType,
    required dynamic imageFile, // Can be XFile
  }) async {
    final bytes = await imageFile.readAsBytes();
    final name = imageFile.name;

    final file = http.MultipartFile.fromBytes('photo', bytes, filename: name);

    final streamedRes = await ApiClient.multipartRequest(
      method: 'POST',
      path: '/photos',
      fields: {'parent_id': parentId.toString(), 'parent_type': parentType},
      file: file,
      headers: {'X-Parent-Type': parentType},
    );
    final res = await http.Response.fromStream(streamedRes);
    if (res.statusCode == 201) return json.decode(res.body);
    return null;
  }

  static Future<void> deletePhoto(int id) async {
    await ApiClient.request(method: 'DELETE', path: '/photos/$id');
  }

  static Future<void> updateOdometer(int id, int odometer) async {
    await ApiClient.request(
      method: 'PUT',
      path: ApiConstants.vehicleOdometer.replaceAll('{id}', id.toString()),
      body: {'current_odometer': odometer},
    );
  }

  // --- To-Do ---
  static Future<List<dynamic>> getPendingTodos() async {
    final res = await ApiClient.request(
      method: 'GET',
      path: ApiConstants.todosPending,
    );
    if (res.statusCode == 200) return json.decode(res.body);
    return [];
  }

  static Future<List<dynamic>> getCompletedTodos() async {
    final res = await ApiClient.request(
      method: 'GET',
      path: ApiConstants.todosCompleted,
    );
    if (res.statusCode == 200) return json.decode(res.body);
    return [];
  }

  static Future<dynamic> createTodo(Map<String, dynamic> data) async {
    final res = await ApiClient.request(
      method: 'POST',
      path: ApiConstants.todosAction,
      body: data,
    );
    if (res.statusCode == 201) return json.decode(res.body);
    return null;
  }

  static Future<void> updateTodoStatus(int id, String status) async {
    await ApiClient.request(
      method: 'PUT',
      path: ApiConstants.todoStatus.replaceAll('{id}', id.toString()),
      body: {'status': status},
    );
  }

  static Future<void> deleteTodo(int id) async {
    await ApiClient.request(
      method: 'DELETE',
      path: ApiConstants.todoDelete.replaceAll('{id}', id.toString()),
    );
  }

  // --- Vendors ---
  static Future<List<dynamic>> getVendors() async {
    final res = await ApiClient.request(
      method: 'GET',
      path: ApiConstants.vendors,
    );
    if (res.statusCode == 200) return json.decode(res.body);
    return [];
  }

  static Future<dynamic> createVendor(Map<String, dynamic> data) async {
    final res = await ApiClient.request(
      method: 'POST',
      path: ApiConstants.vendors,
      body: data,
    );
    if (res.statusCode == 201) return json.decode(res.body);
    return null;
  }

  static Future<void> updateVendor(int id, Map<String, dynamic> data) async {
    await ApiClient.request(
      method: 'PUT',
      path: '${ApiConstants.vendors}/$id',
      body: data,
    );
  }

  static Future<void> deleteVendor(int id) async {
    await ApiClient.request(
      method: 'DELETE',
      path: '${ApiConstants.vendors}/$id',
    );
  }

  // --- Services ---
  static Future<List<dynamic>> getServicesForVehicle(int vehicleId) async {
    final res = await ApiClient.request(
      method: 'GET',
      path: ApiConstants.vehicleServices.replaceAll(
        '{vehicleId}',
        vehicleId.toString(),
      ),
    );
    if (res.statusCode == 200) return json.decode(res.body);
    return [];
  }

  static Future<dynamic> getServiceById(int serviceId) async {
    final res = await ApiClient.request(
      method: 'GET',
      path: ApiConstants.serviceDetails.replaceAll(
        '{serviceId}',
        serviceId.toString(),
      ),
    );
    if (res.statusCode == 200) return json.decode(res.body);
    return null;
  }

  static Future<dynamic> createService(Map<String, dynamic> data) async {
    final res = await ApiClient.request(
      method: 'POST',
      path: ApiConstants.services,
      body: data,
    );
    if (res.statusCode == 201) return json.decode(res.body);
    return null;
  }

  static Future<void> updateService(int id, Map<String, dynamic> data) async {
    await ApiClient.request(
      method: 'PUT',
      path: '${ApiConstants.services}/$id',
      body: data,
    );
  }

  static Future<void> deleteService(int id) async {
    await ApiClient.request(
      method: 'DELETE',
      path: '${ApiConstants.services}/$id',
    );
  }

  // --- Reminders ---
  static Future<List<dynamic>> getRemindersForVehicle(int vehicleId) async {
    final res = await ApiClient.request(
      method: 'GET',
      path: ApiConstants.vehicleReminders.replaceAll(
        '{vehicleId}',
        vehicleId.toString(),
      ),
    );
    if (res.statusCode == 200) return json.decode(res.body);
    return [];
  }

  static Future<dynamic> createReminder(Map<String, dynamic> data) async {
    final res = await ApiClient.request(
      method: 'POST',
      path: ApiConstants.reminders,
      body: data,
    );
    if (res.statusCode == 201) return json.decode(res.body);
    return null;
  }

  static Future<void> updateReminder(
    int id, {
    String? dueDate,
    int? dueOdometer,
    String? status,
  }) async {
    await ApiClient.request(
      method: 'PUT',
      path: '${ApiConstants.reminders}/$id',
      body: {
        if (dueDate != null) 'due_date': dueDate,
        if (dueOdometer != null) 'due_odometer': dueOdometer,
        if (status != null) 'status': status,
      },
    );
  }

  static Future<void> completeRemindersByTemplate({
    required int vehicleId,
    required int templateId,
    required int serviceId,
  }) async {
    await ApiClient.request(
      method: 'PUT',
      path: '/reminders/complete-by-template',
      body: {
        'vehicle_id': vehicleId,
        'template_id': templateId,
        'service_id': serviceId,
      },
    );
  }

  static Future<void> deleteReminder(int id) async {
    await ApiClient.request(
      method: 'DELETE',
      path: '${ApiConstants.reminders}/$id',
    );
  }

  // --- Expenses ---
  static Future<List<dynamic>> getExpensesForVehicle(int vehicleId) async {
    final res = await ApiClient.request(
      method: 'GET',
      path: ApiConstants.vehicleExpenses.replaceAll(
        '{vehicleId}',
        vehicleId.toString(),
      ),
    );
    if (res.statusCode == 200) return json.decode(res.body);
    return [];
  }

  static Future<dynamic> createExpense(Map<String, dynamic> data) async {
    final res = await ApiClient.request(
      method: 'POST',
      path: ApiConstants.expenses,
      body: data,
    );
    if (res.statusCode == 201) return json.decode(res.body);
    return null;
  }

  static Future<void> updateExpense(int id, Map<String, dynamic> data) async {
    await ApiClient.request(
      method: 'PUT',
      path: '${ApiConstants.expenses}/$id',
      body: data,
    );
  }

  static Future<void> deleteExpense(int id) async {
    await ApiClient.request(
      method: 'DELETE',
      path: '${ApiConstants.expenses}/$id',
    );
  }

  // --- Papers ---
  static Future<List<dynamic>> getPapersForVehicle(int vehicleId) async {
    final res = await ApiClient.request(
      method: 'GET',
      path: ApiConstants.vehiclePapers.replaceAll(
        '{vehicleId}',
        vehicleId.toString(),
      ),
    );
    if (res.statusCode == 200) return json.decode(res.body);
    return [];
  }

  static Future<dynamic> createPaper(Map<String, dynamic> data) async {
    final res = await ApiClient.request(
      method: 'POST',
      path: ApiConstants.papers,
      body: data,
    );
    if (res.statusCode == 201) return json.decode(res.body);
    return null;
  }

  static Future<void> updatePaper(int id, Map<String, dynamic> data) async {
    await ApiClient.request(
      method: 'PUT',
      path: '${ApiConstants.papers}/$id',
      body: data,
    );
  }

  static Future<void> deletePaper(int id) async {
    await ApiClient.request(
      method: 'DELETE',
      path: '${ApiConstants.papers}/$id',
    );
  }

  // --- Templates ---
  static Future<List<dynamic>> getTemplates() async {
    final res = await ApiClient.request(
      method: 'GET',
      path: ApiConstants.templates,
    );
    if (res.statusCode == 200) return json.decode(res.body);
    return [];
  }

  static Future<dynamic> createTemplate(Map<String, dynamic> data) async {
    final res = await ApiClient.request(
      method: 'POST',
      path: ApiConstants.templates,
      body: data,
    );
    if (res.statusCode == 201) return json.decode(res.body);
    return null;
  }

  static Future<void> updateTemplate(int id, Map<String, dynamic> data) async {
    await ApiClient.request(
      method: 'PUT',
      path: '${ApiConstants.templates}/$id',
      body: data,
    );
  }

  static Future<void> deleteTemplate(int id) async {
    await ApiClient.request(
      method: 'DELETE',
      path: '${ApiConstants.templates}/$id',
    );
  }

  // --- Documents ---
  static Future<List<dynamic>> getDocuments() async {
    final res = await ApiClient.request(
      method: 'GET',
      path: ApiConstants.documents,
    );
    if (res.statusCode == 200) return json.decode(res.body);
    return [];
  }

  static Future<List<dynamic>> getDocumentsForVehicle(int vehicleId) async {
    final res = await ApiClient.request(
      method: 'GET',
      path: ApiConstants.vehicleDocuments.replaceAll(
        '{vehicleId}',
        vehicleId.toString(),
      ),
    );
    if (res.statusCode == 200) return json.decode(res.body);
    return [];
  }

  static Future<dynamic> createDocument(
    Map<String, String> fields, {
    String? fileName,
    List<int>? fileBytes,
  }) async {
    http.MultipartFile? file;
    if (fileBytes != null && fileName != null) {
      file = http.MultipartFile.fromBytes(
        'document',
        fileBytes,
        filename: fileName,
      );
    }

    final streamedRes = await ApiClient.multipartRequest(
      method: 'POST',
      path: ApiConstants.documents,
      fields: fields,
      file: file,
    );
    final res = await http.Response.fromStream(streamedRes);
    if (res.statusCode == 201) return json.decode(res.body);
    return null;
  }

  static Future<void> deleteDocument(int id) async {
    await ApiClient.request(
      method: 'DELETE',
      path: ApiConstants.documentDetails.replaceAll('{id}', id.toString()),
    );
  }

  // --- Users ---
  static Future<dynamic> syncUserAndFCM(Map<String, dynamic> data) async {
    final res = await ApiClient.request(
      method: 'POST',
      path: ApiConstants.userUpdateFCM,
      body: data,
    );
    if (res.statusCode == 201 || res.statusCode == 200)
      return json.decode(res.body);
    return null;
  }

  static Future<void> updateFCMToken(String uid, String token) async {
    await ApiClient.request(
      method: 'POST',
      path: ApiConstants.userUpdateFCM,
      body: {'firebase_uid': uid, 'fcm_token': token},
    );
  }

  static Future<void> updatePurchaseId(
    String uid,
    String purchaseId, {
    String? fcmToken,
    String? deviceId,
  }) async {
    await ApiClient.request(
      method: 'POST',
      path: ApiConstants.userUpdatePurchase,
      body: {
        'firebase_uid': uid,
        'purchase_id': purchaseId,
        if (fcmToken != null) 'fcm_token': fcmToken,
        if (deviceId != null) 'device_id': deviceId,
      },
    );
  }

  // --- Bulk Sync ---
  static Future<Map<String, dynamic>?> fetchFullAppState() async {
    final res = await ApiClient.request(
      method: 'GET',
      path: ApiConstants.restoreData,
    );
    if (res.statusCode == 200) return json.decode(res.body);
    return null;
  }

  static Future<void> pushFullBackup(Map<String, dynamic> data) async {
    await ApiClient.request(
      method: 'POST',
      path: ApiConstants.backupData,
      body: data,
    );
  }
}

