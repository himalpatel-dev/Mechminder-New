import 'dart:convert';
import 'package:http/http.dart' as http;
import '../core/api_constants.dart';
import 'auth_service.dart';

class ApiClient {
  // Generic request Wrapper with User Identification
  static Future<http.Response> request({
    required String method,
    required String path,
    Map<String, String>? headers,
    dynamic body,
  }) async {
    final uid = await AuthService.getUid();
    final url = Uri.parse('${ApiConstants.baseUrl}$path');

    final finalHeaders = {
      'X-User-Uid': uid ?? '',
      'Content-Type': 'application/json',
      ...?headers,
    };

    switch (method.toUpperCase()) {
      case 'GET':
        return await http.get(url, headers: finalHeaders);
      case 'POST':
        return await http.post(
          url,
          headers: finalHeaders,
          body: body != null ? json.encode(body) : null,
        );
      case 'PUT':
        return await http.put(
          url,
          headers: finalHeaders,
          body: body != null ? json.encode(body) : null,
        );
      case 'DELETE':
        return await http.delete(url, headers: finalHeaders);
      default:
        throw Exception('Unsupported HTTP method: $method');
    }
  }

  // Specialized Request for Multipart/Form-Data (Vehicle adding)
  static Future<http.StreamedResponse> multipartRequest({
    required String
    method, // Added to support PUT if needed, though mostly POST
    required String path,
    required Map<String, String> fields,
    http.MultipartFile? file,
  }) async {
    final uid = await AuthService.getUid();
    final url = Uri.parse('${ApiConstants.baseUrl}$path');

    final req = http.MultipartRequest(method, url);
    req.headers['X-User-Uid'] = uid ?? '';
    req.fields.addAll(fields);
    if (file != null) req.files.add(file);

    return await req.send();
  }
}
