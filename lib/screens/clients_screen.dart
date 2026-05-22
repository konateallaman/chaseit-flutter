import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../services/app_state.dart';
import '../models/client.dart';
import '../theme/app_theme.dart';
import '../widgets/common_widgets.dart';

class ClientsScreen extends StatefulWidget {
  const ClientsScreen({super.key});
  @override
  State<ClientsScreen> createState() => _ClientsScreenState();
}

class _ClientsScreenState extends State<ClientsScreen> {
  String? _expandedId;

  void _showClientDialog(BuildContext context, {Client? existing}) {
    final isEdit    = existing != null;
    final bizCtrl   = TextEditingController(text: existing?.biz ?? '');
    final nameCtrl  = TextEditingController(text: existing?.name ?? '');
    final emailCtrl = TextEditingController(text: existing?.email ?? '');
    final phoneCtrl = TextEditingController(text: existing?.phone ?? '');
    final notesCtrl = TextEditingController(text: existing?.notes ?? '');

    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                Text(isEdit ? 'Edit Client' : 'Add Client',
                    style: const TextStyle(fontFamily: 'Syne', fontSize: 17,
                        fontWeight: FontWeight.w800, color: AppColors.ink)),
                GestureDetector(
                  onTap: () => Navigator.pop(ctx),
                  child: Container(width: 28, height: 28,
                      decoration: BoxDecoration(color: AppColors.surface2,
                          borderRadius: BorderRadius.circular(7)),
                      child: const Icon(Icons.close, size: 15, color: AppColors.muted)),
                ),
              ]),
              const SizedBox(height: 20),
              _field('Business Name', 'Acme Corp', bizCtrl),
              const SizedBox(height: 12),
              _field('Contact Name', 'John Smith', nameCtrl),
              const SizedBox(height: 12),
              _field('Email', 'john@acme.com', emailCtrl,
                  type: TextInputType.emailAddress, readOnly: isEdit),
              const SizedBox(height: 12),
              _field('Phone', '+1 555 000 0000', phoneCtrl, type: TextInputType.phone),
              const SizedBox(height: 12),
              _field('Notes', 'Any notes...', notesCtrl, maxLines: 2),
              const SizedBox(height: 20),
              Row(children: [
                Expanded(child: OutlinedButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Cancel'),
                )),
                const SizedBox(width: 10),
                Expanded(child: ElevatedButton(
                  onPressed: () async {
                    final biz   = bizCtrl.text.trim();
                    final email = emailCtrl.text.trim();
                    if (biz.isEmpty || email.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                          content: Text('Business name and email are required'),
                          backgroundColor: AppColors.accent));
                      return;
                    }
                    Navigator.pop(ctx);
                    if (isEdit) {
                      await context.read<AppState>().updateClient(Client(
                        id: existing!.id, biz: biz, name: nameCtrl.text.trim(),
                        email: email, phone: phoneCtrl.text.trim(), notes: notesCtrl.text.trim(),
                      ));
                      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('$biz updated!'), backgroundColor: AppColors.green));
                    } else {
                      await context.read<AppState>().createClient(Client(
                        id: const Uuid().v4(), biz: biz, name: nameCtrl.text.trim(),
                        email: email, phone: phoneCtrl.text.trim(), notes: notesCtrl.text.trim(),
                      ));
                      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('$biz added!'), backgroundColor: AppColors.green));
                    }
                  },
                  child: Text(isEdit ? 'Save Changes' : 'Save Client'),
                )),
              ]),
            ],
          ),
        ),
      ),
    );
  }

  static Widget _field(String label, String hint, TextEditingController ctrl,
      {TextInputType? type, int maxLines = 1, bool readOnly = false}) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label.toUpperCase(), style: const TextStyle(fontFamily: 'Syne',
          fontSize: 9, color: AppColors.muted, letterSpacing: 1.0)),
      const SizedBox(height: 5),
      TextField(
        controller: ctrl, keyboardType: type, maxLines: maxLines, readOnly: readOnly,
        style: const TextStyle(fontFamily: 'Syne', fontSize: 13, color: AppColors.ink),
        decoration: InputDecoration(hintText: hint,
            filled: readOnly, fillColor: readOnly ? AppColors.surface2 : null),
      ),
    ]);
  }

  void _confirmDelete(BuildContext context, Client client) async {
    final state = context.read<AppState>();
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Client',
            style: TextStyle(fontFamily: 'Syne', fontWeight: FontWeight.w700)),
        content: Text('Delete ${client.displayName}? This cannot be undone.',
            style: const TextStyle(fontFamily: 'Syne')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(context, true),
              child: const Text('Delete', style: TextStyle(color: AppColors.accent))),
        ],
      ),
    );
    if (confirm == true && context.mounted) {
      state.deleteClient(client.id);
      if (_expandedId == client.id) setState(() => _expandedId = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();

    if (state.clients.isEmpty) {
      return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        const Icon(Icons.people_outline, size: 48, color: AppColors.muted2),
        const SizedBox(height: 12),
        const Text('No clients yet', style: TextStyle(fontFamily: 'Syne',
            fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.ink)),
        const SizedBox(height: 6),
        const Text('Add your first client to get started.',
            style: TextStyle(fontFamily: 'Syne', fontSize: 13, color: AppColors.muted)),
        const SizedBox(height: 16),
        AppButton(label: 'Add Client', icon: Icons.add,
            onTap: () => _showClientDialog(context)),
      ]));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(14),
      itemCount: state.clients.length,
      itemBuilder: (_, i) {
        final c          = state.clients[i];
        final expanded   = _expandedId == c.id;
        final clientInvs = state.invoices.where((inv) => inv.email == c.email).toList();
        final total      = clientInvs.fold(0.0, (s, inv) => s + inv.amount);
        final unpaid     = clientInvs.where((inv) => !inv.isFullyPaid).length;
        final color      = avatarColor(c.displayName);

        return GestureDetector(
          onTap: () => setState(() => _expandedId = expanded ? null : c.id),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            margin: const EdgeInsets.only(bottom: 10),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: expanded ? AppColors.accent.withOpacity(0.4) : AppColors.border,
                width: expanded ? 1.5 : 1,
              ),
              boxShadow: expanded ? [BoxShadow(
                color: AppColors.accent.withOpacity(0.06),
                blurRadius: 12, offset: const Offset(0, 4),
              )] : null,
            ),
            child: Column(children: [
              // HEADER
              Padding(
                padding: const EdgeInsets.all(14),
                child: Row(children: [
                  ClientAvatar(initials: c.initials, color: color),
                  const SizedBox(width: 12),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(c.displayName, style: const TextStyle(fontFamily: 'Syne',
                        fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.ink)),
                    const SizedBox(height: 4),
                    Row(children: [
                      Text('${clientInvs.length} invoice${clientInvs.length != 1 ? 's' : ''}',
                          style: const TextStyle(fontFamily: 'Syne', fontSize: 11, color: AppColors.muted)),
                      if (total > 0) ...[
                        const Text('  ·  ', style: TextStyle(color: AppColors.muted)),
                        Text('\$${total.toStringAsFixed(0)} total',
                            style: const TextStyle(fontFamily: 'Syne', fontSize: 11,
                                color: AppColors.ink, fontWeight: FontWeight.w600)),
                      ],
                      if (unpaid > 0) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(color: AppColors.accentBg,
                              borderRadius: BorderRadius.circular(20)),
                          child: Text('$unpaid unpaid', style: const TextStyle(
                              fontFamily: 'Syne', fontSize: 9,
                              fontWeight: FontWeight.w700, color: AppColors.accent)),
                        ),
                      ],
                    ]),
                  ])),
                  AnimatedRotation(
                    turns: expanded ? 0.5 : 0,
                    duration: const Duration(milliseconds: 200),
                    child: const Icon(Icons.keyboard_arrow_down, size: 20, color: AppColors.muted),
                  ),
                ]),
              ),

              // EXPANDED
              if (expanded) ...[
                const Divider(height: 1, color: AppColors.border),
                Padding(
                  padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    if (c.name.isNotEmpty) _detailRow(Icons.person_outline, c.name),
                    _detailRow(Icons.email_outlined, c.email),
                    if (c.phone.isNotEmpty) _detailRow(Icons.phone_outlined, c.phone),
                    if (c.notes.isNotEmpty) _detailRow(Icons.notes_outlined, c.notes),
                    const SizedBox(height: 12),
                    Row(children: [
                      Expanded(child: GestureDetector(
                        onTap: () => _showClientDialog(context, existing: c),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 9),
                          decoration: BoxDecoration(color: AppColors.blueBg,
                              borderRadius: BorderRadius.circular(8)),
                          alignment: Alignment.center,
                          child: const Row(mainAxisSize: MainAxisSize.min, children: [
                            Icon(Icons.edit_outlined, size: 13, color: AppColors.blue),
                            SizedBox(width: 5),
                            Text('Edit', style: TextStyle(fontFamily: 'Syne',
                                fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.blue)),
                          ]),
                        ),
                      )),
                      const SizedBox(width: 8),
                      Expanded(child: GestureDetector(
                        onTap: () => _confirmDelete(context, c),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 9),
                          decoration: BoxDecoration(color: AppColors.accentBg,
                              borderRadius: BorderRadius.circular(8)),
                          alignment: Alignment.center,
                          child: const Row(mainAxisSize: MainAxisSize.min, children: [
                            Icon(Icons.delete_outline, size: 13, color: AppColors.accent),
                            SizedBox(width: 5),
                            Text('Delete', style: TextStyle(fontFamily: 'Syne',
                                fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.accent)),
                          ]),
                        ),
                      )),
                    ]),
                  ]),
                ),
              ],
            ]),
          ),
        );
      },
    );
  }

  Widget _detailRow(IconData icon, String text) => Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: Row(children: [
      Icon(icon, size: 13, color: AppColors.muted),
      const SizedBox(width: 7),
      Expanded(child: Text(text, style: const TextStyle(
          fontFamily: 'Syne', fontSize: 12, color: AppColors.muted))),
    ]),
  );
}