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
  static Future<http.Response> _post(Uri uri,
          {Map<String, String>? headers, Object? body}) =>
      http.post(uri, headers: headers, body: body).timeout(_httpTimeout);

  /// Wrapper: PUT with timeout
  static Future<http.Response> _put(Uri uri,
          {Map<String, String>? headers, Object? body}) =>
      http.put(uri, headers: headers, body: body).timeout(_httpTimeout);

  /// Wrapper: DELETE with timeout
  static Future<http.Response> _delete(Uri uri,
          {Map<String, String>? headers}) =>
      http.delete(uri, headers: headers).timeout(_httpTimeout);

  /// Wrapper: PATCH with timeout
  static Future<http.Response> _patch(Uri uri,
          {Map<String, String>? headers, Object? body}) =>
      http.patch(uri, headers: headers, body: body).timeout(_httpTimeout);

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
        request.files.add(await http.MultipartFile.fromPath(
          entry.key,
          entry.value.path,
        ));
      }
    }
    
    final streamedResponse = await request.send().timeout(_httpTimeout);
    final response = await http.Response.fromStream(streamedResponse);
    return _handleResponse(response);
  }

  static Future<Map<String, dynamic>> _handleResponse(http.Response response) async {
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

  // ============================================================================
  // Authentication
  // ============================================================================
  static Future<Map<String, dynamic>> login(String email, String password) async {
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

  static Future<Map<String, dynamic>> signup(Map<String, dynamic> userData) async {
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
    if (token == 'demo-token') {
      return {
        'success': true,
        'data': [
          {'user_id': '1', 'name': 'Admin User', 'email': 'admin@madhuram.com', 'role': 'admin', 'phone_number': '9999999999'},
          {'user_id': '2', 'name': 'Project Manager', 'email': 'pm@madhuram.com', 'role': 'project_manager', 'phone_number': '9888888888'},
        ],
      };
    }
    final uri = Uri.parse('$baseUrl/api/auth/users');
    final res = await _get(uri, headers: _authHeaders(token));
    return _handleResponse(res);
  }

  static Future<Map<String, dynamic>> updateUser(String userId, Map<String, dynamic> data) async {
    final token = await _getToken();
    final uri = Uri.parse('$baseUrl/api/auth/users/$userId');
    final res = await _put(uri, headers: _authHeaders(token), body: jsonEncode(data));
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
    if (token == 'demo-token') {
      return {
        'success': true,
        'data': [
          {
            'project_id': 'PRJ-001',
            'project_name': 'Oakwood Plumbing',
            'client_name': 'Oakwood',
            'location': 'Mumbai',
            'floor': '1-5',
            'estimate_value': '₹1.2 Cr',
            'status': 'Active',
            'start_date': '2024-01-15',
          },
          {
            'project_id': 'PRJ-002',
            'project_name': 'Nanhi Trap Jali',
            'client_name': 'NANHI',
            'location': 'Pune',
            'floor': 'Ground',
            'estimate_value': '₹40 Lakh',
            'status': 'Planning',
            'start_date': '2024-02-01',
          },
        ],
      };
    }
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

  static Future<Map<String, dynamic>> createProject(Map<String, dynamic> data) async {
    final token = await _getToken();
    final uri = Uri.parse('$baseUrl/api/projects');
    final res = await _post(uri, headers: _authHeaders(token), body: jsonEncode(data));
    return _handleResponse(res);
  }

  static Future<Map<String, dynamic>> updateProject(String projectId, Map<String, dynamic> data) async {
    final token = await _getToken();
    final uri = Uri.parse('$baseUrl/api/projects/$projectId');
    final res = await _put(uri, headers: _authHeaders(token), body: jsonEncode(data));
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
      'work_order_information': (projectData['work_order_information'] ?? '').toString(),
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
      'work_order_information': (projectData['work_order_information'] ?? '').toString(),
    };

    // ML Management for update uses object format
    final mlManagement = projectData['ml_management'];
    if (mlManagement is Map) {
      fields['ml_management[ml_task]'] = (mlManagement['ml_task'] ?? '').toString();
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

    return _multipartRequest('PUT', '/api/projects/$projectId', fields, files: files);
  }

  // ============================================================================
  // BOQ
  // ============================================================================
  static Future<Map<String, dynamic>> getBOQsByProject(String projectId) async {
    final token = await _getToken();
    if (token == 'demo-token') {
      return {
        'success': true,
        'data': [
          {'boq_id': '1', 'item_code': 'C-101', 'category': 'Civil', 'description': 'Cement Grade 53', 'unit': 'Bags', 'quantity': 500, 'rate': 350, 'amount': 175000, 'floor': 'Ground'},
          {'boq_id': '2', 'item_code': 'P-201', 'category': 'Plumbing', 'description': 'PVC Pipe 4 inch', 'unit': 'Meters', 'quantity': 200, 'rate': 120, 'amount': 24000, 'floor': '1st'},
        ],
      };
    }
    final uri = Uri.parse('$baseUrl/api/boq/project/$projectId');
    final res = await _get(uri, headers: _authHeaders(token));
    return _handleResponse(res);
  }

  static Future<Map<String, dynamic>> createBOQ(Map<String, dynamic> data) async {
    final token = await _getToken();
    final uri = Uri.parse('$baseUrl/api/boq');
    final res = await _post(uri, headers: _authHeaders(token), body: jsonEncode(data));
    return _handleResponse(res);
  }

  static Future<Map<String, dynamic>> updateBOQ(String boqId, Map<String, dynamic> data) async {
    final token = await _getToken();
    final uri = Uri.parse('$baseUrl/api/boq/$boqId');
    final res = await _put(uri, headers: _authHeaders(token), body: jsonEncode(data));
    return _handleResponse(res);
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
    if (data['description'] != null && data['description'].toString().isNotEmpty) {
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
    if (data['description'] != null && data['description'].toString().isNotEmpty) {
      fields['description'] = data['description'].toString();
    }

    final files = <String, File>{};
    if (boqFile != null) files['boq_file'] = boqFile;

    return _multipartRequest('PUT', '/api/boq/$boqId', fields, files: files);
  }

  // ============================================================================
  // Purchase Orders
  // ============================================================================
  static Future<Map<String, dynamic>> getPOsByProject(String projectId) async {
    final token = await _getToken();
    if (token == 'demo-token') {
      return {
        'success': true,
        'data': [
          {'po_id': '1', 'order_no': 'PO-001', 'po_date': '2024-01-20', 'vendor_name': 'ABC Suppliers', 'total_amount': '₹50,000', 'status': 'Submitted'},
          {'po_id': '2', 'order_no': 'PO-002', 'po_date': '2024-01-25', 'vendor_name': 'XYZ Traders', 'total_amount': '₹1,25,000', 'status': 'Draft'},
        ],
      };
    }
    final uri = Uri.parse('$baseUrl/api/po/project/$projectId');
    final res = await _get(uri, headers: _authHeaders(token));
    return _handleResponse(res);
  }

  static Future<Map<String, dynamic>> createPO(Map<String, dynamic> data) async {
    final token = await _getToken();
    final uri = Uri.parse('$baseUrl/api/po');
    final res = await _post(uri, headers: _authHeaders(token), body: jsonEncode(data));
    return _handleResponse(res);
  }

  static Future<Map<String, dynamic>> updatePO(String poId, Map<String, dynamic> data) async {
    final token = await _getToken();
    final uri = Uri.parse('$baseUrl/api/po/$poId');
    final res = await _put(uri, headers: _authHeaders(token), body: jsonEncode(data));
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
    return _multipartRequest('POST', '/api/po/upload', {}, files: {'file': file});
  }

  // ============================================================================
  // MIR (Material Inspection Request)
  // ============================================================================
  static Future<Map<String, dynamic>> getMIRsByProject(String projectId) async {
    final token = await _getToken();
    if (token == 'demo-token') {
      return {
        'success': true,
        'data': [
          {'mir_id': '1', 'mir_refrence_no': 'MIR-001', 'material_code': 'M-001', 'client_name': 'Oakwood', 'status': 'Pending'},
          {'mir_id': '2', 'mir_refrence_no': 'MIR-002', 'material_code': 'M-002', 'client_name': 'Oakwood', 'status': 'Approved'},
        ],
      };
    }
    final uri = Uri.parse('$baseUrl/api/mir/project/$projectId');
    final res = await _get(uri, headers: _authHeaders(token));
    return _handleResponse(res);
  }

  static Future<Map<String, dynamic>> createMIR(Map<String, dynamic> data) async {
    final token = await _getToken();
    final uri = Uri.parse('$baseUrl/api/mir');
    final res = await _post(uri, headers: _authHeaders(token), body: jsonEncode(data));
    return _handleResponse(res);
  }

  static Future<Map<String, dynamic>> updateMIR(String mirId, Map<String, dynamic> data) async {
    final token = await _getToken();
    final uri = Uri.parse('$baseUrl/api/mir/$mirId');
    final res = await _put(uri, headers: _authHeaders(token), body: jsonEncode(data));
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
    return _multipartRequest('POST', '/api/mir/upload', {}, files: {'file': file});
  }

  // ============================================================================
  // ITR (Installation Test Report)
  // ============================================================================
  static Future<Map<String, dynamic>> getITRsByProject(String projectId) async {
    final token = await _getToken();
    if (token == 'demo-token') {
      return {
        'success': true,
        'data': [
          {'itr_id': '1', 'itr_ref_no': 'ITR-001', 'project_name': 'Oakwood Plumbing', 'discipline': 'Plumbing', 'status': 'Pending'},
          {'itr_id': '2', 'itr_ref_no': 'ITR-002', 'project_name': 'Oakwood Plumbing', 'discipline': 'Fire Fighting', 'status': 'Completed'},
        ],
      };
    }
    final uri = Uri.parse('$baseUrl/api/itr/project/$projectId');
    final res = await _get(uri, headers: _authHeaders(token));
    return _handleResponse(res);
  }

  static Future<Map<String, dynamic>> createITR(Map<String, dynamic> data) async {
    final token = await _getToken();
    final uri = Uri.parse('$baseUrl/api/itr');
    final res = await _post(uri, headers: _authHeaders(token), body: jsonEncode(data));
    return _handleResponse(res);
  }

  static Future<Map<String, dynamic>> updateITR(String itrId, Map<String, dynamic> data) async {
    final token = await _getToken();
    final uri = Uri.parse('$baseUrl/api/itr/$itrId');
    final res = await _put(uri, headers: _authHeaders(token), body: jsonEncode(data));
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
    if (token == 'demo-token') {
      return {
        'success': true,
        'data': [
          {'vendor_id': '1', 'name': 'ABC Suppliers', 'contact_person': 'John Doe', 'phone': '9876543210', 'email': 'abc@suppliers.com', 'address': 'Mumbai', 'status': 'Active', 'rating': 4.5},
          {'vendor_id': '2', 'name': 'XYZ Traders', 'contact_person': 'Jane Smith', 'phone': '9876543211', 'email': 'xyz@traders.com', 'address': 'Pune', 'status': 'Active', 'rating': 4.0},
        ],
      };
    }
    final uri = Uri.parse('$baseUrl/api/vendors');
    final res = await _get(uri, headers: _authHeaders(token));
    return _handleResponse(res);
  }

  static Future<Map<String, dynamic>> createVendor(Map<String, dynamic> data) async {
    final token = await _getToken();
    final uri = Uri.parse('$baseUrl/api/vendors');
    final res = await _post(uri, headers: _authHeaders(token), body: jsonEncode(data));
    return _handleResponse(res);
  }

  static Future<Map<String, dynamic>> updateVendor(String vendorId, Map<String, dynamic> data) async {
    final token = await _getToken();
    final uri = Uri.parse('$baseUrl/api/vendors/$vendorId');
    final res = await _put(uri, headers: _authHeaders(token), body: jsonEncode(data));
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
    if (token == 'demo-token') {
      return {
        'success': true,
        'data': [
          {'material_id': '1', 'code': 'MAT-001', 'name': 'Cement OPC 53', 'category': 'Civil', 'unit': 'Bags', 'stock': 500},
          {'material_id': '2', 'code': 'MAT-002', 'name': 'PVC Pipe 4"', 'category': 'Plumbing', 'unit': 'Meters', 'stock': 200},
        ],
      };
    }
    final uri = Uri.parse('$baseUrl/api/materials');
    final res = await _get(uri, headers: _authHeaders(token));
    return _handleResponse(res);
  }

  // ============================================================================
  // Stock Areas
  // ============================================================================
  static Future<Map<String, dynamic>> getStockAreas() async {
    final token = await _getToken();
    if (token == 'demo-token') {
      return {
        'success': true,
        'data': [
          {'area_id': '1', 'name': 'Main Warehouse', 'location': 'Site A', 'capacity': 1000, 'current_stock': 650},
          {'area_id': '2', 'name': 'Secondary Store', 'location': 'Site B', 'capacity': 500, 'current_stock': 320},
        ],
      };
    }
    final uri = Uri.parse('$baseUrl/api/stock-areas');
    final res = await _get(uri, headers: _authHeaders(token));
    return _handleResponse(res);
  }

  // ============================================================================
  // Stock Transfers
  // ============================================================================
  static Future<Map<String, dynamic>> getStockTransfers(String projectId) async {
    final token = await _getToken();
    if (token == 'demo-token') {
      return {
        'success': true,
        'data': [
          {'transfer_id': '1', 'from_area': 'Main Warehouse', 'to_area': 'Secondary Store', 'material': 'Cement', 'quantity': 50, 'date': '2024-01-20', 'status': 'Completed'},
        ],
      };
    }
    final uri = Uri.parse('$baseUrl/api/stock-transfers/project/$projectId');
    final res = await _get(uri, headers: _authHeaders(token));
    return _handleResponse(res);
  }

  // ============================================================================
  // Consumption
  // ============================================================================
  static Future<Map<String, dynamic>> getConsumption(String projectId) async {
    final token = await _getToken();
    if (token == 'demo-token') {
      return {
        'success': true,
        'data': [
          {'consumption_id': '1', 'material': 'Cement', 'quantity': 100, 'unit': 'Bags', 'date': '2024-01-20', 'floor': 'Ground'},
        ],
      };
    }
    final uri = Uri.parse('$baseUrl/api/consumption/project/$projectId');
    final res = await _get(uri, headers: _authHeaders(token));
    return _handleResponse(res);
  }

  // ============================================================================
  // Returns
  // ============================================================================
  static Future<Map<String, dynamic>> getReturns(String projectId) async {
    final token = await _getToken();
    if (token == 'demo-token') {
      return {
        'success': true,
        'data': [
          {'return_id': '1', 'material': 'PVC Pipe', 'quantity': 20, 'reason': 'Damaged', 'date': '2024-01-22', 'status': 'Processed'},
        ],
      };
    }
    final uri = Uri.parse('$baseUrl/api/returns/project/$projectId');
    final res = await _get(uri, headers: _authHeaders(token));
    return _handleResponse(res);
  }

  // ============================================================================
  // Challans
  // ============================================================================
  static Future<Map<String, dynamic>> getChallansByProject(String projectId) async {
    final token = await _getToken();
    if (token == 'demo-token') {
      return {
        'success': true,
        'data': [
          {'challan_id': '1', 'challan_no': 'DC-001', 'vendor': 'ABC Suppliers', 'date': '2024-01-20', 'items': 5, 'status': 'Received'},
        ],
      };
    }
    final uri = Uri.parse('$baseUrl/api/challans/project/$projectId');
    final res = await _get(uri, headers: _authHeaders(token));
    return _handleResponse(res);
  }

  // ============================================================================
  // Billing
  // ============================================================================
  static Future<Map<String, dynamic>> getBillingByProject(String projectId) async {
    final token = await _getToken();
    if (token == 'demo-token') {
      return {
        'success': true,
        'data': [
          {'bill_id': '1', 'invoice_no': 'INV-001', 'amount': '₹1,50,000', 'date': '2024-01-25', 'status': 'Pending'},
        ],
      };
    }
    final uri = Uri.parse('$baseUrl/api/billing/project/$projectId');
    final res = await _get(uri, headers: _authHeaders(token));
    return _handleResponse(res);
  }

  // ============================================================================
  // Reports
  // ============================================================================
  static Future<Map<String, dynamic>> getReports(String projectId) async {
    final token = await _getToken();
    if (token == 'demo-token') {
      return {
        'success': true,
        'data': {
          'total_value': '₹45,231.89',
          'active_orders': 2350,
          'low_stock_items': 12,
          'total_materials': 573,
          'consumption_data': [
            {'name': 'Jan', 'total': 1200},
            {'name': 'Feb', 'total': 2100},
            {'name': 'Mar', 'total': 800},
            {'name': 'Apr', 'total': 1600},
            {'name': 'May', 'total': 900},
            {'name': 'Jun', 'total': 1700},
          ],
        },
      };
    }
    final uri = Uri.parse('$baseUrl/api/reports/project/$projectId');
    final res = await _get(uri, headers: _authHeaders(token));
    return _handleResponse(res);
  }

  // ============================================================================
  // Audit Logs
  // ============================================================================
  static Future<Map<String, dynamic>> getAuditLogs(String projectId) async {
    final token = await _getToken();
    if (token == 'demo-token') {
      return {
        'success': true,
        'data': [
          {'log_id': '1', 'user': 'John Doe', 'action': 'Created a purchase order', 'time': '2 mins ago', 'status': 'success'},
          {'log_id': '2', 'user': 'Jane Smith', 'action': 'Approved material request', 'time': '1 hour ago', 'status': 'success'},
          {'log_id': '3', 'user': 'System', 'action': 'Low stock alert: Cement', 'time': '2 hours ago', 'status': 'warning'},
        ],
      };
    }
    final uri = Uri.parse('$baseUrl/api/audit-logs/project/$projectId');
    final res = await _get(uri, headers: _authHeaders(token));
    return _handleResponse(res);
  }

  // ============================================================================
  // Dashboard Stats
  // ============================================================================
  static Future<Map<String, dynamic>> getDashboardStats(String projectId) async {
    final token = await _getToken();
    if (token == 'demo-token') {
      return {
        'success': true,
        'data': {
          'total_value': '₹45,231.89',
          'total_value_change': 20.1,
          'active_orders': 2350,
          'active_orders_change': -4.0,
          'low_stock_items': 12,
          'total_materials': 573,
          'warehouses': 4,
          'consumption_chart': [
            {'name': 'Jan', 'total': 1200},
            {'name': 'Feb', 'total': 2100},
            {'name': 'Mar', 'total': 800},
            {'name': 'Apr', 'total': 1600},
            {'name': 'May', 'total': 900},
            {'name': 'Jun', 'total': 1700},
          ],
          'recent_activity': [
            {'user': 'John Doe', 'action': 'Created a purchase order', 'time': '2 mins ago', 'status': 'success', 'initials': 'JD'},
            {'user': 'Jane Smith', 'action': 'Approved material request', 'time': '1 hour ago', 'status': 'success', 'initials': 'JS'},
            {'user': 'System', 'action': 'Low stock alert: Cement', 'time': '2 hours ago', 'status': 'warning', 'initials': 'SY'},
            {'user': 'Mike Johnson', 'action': 'Received shipment PO-123', 'time': '4 hours ago', 'status': 'info', 'initials': 'MJ'},
          ],
        },
      };
    }
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
    return _multipartRequest('POST', '/api/compress', {}, files: {'file': file});
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
    if (token == 'demo-token') {
      return {
        'success': true,
        'data': [
          {'notification_id': '1', 'title': 'New PO Approved', 'message': 'Purchase order PO-123 has been approved', 'type': 'success', 'is_read': false, 'created_at': DateTime.now().subtract(const Duration(minutes: 5)).toIso8601String()},
          {'notification_id': '2', 'title': 'Low Stock Alert', 'message': 'Cement stock is below minimum level', 'type': 'warning', 'is_read': false, 'created_at': DateTime.now().subtract(const Duration(hours: 1)).toIso8601String()},
          {'notification_id': '3', 'title': 'MIR Submitted', 'message': 'Material inspection request MIR-456 submitted', 'type': 'info', 'is_read': true, 'created_at': DateTime.now().subtract(const Duration(hours: 3)).toIso8601String()},
        ],
      };
    }
    final uri = Uri.parse('$baseUrl/api/v1/notifications');
    final res = await _get(uri, headers: _authHeaders(token));
    return _handleResponse(res);
  }

  /// Mark a notification as read
  static Future<Map<String, dynamic>> markNotificationRead(String notificationId) async {
    final token = await _getToken();
    final uri = Uri.parse('$baseUrl/api/v1/notifications/$notificationId/read');
    final res = await _patch(uri, headers: _authHeaders(token));
    return _handleResponse(res);
  }

  /// Delete a notification
  static Future<Map<String, dynamic>> deleteNotification(String notificationId) async {
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
