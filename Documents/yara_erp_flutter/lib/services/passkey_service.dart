import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:passkeys/authenticator.dart';
import 'package:passkeys/types.dart';
import '../config/api.dart';

/// Service for handling WebAuthn Passkey operations
class PasskeyService {
  final PasskeyAuthenticator _authenticator = PasskeyAuthenticator();
  
  /// Check if device supports passkeys
  Future<bool> isPasskeyAvailable() async {
    try {
      // ignore: deprecated_member_use
      final canAuth = await _authenticator.canAuthenticate();
      debugPrint('Passkey available: $canAuth');
      return canAuth;
    } catch (e) {
      debugPrint('Passkey availability check error: $e');
      return false;
    }
  }
  
  /// Register a new passkey for the current user
  /// Requires valid auth token
  Future<Map<String, dynamic>> registerPasskey({
    required String token,
    String? passkeyName,
  }) async {
    try {
      // Step 1: Get registration options from server
      final optionsResponse = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/passkey/register-options'),
        headers: ApiConfig.headers(token: token),
      );
      
      if (optionsResponse.statusCode != 200) {
        return {
          'success': false,
          'message': 'Failed to get registration options: ${optionsResponse.statusCode}',
        };
      }
      
      final optionsData = jsonDecode(optionsResponse.body);
      if (optionsData['success'] != true) {
        return {
          'success': false,
          'message': optionsData['message'] ?? 'Failed to get options',
        };
      }
      
      final options = optionsData['options'];
      final sessionKey = optionsData['session_key']; // Store session key
      debugPrint('Registration options received, session_key: $sessionKey');
      debugPrint('Options data: ${jsonEncode(options)}');
      
      // Step 2: Create passkey credential using platform API
      try {
        final registerRequest = RegisterRequestType.fromJson(options);
        final credential = await _authenticator.register(registerRequest);
        
        // Step 3: Send credential to server with session_key
        final credentialJson = credential.toJsonString();
        
        final registerResponse = await http.post(
          Uri.parse('${ApiConfig.baseUrl}/passkey/register'),
          headers: ApiConfig.headers(token: token),
          body: jsonEncode({
            'name': passkeyName ?? 'Flutter Mobile',
            'credential': credentialJson,
            'session_key': sessionKey, // Send back session key
          }),
        );
        
        final registerData = jsonDecode(registerResponse.body);
        return registerData;
      } on TypeError catch (e) {
        debugPrint('Type error in passkey registration: $e');
        debugPrint('Stack trace: ${e.stackTrace}');
        return {
          'success': false,
          'message': 'Pendaftaran gagal: Tipe data tidak sesuai. Silakan coba lagi.',
        };
      }
      
      
    } on PasskeyAuthCancelledException {
      return {
        'success': false,
        'message': 'Pendaftaran passkey dibatalkan',
      };
    } on DomainNotAssociatedException catch (e) {
      return {
        'success': false,
        'message': 'Domain tidak terhubung dengan app: ${e.message}',
      };
    } on DeviceNotSupportedException {
      return {
        'success': false,
        'message': 'Perangkat tidak mendukung passkey',
      };
    } catch (e) {
      debugPrint('Passkey registration error: $e');
      return {
        'success': false,
        'message': 'Pendaftaran gagal: $e',
      };
    }
  }
  
  /// Authenticate using passkey
  /// Returns token and user data on success
  Future<Map<String, dynamic>> authenticateWithPasskey() async {
    try {
      // Step 1: Get authentication options from server
      final optionsResponse = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/passkey/auth-options'),
        headers: ApiConfig.headers(),
      );
      
      if (optionsResponse.statusCode != 200) {
        return {
          'success': false,
          'message': 'Failed to get authentication options: ${optionsResponse.statusCode}',
        };
      }
      
      final optionsData = jsonDecode(optionsResponse.body);
      if (optionsData['success'] != true) {
        return {
          'success': false,
          'message': optionsData['message'] ?? 'Failed to get options',
        };
      }
      
      final options = optionsData['options'];
      final sessionKey = optionsData['session_key']; // Store session key
      debugPrint('Auth options received, session_key: $sessionKey');
      
      // Step 2: Authenticate using platform API
      final authRequest = AuthenticateRequestType.fromJson(
        options,
        mediation: MediationType.Optional,
        preferImmediatelyAvailableCredentials: true,
      );
      
      final credential = await _authenticator.authenticate(authRequest);
      
      // Step 3: Send credential to server for verification with session_key
      final credentialJson = credential.toJsonString();
      
      final authResponse = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/passkey/authenticate'),
        headers: ApiConfig.headers(),
        body: jsonEncode({
          'credential': credentialJson,
          'session_key': sessionKey, // Send back session key
        }),
      );
      
      final authData = jsonDecode(authResponse.body);
      return authData;
      
    } on PasskeyAuthCancelledException {
      return {
        'success': false,
        'message': 'Autentikasi dibatalkan',
      };
    } on NoCredentialsAvailableException {
      return {
        'success': false,
        'message': 'Tidak ada passkey terdaftar. Silakan daftar passkey terlebih dahulu.',
      };
    } on DomainNotAssociatedException catch (e) {
      return {
        'success': false,
        'message': 'Domain tidak terhubung dengan app: ${e.message}',
      };
    } on DeviceNotSupportedException {
      return {
        'success': false,
        'message': 'Perangkat tidak mendukung passkey',
      };
    } catch (e) {
      debugPrint('Passkey authentication error: $e');
      return {
        'success': false,
        'message': 'Autentikasi gagal: $e',
      };
    }
  }
  
  /// Get list of registered passkeys
  Future<List<Map<String, dynamic>>> getPasskeys(String token) async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/passkeys'),
        headers: ApiConfig.headers(token: token),
      );
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          return List<Map<String, dynamic>>.from(data['passkeys']);
        }
      }
      return [];
    } catch (e) {
      debugPrint('Get passkeys error: $e');
      return [];
    }
  }
  
  /// Delete a passkey
  Future<bool> deletePasskey(String token, int passkeyId) async {
    try {
      final response = await http.delete(
        Uri.parse('${ApiConfig.baseUrl}/passkeys/$passkeyId'),
        headers: ApiConfig.headers(token: token),
      );
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['success'] == true;
      }
      return false;
    } catch (e) {
      debugPrint('Delete passkey error: $e');
      return false;
    }
  }
}
