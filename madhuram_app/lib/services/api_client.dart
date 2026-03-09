import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'auth_storage.dart';

class ApiClient {
  static const String baseUrl = 'https://api.festmate.in';

  /// Global timeout for ALL HTTP requests.
  /// If the server is unreachable, calls fail fast instead of hanging forever.
  static const Duration _httpTimeout = Duration(seconds: 6);

  // ============================================================================
  // Helper Methods
  // ============================================================================
  static Map<String, String> _authHeaders(String? token) {
    final headers = <String, String>{'Content-Type': 'application/json'};
    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }
    return headers;
  }

  /// Wrapper: GET with timeout
  static Future<http.Response> _get(Uri uri, {Map<String, String>? headers}) =>
      http.get(uri, headers: headers).timeout(_httpTimeout);

  /// Wrapper: POST with timeout
  static Future<http.Response> _post(
    Uri uri, {
    Map<String, String>? headers,
    Object? body,
  }) => http.post(uri, headers: headers, body: body).timeout(_httpTimeout);

  /// Wrapper: PUT with timeout
  static Future<http.Response> _put(
    Uri uri, {
    Map<String, String>? headers,
    Object? body,
  }) => http.put(uri, headers: headers, body: body).timeout(_httpTimeout);

  /// Wrapper: DELETE with timeout
  static Future<http.Response> _delete(
    Uri uri, {
    Map<String, String>? headers,
  }) => http.delete(uri, headers: headers).timeout(_httpTimeout);

  /// Wrapper: PATCH with timeout
  static Future<http.Response> _patch(
    Uri uri, {
    Map<String, String>? headers,
    Object? body,
  }) => http.patch(uri, headers: headers, body: body).timeout(_httpTimeout);

  /// Helper for multipart form-data requests (for file uploads)
  static Future<Map<String, dynamic>> _multipartRequest(
    String method,
    String endpoint,
    Map<String, String> fields, {
    Map<String, File>? files,
  }) async {
    final token = await _getToken();
    final uri = Uri.parse('$baseUrl$endpoint');
    final request = http.MultipartRequest(method, uri);

    // Add authorization header
    if (token != null && token.isNotEmpty) {
      request.headers['Authorization'] = 'Bearer $token';
    }

    // Add fields
    request.fields.addAll(fields);

    // Add files
    if (files != null) {
      for (final entry in files.entries) {
        request.files.add(
          await http.MultipartFile.fromPath(entry.key, entry.value.path),
        );
      }
    }

    final streamedResponse = await request.send().timeout(_httpTimeout);
    final response = await http.Response.fromStream(streamedResponse);
    return _handleResponse(response);
  }

  static Future<Map<String, dynamic>> _handleResponse(
    http.Response response,
  ) async {
    final contentType = response.headers['content-type'] ?? '';
    dynamic data;
    try {
      if (contentType.contains('application/json')) {
        data = jsonDecode(response.body);
      } else {
        data = response.body;
      }
    } catch (_) {
      data = response.body;
    }
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return {'success': true, 'data': data};
    }
    final error = (data is Map && (data['error'] ?? data['message'] != null))
        ? (data['error'] ?? data['message'])
        : response.reasonPhrase;
    return {'success': false, 'error': error, 'status': response.statusCode};
  }

  static Future<String?> _getToken() => AuthStorage.getToken();

  /// Some environments return payloads wrapped as { data: ... }.
  /// Unwrap recursively so callers get the actual entity/list.
  static dynamic _unwrapData(dynamic data) {
    dynamic current = data;
    while (current is Map && current.containsKey('data')) {
      current = current['data'];
    }
    return current;
  }

  // ============================================================================
  // Authentication
  // ============================================================================
  static Future<Map<String, dynamic>> login(
    String email,
    String password,
  ) async {
    final uri = Uri.parse('$baseUrl/api/auth/login');
    final res = await _post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'password': password}),
    );
    final result = await _handleResponse(res);
    if (result['success'] == true) {
      final Map<String, dynamic> data = result['data'] as Map<String, dynamic>;
      final user = {
        ...((data['user'] ?? {}) as Map<String, dynamic>),
        'token': data['token'],
      };
      await AuthStorage.setUser(user);
    }
    return result;
  }

  static Future<Map<String, dynamic>> signup(
    Map<String, dynamic> userData,
  ) async {
    final uri = Uri.parse('$baseUrl/api/auth/signup');
    final res = await _post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(userData),
    );
    return _handleResponse(res);
  }

  static Future<Map<String, dynamic>> logout() async {
    final token = await _getToken();
    final uri = Uri.parse('$baseUrl/api/auth/logout');
    final res = await _post(uri, headers: _authHeaders(token));
    await AuthStorage.clear();
    return _handleResponse(res);
  }

  // ============================================================================
  // Users
  // ============================================================================
  static Future<Map<String, dynamic>> getUsers() async {
    final token = await _getToken();
    final uri = Uri.parse('$baseUrl/api/auth/users');
    final res = await _get(uri, headers: _authHeaders(token));
    return _handleResponse(res);
  }

  static Future<Map<String, dynamic>> updateUser(
    String userId,
    Map<String, dynamic> data,
  ) async {
    final token = await _getToken();
    final uri = Uri.parse('$baseUrl/api/auth/users/$userId');
    final res = await _put(
      uri,
      headers: _authHeaders(token),
      body: jsonEncode(data),
    );
    return _handleResponse(res);
  }

  static Future<Map<String, dynamic>> deleteUser(String userId) async {
    final token = await _getToken();
    final uri = Uri.parse('$baseUrl/api/auth/users/$userId');
    final res = await _delete(uri, headers: _authHeaders(token));
    return _handleResponse(res);
  }

  // ============================================================================
  // Projects
  // ============================================================================
  static Future<Map<String, dynamic>> getProjects() async {
    final token = await _getToken();
    final uri = Uri.parse('$baseUrl/api/projects');
    final res = await _get(uri, headers: _authHeaders(token));
    return _handleResponse(res);
  }

  static Future<Map<String, dynamic>> getProject(String projectId) async {
    final token = await _getToken();
    final uri = Uri.parse('$baseUrl/api/projects/$projectId');
    final res = await _get(uri, headers: _authHeaders(token));
    return _handleResponse(res);
  }

  static Future<Map<String, dynamic>> createProject(
    Map<String, dynamic> data,
  ) async {
    final token = await _getToken();
    final uri = Uri.parse('$baseUrl/api/projects');
    final res = await _post(
      uri,
      headers: _authHeaders(token),
      body: jsonEncode(data),
    );
    return _handleResponse(res);
  }

  static Future<Map<String, dynamic>> updateProject(
    String projectId,
    Map<String, dynamic> data,
  ) async {
    final token = await _getToken();
    final uri = Uri.parse('$baseUrl/api/projects/$projectId');
    final res = await _put(
      uri,
      headers: _authHeaders(token),
      body: jsonEncode(data),
    );
    return _handleResponse(res);
  }

  static Future<Map<String, dynamic>> deleteProject(String projectId) async {
    final token = await _getToken();
    final uri = Uri.parse('$baseUrl/api/projects/$projectId');
    final res = await _delete(uri, headers: _authHeaders(token));
    return _handleResponse(res);
  }

  /// Create project with file uploads (FormData)
  static Future<Map<String, dynamic>> createProjectWithFiles({
    required Map<String, dynamic> projectData,
    File? workOrderFile,
    File? masFile,
  }) async {
    final fields = <String, String>{
      'project_name': (projectData['project_name'] ?? '').toString(),
      'project_startdate': (projectData['project_startdate'] ?? '').toString(),
      'client_name': (projectData['client_name'] ?? '').toString(),
      'location': (projectData['location'] ?? '').toString(),
      'floor': (projectData['floor'] ?? '').toString(),
      'estimate_value': (projectData['estimate_value'] ?? '').toString(),
      'wo_number': (projectData['wo_number'] ?? '').toString(),
      'work_order_information': (projectData['work_order_information'] ?? '')
          .toString(),
    };

    // Add array fields with indexed keys
    final prPoTracking = projectData['pr_po_tracking'] as List? ?? [];
    for (var i = 0; i < prPoTracking.length; i++) {
      fields['pr_po_tracking[$i]'] = prPoTracking[i].toString();
    }

    final samples = projectData['samples'] as List? ?? [];
    for (var i = 0; i < samples.length; i++) {
      fields['samples[$i]'] = samples[i].toString();
    }

    final mlManagement = projectData['ml_management'] as List? ?? [];
    for (var i = 0; i < mlManagement.length; i++) {
      fields['ml_management[$i]'] = mlManagement[i].toString();
    }

    final files = <String, File>{};
    if (workOrderFile != null) files['work_order_file'] = workOrderFile;
    if (masFile != null) files['mas_file'] = masFile;

    return _multipartRequest('POST', '/api/projects', fields, files: files);
  }

  /// Update project with file uploads (FormData)
  static Future<Map<String, dynamic>> updateProjectWithFiles({
    required String projectId,
    required Map<String, dynamic> projectData,
    File? workOrderFile,
    File? masFile,
  }) async {
    final fields = <String, String>{
      'project_name': (projectData['project_name'] ?? '').toString(),
      'product_duration': (projectData['product_duration'] ?? '').toString(),
      'client_name': (projectData['client_name'] ?? '').toString(),
      'location': (projectData['location'] ?? '').toString(),
      'floor': (projectData['floor'] ?? '').toString(),
      'estimate_value': (projectData['estimate_value'] ?? '').toString(),
      'wo_number': (projectData['wo_number'] ?? '').toString(),
      'work_order_information': (projectData['work_order_information'] ?? '')
          .toString(),
    };

    // ML Management for update uses object format
    final mlManagement = projectData['ml_management'];
    if (mlManagement is Map) {
      fields['ml_management[ml_task]'] = (mlManagement['ml_task'] ?? '')
          .toString();
    }

    final prPoTracking = projectData['pr_po_tracking'] as List? ?? [];
    for (var i = 0; i < prPoTracking.length; i++) {
      fields['pr_po_tracking[$i]'] = prPoTracking[i].toString();
    }

    final samples = projectData['samples'] as List? ?? [];
    for (var i = 0; i < samples.length; i++) {
      fields['samples[$i]'] = samples[i].toString();
    }

    final files = <String, File>{};
    if (workOrderFile != null) files['work_order_file'] = workOrderFile;
    if (masFile != null) files['mas_file'] = masFile;

    return _multipartRequest(
      'PUT',
      '/api/projects/$projectId',
      fields,
      files: files,
    );
  }

  // ============================================================================
  // BOQ
  // ============================================================================
  static Future<Map<String, dynamic>> getBOQsByProject(String projectId) async {
    final token = await _getToken();
    final uri = Uri.parse('$baseUrl/api/boq/project/$projectId');
    final res = await _get(uri, headers: _authHeaders(token));
    return _handleResponse(res);
  }

  static Future<Map<String, dynamic>> createBOQ(
    Map<String, dynamic> data,
  ) async {
    final fields = <String, String>{
      // Match React contract: always send category key, default empty string.
      'category': (data['category'] ?? '').toString(),
      // Required in create flow.
      'project_id': (data['project_id'] ?? '').toString(),
    };

    if (data['item_code'] != null && data['item_code'].toString().isNotEmpty) {
      fields['item_code'] = data['item_code'].toString();
    }
    if (data['description'] != null &&
        data['description'].toString().isNotEmpty) {
      fields['description'] = data['description'].toString();
    }
    if (data['floor'] != null && data['floor'].toString().isNotEmpty) {
      fields['floor'] = data['floor'].toString();
    }
    if (data['unit'] != null && data['unit'].toString().isNotEmpty) {
      fields['unit'] = data['unit'].toString();
    }
    if (data['quantity'] != null && data['quantity'].toString().isNotEmpty) {
      fields['quantity'] = data['quantity'].toString();
    }
    if (data['rate'] != null && data['rate'].toString().isNotEmpty) {
      fields['rate'] = data['rate'].toString();
    }
    if (data['amount'] != null && data['amount'].toString().isNotEmpty) {
      fields['amount'] = data['amount'].toString();
    }

    final files = <String, File>{};
    final file = data['boq_file'];
    if (file is File) {
      files['boq_file'] = file;
    }

    return _multipartRequest(
      'POST',
      '/api/boq',
      fields,
      files: files.isEmpty ? null : files,
    );
  }

  static Future<Map<String, dynamic>> updateBOQ(
    String boqId,
    Map<String, dynamic> data,
  ) async {
    final fields = <String, String>{};
    const keys = [
      'category',
      'item_code',
      'description',
      'floor',
      'unit',
      'quantity',
      'rate',
      'amount',
      'project_id',
    ];
    for (final key in keys) {
      final value = data[key];
      if (value != null && value.toString().isNotEmpty) {
        fields[key] = value.toString();
      }
    }

    final files = <String, File>{};
    final file = data['boq_file'];
    if (file is File) {
      files['boq_file'] = file;
    }

    return _multipartRequest(
      'PUT',
      '/api/boq/$boqId',
      fields,
      files: files.isEmpty ? null : files,
    );
  }

  static Future<Map<String, dynamic>> deleteBOQ(String boqId) async {
    final token = await _getToken();
    final uri = Uri.parse('$baseUrl/api/boq/$boqId');
    final res = await _delete(uri, headers: _authHeaders(token));
    return _handleResponse(res);
  }

  /// Get individual BOQ by ID
  static Future<Map<String, dynamic>> getBOQ(String boqId) async {
    final token = await _getToken();
    final uri = Uri.parse('$baseUrl/api/boq/$boqId');
    final res = await _get(uri, headers: _authHeaders(token));
    return _handleResponse(res);
  }

  /// Get all BOQs
  static Future<Map<String, dynamic>> getAllBOQs() async {
    final token = await _getToken();
    final uri = Uri.parse('$baseUrl/api/boq');
    final res = await _get(uri, headers: _authHeaders(token));
    return _handleResponse(res);
  }

  /// Create BOQ with file upload (FormData)
  static Future<Map<String, dynamic>> createBOQWithFile({
    required Map<String, dynamic> data,
    File? boqFile,
  }) async {
    final fields = <String, String>{
      'category': (data['category'] ?? '').toString(),
      'project_id': (data['project_id'] ?? '').toString(),
      'floor': (data['floor'] ?? '').toString(),
      'unit': (data['unit'] ?? '').toString(),
      'quantity': (data['quantity'] ?? '').toString(),
      'rate': (data['rate'] ?? '').toString(),
      'amount': (data['amount'] ?? '').toString(),
    };

    // Only add optional fields if they have value
    if (data['item_code'] != null && data['item_code'].toString().isNotEmpty) {
      fields['item_code'] = data['item_code'].toString();
    }
    if (data['description'] != null &&
        data['description'].toString().isNotEmpty) {
      fields['description'] = data['description'].toString();
    }

    final files = <String, File>{};
    if (boqFile != null) files['boq_file'] = boqFile;

    return _multipartRequest('POST', '/api/boq', fields, files: files);
  }

  /// Update BOQ with file upload (FormData)
  static Future<Map<String, dynamic>> updateBOQWithFile({
    required String boqId,
    required Map<String, dynamic> data,
    File? boqFile,
  }) async {
    final fields = <String, String>{
      'category': (data['category'] ?? '').toString(),
      'project_id': (data['project_id'] ?? '').toString(),
      'floor': (data['floor'] ?? '').toString(),
      'unit': (data['unit'] ?? '').toString(),
      'quantity': (data['quantity'] ?? '').toString(),
      'rate': (data['rate'] ?? '').toString(),
      'amount': (data['amount'] ?? '').toString(),
    };

    if (data['item_code'] != null && data['item_code'].toString().isNotEmpty) {
      fields['item_code'] = data['item_code'].toString();
    }
    if (data['description'] != null &&
        data['description'].toString().isNotEmpty) {
      fields['description'] = data['description'].toString();
    }

    final files = <String, File>{};
    if (boqFile != null) files['boq_file'] = boqFile;

    return _multipartRequest('PUT', '/api/boq/$boqId', fields, files: files);
  }

  // ============================================================================
  // Samples
  // ============================================================================
  static const List<String> _sampleCreateCandidates = [
    '/api/sample',
    '/api/sample/create',
    '/api/sample/create-sample',
    '/api/samples',
    '/api/samples/create',
    '/api/samples/create-sample',
  ];

  static const List<String> _sampleUploadCandidates = [
    '/api/sample/upload',
    '/api/samples/upload',
  ];

  static const List<String> _sampleListCandidates = [
    '/api/sample',
    '/api/samples',
  ];

  static const List<String> _sampleProjectCandidates = [
    '/api/sample/project/{projectId}',
    '/api/samples/project/{projectId}',
  ];

  static const List<String> _sampleByIdCandidates = [
    '/api/sample/{id}',
    '/api/samples/{id}',
  ];

  static Future<Map<String, dynamic>> uploadSampleFiles(
    List<File> files,
  ) async {
    if (files.isEmpty) {
      return {'success': false, 'error': 'No files to upload'};
    }
    final token = await _getToken();
    Map<String, dynamic>? lastError;
    for (final path in _sampleUploadCandidates) {
      final uri = Uri.parse('$baseUrl$path');
      final request = http.MultipartRequest('POST', uri);
      if (token != null && token.isNotEmpty) {
        request.headers['Authorization'] = 'Bearer $token';
      }
      for (final f in files) {
        request.files.add(await http.MultipartFile.fromPath('file', f.path));
      }
      final streamedResponse = await request.send().timeout(_httpTimeout);
      final response = await http.Response.fromStream(streamedResponse);
      final result = await _handleResponse(response);
      if (result['success'] == true) {
        return {...result, 'data': _unwrapData(result['data'])};
      }
      lastError = result;
      if (result['status'] != 404) return result;
    }
    return lastError ??
        {'success': false, 'error': 'Upload path not found', 'status': 404};
  }

  static Future<Map<String, dynamic>> getSamples() async {
    final token = await _getToken();
    Map<String, dynamic>? lastError;
    for (final path in _sampleListCandidates) {
      final uri = Uri.parse('$baseUrl$path');
      final res = await _get(uri, headers: _authHeaders(token));
      final result = await _handleResponse(res);
      if (result['success'] == true) {
        return {...result, 'data': _unwrapData(result['data'])};
      }
      lastError = result;
      if (result['status'] != 404) return result;
    }
    return lastError ??
        {'success': false, 'error': 'List path not found', 'status': 404};
  }

  static Future<Map<String, dynamic>> getSampleById(String id) async {
    final token = await _getToken();
    Map<String, dynamic>? lastError;
    for (final path in _sampleByIdCandidates) {
      final uri = Uri.parse('$baseUrl${path.replaceAll('{id}', id)}');
      final res = await _get(uri, headers: _authHeaders(token));
      final result = await _handleResponse(res);
      if (result['success'] == true) {
        return {...result, 'data': _unwrapData(result['data'])};
      }
      lastError = result;
      if (result['status'] != 404) return result;
    }
    return lastError ??
        {'success': false, 'error': 'Get by id path not found', 'status': 404};
  }

  static Future<Map<String, dynamic>> getSamplesByProject(
    String projectId,
  ) async {
    final token = await _getToken();
    Map<String, dynamic>? lastError;
    for (final path in _sampleProjectCandidates) {
      final resolved = path.replaceAll('{projectId}', projectId);
      final uri = Uri.parse('$baseUrl$resolved');
      final res = await _get(uri, headers: _authHeaders(token));
      final result = await _handleResponse(res);
      if (result['success'] == true) {
        return {...result, 'data': _unwrapData(result['data'])};
      }
      lastError = result;
      if (result['status'] != 404) return result;
    }
    return lastError ??
        {
          'success': false,
          'error': 'Get by project path not found',
          'status': 404,
        };
  }

  static Future<Map<String, dynamic>> createSample(
    Map<String, dynamic> data,
  ) async {
    final token = await _getToken();
    final payload = Map<String, dynamic>.from(data);
    for (final k in ['location', 'item_description', 'add_fields']) {
      if (payload[k] != null && payload[k] is! String) {
        payload[k] = jsonEncode(payload[k]);
      }
    }
    Map<String, dynamic>? lastError;
    for (final path in _sampleCreateCandidates) {
      final uri = Uri.parse('$baseUrl$path');
      final res = await _post(
        uri,
        headers: _authHeaders(token),
        body: jsonEncode(payload),
      );
      final result = await _handleResponse(res);
      if (result['success'] == true) {
        return {...result, 'data': _unwrapData(result['data'])};
      }
      lastError = result;
      if (result['status'] != 404) return result;
    }
    return lastError ??
        {'success': false, 'error': 'Create path not found', 'status': 404};
  }

  static Future<Map<String, dynamic>> updateSample(
    String id,
    Map<String, dynamic> data,
  ) async {
    final token = await _getToken();
    final payload = Map<String, dynamic>.from(data);
    for (final k in ['location', 'item_description', 'add_fields']) {
      if (payload[k] != null && payload[k] is! String) {
        payload[k] = jsonEncode(payload[k]);
      }
    }
    Map<String, dynamic>? lastError;
    for (final path in _sampleByIdCandidates) {
      final uri = Uri.parse('$baseUrl${path.replaceAll('{id}', id)}');
      final res = await _put(
        uri,
        headers: _authHeaders(token),
        body: jsonEncode(payload),
      );
      final result = await _handleResponse(res);
      if (result['success'] == true) {
        return {...result, 'data': _unwrapData(result['data'])};
      }
      lastError = result;
      if (result['status'] != 404) return result;
    }
    return lastError ??
        {'success': false, 'error': 'Update path not found', 'status': 404};
  }

  static Future<Map<String, dynamic>> deleteSample(String id) async {
    final token = await _getToken();
    Map<String, dynamic>? lastError;
    for (final path in _sampleByIdCandidates) {
      final uri = Uri.parse('$baseUrl${path.replaceAll('{id}', id)}');
      final res = await _delete(uri, headers: _authHeaders(token));
      final result = await _handleResponse(res);
      if (result['success'] == true) {
        return {...result, 'data': _unwrapData(result['data'])};
      }
      lastError = result;
      if (result['status'] != 404) return result;
    }
    return lastError ??
        {'success': false, 'error': 'Delete path not found', 'status': 404};
  }

  // ============================================================================
  // Purchase Orders
  // ============================================================================
  static Future<Map<String, dynamic>> getPOsByProject(String projectId) async {
    final token = await _getToken();
    final uri = Uri.parse('$baseUrl/api/po/project/$projectId');
    final res = await _get(uri, headers: _authHeaders(token));
    return _handleResponse(res);
  }

  static Future<Map<String, dynamic>> createPO(
    Map<String, dynamic> data,
  ) async {
    final token = await _getToken();
    final uri = Uri.parse('$baseUrl/api/po');
    final res = await _post(
      uri,
      headers: _authHeaders(token),
      body: jsonEncode(data),
    );
    return _handleResponse(res);
  }

  static Future<Map<String, dynamic>> updatePO(
    String poId,
    Map<String, dynamic> data,
  ) async {
    final token = await _getToken();
    final uri = Uri.parse('$baseUrl/api/po/$poId');
    final res = await _put(
      uri,
      headers: _authHeaders(token),
      body: jsonEncode(data),
    );
    return _handleResponse(res);
  }

  static Future<Map<String, dynamic>> deletePO(String poId) async {
    final token = await _getToken();
    final uri = Uri.parse('$baseUrl/api/po/$poId');
    final res = await _delete(uri, headers: _authHeaders(token));
    return _handleResponse(res);
  }

  /// Get individual PO by ID
  static Future<Map<String, dynamic>> getPO(String poId) async {
    final token = await _getToken();
    final uri = Uri.parse('$baseUrl/api/po/$poId');
    final res = await _get(uri, headers: _authHeaders(token));
    return _handleResponse(res);
  }

  /// Upload PO file
  static Future<Map<String, dynamic>> uploadPOFile(File file) async {
    return _multipartRequest(
      'POST',
      '/api/po/upload',
      {},
      files: {'file': file},
    );
  }

  /// Parse PO file (extract structured data from uploaded PDF)
  static Future<Map<String, dynamic>> parsePOFile(File file) async {
    return _multipartRequest(
      'POST',
      '/api/po-parser/parse',
      {},
      files: {'file': file},
    );
  }

  // ============================================================================
  // MIR (Material Inspection Request)
  // ============================================================================
  static Future<Map<String, dynamic>> getMIRsByProject(String projectId) async {
    final token = await _getToken();
    final uri = Uri.parse('$baseUrl/api/mir/project/$projectId');
    final res = await _get(uri, headers: _authHeaders(token));
    return _handleResponse(res);
  }

  static Future<Map<String, dynamic>> createMIR(
    Map<String, dynamic> data,
  ) async {
    final token = await _getToken();
    final uri = Uri.parse('$baseUrl/api/mir');
    final res = await _post(
      uri,
      headers: _authHeaders(token),
      body: jsonEncode(data),
    );
    return _handleResponse(res);
  }

  static Future<Map<String, dynamic>> updateMIR(
    String mirId,
    Map<String, dynamic> data,
  ) async {
    final token = await _getToken();
    final uri = Uri.parse('$baseUrl/api/mir/$mirId');
    final res = await _put(
      uri,
      headers: _authHeaders(token),
      body: jsonEncode(data),
    );
    return _handleResponse(res);
  }

  static Future<Map<String, dynamic>> deleteMIR(String mirId) async {
    final token = await _getToken();
    final uri = Uri.parse('$baseUrl/api/mir/$mirId');
    final res = await _delete(uri, headers: _authHeaders(token));
    return _handleResponse(res);
  }

  /// Get individual MIR by ID
  static Future<Map<String, dynamic>> getMIR(String mirId) async {
    final token = await _getToken();
    final uri = Uri.parse('$baseUrl/api/mir/$mirId');
    final res = await _get(uri, headers: _authHeaders(token));
    return _handleResponse(res);
  }

  /// Get all MIRs
  static Future<Map<String, dynamic>> getAllMIRs() async {
    final token = await _getToken();
    final uri = Uri.parse('$baseUrl/api/mir');
    final res = await _get(uri, headers: _authHeaders(token));
    return _handleResponse(res);
  }

  /// Upload MIR file
  static Future<Map<String, dynamic>> uploadMIRFile(File file) async {
    return _multipartRequest(
      'POST',
      '/api/mir/upload',
      {},
      files: {'file': file},
    );
  }

  // ============================================================================
  // ITR (Installation Test Report)
  // ============================================================================
  static Future<Map<String, dynamic>> getITRsByProject(String projectId) async {
    final token = await _getToken();
    final uri = Uri.parse('$baseUrl/api/itr/project/$projectId');
    final res = await _get(uri, headers: _authHeaders(token));
    return _handleResponse(res);
  }

  static Future<Map<String, dynamic>> createITR(
    Map<String, dynamic> data,
  ) async {
    final token = await _getToken();
    final uri = Uri.parse('$baseUrl/api/itr');
    final res = await _post(
      uri,
      headers: _authHeaders(token),
      body: jsonEncode(data),
    );
    return _handleResponse(res);
  }

  static Future<Map<String, dynamic>> updateITR(
    String itrId,
    Map<String, dynamic> data,
  ) async {
    final token = await _getToken();
    final uri = Uri.parse('$baseUrl/api/itr/$itrId');
    final res = await _put(
      uri,
      headers: _authHeaders(token),
      body: jsonEncode(data),
    );
    return _handleResponse(res);
  }

  static Future<Map<String, dynamic>> deleteITR(String itrId) async {
    final token = await _getToken();
    final uri = Uri.parse('$baseUrl/api/itr/$itrId');
    final res = await _delete(uri, headers: _authHeaders(token));
    return _handleResponse(res);
  }

  /// Get individual ITR by ID
  static Future<Map<String, dynamic>> getITR(String itrId) async {
    final token = await _getToken();
    final uri = Uri.parse('$baseUrl/api/itr/$itrId');
    final res = await _get(uri, headers: _authHeaders(token));
    return _handleResponse(res);
  }

  /// Get all ITRs
  static Future<Map<String, dynamic>> getAllITRs() async {
    final token = await _getToken();
    final uri = Uri.parse('$baseUrl/api/itr');
    final res = await _get(uri, headers: _authHeaders(token));
    return _handleResponse(res);
  }

  // ============================================================================
  // Vendors
  // ============================================================================
  static Future<Map<String, dynamic>> getVendors() async {
    final token = await _getToken();
    final uri = Uri.parse('$baseUrl/api/vendors');
    final res = await _get(uri, headers: _authHeaders(token));
    return _handleResponse(res);
  }

  static Future<Map<String, dynamic>> getVendorsByProject(
    String projectId,
  ) async {
    final token = await _getToken();
    final uri = Uri.parse('$baseUrl/api/vendors/project/$projectId');
    final res = await _get(uri, headers: _authHeaders(token));
    return _handleResponse(res);
  }

  static Future<Map<String, dynamic>> createVendor(
    Map<String, dynamic> data,
  ) async {
    final token = await _getToken();
    final uri = Uri.parse('$baseUrl/api/vendors');
    final res = await _post(
      uri,
      headers: _authHeaders(token),
      body: jsonEncode(data),
    );
    return _handleResponse(res);
  }

  static Future<Map<String, dynamic>> updateVendor(
    String vendorId,
    Map<String, dynamic> data,
  ) async {
    final token = await _getToken();
    final uri = Uri.parse('$baseUrl/api/vendors/$vendorId');
    final res = await _put(
      uri,
      headers: _authHeaders(token),
      body: jsonEncode(data),
    );
    return _handleResponse(res);
  }

  static Future<Map<String, dynamic>> updateVendorStatus(
    String vendorId,
    String status,
  ) async {
    final token = await _getToken();
    final uri = Uri.parse('$baseUrl/api/vendors/$vendorId/status');
    final res = await _patch(
      uri,
      headers: _authHeaders(token),
      body: jsonEncode({'status': status}),
    );
    return _handleResponse(res);
  }

  static Future<Map<String, dynamic>> deleteVendor(String vendorId) async {
    final token = await _getToken();
    final uri = Uri.parse('$baseUrl/api/vendors/$vendorId');
    final res = await _delete(uri, headers: _authHeaders(token));
    return _handleResponse(res);
  }

  // ============================================================================
  // Materials (Product Master)
  // ============================================================================
  static Future<Map<String, dynamic>> getMaterials() async {
    final token = await _getToken();
    final uri = Uri.parse('$baseUrl/api/materials');
    final res = await _get(uri, headers: _authHeaders(token));
    return _handleResponse(res);
  }

  // ============================================================================
  // Inventory (Project-linked)
  // ============================================================================
  static Future<Map<String, dynamic>> getInventories() async {
    final token = await _getToken();
    final uri = Uri.parse('$baseUrl/api/inventory');
    final res = await _get(uri, headers: _authHeaders(token));
    return _handleResponse(res);
  }

  static Future<Map<String, dynamic>> getInventoryById(
    String inventoryId,
  ) async {
    final token = await _getToken();
    final uri = Uri.parse('$baseUrl/api/inventory/$inventoryId');
    final res = await _get(uri, headers: _authHeaders(token));
    return _handleResponse(res);
  }

  static Future<Map<String, dynamic>> getInventoriesByProject(
    String projectId,
  ) async {
    final token = await _getToken();
    final uri = Uri.parse('$baseUrl/api/inventory/project/$projectId');
    final res = await _get(uri, headers: _authHeaders(token));
    return _handleResponse(res);
  }

  static Future<Map<String, dynamic>> createInventory(
    Map<String, dynamic> data,
  ) async {
    final token = await _getToken();
    final uri = Uri.parse('$baseUrl/api/inventory');
    final payload = {
      'project_id': data['project_id'],
      'brand': data['brand'],
      'name': data['name'],
      'quantity': data['quantity'],
      'price': data['price'],
      'stockin': data['stockin'],
    };
    final res = await _post(
      uri,
      headers: _authHeaders(token),
      body: jsonEncode(payload),
    );
    return _handleResponse(res);
  }

  static Future<Map<String, dynamic>> updateInventory(
    String inventoryId,
    Map<String, dynamic> data,
  ) async {
    final token = await _getToken();
    final uri = Uri.parse('$baseUrl/api/inventory/$inventoryId');
    final payload = <String, dynamic>{};
    if (data['brand'] != null) payload['brand'] = data['brand'];
    if (data['name'] != null) payload['name'] = data['name'];
    if (data['quantity'] != null) payload['quantity'] = data['quantity'];
    if (data['price'] != null) payload['price'] = data['price'];
    if (data['stockin'] != null) payload['stockin'] = data['stockin'];
    final res = await _put(
      uri,
      headers: _authHeaders(token),
      body: jsonEncode(payload),
    );
    return _handleResponse(res);
  }

  static Future<Map<String, dynamic>> deleteInventory(
    String inventoryId,
  ) async {
    final token = await _getToken();
    final uri = Uri.parse('$baseUrl/api/inventory/$inventoryId');
    final res = await _delete(uri, headers: _authHeaders(token));
    return _handleResponse(res);
  }

  // ============================================================================
  // Stock Areas
  // ============================================================================
  static Future<Map<String, dynamic>> getStockAreas() async {
    final token = await _getToken();
    final uri = Uri.parse('$baseUrl/api/stock-areas');
    final res = await _get(uri, headers: _authHeaders(token));
    return _handleResponse(res);
  }

  // ============================================================================
  // Stock Transfers
  // ============================================================================
  static Future<Map<String, dynamic>> getStockTransfers(
    String projectId,
  ) async {
    final token = await _getToken();
    final uri = Uri.parse('$baseUrl/api/stock-transfers/project/$projectId');
    final res = await _get(uri, headers: _authHeaders(token));
    return _handleResponse(res);
  }

  // ============================================================================
  // Consumption
  // ============================================================================
  static Future<Map<String, dynamic>> getConsumption(String projectId) async {
    final token = await _getToken();
    final uri = Uri.parse('$baseUrl/api/consumption/project/$projectId');
    final res = await _get(uri, headers: _authHeaders(token));
    return _handleResponse(res);
  }

  // ============================================================================
  // Returns
  // ============================================================================
  static Future<Map<String, dynamic>> getReturns(String projectId) async {
    final token = await _getToken();
    final uri = Uri.parse('$baseUrl/api/returns/project/$projectId');
    final res = await _get(uri, headers: _authHeaders(token));
    return _handleResponse(res);
  }

  // ============================================================================
  // Challans
  // ============================================================================
  static Future<Map<String, dynamic>> getChallansByProject(
    String projectId,
  ) async {
    final token = await _getToken();
    final uri = Uri.parse('$baseUrl/api/dc/project/$projectId');
    final res = await _get(uri, headers: _authHeaders(token));
    return _handleResponse(res);
  }

  static Future<Map<String, dynamic>> getChallansByPO(String poId) async {
    final token = await _getToken();
    final uri = Uri.parse('$baseUrl/api/dc/po/$poId');
    final res = await _get(uri, headers: _authHeaders(token));
    return _handleResponse(res);
  }

  static Future<Map<String, dynamic>> getChallanById(String id) async {
    final token = await _getToken();
    final uri = Uri.parse('$baseUrl/api/dc/$id');
    final res = await _get(uri, headers: _authHeaders(token));
    return _handleResponse(res);
  }

  static Future<Map<String, dynamic>> createChallan(
    Map<String, dynamic> data,
  ) async {
    final token = await _getToken();
    final uri = Uri.parse('$baseUrl/api/dc');
    final res = await _post(
      uri,
      headers: _authHeaders(token),
      body: jsonEncode(data),
    );
    return _handleResponse(res);
  }

  static Future<Map<String, dynamic>> updateChallan(
    String id,
    Map<String, dynamic> data,
  ) async {
    final token = await _getToken();
    final uri = Uri.parse('$baseUrl/api/dc/$id');
    final res = await _put(
      uri,
      headers: _authHeaders(token),
      body: jsonEncode(data),
    );
    return _handleResponse(res);
  }

  static Future<Map<String, dynamic>> deleteChallan(String id) async {
    final token = await _getToken();
    final uri = Uri.parse('$baseUrl/api/dc/$id');
    final res = await _delete(uri, headers: _authHeaders(token));
    return _handleResponse(res);
  }

  static Future<Map<String, dynamic>> uploadChallanFile(File file) async {
    final token = await _getToken();
    final uri = Uri.parse('$baseUrl/api/dc/upload');
    final request = http.MultipartRequest('POST', uri);
    if (token != null && token.isNotEmpty) {
      request.headers['Authorization'] = 'Bearer $token';
    }
    request.files.add(await http.MultipartFile.fromPath('file', file.path));
    final streamedResponse = await request.send().timeout(_httpTimeout);
    final response = await http.Response.fromStream(streamedResponse);
    return _handleResponse(response);
  }

  // ============================================================================
  // Billing
  // ============================================================================
  static Future<Map<String, dynamic>> getBillingByProject(
    String projectId,
  ) async {
    final token = await _getToken();
    final uri = Uri.parse('$baseUrl/api/billing/project/$projectId');
    final res = await _get(uri, headers: _authHeaders(token));
    return _handleResponse(res);
  }

  // ============================================================================
  // Reports
  // ============================================================================
  static Future<Map<String, dynamic>> getReports(String projectId) async {
    final token = await _getToken();
    final uri = Uri.parse('$baseUrl/api/reports/project/$projectId');
    final res = await _get(uri, headers: _authHeaders(token));
    return _handleResponse(res);
  }

  // ============================================================================
  // Audit Logs
  // ============================================================================
  static Future<Map<String, dynamic>> getAuditLogs(String projectId) async {
    final token = await _getToken();
    final uri = Uri.parse('$baseUrl/api/audit-logs/project/$projectId');
    final res = await _get(uri, headers: _authHeaders(token));
    return _handleResponse(res);
  }

  // ============================================================================
  // Dashboard Stats
  // ============================================================================
  static Future<Map<String, dynamic>> getDashboardStats(
    String projectId,
  ) async {
    final token = await _getToken();
    final uri = Uri.parse('$baseUrl/api/dashboard/$projectId');
    final res = await _get(uri, headers: _authHeaders(token));
    return _handleResponse(res);
  }

  // ============================================================================
  // Authentication Extras
  // ============================================================================
  /// Forgot password request
  static Future<Map<String, dynamic>> forgotPassword(String email) async {
    final uri = Uri.parse('$baseUrl/api/auth/forgot-password');
    final res = await _post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email}),
    );
    return _handleResponse(res);
  }

  // ============================================================================
  // File Operations
  // ============================================================================
  /// Compress a file
  static Future<Map<String, dynamic>> compressFile(File file) async {
    return _multipartRequest(
      'POST',
      '/api/compress',
      {},
      files: {'file': file},
    );
  }

  /// Get file URL for uploaded files
  static String getFileUrl(String filename) {
    return '$baseUrl/uploads/$filename';
  }

  /// Get full API file URL
  static String getApiFileUrl(String path) {
    if (path.startsWith('http')) return path;
    return '$baseUrl$path';
  }

  // ============================================================================
  // Notifications
  // ============================================================================
  /// Get all notifications for the current user
  static Future<Map<String, dynamic>> getNotifications() async {
    final token = await _getToken();
    final uri = Uri.parse('$baseUrl/api/v1/notifications');
    final res = await _get(uri, headers: _authHeaders(token));
    return _handleResponse(res);
  }

  /// Mark a notification as read
  static Future<Map<String, dynamic>> markNotificationRead(
    String notificationId,
  ) async {
    final token = await _getToken();
    final uri = Uri.parse('$baseUrl/api/v1/notifications/$notificationId/read');
    final res = await _patch(uri, headers: _authHeaders(token));
    return _handleResponse(res);
  }

  /// Delete a notification
  static Future<Map<String, dynamic>> deleteNotification(
    String notificationId,
  ) async {
    final token = await _getToken();
    final uri = Uri.parse('$baseUrl/api/v1/notifications/$notificationId');
    final res = await _delete(uri, headers: _authHeaders(token));
    return _handleResponse(res);
  }

  /// Mark all notifications as read
  static Future<Map<String, dynamic>> markAllNotificationsRead() async {
    final token = await _getToken();
    final uri = Uri.parse('$baseUrl/api/v1/notifications/read-all');
    final res = await _patch(uri, headers: _authHeaders(token));
    return _handleResponse(res);
  }
}
