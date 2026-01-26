import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../config/api_config.dart';
import '../services/api_service.dart';

class AuthProvider with ChangeNotifier {
  String? _token;
  Map<String, dynamic>? _user;
  String? _userType; // 'admin' or 'tenant'

  String? get token => _token;
  Map<String, dynamic>? get user => _user;
  String? get userType => _userType;
  bool get isAuthenticated => _token != null;

  AuthProvider() {
    _loadToken();
  }

  Future<void> _loadToken() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString('token');
    _userType = prefs.getString('userType');
    if (_token != null) {
      // Load user data if needed
    }
    notifyListeners();
  }

  Future<bool> adminLogin(String email, String password) async {
    try {
      final response = await ApiService.post(
        ApiConfig.adminLogin,
        {'email': email, 'password': password},
      );

      if (response['success'] == true) {
        _token = response['token'];
        _user = response['admin'];
        _userType = 'admin';

        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('token', _token!);
        await prefs.setString('userType', _userType!);

        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  Future<bool> tenantLogin(String phone, String password) async {
    try {
      final response = await ApiService.post(
        ApiConfig.tenantLogin,
        {'phone': phone, 'password': password},
      );

      if (response['success'] == true) {
        _token = response['token'];
        _user = response['tenant'];
        _userType = 'tenant';

        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('token', _token!);
        await prefs.setString('userType', _userType!);

        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  Future<bool> tenantSignup(Map<String, dynamic> data) async {
    try {
      final response = await ApiService.post(
        ApiConfig.tenantSignup,
        data,
      );

      return response['success'] == true;
    } catch (e) {
      return false;
    }
  }

  Future<Map<String, dynamic>?> initiateSignupPayment(String propertyId, double amount) async {
    try {
      final response = await ApiService.post(
        ApiConfig.signupPayment,
        {
          'propertyId': propertyId,
          'amount': amount,
        },
      );

      if (response['success'] == true) {
        return {
          'order': response['order'],
          'propertyId': response['propertyId'],
        };
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  Future<bool> verifySignupPayment(Map<String, dynamic> signupData) async {
    try {
      final response = await ApiService.post(
        ApiConfig.verifySignupPayment,
        signupData,
      );

      return response['success'] == true;
    } catch (e) {
      return false;
    }
  }

  Future<void> logout() async {
    _token = null;
    _user = null;
    _userType = null;

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
    await prefs.remove('userType');

    notifyListeners();
  }
}
