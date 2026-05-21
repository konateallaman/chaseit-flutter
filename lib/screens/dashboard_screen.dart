import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../services/app_state.dart';
import '../theme/app_theme.dart';
import '../widgets/common_widgets.dart';
import '../models/invoice.dart';
import 'invoice_form_screen.dart';
import 'chase_screen.dart';
import 'payment_screen.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  String _fmt(double n) => '\$${NumberFormat('#,##0.00').format(n)}';

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();

    if (state.loading) {
      return const Center(child: CircularProgressIndicator(color: AppColors.accent));
    }

    final outstanding = state.totalOutstanding;
    final collected = state.totalCollected;
    final overdue = state.overdueInvoices;
    final paid = state.paidInvoices;
    final rate = state.invoices.isEmpty
        ? '—'
        : '${(state.recoveryRate * 100).round()}%';
    final recent = state.invoices.take(5).toList();
    final isWide = MediaQuery.of(context).size.width >= 700;

    return RefreshIndicator(
      color: AppColors.accent,
      onRefresh: () => state.loadData(),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── STATS GRID ──
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              childAspectRatio: isWide ? 1.8 : (MediaQuery.of(context).size.width < 380 ? 1.2 : 1.4),
              children: [
                StatCard(
                  label: 'Outstanding',
                  value: _fmt(outstanding),
                  sub: 'unpaid invoices',
                  badgeText: '${overdue.length} overdue',
                  badgeColor: AppColors.accent,
                  badgeBg: AppColors.accentBg,
                ),
                StatCard(
                  label: 'Collected',
                  value: _fmt(collected),
                  sub: 'paid invoices',
                  badgeText: '${paid.length} paid',
                  badgeColor: AppColors.green,
                  badgeBg: AppColors.greenBg,
                ),
                StatCard(
                  label: 'Chasers Sent',
                  value: state.totalChasers.toString(),
                  sub: 'follow-ups automated',
                  badgeText: 'this month',
                  badgeColor: AppColors.yellow,
                  badgeBg: AppColors.yellowBg,
                ),
                StatCard(
                  label: 'Recovery Rate',
                  value: rate,
                  sub: 'invoices recovered',
                  badgeText: 'via automation',
                  badgeColor: AppColors.blue,
                  badgeBg: AppColors.blueBg,
                ),
              ],
            ),
            const SizedBox(height: 20),

            // ── RECENT INVOICES ──
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Expanded(
                  child: Text('Recent Invoices',
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: AppColors.ink,
                          fontFamily: 'Syne')),
                ),
                TextButton(
                  onPressed: () {},
                  child: const Text('View all →',
                      style: TextStyle(fontSize: 12, color: AppColors.accent, fontFamily: 'Syne')),
                ),
              ],
            ),
            const SizedBox(height: 8),

            if (recent.isEmpty)
              _emptyState(context)
            else
              // ── MOBILE: cards, WIDE: table ──
              isWide
                  ? _wideTable(context, recent, state)
                  : _mobileCards(context, recent, state),

            const SizedBox(height: 20),

            // ── NEEDS ATTENTION ──
            if (overdue.isNotEmpty) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const Expanded(
                    child: Text('🔥  Needs attention',
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                        style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: AppColors.ink,
                            fontFamily: 'Syne')),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () => Navigator.push(context,
                        MaterialPageRoute(builder: (_) => BulkChaseScreen(invoices: overdue))),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.yellowBg,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppColors.yellow.withOpacity(0.3)),
                      ),
                      child: const Row(mainAxisSize: MainAxisSize.min, children: [
                        Icon(Icons.auto_awesome, size: 11, color: AppColors.yellow),
                        SizedBox(width: 3),
                        Text('Run Chasers',
                            style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: AppColors.yellow,
                                fontFamily: 'Syne')),
                      ]),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.yellowBg,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.yellow.withOpacity(0.2)),
                ),
                child: RichText(
                  text: TextSpan(
                    style: const TextStyle(
                        fontSize: 13, color: AppColors.yellow, height: 1.5, fontFamily: 'Syne'),
                    children: [
                      TextSpan(
                        text: '${overdue.length} overdue invoice${overdue.length > 1 ? 's' : ''}',
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      const TextSpan(text: ' totalling '),
                      TextSpan(
                        text: _fmt(overdue.fold(0.0, (s, i) => s + i.remaining)),
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      const TextSpan(text: ' need follow-ups. Hit '),
                      const TextSpan(
                          text: 'Run Chasers Now',
                          style: TextStyle(fontWeight: FontWeight.w700)),
                      const TextSpan(text: ' to auto-generate AI messages.'),
                    ],
                  ),
                ),
              ),
            ] else ...[
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.greenBg,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.green.withOpacity(0.2)),
                ),
                child: const Row(children: [
                  Icon(Icons.check_circle_outline, size: 16, color: AppColors.green),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text('No overdue invoices — you\'re all caught up!',
                        style: TextStyle(
                            fontSize: 13,
                            color: AppColors.green,
                            fontWeight: FontWeight.w500,
                            fontFamily: 'Syne')),
                  ),
                ]),
              ),
            ],
            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }

  // ── MOBILE CARD LAYOUT ──────────────────────────────────
  Widget _mobileCards(BuildContext context, List<Invoice> invoices, AppState state) {
    return Column(
      children: invoices.map((inv) => _mobileInvoiceCard(context, inv, state)).toList(),
    );
  }

  Widget _mobileInvoiceCard(BuildContext context, Invoice inv, AppState state) {
    final pct = inv.amount > 0 ? (inv.paidAmount / inv.amount * 100).round() : 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          // Card header — client + status
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(inv.client,
                              style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.ink,
                                  fontFamily: 'Syne')),
                          const SizedBox(height: 2),
                          Text(inv.email,
                              style: const TextStyle(
                                  fontSize: 11,
                                  color: AppColors.muted,
                                  fontFamily: 'Syne'),
                              overflow: TextOverflow.ellipsis),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    StatusBadge(status: inv.status, daysOverdue: inv.daysOverdue, pctPaid: pct),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(
                        '\$${NumberFormat('#,##0.00').format(inv.amount)}',
                        style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: AppColors.ink,
                            fontFamily: 'Syne',
                            letterSpacing: -0.5),
                      ),
                      if (inv.paidAmount > 0 && !inv.isFullyPaid)
                        Text(
                          '\$${NumberFormat('#,##0.00').format(inv.paidAmount)} received',
                          style: const TextStyle(
                              fontSize: 11, color: AppColors.yellow, fontFamily: 'Syne'),
                        ),
                    ]),
                    Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                      const Text('Due',
                          style: TextStyle(fontSize: 10, color: AppColors.muted, fontFamily: 'Syne')),
                      Text(inv.due,
                          style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppColors.ink,
                              fontFamily: 'Syne')),
                      Text('${inv.chases} chase${inv.chases != 1 ? 's' : ''} sent',
                          style: const TextStyle(
                              fontSize: 10, color: AppColors.muted, fontFamily: 'Syne')),
                    ]),
                  ],
                ),
              ],
            ),
          ),

          // Action buttons row
          Container(
            decoration: const BoxDecoration(
              border: Border(top: BorderSide(color: AppColors.border)),
            ),
            child: inv.isFullyPaid
                ? Row(children: [
                    Expanded(child: _actionBtn('✓ Collected', AppColors.green,
                        AppColors.greenBg, () => state.undoPaid(inv.id))),
                    Expanded(child: _actionBtn('Edit', AppColors.muted,
                        AppColors.surface2, () => Navigator.push(context,
                            MaterialPageRoute(builder: (_) => InvoiceFormScreen(invoice: inv))))),
                    Expanded(child: _actionBtn('Delete', AppColors.accent,
                        AppColors.accentBg, () => _confirmDelete(context, inv, state))),
                  ])
                : Row(children: [
                    Expanded(child: _actionBtn('Chase', AppColors.accent,
                        AppColors.accentBg, () => Navigator.push(context,
                            MaterialPageRoute(builder: (_) => ChaseScreen(invoice: inv))))),
                    Expanded(child: _actionBtn('+ Pay', AppColors.yellow,
                        AppColors.yellowBg, () => Navigator.push(context,
                            MaterialPageRoute(builder: (_) => PaymentScreen(invoice: inv))))),
                    Expanded(child: _actionBtn('Edit', AppColors.muted,
                        AppColors.surface2, () => Navigator.push(context,
                            MaterialPageRoute(builder: (_) => InvoiceFormScreen(invoice: inv))))),
                    Expanded(child: _actionBtn('Paid ✓', AppColors.green,
                        AppColors.greenBg, () => state.markPaid(inv.id))),
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
        padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 2),
        decoration: BoxDecoration(color: bg),
        alignment: Alignment.center,
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(label,
              style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: fg,
                  fontFamily: 'Syne')),
        ),
      ),
    );
  }

  // ── WIDE TABLE LAYOUT ───────────────────────────────────
  Widget _wideTable(BuildContext context, List<Invoice> invoices, AppState state) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: const BoxDecoration(
              color: AppColors.surface2,
              borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(12), topRight: Radius.circular(12)),
            ),
            child: const Row(children: [
              Expanded(flex: 3, child: Text('CLIENT', style: TextStyle(fontSize: 9, color: AppColors.muted, letterSpacing: 1.0, fontFamily: 'Syne'))),
              Expanded(flex: 2, child: Text('AMOUNT', style: TextStyle(fontSize: 9, color: AppColors.muted, letterSpacing: 1.0, fontFamily: 'Syne'))),
              Expanded(flex: 2, child: Text('DUE', style: TextStyle(fontSize: 9, color: AppColors.muted, letterSpacing: 1.0, fontFamily: 'Syne'))),
              Expanded(flex: 2, child: Text('STATUS', style: TextStyle(fontSize: 9, color: AppColors.muted, letterSpacing: 1.0, fontFamily: 'Syne'))),
              Expanded(flex: 4, child: Text('ACTIONS', textAlign: TextAlign.right, style: TextStyle(fontSize: 9, color: AppColors.muted, letterSpacing: 1.0, fontFamily: 'Syne'))),
            ]),
          ),
          ...invoices.asMap().entries.map((e) {
            final inv = e.value;
            final isLast = e.key == invoices.length - 1;
            final pct = inv.amount > 0 ? (inv.paidAmount / inv.amount * 100).round() : 0;
            return Container(
              decoration: BoxDecoration(
                border: isLast ? null : const Border(bottom: BorderSide(color: AppColors.border)),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(flex: 3, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(inv.client, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.ink, fontFamily: 'Syne')),
                    Text(inv.email, style: const TextStyle(fontSize: 10, color: AppColors.muted, fontFamily: 'Syne'), overflow: TextOverflow.ellipsis),
                  ])),
                  Expanded(flex: 2, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('\$${NumberFormat('#,##0.00').format(inv.amount)}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.ink, fontFamily: 'Syne')),
                    if (inv.paidAmount > 0 && !inv.isFullyPaid)
                      Text('\$${NumberFormat('#,##0.00').format(inv.paidAmount)} rcvd', style: const TextStyle(fontSize: 10, color: AppColors.yellow, fontFamily: 'Syne')),
                  ])),
                  Expanded(flex: 2, child: Text(inv.due, style: const TextStyle(fontSize: 11, color: AppColors.muted, fontFamily: 'Syne'))),
                  Expanded(flex: 2, child: StatusBadge(status: inv.status, daysOverdue: inv.daysOverdue, pctPaid: pct)),
                  Expanded(flex: 4, child: Wrap(
                    alignment: WrapAlignment.end,
                    spacing: 4,
                    runSpacing: 4,
                    children: inv.isFullyPaid ? [
                      _miniBtn('✓ Collected', AppColors.green, AppColors.greenBg, () => state.undoPaid(inv.id)),
                      _miniBtn('Edit', AppColors.muted, AppColors.surface2, () => Navigator.push(context, MaterialPageRoute(builder: (_) => InvoiceFormScreen(invoice: inv)))),
                      _miniBtn('Delete', AppColors.accent, AppColors.accentBg, () => _confirmDelete(context, inv, state)),
                    ] : [
                      _miniBtn('Chase', AppColors.accent, AppColors.accentBg, () => Navigator.push(context, MaterialPageRoute(builder: (_) => ChaseScreen(invoice: inv)))),
                      _miniBtn('+ Pay', AppColors.yellow, AppColors.yellowBg, () => Navigator.push(context, MaterialPageRoute(builder: (_) => PaymentScreen(invoice: inv)))),
                      _miniBtn('Edit', AppColors.muted, AppColors.surface2, () => Navigator.push(context, MaterialPageRoute(builder: (_) => InvoiceFormScreen(invoice: inv)))),
                      _miniBtn('Full ✓', AppColors.green, AppColors.greenBg, () => state.markPaid(inv.id)),
                    ],
                  )),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _miniBtn(String label, Color fg, Color bg, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(6)),
        child: Text(label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: fg, fontFamily: 'Syne')),
      ),
    );
  }

  void _confirmDelete(BuildContext context, Invoice inv, AppState state) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Invoice', style: TextStyle(fontFamily: 'Syne', fontWeight: FontWeight.w700)),
        content: Text('Delete invoice for ${inv.client}? This cannot be undone.',
            style: const TextStyle(fontFamily: 'Syne')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(context, true),
              child: const Text('Delete', style: TextStyle(color: AppColors.accent))),
        ],
      ),
    );
    if (confirm == true && context.mounted) state.deleteInvoice(inv.id);
  }

  Widget _emptyState(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(children: [
        const Icon(Icons.receipt_long_outlined, size: 40, color: AppColors.muted2),
        const SizedBox(height: 12),
        const Text('No invoices yet',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.ink, fontFamily: 'Syne')),
        const SizedBox(height: 6),
        const Text('Create your first invoice to start automating follow-ups.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: AppColors.muted, fontFamily: 'Syne')),
        const SizedBox(height: 16),
        ElevatedButton.icon(
          onPressed: () => Navigator.push(context,
              MaterialPageRoute(builder: (_) => const InvoiceFormScreen())),
          icon: const Icon(Icons.add, size: 16),
          label: const Text('New Invoice'),
        ),
      ]),
    );
  }
}