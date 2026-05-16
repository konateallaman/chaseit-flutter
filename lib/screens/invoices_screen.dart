import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../services/app_state.dart';
import '../models/invoice.dart';
import '../theme/app_theme.dart';
import '../widgets/common_widgets.dart';
import 'invoice_form_screen.dart';
import 'chase_screen.dart';
import 'payment_screen.dart';

class InvoicesScreen extends StatefulWidget {
  const InvoicesScreen({super.key});
  @override
  State<InvoicesScreen> createState() => _InvoicesScreenState();
}

class _InvoicesScreenState extends State<InvoicesScreen> {
  String _filter = 'all';

  List<Invoice> _filtered(List<Invoice> invoices) {
    switch (_filter) {
      case 'overdue': return invoices.where((i) => !i.isFullyPaid && i.daysOverdue > 0).toList();
      case 'pending': return invoices.where((i) => !i.isFullyPaid && i.daysOverdue <= 0).toList();
      case 'paid': return invoices.where((i) => i.isFullyPaid).toList();
      default: return invoices;
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final invoices = _filtered(state.invoices);

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: Column(
        children: [
          // Filter tabs
          Container(
            color: AppColors.surface,
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 10),
            child: Row(
              children: [
                for (final f in ['all', 'overdue', 'pending', 'paid'])
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _filter = f),
                      child: Container(
                        margin: const EdgeInsets.only(right: 4),
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        decoration: BoxDecoration(
                          color: _filter == f ? AppColors.surface : AppColors.surface2,
                          borderRadius: BorderRadius.circular(6),
                          boxShadow: _filter == f ? [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 4)] : null,
                        ),
                        alignment: Alignment.center,
                        child: Text(f[0].toUpperCase() + f.substring(1),
                            style: TextStyle(fontFamily: 'Roboto', fontSize: 11, fontWeight: FontWeight.w500,
                                color: _filter == f ? AppColors.ink : AppColors.muted)),
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // Invoice list
          Expanded(
            child: invoices.isEmpty
                ? Center(
                    child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                      const Icon(Icons.receipt_long_outlined, size: 48, color: AppColors.muted2),
                      const SizedBox(height: 12),
                      Text('No $_filter invoices', style: const TextStyle(fontFamily: 'Roboto', fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.ink)),
                      const SizedBox(height: 6),
                      const Text('Try a different filter', style: TextStyle(fontFamily: 'Roboto', fontSize: 13, color: AppColors.muted)),
                    ]),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: invoices.length,
                    itemBuilder: (_, i) => _InvoiceListItem(invoice: invoices[i]),
                  ),
          ),
        ],
      ),
    );
  }
}

class _InvoiceListItem extends StatelessWidget {
  final Invoice invoice;
  const _InvoiceListItem({required this.invoice});

  void _confirmDelete(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Invoice', style: TextStyle(fontFamily: 'Roboto', fontWeight: FontWeight.w700)),
        content: Text('Delete invoice for ${invoice.client}? This cannot be undone.', style: const TextStyle(fontFamily: 'Roboto')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(context, true),
              child: const Text('Delete', style: TextStyle(color: AppColors.accent))),
        ],
      ),
    );
    if (confirm == true && context.mounted) {
      context.read<AppState>().deleteInvoice(invoice.id);
    }
  }

  void _confirmUndoPaid(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Reverse Payment', style: TextStyle(fontFamily: 'Roboto', fontWeight: FontWeight.w700)),
        content: Text('Reverse full payment for ${invoice.client}? This resets to unpaid.', style: const TextStyle(fontFamily: 'Roboto')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(context, true),
              child: const Text('Reverse', style: TextStyle(color: AppColors.accent))),
        ],
      ),
    );
    if (confirm == true && context.mounted) {
      context.read<AppState>().undoPaid(invoice.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final inv = invoice;
    final pct = inv.amount > 0 ? (inv.paidAmount / inv.amount * 100).round() : 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: AppColors.surface, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(inv.client, style: const TextStyle(fontFamily: 'Roboto', fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.ink)),
                      Text(inv.email, style: const TextStyle(fontFamily: 'Roboto', fontSize: 11, color: AppColors.muted)),
                    ])),
                    StatusBadge(status: inv.status, daysOverdue: inv.daysOverdue, pctPaid: pct),
                  ],
                ),
                const SizedBox(height: 10),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('\$${NumberFormat('#,##0.00').format(inv.amount)}',
                        style: const TextStyle(fontFamily: 'Roboto', fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.ink)),
                    if (inv.paidAmount > 0 && !inv.isFullyPaid)
                      Text('\$${NumberFormat('#,##0.00').format(inv.paidAmount)} received',
                          style: const TextStyle(fontFamily: 'Roboto', fontSize: 11, color: AppColors.yellow)),
                  ]),
                  Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                    Text('Due ${inv.due}', style: const TextStyle(fontFamily: 'Roboto', fontSize: 12, color: AppColors.muted)),
                    Text('${inv.chases} chase${inv.chases != 1 ? 's' : ''} sent',
                        style: const TextStyle(fontFamily: 'Roboto', fontSize: 11, color: AppColors.muted)),
                  ]),
                ]),
              ],
            ),
          ),

          // Action buttons
          Container(
            decoration: const BoxDecoration(border: Border(top: BorderSide(color: AppColors.border))),
            child: inv.isFullyPaid
                ? Row(children: [
                    Expanded(child: _actionBtn('✓ Collected', AppColors.green, AppColors.greenBg,
                        () => _confirmUndoPaid(context))),
                    Expanded(child: _actionBtn('Edit', AppColors.muted, AppColors.surface2,
                        () => Navigator.push(context, MaterialPageRoute(builder: (_) => InvoiceFormScreen(invoice: inv))))),
                    Expanded(child: _actionBtn('Delete', AppColors.accent, AppColors.accentBg,
                        () => _confirmDelete(context))),
                  ])
                : Row(children: [
                    Expanded(child: _actionBtn('Chase', AppColors.accent, AppColors.accentBg,
                        () => Navigator.push(context, MaterialPageRoute(builder: (_) => ChaseScreen(invoice: inv))))),
                    Expanded(child: _actionBtn('+ Pay', AppColors.yellow, AppColors.yellowBg,
                        () => Navigator.push(context, MaterialPageRoute(builder: (_) => PaymentScreen(invoice: inv))))),
                    Expanded(child: _actionBtn('Edit', AppColors.muted, AppColors.surface2,
                        () => Navigator.push(context, MaterialPageRoute(builder: (_) => InvoiceFormScreen(invoice: inv))))),
                    Expanded(child: _actionBtn('Paid ✓', AppColors.green, AppColors.greenBg,
                        () => context.read<AppState>().markPaid(inv.id))),
                  ]),
          ),
        ],
      ),
    );
  }

  Widget _actionBtn(String label, Color fg, Color bg, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 9),
        decoration: BoxDecoration(color: bg),
        alignment: Alignment.center,
        child: Text(label, style: TextStyle(fontFamily: 'Roboto', fontSize: 11, fontWeight: FontWeight.w600, color: fg)),
      ),
    );
  }
}
