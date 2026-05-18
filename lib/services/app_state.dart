import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../models/invoice.dart';
import '../models/client.dart';
import 'supabase_service.dart';

class AppState extends ChangeNotifier {
  List<Invoice> invoices = [];
  List<Client> clients   = [];
  int totalChasers = 0;
  bool loading = true;
  int _invNum  = 1;
  String? _profileId;

  final _uuid = const Uuid();

  // ── COMPUTED ────────────────────────────────────────────
  double get totalOutstanding =>
      invoices.where((i) => !i.isFullyPaid).fold(0, (s, i) => s + i.remaining);

  double get totalCollected =>
      invoices.fold(0, (s, i) => s + i.paidAmount + (i.paid && i.paidAmount == 0 ? i.amount : 0));

  List<Invoice> get overdueInvoices =>
      invoices.where((i) => !i.isFullyPaid && i.daysOverdue > 0).toList();

  List<Invoice> get paidInvoices => invoices.where((i) => i.isFullyPaid).toList();

  double get recoveryRate => invoices.isEmpty ? 0 : paidInvoices.length / invoices.length;

  String get nextInvNum => 'INV-${_invNum.toString().padLeft(3, '0')}';

  // ── LOAD ────────────────────────────────────────────────
  Future<void> loadData() async {
    loading = true;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    _profileId = prefs.getString('chaseit_profile_id');

    if (_profileId == null) {
      loading = false;
      notifyListeners();
      return;
    }

    try {
      // Load from Supabase
      invoices = await SupabaseService.getInvoices(_profileId!);
      clients  = await SupabaseService.getClients(_profileId!);
      final settings = await SupabaseService.getSettings(_profileId!);
      totalChasers = settings['total_chasers'] ?? 0;
      _invNum = settings['inv_num'] ?? 1;

      // Seed demo data if empty
      if (invoices.isEmpty) await _seedDemoData();
    } catch (e) {
      print('[AppState] Load error: $e');
    }

    loading = false;
    notifyListeners();
  }

  Future<void> _seedDemoData() async {
    if (_profileId == null) return;
    final now = DateTime.now();

    final demoInvoices = [
      Invoice(id: _uuid.v4(), client: 'Acme Corp', email: 'john@acme.com',
          amount: 3500, due: now.subtract(const Duration(days: 14)).toIso8601String().split('T')[0],
          desc: 'Website redesign', sender: 'Your Business', num: 'INV-001',
          seq: 'gentle', chases: 1, created: now.toIso8601String()),
      Invoice(id: _uuid.v4(), client: 'Blue Sky Agency', email: 'sarah@bluesky.co',
          amount: 1200, due: now.subtract(const Duration(days: 3)).toIso8601String().split('T')[0],
          desc: 'Social media management', sender: 'Your Business', num: 'INV-002',
          seq: 'firm', created: now.toIso8601String()),
      Invoice(id: _uuid.v4(), client: 'TechStart Inc', email: 'mike@techstart.io',
          amount: 8000, due: now.add(const Duration(days: 7)).toIso8601String().split('T')[0],
          desc: 'Mobile app development', sender: 'Your Business', num: 'INV-003',
          seq: 'gentle', chases: 1, created: now.toIso8601String()),
      Invoice(id: _uuid.v4(), client: 'Green Solutions', email: 'lisa@green.com',
          amount: 950, paidAmount: 950,
          due: now.subtract(const Duration(days: 14)).toIso8601String().split('T')[0],
          desc: 'Brand identity', sender: 'Your Business', num: 'INV-004',
          seq: 'urgent', chases: 2, paid: true, created: now.toIso8601String()),
    ];

    final demoClients = [
      Client(id: _uuid.v4(), biz: 'Acme Corp', name: 'John Smith', email: 'john@acme.com'),
      Client(id: _uuid.v4(), biz: 'Blue Sky Agency', name: 'Sarah Jones', email: 'sarah@bluesky.co'),
      Client(id: _uuid.v4(), biz: 'TechStart Inc', name: 'Mike Lee', email: 'mike@techstart.io'),
      Client(id: _uuid.v4(), biz: 'Green Solutions', name: 'Lisa Green', email: 'lisa@green.com'),
    ];

    for (final inv in demoInvoices) {
      final saved = await SupabaseService.insertInvoice(inv, _profileId!);
      if (saved != null) invoices.add(saved);
    }
    for (final c in demoClients) {
      final saved = await SupabaseService.insertClient(c, _profileId!);
      if (saved != null) clients.add(saved);
    }

    totalChasers = 3;
    _invNum = 5;
    await SupabaseService.upsertSettings(_profileId!, totalChasers, _invNum);
  }

  // ── INVOICE ACTIONS ──────────────────────────────────────
  Future<void> createInvoice(Invoice inv) async {
    if (_profileId == null) return;
    final saved = await SupabaseService.insertInvoice(inv, _profileId!);
    if (saved != null) invoices.insert(0, saved);
    _invNum++;
    await SupabaseService.upsertSettings(_profileId!, totalChasers, _invNum);
    notifyListeners();
  }

  Future<void> updateInvoice(Invoice inv) async {
    if (_profileId == null) return;
    await SupabaseService.updateInvoice(inv, _profileId!);
    final idx = invoices.indexWhere((i) => i.id == inv.id);
    if (idx != -1) invoices[idx] = inv;
    notifyListeners();
  }

  Future<void> deleteInvoice(String id) async {
    await SupabaseService.deleteInvoice(id);
    invoices.removeWhere((i) => i.id == id);
    notifyListeners();
  }

  Future<void> markPaid(String id) async {
    final inv = invoices.firstWhere((i) => i.id == id);
    inv.paid = true;
    inv.paidAmount = inv.amount;
    await updateInvoice(inv);
  }

  Future<void> undoPaid(String id) async {
    final inv = invoices.firstWhere((i) => i.id == id);
    inv.paid = false;
    inv.paidAmount = 0;
    await updateInvoice(inv);
  }

  Future<void> recordPayment(String id, double amount) async {
    final inv = invoices.firstWhere((i) => i.id == id);
    inv.paidAmount += amount;
    if (inv.remaining <= 0.01) { inv.paid = true; inv.paidAmount = inv.amount; }
    await updateInvoice(inv);
  }

  Future<void> incrementChase(String id) async {
    if (_profileId == null) return;
    final inv = invoices.firstWhere((i) => i.id == id);
    inv.chases++;
    totalChasers++;
    await SupabaseService.updateInvoice(inv, _profileId!);
    await SupabaseService.upsertSettings(_profileId!, totalChasers, _invNum);
    notifyListeners();
  }

  // ── CLIENT ACTIONS ───────────────────────────────────────
  Future<void> createClient(Client c) async {
    if (_profileId == null) return;
    final saved = await SupabaseService.insertClient(c, _profileId!);
    if (saved != null) clients.add(saved);
    notifyListeners();
  }

  Future<void> deleteClient(String id) async {
    await SupabaseService.deleteClient(id);
    clients.removeWhere((c) => c.id == id);
    notifyListeners();
  }
}
