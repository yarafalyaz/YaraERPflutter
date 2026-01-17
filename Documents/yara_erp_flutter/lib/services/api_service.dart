import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart'; // Ensure this is available or use generic mimetype
import '../config/api.dart';

class ApiService {
  final String? token;

  ApiService({this.token});

  Future<List<dynamic>> getProjects() async {
    final response = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/projects'),
      headers: ApiConfig.headers(token: token),
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    return [];
  }

  Future<Map<String, dynamic>?> getProjectDetail(int id) async {
    final response = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/projects/$id'),
      headers: ApiConfig.headers(token: token),
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    return null;
  }

  Future<List<dynamic>> getEmployees() async {
    final response = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/employees'),
      headers: ApiConfig.headers(token: token),
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    return [];
  }

  Future<Map<String, dynamic>?> getEmployeeDetail(int id) async {
    final response = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/employees/$id'),
      headers: ApiConfig.headers(token: token),
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    return null;
  }

  Future<List<dynamic>> getCustomers() async {
    final response = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/customers'),
      headers: ApiConfig.headers(token: token),
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    return [];
  }

  Future<Map<String, dynamic>?> getCustomerDetail(int id) async {
    final response = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/customers/$id'),
      headers: ApiConfig.headers(token: token),
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    return null;
  }

  Future<dynamic> getAttendance() async {
    final response = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/attendance'),
      headers: ApiConfig.headers(token: token),
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    return null;
  }

  Future<Map<String, dynamic>> checkIn({double? latitude, double? longitude}) async {
    final response = await http.post(
      Uri.parse('${ApiConfig.baseUrl}/attendance/check-in'),
      headers: ApiConfig.headers(token: token),
      body: jsonEncode({
        'latitude': latitude,
        'longitude': longitude,
      }),
    );
    return jsonDecode(response.body);
  }

  Future<Map<String, dynamic>> checkOut({double? latitude, double? longitude}) async {
    final response = await http.post(
      Uri.parse('${ApiConfig.baseUrl}/attendance/check-out'),
      headers: ApiConfig.headers(token: token),
      body: jsonEncode({
        'latitude': latitude,
        'longitude': longitude,
      }),
    );
    return jsonDecode(response.body);
  }

  Future<List<dynamic>> getSales() async {
    final response = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/sales-invoices'),
      headers: ApiConfig.headers(token: token),
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    return [];
  }

  Future<List<dynamic>> getQuotations() async {
    final response = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/quotations'),
      headers: ApiConfig.headers(token: token),
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    return [];
  }

  Future<List<dynamic>> getSalesInvoices() async {
    return getSales(); // Alias for consistency
  }

  Future<List<dynamic>> getSalesPayments() async {
    final response = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/sales-payments'),
      headers: ApiConfig.headers(token: token),
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    return [];
  }

  Future<Map<String, dynamic>> createQuotation(Map<String, dynamic> data) async {
    final response = await http.post(
      Uri.parse('${ApiConfig.baseUrl}/quotations'),
      headers: ApiConfig.headers(token: token),
      body: jsonEncode(data),
    );
    return jsonDecode(response.body);
  }

  Future<Map<String, dynamic>> createSalesPayment(Map<String, dynamic> data) async {
    final response = await http.post(
      Uri.parse('${ApiConfig.baseUrl}/sales-payments'),
      headers: ApiConfig.headers(token: token),
      body: jsonEncode(data),
    );
    return jsonDecode(response.body);
  }

  Future<List<dynamic>> getItems() async {
    final response = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/items'),
      headers: ApiConfig.headers(token: token),
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    return [];
  }

  Future<List<dynamic>> getWarehouses() async {
    final response = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/warehouses'),
      headers: ApiConfig.headers(token: token),
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    return [];
  }

  Future<List<dynamic>> getRacks() async {
    final response = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/racks'),
      headers: ApiConfig.headers(token: token),
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    return [];
  }

  Future<List<dynamic>> getVehicles() async {
    final response = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/vehicles'),
      headers: ApiConfig.headers(token: token),
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    return [];
  }

  Future<List<dynamic>> getStockAdjustments() async {
    final response = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/stock-adjustments'),
      headers: ApiConfig.headers(token: token),
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    return [];
  }

  Future<Map<String, dynamic>> createStockAdjustment(Map<String, dynamic> data) async {
    final response = await http.post(
      Uri.parse('${ApiConfig.baseUrl}/stock-adjustments'),
      headers: ApiConfig.headers(token: token),
      body: jsonEncode(data),
    );
    return jsonDecode(response.body);
  }

  // Leave Management
  Future<List<dynamic>> getLeaves() async {
    final response = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/leaves'),
      headers: ApiConfig.headers(token: token),
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    return [];
  }

  Future<Map<String, dynamic>> createLeave(Map<String, dynamic> data) async {
    final response = await http.post(
      Uri.parse('${ApiConfig.baseUrl}/leaves'),
      headers: ApiConfig.headers(token: token),
      body: jsonEncode(data),
    );
    return jsonDecode(response.body);
  }

