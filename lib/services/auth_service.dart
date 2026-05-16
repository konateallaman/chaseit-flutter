import 'dart:convert';
import 'dart:math';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_profile.dart';

class AuthService {
  static const _profileKey   = 'chaseit_profile';
  static const _passwordKey  = 'chaseit_password';
  static const _loggedInKey  = 'chaseit_logged_in';
  static const _pendingKey   = 'chaseit_pending'; // pending registration
  static const _codeKey      = 'chaseit_vcode';   // verification code

  // ── CHECK STATE ─────────────────────────────────────────
  static Future<bool> isRegistered() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_profileKey) != null;
  }

  static Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_loggedInKey) ?? false;
  }

  static Future<UserProfile?> getProfile() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_profileKey);
    if (raw == null) return null;
    try { return UserProfile.fromMap(jsonDecode(raw)); } catch (_) { return null; }
  }

  // ── SAVE PENDING REGISTRATION ────────────────────────────
  // Stores registration data + generates code — call BEFORE sending email
  static Future<String> savePendingRegistration({
    required String businessName,
    required String ownerName,
    required String email,
    required String password,
    String phone = '',
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final code = _generateCode();

    final pending = {
      'businessName': businessName.trim(),
      'ownerName': ownerName.trim(),
      'email': email.trim().toLowerCase(),
      'phone': phone.trim(),
      'passwordHash': _hash(password),
    };

    await prefs.setString(_pendingKey, jsonEncode(pending));
    await prefs.setString(_codeKey, code);
    return code;
  }

  // ── VERIFY CODE & CREATE ACCOUNT ─────────────────────────
  static Future<String?> verifyAndCreateAccount(String inputCode) async {
    final prefs = await SharedPreferences.getInstance();
    final storedCode = prefs.getString(_codeKey) ?? '';
    final pendingRaw = prefs.getString(_pendingKey);

    if (pendingRaw == null) return 'No pending registration found.';
    if (inputCode.trim() != storedCode) return 'Invalid code. Please check your email.';

    final pending = jsonDecode(pendingRaw) as Map<String, dynamic>;

    final profile = UserProfile(
      id: _generateId(),
      businessName: pending['businessName'],
      ownerName: pending['ownerName'],
      email: pending['email'],
      phone: pending['phone'] ?? '',
      plan: 'free',
      createdAt: DateTime.now().toIso8601String(),
      emailVerified: true,
    );

    await prefs.setString(_profileKey, jsonEncode(profile.toMap()));
    await prefs.setString(_passwordKey, pending['passwordHash']);
    await prefs.setBool(_loggedInKey, true);
    await prefs.remove(_pendingKey);
    await prefs.remove(_codeKey);
    return null; // success
  }

  // ── LOGIN ────────────────────────────────────────────────
  static Future<String?> login(String email, String password) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_profileKey);
    if (raw == null) return 'No account found. Please register first.';

    final profile = UserProfile.fromMap(jsonDecode(raw));
    if (profile.email != email.trim().toLowerCase()) return 'Email not found.';

    final storedHash = prefs.getString(_passwordKey) ?? '';
    if (storedHash != _hash(password)) return 'Incorrect password.';

    await prefs.setBool(_loggedInKey, true);
    return null;
  }

  // ── UPDATE PROFILE ───────────────────────────────────────
  static Future<String?> updateProfile(UserProfile updated) async {
    final prefs = await SharedPreferences.getInstance();
    if (updated.businessName.trim().isEmpty) return 'Business name is required';
    if (updated.ownerName.trim().isEmpty) return 'Your name is required';
    await prefs.setString(_profileKey, jsonEncode(updated.toMap()));
    return null;
  }

  // ── UPDATE AVATAR URL ────────────────────────────────────
  static Future<void> updateAvatarUrl(String url) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_profileKey);
    if (raw == null) return;
    final profile = UserProfile.fromMap(jsonDecode(raw));
    final updated = profile.copyWith(avatarUrl: url);
    await prefs.setString(_profileKey, jsonEncode(updated.toMap()));
  }

  // ── CHANGE PASSWORD ──────────────────────────────────────
  static Future<String?> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final storedHash = prefs.getString(_passwordKey) ?? '';
    if (storedHash != _hash(currentPassword)) return 'Current password is incorrect.';
    if (newPassword.length < 6) return 'New password must be at least 6 characters.';
    await prefs.setString(_passwordKey, _hash(newPassword));
    return null;
  }

  // ── LOGOUT ───────────────────────────────────────────────
  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_loggedInKey, false);
  }

  // ── DELETE ACCOUNT ───────────────────────────────────────
  static Future<void> deleteAccount() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }

  // ── HELPERS ──────────────────────────────────────────────
  static String _generateCode() {
    final r = Random();
    return List.generate(6, (_) => r.nextInt(10)).join();
  }

  static String _generateId() =>
      DateTime.now().millisecondsSinceEpoch.toString() +
      Random().nextInt(9999).toString();

  static String _hash(String input) {
    int hash = 5381;
    for (final c in input.runes) hash = ((hash << 5) + hash) ^ c;
    return hash.abs().toRadixString(16);
  }
}
