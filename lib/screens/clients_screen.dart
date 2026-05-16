import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../services/app_state.dart';
import '../models/client.dart';
import '../theme/app_theme.dart';
import '../widgets/common_widgets.dart';

class ClientsScreen extends StatelessWidget {
  const ClientsScreen({super.key});

  void _showAddClient(BuildContext context) {
    final bizCtrl = TextEditingController();
    final nameCtrl = TextEditingController();
    final emailCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    final notesCtrl = TextEditingController();

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => Dialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              const Text('Add Client', style: TextStyle(fontFamily: 'Syne', fontSize: 17, fontWeight: FontWeight.w800, color: AppColors.ink)),
              GestureDetector(
                onTap: () => Navigator.pop(ctx),
                child: Container(
                  width: 28, height: 28,
                  decoration: BoxDecoration(color: AppColors.surface2, borderRadius: BorderRadius.circular(7)),
                  child: const Icon(Icons.close, size: 15, color: AppColors.muted),
                ),
              ),
            ]),
            const SizedBox(height: 20),
            AppField(label: 'Business Name', hint: 'Acme Corp', controller: bizCtrl),
            const SizedBox(height: 12),
            AppField(label: 'Contact Name', hint: 'John Smith', controller: nameCtrl),
            const SizedBox(height: 12),
            AppField(label: 'Email', hint: 'john@acme.com', controller: emailCtrl, keyboardType: TextInputType.emailAddress),
            const SizedBox(height: 12),
            AppField(label: 'Phone', hint: '+1 555 000 0000', controller: phoneCtrl, keyboardType: TextInputType.phone),
            const SizedBox(height: 20),
            Row(children: [
              Expanded(child: OutlinedButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancel'),
              )),
              const SizedBox(width: 10),
              Expanded(child: ElevatedButton(
                onPressed: () async {
                  final biz = bizCtrl.text.trim();
                  final name = nameCtrl.text.trim();
                  final email = emailCtrl.text.trim();
                  final phone = phoneCtrl.text.trim();
                  final notes = notesCtrl.text.trim();

                  if (biz.isEmpty || email.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Business name and email are required'), backgroundColor: AppColors.accent),
                    );
                    return;
                  }

                  Navigator.pop(ctx);

                  await context.read<AppState>().createClient(Client(
                    id: const Uuid().v4(),
                    biz: biz,
                    name: name,
                    email: email,
                    phone: phone,
                    notes: notes,
                  ));

                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('$biz added!'), backgroundColor: AppColors.green),
                    );
                  }
                },
                child: const Text('Save Client'),
              )),
            ]),
          ]),
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context, Client client) async {
    final state = context.read<AppState>();
    final hasInvoices = state.invoices.any((i) => i.email == client.email);
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Client', style: TextStyle(fontFamily: 'Syne', fontWeight: FontWeight.w700)),
        content: Text(hasInvoices
            ? '${client.displayName} has linked invoices. Delete client anyway? Their invoices will remain.'
            : 'Delete ${client.displayName}? This cannot be undone.',
            style: const TextStyle(fontFamily: 'Syne')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(context, true),
              child: const Text('Delete', style: TextStyle(color: AppColors.accent))),
        ],
      ),
    );
    if (confirm == true && context.mounted) state.deleteClient(client.id);
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();

    if (state.clients.isEmpty) {
      return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        const Icon(Icons.people_outline, size: 48, color: AppColors.muted2),
        const SizedBox(height: 12),
        const Text('No clients yet', style: TextStyle(fontFamily: 'Syne', fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.ink)),
        const SizedBox(height: 6),
        const Text('Add your first client to get started.', style: TextStyle(fontFamily: 'Syne', fontSize: 13, color: AppColors.muted)),
        const SizedBox(height: 16),
        AppButton(label: 'Add Client', icon: Icons.add, onTap: () => _showAddClient(context)),
      ]));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: state.clients.length,
      itemBuilder: (_, i) {
        final c = state.clients[i];
        final clientInvs = state.invoices.where((inv) => inv.email == c.email).toList();
        final total = clientInvs.fold(0.0, (s, inv) => s + inv.amount);
        final unpaid = clientInvs.where((inv) => !inv.isFullyPaid).length;
        final color = avatarColor(c.displayName);

        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surface, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.border),
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClientAvatar(initials: c.initials, color: color),
                const SizedBox(width: 12),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(c.displayName, style: const TextStyle(fontFamily: 'Syne', fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.ink)),
                  if (c.name.isNotEmpty && c.name != c.biz)
                    Text(c.name, style: const TextStyle(fontFamily: 'Syne', fontSize: 12, color: AppColors.muted)),
                  Text(c.email, style: const TextStyle(fontFamily: 'Syne', fontSize: 11, color: AppColors.muted)),
                ])),
                GestureDetector(
                  onTap: () => _confirmDelete(context, c),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(color: AppColors.accentBg, borderRadius: BorderRadius.circular(6)),
                    child: const Text('Delete', style: TextStyle(fontFamily: 'Syne', fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.accent)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(children: [
              _statChip('${clientInvs.length} invoices', AppColors.muted),
              const SizedBox(width: 8),
              _statChip('\$${total.toStringAsFixed(0)} total', AppColors.ink),
              if (unpaid > 0) ...[const SizedBox(width: 8), _statChip('$unpaid unpaid', AppColors.accent)],
            ]),
          ]),
        );
      },
    );
  }

  Widget _statChip(String text, Color color) {
    return Text(text, style: TextStyle(fontFamily: 'Syne', fontSize: 11, color: color, fontWeight: FontWeight.w500));
  }
}
