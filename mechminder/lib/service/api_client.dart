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

    final deviceId = await AuthService.getDeviceId();
    final fcmToken = await AuthService.getFcmToken();

    final finalHeaders = {
      'X-User-Uid': uid ?? '',
      'X-Device-Id': deviceId ?? '',
      'X-Fcm-Token': fcmToken ?? '',
      'Content-Type': 'application/json',
      ...?headers,
    };

    try {
      final Future<http.Response> requestFunc;
      switch (method.toUpperCase()) {
        case 'GET':
          requestFunc = http.get(url, headers: finalHeaders);
          break;
        case 'POST':
          requestFunc = http.post(
            url,
            headers: finalHeaders,
            body: body != null ? json.encode(body) : null,
          );
          break;
        case 'PUT':
          requestFunc = http.put(
            url,
            headers: finalHeaders,
            body: body != null ? json.encode(body) : null,
          );
          break;
        case 'DELETE':
          requestFunc = http.delete(url, headers: finalHeaders);
          break;
        default:
          throw Exception('Unsupported HTTP method: $method');
      }

      return await requestFunc.timeout(const Duration(seconds: 30));
    } catch (e) {
      // Return a 503 response if timeout or error happens
      return http.Response(json.encode({'error': e.toString()}), 503);
    }
  }

  // Specialized Request for Multipart/Form-Data (Vehicle adding)
  static Future<http.StreamedResponse> multipartRequest({
    required String method,
    required String path,
    required Map<String, String> fields,
    http.MultipartFile? file,
    Map<String, String>? headers,
  }) async {
    final uid = await AuthService.getUid();
    final url = Uri.parse('${ApiConstants.baseUrl}$path');

    final deviceId = await AuthService.getDeviceId();
    final fcmToken = await AuthService.getFcmToken();

    final req = http.MultipartRequest(method, url);
    req.headers['X-User-Uid'] = uid ?? '';
    req.headers['X-Device-Id'] = deviceId ?? '';
    req.headers['X-Fcm-Token'] = fcmToken ?? '';
    if (headers != null) req.headers.addAll(headers);
    req.fields.addAll(fields);
    if (file != null) req.files.add(file);

    try {
      return await req.send().timeout(const Duration(seconds: 60));
    } catch (e) {
      // Create a mocked failure response for the caller
      final mock = http.StreamedResponse(
        Stream.value(utf8.encode(json.encode({'error': 'Upload timed out after 60 seconds.'}))),
        504,
      );
      return mock;
    }
  }
}
