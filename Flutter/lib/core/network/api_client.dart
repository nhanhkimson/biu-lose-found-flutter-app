import 'dart:convert';

import 'package:beltei_app/core/config/app_config.dart';
import 'package:beltei_app/core/media/image_upload_helper.dart';
import 'package:beltei_app/core/network/api_exception.dart';
import 'package:beltei_app/core/storage/session_store.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

/// HTTP client with Bearer session token (mobile).
class ApiClient {
  ApiClient(this._session);

  final SessionStore _session;

  Uri _uri(String path, [Map<String, String>? query]) {
    final base = Uri.parse('${AppConfig.apiBaseUrl}$path');
    if (query == null || query.isEmpty) return base;
    return base.replace(queryParameters: query);
  }

  Future<Map<String, String>> _headers({bool auth = false}) async {
    final headers = <String, String>{'Accept': 'application/json'};
    if (auth) {
      final token = await _resolveAuthToken();
      if (token != null && token.isNotEmpty) {
        headers['Authorization'] = 'Bearer $token';
      }
    }
    return headers;
  }

  Future<String?> _resolveAuthToken() async {
    final cached = await _session.sessionToken;
    if (cached != null && cached.isNotEmpty) return cached;
    return FirebaseAuth.instance.currentUser?.getIdToken();
  }

  Future<Map<String, dynamic>> get(
    String path, {
    Map<String, String>? query,
    bool auth = false,
  }) async {
    final response = await http.get(
      _uri(path, query),
      headers: await _headers(auth: auth),
    );
    return _decode(response);
  }

  Future<Map<String, dynamic>> post(
    String path, {
    Map<String, dynamic>? body,
    bool auth = false,
  }) async {
    final headers = await _headers(auth: auth);
    headers['Content-Type'] = 'application/json';
    final response = await http.post(
      _uri(path),
      headers: headers,
      body: body == null ? null : jsonEncode(body),
    );
    return _decode(response);
  }

  Future<Map<String, dynamic>> patch(
    String path, {
    required Map<String, dynamic> body,
    bool auth = true,
  }) async {
    final headers = await _headers(auth: auth);
    headers['Content-Type'] = 'application/json';
    final response = await http.patch(
      _uri(path),
      headers: headers,
      body: jsonEncode(body),
    );
    return _decode(response);
  }

  /// Compresses/converts locally, then uploads via POST /api/uploads.
  Future<String> uploadImageFile(XFile file) async {
    final prepared = await ImageUploadHelper.prepare(file);
    return uploadImage(prepared.bytes, prepared.fileName);
  }

  Future<String> uploadImage(List<int> bytes, String fileName) async {
    final uri = _uri('/api/uploads');
    final request = http.MultipartRequest('POST', uri);
    final authHeaders = await _headers(auth: true);
    request.headers.addAll(authHeaders);
    request.files.add(
      http.MultipartFile.fromBytes(
        'file',
        bytes,
        filename: fileName.endsWith('.jpg') || fileName.endsWith('.jpeg')
            ? fileName
            : 'upload.jpg',
      ),
    );
    final streamed = await request.send();
    final response = await http.Response.fromStream(streamed);
    final json = _decode(response);
    final url = json['url'] as String?;
    if (url == null || url.isEmpty) {
      throw ApiException('Upload did not return a URL.');
    }
    return url;
  }

  Map<String, dynamic> _decode(http.Response response) {
    Map<String, dynamic>? body;
    if (response.body.isNotEmpty) {
      final decoded = jsonDecode(response.body);
      if (decoded is Map<String, dynamic>) body = decoded;
    }
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return body ?? <String, dynamic>{};
    }
    final message =
        body?['error'] as String? ?? 'Request failed (${response.statusCode})';
    throw ApiException(message, statusCode: response.statusCode);
  }
}
