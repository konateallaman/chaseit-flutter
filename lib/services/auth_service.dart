import 'dart:convert';
import 'dart:math';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_profile.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'supabase_service.dart';

class AuthService {
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
    final passwordHash = pending['passwordHash'] as String;

    // Create profile in Supabase with password hash
    final profile = await SupabaseService.insertProfile(
      UserProfile(
        id: '',
        businessName: pending['businessName'],
        ownerName: pending['ownerName'],
        email: pending['email'],
        phone: pending['phone'] ?? '',
        plan: 'free',
        createdAt: DateTime.now().toIso8601String(),
        emailVerified: true,
      ),
      passwordHash: passwordHash,
    );

    if (profile == null) return 'Failed to create account. Please try again.';

    // Save locally
    await prefs.setString(_profileIdKey, profile.id);
    await prefs.setBool(_loggedInKey, true);
    await prefs.remove(_pendingKey);
    await prefs.remove(_codeKey);

    // Init settings
    await SupabaseService.upsertSettings(profile.id, 0, 1);
    return null;
  }

  // ── LOGIN ────────────────────────────────────────────────
  static Future<String?> login(String email, String password) async {
    final prefs = await SharedPreferences.getInstance();

    // Fetch profile from Supabase
    final profile = await SupabaseService.getProfile(email.trim().toLowerCase());
    if (profile == null) return 'No account found with this email.';

    // Get password hash from Supabase
    final storedHash = await SupabaseService.getPasswordHash(email.trim().toLowerCase());
    if (storedHash == null || storedHash.isEmpty) {
      return 'Account error. Please contact support.';
    }

    if (storedHash != _hash(password)) return 'Incorrect password.';

    // Save locally so app knows who is logged in
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
    final id = prefs.getString(_profileIdKey);
    if (id == null) return 'Not logged in.';

    // Get profile to find email
    final profile = await SupabaseService.getProfileById(id);
    if (profile == null) return 'Profile not found.';

    // Verify current password from Supabase
    final storedHash = await SupabaseService.getPasswordHash(profile.email);
    if (storedHash != _hash(currentPassword)) return 'Current password is incorrect.';
    if (newPassword.length < 6) return 'New password must be at least 6 characters.';

    // Update in Supabase
    await SupabaseService.updatePasswordHash(id, _hash(newPassword));
    return null;
  }

  // ── LOGOUT ───────────────────────────────────────────────
  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_loggedInKey, false);
    await prefs.remove(_profileIdKey);
  }

  // ── DELETE ACCOUNT ───────────────────────────────────────
  static Future<void> deleteAccount() async {
    final prefs = await SharedPreferences.getInstance();
    final id = prefs.getString(_profileIdKey);
    if (id != null) await SupabaseService.deleteProfile(id);
    await prefs.clear();
  }

  // ── GET PROFILE BY EMAIL (public) ───────────────────────
  static Future<UserProfile?> getProfileByEmail(String email) async {
    return await SupabaseService.getProfile(email);
  }

  // ── RESET PASSWORD ───────────────────────────────────────
  static Future<String> saveResetCode(String email) async {
    final prefs = await SharedPreferences.getInstance();
    final code = _generateCode();
    await prefs.setString('chaseit_reset_code', code);
    await prefs.setString('chaseit_reset_email', email);
    await prefs.setInt('chaseit_reset_expiry',
        DateTime.now().add(const Duration(minutes: 10)).millisecondsSinceEpoch);
    return code;
  }

  static Future<bool> verifyResetCode({required String email, required String code}) async {
    final prefs = await SharedPreferences.getInstance();
    final storedCode  = prefs.getString('chaseit_reset_code') ?? '';
    final storedEmail = prefs.getString('chaseit_reset_email') ?? '';
    final expiry      = prefs.getInt('chaseit_reset_expiry') ?? 0;
    final now         = DateTime.now().millisecondsSinceEpoch;
    return storedCode == code && storedEmail == email && now < expiry;
  }

  static Future<void> resetPassword({required String email, required String newPassword}) async {
    final profile = await SupabaseService.getProfile(email);
    if (profile == null) return;
    await SupabaseService.updatePasswordHash(profile.id, _hash(newPassword));
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('chaseit_reset_code');
    await prefs.remove('chaseit_reset_email');
    await prefs.remove('chaseit_reset_expiry');
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
