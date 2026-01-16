import 'dart:convert';
import 'package:http/http.dart' as http;
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

  Future<List<dynamic>> getAttendance() async {
    final response = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/attendance'),
      headers: ApiConfig.headers(token: token),
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    return [];
  }

  Future<Map<String, dynamic>> checkIn() async {
    final response = await http.post(
      Uri.parse('${ApiConfig.baseUrl}/attendance/check-in'),
      headers: ApiConfig.headers(token: token),
    );
    return jsonDecode(response.body);
  }

  Future<Map<String, dynamic>> checkOut() async {
    final response = await http.post(
      Uri.parse('${ApiConfig.baseUrl}/attendance/check-out'),
      headers: ApiConfig.headers(token: token),
    );
    return jsonDecode(response.body);
  }

  Future<List<dynamic>> getSales() async {
    final response = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/sales'),
      headers: ApiConfig.headers(token: token),
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    return [];
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
}
