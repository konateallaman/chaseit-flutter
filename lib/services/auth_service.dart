import 'dart:convert';
import 'dart:math';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_profile.dart';
import 'supabase_service.dart';

class AuthService {
  static const _passwordKey  = 'chaseit_password';
  static const _loggedInKey  = 'chaseit_logged_in';
  static const _profileIdKey = 'chaseit_profile_id';
  static const _pendingKey   = 'chaseit_pending';
  static const _codeKey      = 'chaseit_vcode';

  // ── STATE ────────────────────────────────────────────────
  static Future<bool> isRegistered() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_profileIdKey) != null;
  }

  static Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_loggedInKey) ?? false;
  }

  static Future<UserProfile?> getProfile() async {
    final prefs = await SharedPreferences.getInstance();
    final id = prefs.getString(_profileIdKey);
    if (id == null) return null;
    // Fetch fresh from Supabase
    return await SupabaseService.getProfileById(id);
  }

  // ── PENDING REGISTRATION ─────────────────────────────────
  static Future<String> savePendingRegistration({
    required String businessName,
    required String ownerName,
    required String email,
    required String password,
    String phone = '',
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final code = _generateCode();

    await prefs.setString(_pendingKey, jsonEncode({
      'businessName': businessName.trim(),
      'ownerName': ownerName.trim(),
      'email': email.trim().toLowerCase(),
      'phone': phone.trim(),
      'passwordHash': _hash(password),
    }));
    await prefs.setString(_codeKey, code);
    print('[ChaseIt] VERIFICATION CODE: $code');
    return code;
  }

  // ── VERIFY & CREATE ACCOUNT ──────────────────────────────
  static Future<String?> verifyAndCreateAccount(String inputCode) async {
    final prefs = await SharedPreferences.getInstance();
    final storedCode = prefs.getString(_codeKey) ?? '';
    final pendingRaw = prefs.getString(_pendingKey);

    if (pendingRaw == null) return 'No pending registration found.';
    if (inputCode.trim() != storedCode) return 'Invalid code. Please check your email.';

    final pending = jsonDecode(pendingRaw) as Map<String, dynamic>;

    // Create profile in Supabase
    final profile = await SupabaseService.insertProfile(UserProfile(
      id: '',
      businessName: pending['businessName'],
      ownerName: pending['ownerName'],
      email: pending['email'],
      phone: pending['phone'] ?? '',
      plan: 'free',
      createdAt: DateTime.now().toIso8601String(),
      emailVerified: true,
    ));

    if (profile == null) return 'Failed to create account. Please try again.';

    // Save locally
    await prefs.setString(_profileIdKey, profile.id);
    await prefs.setString(_passwordKey, pending['passwordHash']);
    await prefs.setBool(_loggedInKey, true);
    await prefs.remove(_pendingKey);
    await prefs.remove(_codeKey);

    // Init settings in Supabase
    await SupabaseService.upsertSettings(profile.id, 0, 1);

    return null;
  }

  // ── LOGIN ────────────────────────────────────────────────
  static Future<String?> login(String email, String password) async {
    final prefs = await SharedPreferences.getInstance();

    // Fetch profile from Supabase
    final profile = await SupabaseService.getProfile(email.trim().toLowerCase());
    if (profile == null) return 'No account found with this email.';

    // Check password
    final storedHash = prefs.getString(_passwordKey);
    if (storedHash == null || storedHash != _hash(password)) {
      // Password hash might be on a different device — store it
      // For now we store the hash locally per device
      return 'Incorrect password. If you registered on another device, you need to reset your password.';
    }

    await prefs.setString(_profileIdKey, profile.id);
    await prefs.setBool(_loggedInKey, true);
    return null;
  }

  // ── UPDATE PROFILE ───────────────────────────────────────
  static Future<String?> updateProfile(UserProfile updated) async {
    if (updated.businessName.trim().isEmpty) return 'Business name is required';
    if (updated.ownerName.trim().isEmpty) return 'Your name is required';
    final ok = await SupabaseService.updateProfile(updated);
    return ok ? null : 'Failed to update profile.';
  }

  // ── UPDATE AVATAR ────────────────────────────────────────
  static Future<void> updateAvatarUrl(String url) async {
    final prefs = await SharedPreferences.getInstance();
    final id = prefs.getString(_profileIdKey);
    if (id != null) await SupabaseService.updateAvatarUrl(id, url);
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
    final id = prefs.getString(_profileIdKey);
    if (id != null) await SupabaseService.deleteProfile(id);
    await prefs.clear();
  }

  // ── HELPERS ──────────────────────────────────────────────
  static String _generateCode() =>
      List.generate(6, (_) => Random().nextInt(10)).join();

  static String _hash(String input) {
    int hash = 5381;
    for (final c in input.runes) hash = ((hash << 5) + hash) ^ c;
    return hash.abs().toRadixString(16);
  }
}
