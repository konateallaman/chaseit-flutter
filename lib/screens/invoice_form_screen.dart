import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../models/invoice.dart';
import '../models/client.dart';
import '../services/app_state.dart';
import '../theme/app_theme.dart';
import '../widgets/common_widgets.dart';

class InvoiceFormScreen extends StatefulWidget {
  final Invoice? invoice; // null = create, non-null = edit

  const InvoiceFormScreen({super.key, this.invoice});

  @override
  State<InvoiceFormScreen> createState() => _InvoiceFormScreenState();
}

class _InvoiceFormScreenState extends State<InvoiceFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _client, _email, _amount, _due, _desc, _sender, _num, _phone;
  String _seq = 'gentle';
  Client? _selectedClient;
  bool _saving = false;

  bool get isEdit => widget.invoice != null;

  @override
  void initState() {
    super.initState();
    final inv = widget.invoice;
    _client = TextEditingController(text: inv?.client ?? '');
    _email = TextEditingController(text: inv?.email ?? '');
    _amount = TextEditingController(text: inv?.amount.toString() ?? '');
    _desc = TextEditingController(text: inv?.desc ?? '');
    _sender = TextEditingController(text: inv?.sender ?? '');
    _phone = TextEditingController(text: inv?.phone ?? '');
    _seq = inv?.seq ?? 'gentle';

    // Default due date
    final defaultDue = inv?.due ?? DateTime.now().add(const Duration(days: 30)).toIso8601String().split('T')[0];
    _due = TextEditingController(text: defaultDue);

    final state = context.read<AppState>();
    _num = TextEditingController(text: inv?.num ?? state.nextInvNum);
  }

  @override
  void dispose() {
    for (final c in [_client, _email, _amount, _due, _desc, _sender, _num, _phone]) c.dispose();
    super.dispose();
  }

  void _fillFromClient(Client c) {
    setState(() {
      _selectedClient = c;
      _client.text = c.biz.isNotEmpty ? c.biz : c.name;
      _email.text = c.email;
      _phone.text = c.phone;
    });
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.tryParse(_due.text) ?? DateTime.now().add(const Duration(days: 30)),
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(colorScheme: const ColorScheme.light(primary: AppColors.accent)),
        child: child!,
      ),
    );
    if (picked != null) _due.text = picked.toIso8601String().split('T')[0];
  }

  Future<void> _save() async {
    // Manual validation with user feedback
    if (_client.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Client name is required'), backgroundColor: AppColors.accent));
      return;
    }
    if (_email.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Client email is required'), backgroundColor: AppColors.accent));
      return;
    }
    if (_amount.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Amount is required'), backgroundColor: AppColors.accent));
      return;
    }
    if (_due.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Due date is required'), backgroundColor: AppColors.accent));
      return;
    }
    setState(() => _saving = true);

    final state = context.read<AppState>();
    final now = DateTime.now().toIso8601String();

    if (isEdit) {
      final updated = widget.invoice!.copyWith(
        client: _client.text.trim(),
        email: _email.text.trim(),
        amount: double.tryParse(_amount.text) ?? 0,
        due: _due.text,
        desc: _desc.text.trim(),
        sender: _sender.text.trim(),
        num: _num.text.trim(),
        seq: _seq,
        phone: _phone.text.trim(),
      );
      await state.updateInvoice(updated);
    } else {
      final inv = Invoice(
        id: const Uuid().v4(),
        client: _client.text.trim(),
        email: _email.text.trim(),
        amount: double.tryParse(_amount.text) ?? 0,
        due: _due.text,
        desc: _desc.text.trim(),
        sender: _sender.text.trim(),
        num: _num.text.trim(),
        seq: _seq,
        phone: _phone.text.trim(),
        created: now,
      );
      await state.createInvoice(inv);

      // Auto-add client if new
      if (state.clients.every((c) => c.email != inv.email)) {
        await state.createClient(Client(
          id: const Uuid().v4(),
          biz: inv.client,
          name: inv.client,
          email: inv.email,
          phone: inv.phone,
        ));
      }
    }

    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(isEdit ? 'Invoice updated' : 'Invoice created'), backgroundColor: AppColors.green),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        title: Text(isEdit ? 'Edit Invoice' : 'New Invoice'),
        backgroundColor: AppColors.surface,
        actions: [
          if (_saving)
            const Padding(padding: EdgeInsets.all(14), child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.accent)))
          else
            TextButton(
              onPressed: _save,
              child: Text(isEdit ? 'Save' : 'Create',
                  style: const TextStyle(fontFamily: 'Syne', color: AppColors.accent, fontWeight: FontWeight.w700)),
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Client selector (create mode only)
              if (!isEdit && state.clients.isNotEmpty) ...[
                const Text('SELECT CLIENT', style: TextStyle(fontFamily: 'Syne', fontSize: 9, color: AppColors.muted, letterSpacing: 1.0)),
                const SizedBox(height: 5),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: AppColors.bg,
                    border: Border.all(color: AppColors.accent, width: 1.5),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<Client>(
                      isExpanded: true,
                      hint: const Text('Pick a client to auto-fill', style: TextStyle(fontFamily: 'Syne', color: AppColors.muted2, fontSize: 13)),
                      value: _selectedClient,
                      items: state.clients.map((c) => DropdownMenuItem(
                        value: c,
                        child: Text(c.displayName, style: const TextStyle(fontFamily: 'Syne', fontSize: 13, fontWeight: FontWeight.w600)),
                      )).toList(),
                      onChanged: (c) { if (c != null) _fillFromClient(c); },
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Row(children: [
                  const Expanded(child: Divider(color: AppColors.border2)),
                  const Padding(padding: EdgeInsets.symmetric(horizontal: 10), child: Text('or enter manually', style: TextStyle(fontFamily: 'Syne', fontSize: 11, color: AppColors.muted))),
                  const Expanded(child: Divider(color: AppColors.border2)),
                ]),
                const SizedBox(height: 12),
              ],

              AppField(label: 'Client Name', hint: 'Acme Corp', controller: _client,
                  validator: (v) => v!.isEmpty ? 'Required' : null),
              const SizedBox(height: 12),
              AppField(label: 'Client Email', hint: 'client@email.com', controller: _email,
                  keyboardType: TextInputType.emailAddress,
                  validator: (v) => v!.isEmpty ? 'Required' : null),
              const SizedBox(height: 12),
              Row(children: [
                Expanded(child: AppField(label: 'Amount (\$)', hint: '2500', controller: _amount,
                    keyboardType: TextInputType.number,
                    validator: (v) => v!.isEmpty ? 'Required' : null)),
                const SizedBox(width: 12),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Text('DUE DATE', style: TextStyle(fontFamily: 'Syne', fontSize: 9, color: AppColors.muted, letterSpacing: 1.0)),
                  const SizedBox(height: 5),
                  GestureDetector(
                    onTap: _pickDate,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(
                        color: AppColors.bg,
                        border: Border.all(color: AppColors.border2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(children: [
                        Expanded(child: Text(_due.text.isEmpty ? 'Pick date' : _due.text,
                            style: TextStyle(fontFamily: 'Syne', fontSize: 13, color: _due.text.isEmpty ? AppColors.muted2 : AppColors.ink))),
                        const Icon(Icons.calendar_today, size: 14, color: AppColors.muted),
                      ]),
                    ),
                  ),
                ])),
              ]),
              const SizedBox(height: 12),
              AppField(label: 'Description', hint: 'e.g. Website redesign — Phase 1', controller: _desc),
              const SizedBox(height: 12),
              Row(children: [
                Expanded(child: AppField(label: 'Your Name / Business', hint: 'Your Name', controller: _sender)),
                const SizedBox(width: 12),
                Expanded(child: AppField(label: 'Invoice #', hint: 'INV-001', controller: _num)),
              ]),
              const SizedBox(height: 12),
              const Text('AUTO-CHASE SEQUENCE', style: TextStyle(fontFamily: 'Syne', fontSize: 9, color: AppColors.muted, letterSpacing: 1.0)),
              const SizedBox(height: 5),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: AppColors.bg, border: Border.all(color: AppColors.border2), borderRadius: BorderRadius.circular(8),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    isExpanded: true, value: _seq,
                    items: const [
                      DropdownMenuItem(value: 'gentle', child: Text('Gentle — 3, 7, 14 days', style: TextStyle(fontFamily: 'Syne', fontSize: 13))),
                      DropdownMenuItem(value: 'firm', child: Text('Firm — 1, 3, 7 days', style: TextStyle(fontFamily: 'Syne', fontSize: 13))),
                      DropdownMenuItem(value: 'urgent', child: Text('Urgent — 1, 2, 3 days', style: TextStyle(fontFamily: 'Syne', fontSize: 13))),
                      DropdownMenuItem(value: 'none', child: Text('No auto-chase', style: TextStyle(fontFamily: 'Syne', fontSize: 13))),
                    ],
                    onChanged: (v) => setState(() => _seq = v!),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              AppField(label: 'Phone (SMS / WhatsApp)', hint: '+1 555 000 0000', controller: _phone,
                  keyboardType: TextInputType.phone),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _saving ? null : _save,
                  child: Text(isEdit ? 'Save Changes' : 'Create Invoice'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
