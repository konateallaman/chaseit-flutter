import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/invoice.dart';
import '../models/client.dart';
import '../models/user_profile.dart';

/// Supabase REST API client
/// No SDK needed — uses plain HTTP requests
class SupabaseService {
  static const String _url = 'https://dhswzxyeifqkxvwmnewh.supabase.co';
  static const String _key = 'sb_publishable_UMJu41Hb2R1XbQLyiBJx3g_bZXNs6vQ';

  static Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    'apikey': _key,
    'Authorization': 'Bearer $_key',
    'Prefer': 'return=representation',
  };

  // ── PROFILES ────────────────────────────────────────────

  static Future<UserProfile?> getProfile(String email) async {
    final res = await http.get(
      Uri.parse('$_url/rest/v1/profiles?email=eq.$email&limit=1'),
      headers: _headers,
    );
    if (res.statusCode == 200) {
      final list = jsonDecode(res.body) as List;
      if (list.isEmpty) return null;
      final m = list[0] as Map<String, dynamic>;
      return _profileFromRow(m);
    }
    return null;
  }

  static Future<UserProfile?> getProfileById(String id) async {
    final res = await http.get(
      Uri.parse('$_url/rest/v1/profiles?id=eq.$id&limit=1'),
      headers: _headers,
    );
    if (res.statusCode == 200) {
      final list = jsonDecode(res.body) as List;
      if (list.isEmpty) return null;
      return _profileFromRow(list[0]);
    }
    return null;
  }

  static Future<UserProfile?> insertProfile(UserProfile p) async {
    final res = await http.post(
      Uri.parse('$_url/rest/v1/profiles'),
      headers: _headers,
      body: jsonEncode({
        'email': p.email,
        'business_name': p.businessName,
        'owner_name': p.ownerName,
        'phone': p.phone,
        'plan': p.plan,
        'avatar_url': p.avatarUrl,
        'email_verified': p.emailVerified,
      }),
    );
    if (res.statusCode == 201) {
      final list = jsonDecode(res.body) as List;
      if (list.isEmpty) return null;
      return _profileFromRow(list[0]);
    }
    print('[Supabase] insertProfile error: ${res.statusCode} ${res.body}');
    return null;
  }

  static Future<bool> updateProfile(UserProfile p) async {
    final res = await http.patch(
      Uri.parse('$_url/rest/v1/profiles?id=eq.${p.id}'),
      headers: _headers,
      body: jsonEncode({
        'business_name': p.businessName,
        'owner_name': p.ownerName,
        'phone': p.phone,
        'avatar_url': p.avatarUrl,
        'email_verified': p.emailVerified,
      }),
    );
    return res.statusCode == 200 || res.statusCode == 204;
  }

  static Future<bool> updateAvatarUrl(String id, String url) async {
    final res = await http.patch(
      Uri.parse('$_url/rest/v1/profiles?id=eq.$id'),
      headers: _headers,
      body: jsonEncode({'avatar_url': url}),
    );
    return res.statusCode == 200 || res.statusCode == 204;
  }

  static Future<bool> deleteProfile(String id) async {
    final res = await http.delete(
      Uri.parse('$_url/rest/v1/profiles?id=eq.$id'),
      headers: _headers,
    );
    return res.statusCode == 200 || res.statusCode == 204;
  }

  static Future<String?> getPasswordHash(String email) async {
    final res = await http.get(
      Uri.parse('$_url/rest/v1/profiles?email=eq.$email&select=id&limit=1'),
      headers: _headers,
    );
    // We store password hash in shared_preferences locally for security
    // Supabase only stores profile data
    return null;
  }

  // ── INVOICES ────────────────────────────────────────────

  static Future<List<Invoice>> getInvoices(String profileId) async {
    final res = await http.get(
      Uri.parse('$_url/rest/v1/invoices?profile_id=eq.$profileId&order=created_at.desc'),
      headers: _headers,
    );
    if (res.statusCode == 200) {
      final list = jsonDecode(res.body) as List;
      return list.map((m) => _invoiceFromRow(m)).toList();
    }
    return [];
  }

  static Future<Invoice?> insertInvoice(Invoice inv, String profileId) async {
    final res = await http.post(
      Uri.parse('$_url/rest/v1/invoices'),
      headers: _headers,
      body: jsonEncode(_invoiceToRow(inv, profileId)),
    );
    if (res.statusCode == 201) {
      final list = jsonDecode(res.body) as List;
      if (list.isEmpty) return null;
      return _invoiceFromRow(list[0]);
    }
    print('[Supabase] insertInvoice error: ${res.statusCode} ${res.body}');
    return null;
  }

  static Future<bool> updateInvoice(Invoice inv, String profileId) async {
    final res = await http.patch(
      Uri.parse('$_url/rest/v1/invoices?id=eq.${inv.id}'),
      headers: _headers,
      body: jsonEncode(_invoiceToRow(inv, profileId)),
    );
    return res.statusCode == 200 || res.statusCode == 204;
  }

  static Future<bool> deleteInvoice(String id) async {
    final res = await http.delete(
      Uri.parse('$_url/rest/v1/invoices?id=eq.$id'),
      headers: _headers,
    );
    return res.statusCode == 200 || res.statusCode == 204;
  }

  // ── CLIENTS ─────────────────────────────────────────────

  static Future<List<Client>> getClients(String profileId) async {
    final res = await http.get(
      Uri.parse('$_url/rest/v1/clients?profile_id=eq.$profileId&order=created_at.desc'),
      headers: _headers,
    );
    if (res.statusCode == 200) {
      final list = jsonDecode(res.body) as List;
      return list.map((m) => _clientFromRow(m)).toList();
    }
    return [];
  }

  static Future<Client?> insertClient(Client c, String profileId) async {
    final res = await http.post(
      Uri.parse('$_url/rest/v1/clients'),
      headers: _headers,
      body: jsonEncode({
        'profile_id': profileId,
        'biz': c.biz,
        'name': c.name,
        'email': c.email,
        'phone': c.phone,
        'notes': c.notes,
      }),
    );
    if (res.statusCode == 201) {
      final list = jsonDecode(res.body) as List;
      if (list.isEmpty) return null;
      return _clientFromRow(list[0]);
    }
    print('[Supabase] insertClient error: ${res.statusCode} ${res.body}');
    return null;
  }

  static Future<bool> deleteClient(String id) async {
    final res = await http.delete(
      Uri.parse('$_url/rest/v1/clients?id=eq.$id'),
      headers: _headers,
    );
    return res.statusCode == 200 || res.statusCode == 204;
  }

  // ── SETTINGS ────────────────────────────────────────────

  static Future<Map<String, dynamic>> getSettings(String profileId) async {
    final res = await http.get(
      Uri.parse('$_url/rest/v1/settings?profile_id=eq.$profileId&limit=1'),
      headers: _headers,
    );
    if (res.statusCode == 200) {
      final list = jsonDecode(res.body) as List;
      if (list.isNotEmpty) return Map<String, dynamic>.from(list[0]);
    }
    return {'total_chasers': 0, 'inv_num': 1};
  }

  static Future<void> upsertSettings(String profileId, int totalChasers, int invNum) async {
    await http.post(
      Uri.parse('$_url/rest/v1/settings'),
      headers: {..._headers, 'Prefer': 'resolution=merge-duplicates'},
      body: jsonEncode({
        'profile_id': profileId,
        'total_chasers': totalChasers,
        'inv_num': invNum,
      }),
    );
  }

  // ── CONVERTERS ──────────────────────────────────────────

  static UserProfile _profileFromRow(Map<String, dynamic> m) => UserProfile(
    id: m['id'] ?? '',
    businessName: m['business_name'] ?? '',
    ownerName: m['owner_name'] ?? '',
    email: m['email'] ?? '',
    phone: m['phone'] ?? '',
    plan: m['plan'] ?? 'free',
    avatarUrl: m['avatar_url'] ?? '',
    emailVerified: m['email_verified'] ?? false,
    createdAt: m['created_at'] ?? DateTime.now().toIso8601String(),
  );

  static Invoice _invoiceFromRow(Map<String, dynamic> m) => Invoice(
    id: m['id'] ?? '',
    client: m['client'] ?? '',
    email: m['email'] ?? '',
    amount: Invoice.toDouble(m['amount']),
    paidAmount: Invoice.toDouble(m['paid_amount']),
    due: m['due'] ?? '',
    desc: m['description'] ?? '',
    sender: m['sender'] ?? '',
    num: m['invoice_num'] ?? '',
    seq: m['sequence'] ?? 'gentle',
    phone: m['phone'] ?? '',
    chases: m['chases'] ?? 0,
    paid: m['paid'] ?? false,
    created: m['created_at'] ?? DateTime.now().toIso8601String(),
  );

  static Map<String, dynamic> _invoiceToRow(Invoice inv, String profileId) => {
    'profile_id': profileId,
    'client': inv.client,
    'email': inv.email,
    'amount': inv.amount,
    'paid_amount': inv.paidAmount,
    'due': inv.due,
    'description': inv.desc,
    'sender': inv.sender,
    'invoice_num': inv.num,
    'sequence': inv.seq,
    'phone': inv.phone,
    'chases': inv.chases,
    'paid': inv.paid,
  };

  static Client _clientFromRow(Map<String, dynamic> m) => Client(
    id: m['id'] ?? '',
    biz: m['biz'] ?? '',
    name: m['name'] ?? '',
    email: m['email'] ?? '',
    phone: m['phone'] ?? '',
    notes: m['notes'] ?? '',
  );
}
