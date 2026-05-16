import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/invoice.dart';
import '../models/client.dart';

/// Web-compatible storage using shared_preferences (JSON)
/// Works on Web, iOS, Android, Windows, macOS, Linux
class DatabaseService {
  static const _invoicesKey = 'chaseit_invoices';
  static const _clientsKey = 'chaseit_clients';
  static const _settingsKey = 'chaseit_settings';

  // ── INVOICES ──────────────────────────────────────────
  static Future<List<Invoice>> getInvoices() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_invoicesKey);
    if (raw == null || raw.isEmpty) return [];
    try {
      final list = jsonDecode(raw) as List;
      return list.map((e) => Invoice.fromMap(Map<String, dynamic>.from(e))).toList();
    } catch (_) { return []; }
  }

  static Future<void> saveInvoices(List<Invoice> invoices) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_invoicesKey, jsonEncode(invoices.map((i) => i.toMap()).toList()));
  }

  static Future<void> insertInvoice(Invoice inv) async {
    final invoices = await getInvoices();
    invoices.removeWhere((i) => i.id == inv.id);
    invoices.insert(0, inv);
    await saveInvoices(invoices);
  }

  static Future<void> updateInvoice(Invoice inv) async {
    final invoices = await getInvoices();
    final idx = invoices.indexWhere((i) => i.id == inv.id);
    if (idx != -1) invoices[idx] = inv;
    await saveInvoices(invoices);
  }

  static Future<void> deleteInvoice(String id) async {
    final invoices = await getInvoices();
    invoices.removeWhere((i) => i.id == id);
    await saveInvoices(invoices);
  }

  // ── CLIENTS ───────────────────────────────────────────
  static Future<List<Client>> getClients() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_clientsKey);
    if (raw == null || raw.isEmpty) return [];
    try {
      final list = jsonDecode(raw) as List;
      return list.map((e) => Client.fromMap(Map<String, dynamic>.from(e))).toList();
    } catch (_) { return []; }
  }

  static Future<void> saveClients(List<Client> clients) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_clientsKey, jsonEncode(clients.map((c) => c.toMap()).toList()));
  }

  static Future<void> insertClient(Client c) async {
    final clients = await getClients();
    clients.removeWhere((x) => x.id == c.id);
    clients.add(c);
    await saveClients(clients);
  }

  static Future<void> deleteClient(String id) async {
    final clients = await getClients();
    clients.removeWhere((c) => c.id == id);
    await saveClients(clients);
  }

  // ── SETTINGS ──────────────────────────────────────────
  static Future<String?> getSetting(String key) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_settingsKey);
    if (raw == null) return null;
    try {
      final map = jsonDecode(raw) as Map<String, dynamic>;
      return map[key] as String?;
    } catch (_) { return null; }
  }

  static Future<void> setSetting(String key, String value) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_settingsKey) ?? '{}';
    final map = Map<String, dynamic>.from(jsonDecode(raw));
    map[key] = value;
    await prefs.setString(_settingsKey, jsonEncode(map));
  }
}