  // Finance / Expenses
  Future<List<dynamic>> getAccounts({String? type}) async {
    String url = '${ApiConfig.baseUrl}/accounts';
    if (type != null) {
      url += '?type=$type';
    }
    final response = await http.get(
      Uri.parse(url),
      headers: ApiConfig.headers(token: token),
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    return [];
  }

  Future<List<dynamic>> getExpenses() async {
    final response = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/expenses'),
      headers: ApiConfig.headers(token: token),
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    return [];
  }

  Future<Map<String, dynamic>> createExpense(Map<String, String> data, File? receipt) async {
    var uri = Uri.parse('${ApiConfig.baseUrl}/expenses');
    var request = http.MultipartRequest('POST', uri);
    
    request.headers.addAll(ApiConfig.headers(token: token));
    request.fields.addAll(data);

    if (receipt != null) {
      request.files.add(
        await http.MultipartFile.fromPath(
          'receipt_image',
          receipt.path,
        ),
      );
    }

    var streamedResponse = await request.send();
    var response = await http.Response.fromStream(streamedResponse);
    return jsonDecode(response.body);
  }

  // Payroll
  Future<List<dynamic>> getPayrolls() async {
    final response = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/payrolls'),
      headers: ApiConfig.headers(token: token),
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    return [];
  }

  Future<Map<String, dynamic>?> getPayrollDetail(int id) async {
    final response = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/payrolls/$id'),
      headers: ApiConfig.headers(token: token),
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    return null;
  }

  // Finance / Accounting
  Future<List<dynamic>> getJournalEntries() async {
    final response = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/journal-entries'),
      headers: ApiConfig.headers(token: token),
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    return [];
  }

  Future<List<dynamic>> getBudgets() async {
    final response = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/budgets'),
      headers: ApiConfig.headers(token: token),
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    return [];
  }

  Future<List<dynamic>> getPettyCash() async {
    final response = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/petty-cash'),
      headers: ApiConfig.headers(token: token),
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    return [];
  }

  Future<Map<String, dynamic>> createPettyCash(Map<String, dynamic> data) async {
    final response = await http.post(
      Uri.parse('${ApiConfig.baseUrl}/petty-cash'),
      headers: ApiConfig.headers(token: token),
      body: jsonEncode(data),
    );
    return jsonDecode(response.body);
  }

  // HR & Operations
  Future<List<dynamic>> getLoans() async {
    final response = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/loans'),
      headers: ApiConfig.headers(token: token),
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    return [];
  }

  Future<Map<String, dynamic>> createLoan(Map<String, dynamic> data) async {
    final response = await http.post(
      Uri.parse('${ApiConfig.baseUrl}/loans'),
      headers: ApiConfig.headers(token: token),
      body: jsonEncode(data),
    );
    return jsonDecode(response.body);
  }

  Future<List<dynamic>> getOvertimes() async {
    final response = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/overtimes'),
      headers: ApiConfig.headers(token: token),
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    return [];
  }

  Future<Map<String, dynamic>> createOvertime(Map<String, dynamic> data) async {
    final response = await http.post(
      Uri.parse('${ApiConfig.baseUrl}/overtimes'),
      headers: ApiConfig.headers(token: token),
      body: jsonEncode(data),
    );
    return jsonDecode(response.body);
  }

  Future<List<dynamic>> getTasks() async {
    final response = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/tasks'),
      headers: ApiConfig.headers(token: token),
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    return [];
  }

  Future<Map<String, dynamic>> updateTaskStatus(int taskId, String status) async {
    final response = await http.patch(
      Uri.parse('${ApiConfig.baseUrl}/tasks/$taskId'),
      headers: ApiConfig.headers(token: token),
      body: jsonEncode({'status': status}),
    );
    return jsonDecode(response.body);
  }

  // Admin
  Future<List<dynamic>> getAdminUsers() async {
    final response = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/admin/users'),
      headers: ApiConfig.headers(token: token),
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    return [];
  }

  Future<List<dynamic>> getAdminRoles() async {
    final response = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/admin/roles'),
      headers: ApiConfig.headers(token: token),
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    return [];
  }

  Future<Map<String, dynamic>> getAdminSettings() async {
    final response = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/admin/settings'),
      headers: ApiConfig.headers(token: token),
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    return {};
  }

  Future<Map<String, dynamic>> updateAdminSettings(Map<String, dynamic> data) async {
    final response = await http.patch(
      Uri.parse('${ApiConfig.baseUrl}/admin/settings'),
      headers: ApiConfig.headers(token: token),
      body: jsonEncode(data),
    );
    return jsonDecode(response.body);
  }

  // Logic Parity & Metrics
  Future<Map<String, dynamic>> getDashboardMetrics() async {
    final response = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/dashboard/metrics'),
      headers: ApiConfig.headers(token: token),
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    return {};
  }

  Future<Map<String, dynamic>> updateQuotationStatus(int id, String status) async {
    final response = await http.patch(
      Uri.parse('${ApiConfig.baseUrl}/quotations/$id'),
      headers: ApiConfig.headers(token: token),
      body: jsonEncode({'status': status}),
    );
    return jsonDecode(response.body);
  }

  Future<Map<String, dynamic>> checkStock(int itemId, double qty) async {
    final response = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/stock-check?item_id=$itemId&qty=$qty'),
      headers: ApiConfig.headers(token: token),
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    return {'is_available': false};
  }
}
