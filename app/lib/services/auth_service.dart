// lib/services/auth_service.dart

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../models/user_model.dart';

// ── Change this to your deployed Railway/local URL ────────────────────────────
const String _kBaseUrl = 'http://127.0.0.1:8000';

class AuthService extends ChangeNotifier {
  UserModel? _currentUser;
  String? _token;
  bool _isLoggedIn = false;
  bool _isLoading = false;
  String? _error;

  UserModel? get currentUser => _currentUser;
  String? get token => _token;
  bool get isLoggedIn => _isLoggedIn;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isAdmin =>
      _currentUser?.role == 'Admin' ||
      _currentUser?.role == 'BDO Manager' ||
      _currentUser?.role == 'SuperAdmin';

  // ── Helpers ──────────────────────────────────────────────────────────────

  /// Decode a JWT without verifying the signature (safe for display data).
  /// We only need full_name + role from the payload — no secrets involved.
  Map<String, dynamic> _decodeJwt(String token) {
    try {
      final parts = token.split('.');
      if (parts.length != 3) return {};
      // Base64Url → Base64 padding
      String payload = parts[1];
      payload += '=' * ((4 - payload.length % 4) % 4);
      final decoded = utf8.decode(base64Url.decode(payload));
      return jsonDecode(decoded) as Map<String, dynamic>;
    } catch (_) {
      return {};
    }
  }

  UserModel _userFromPayload(
    Map<String, dynamic> payload,
    Map<String, dynamic> userJson,
  ) {
    // Prefer the explicit user object from the response body; fall back to JWT claims.
    final name =
        (userJson['full_name'] ?? payload['full_name'] ?? 'BDO User') as String;
    final email = (userJson['email'] ?? payload['email'] ?? '') as String;
    final role = (userJson['role'] ?? payload['role'] ?? 'BDO') as String;
    final id = (userJson['id']?.toString() ?? payload['sub'] ?? 'unknown');
    final dept = (userJson['designation'] ?? 'Business Development') as String;

    return UserModel(
      id: id,
      name: name,
      email: email,
      role: role,
      department: dept,
      phone: '',
      createdAt: DateTime.now(),
    );
  }

  // ── Login ─────────────────────────────────────────────────────────────────

  /// FIX 1 & 3 combined:
  ///   • Sends credentials to the real backend
  ///   • On 401 → sets _error and returns false  (never logs user in)
  ///   • On 200 → decodes JWT for name, stores user, returns true
  Future<bool> login(String email, String password) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await http
          .post(
            Uri.parse('$_kBaseUrl/auth/login'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'email': email, 'password': password}),
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body) as Map<String, dynamic>;
        _token = body['access_token'] as String;
        final payload = _decodeJwt(_token!);
        final userMap = body['user'] as Map<String, dynamic>? ?? {};

        // FIX 2 — currentUser is set from the real authenticated response,
        //          not from a hardcoded mock, so initials are always correct.
        _currentUser = _userFromPayload(payload, userMap);
        _isLoggedIn = true;
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        // 401, 403, 422, etc.
        final body = jsonDecode(response.body);
        _error = (body['detail'] ?? 'Invalid credentials').toString();
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _error = 'Connection error. Check your network.';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // ── Register ──────────────────────────────────────────────────────────────

  /// FIX 1 — backend enforces EmailStr; frontend forwards raw values.
  ///   On 422 (Pydantic validation error) or 409 (duplicate email) the
  ///   error message is surfaced to the UI.
  Future<bool> register(
    String name,
    String email,
    String password,
    String department,
  ) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await http
          .post(
            Uri.parse('$_kBaseUrl/auth/signup'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'full_name': name,
              'email': email,
              'password': password,
              'designation': department,
            }),
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 201) {
        final body = jsonDecode(response.body) as Map<String, dynamic>;
        _token = body['access_token'] as String;
        final payload = _decodeJwt(_token!);
        final userMap = body['user'] as Map<String, dynamic>? ?? {};

        _currentUser = _userFromPayload(payload, userMap);
        _isLoggedIn = true;
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        final body = jsonDecode(response.body);
        // 422 detail is a list; 409 is a string — handle both
        final detail = body['detail'];
        if (detail is List && detail.isNotEmpty) {
          _error = (detail.first['msg'] ?? 'Validation error').toString();
        } else {
          _error = detail?.toString() ?? 'Registration failed';
        }
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _error = 'Connection error. Check your network.';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // ── Forgot password ───────────────────────────────────────────────────────

  Future<bool> forgotPassword(String email) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await http
          .post(
            Uri.parse('$_kBaseUrl/auth/forgot-password'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'email': email}),
          )
          .timeout(const Duration(seconds: 15));

      _isLoading = false;
      notifyListeners();

      if (response.statusCode == 200) {
        return true;
      } else {
        _error = 'Failed to send reset email. Try again.';
        return false;
      }
    } catch (e) {
      _error = 'Connection error. Check your network.';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // ── Logout ────────────────────────────────────────────────────────────────

  /// FIX 3 — clears ALL state so GoRouter's redirect guard fires immediately
  ///          and pushes the user back to /login (not a blank settings shell).
  Future<void> logout() async {
    _token = null;
    _currentUser = null;
    _isLoggedIn = false;
    _error = null;
    notifyListeners(); // ← GoRouter listens to AuthService; this triggers redirect
  }

  // ── Profile update ────────────────────────────────────────────────────────

  Future<void> updateProfile(UserModel updated) async {
    _currentUser = updated;
    notifyListeners();
  }
}
