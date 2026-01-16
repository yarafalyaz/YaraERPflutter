// API Configuration for Flutter App
class ApiConfig {
  // Change this to your actual server URL
  static const String baseUrl = 'https://erp.zzzzzz.cloud/api';
  
  // Headers for API requests
  static Map<String, String> headers({String? token}) {
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }
}
