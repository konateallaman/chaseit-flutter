import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/app_state.dart';
import '../theme/app_theme.dart';
import '../models/invoice.dart';

class AutomationScreen extends StatelessWidget {
  const AutomationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final overdue = state.overdueInvoices;
    final upcoming = state.invoices.where((i) =>
        !i.isFullyPaid && i.daysOverdue <= 0 &&
        DateTime.tryParse(i.due) != null &&
        DateTime.parse(i.due).difference(DateTime.now()).inDays <= 2
    ).toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

        // ── STATUS CARD ──────────────────────────────────
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF1A1612), Color(0xFF2D2418)],
              begin: Alignment.topLeft, end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Container(
                width: 10, height: 10,
                decoration: const BoxDecoration(color: AppColors.green, shape: BoxShape.circle),
              ),
              const SizedBox(width: 8),
              const Text('Automation Active', style: TextStyle(fontFamily: 'Syne',
                  fontSize: 14, fontWeight: FontWeight.w700, color: Colors.white)),
            ]),
            const SizedBox(height: 8),
            Text('ChaseIt runs automatically every day at 8:00 AM.\nFollow-ups are sent based on each invoice\'s chase sequence.',
                style: TextStyle(fontFamily: 'Syne', fontSize: 12,
                    color: Colors.white.withOpacity(0.55), height: 1.6)),
            const SizedBox(height: 14),
            Row(children: [
              _statPill('${state.totalChasers}', 'total sent', AppColors.accent),
              const SizedBox(width: 8),
              _statPill('${overdue.length}', 'overdue', AppColors.yellow),
              const SizedBox(width: 8),
              _statPill('${upcoming.length}', 'due soon', AppColors.blue),
            ]),
          ]),
        ),
        const SizedBox(height: 20),

        // ── HOW IT WORKS ─────────────────────────────────
        const Text('How automation works', style: TextStyle(fontFamily: 'Syne',
            fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.ink)),
        const SizedBox(height: 12),
        _ruleCard(
          icon: Icons.notifications_outlined,
          color: AppColors.yellow,
          bg: AppColors.yellowBg,
          title: 'Due tomorrow reminder',
          desc: 'A friendly reminder is sent to the client 1 day before the invoice is due.',
        ),
        const SizedBox(height: 8),
        _ruleCard(
          icon: Icons.psychology_outlined,
          color: AppColors.accent,
          bg: AppColors.accentBg,
          title: 'Gentle sequence',
          desc: 'Follow-ups sent at 3, 7, and 14 days overdue. Friendly tone that escalates.',
        ),
        const SizedBox(height: 8),
        _ruleCard(
          icon: Icons.bolt_outlined,
          color: AppColors.blue,
          bg: AppColors.blueBg,
          title: 'Firm sequence',
          desc: 'Follow-ups sent at 1, 3, and 7 days overdue. Professional and direct.',
        ),
        const SizedBox(height: 8),
        _ruleCard(
          icon: Icons.warning_amber_outlined,
          color: const Color(0xFF7C3AED),
          bg: const Color(0xFFF3F0FF),
          title: 'Urgent sequence',
          desc: 'Follow-ups sent at 1, 2, and 3 days overdue. Serious and firm tone.',
        ),
        const SizedBox(height: 20),

        // ── UPCOMING AUTOMATIONS ─────────────────────────
        if (upcoming.isNotEmpty) ...[
          const Text('Due soon — reminders pending', style: TextStyle(fontFamily: 'Syne',
              fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.ink)),
          const SizedBox(height: 10),
          ...upcoming.map((inv) => _invoiceAutomationCard(inv, 'Reminder tomorrow', AppColors.yellow)),
          const SizedBox(height: 20),
        ],

        // ── OVERDUE QUEUE ────────────────────────────────
        if (overdue.isNotEmpty) ...[
          const Text('Overdue — chase queue', style: TextStyle(fontFamily: 'Syne',
              fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.ink)),
          const SizedBox(height: 10),
          ...overdue.map((inv) {
            final seq = inv.seq;
            final chases = inv.chases;
            final schedules = {'gentle': [3,7,14], 'firm': [1,3,7], 'urgent': [1,2,3]};
            final schedule = schedules[seq] ?? [3,7,14];
            final nextDay = chases < schedule.length ? schedule[chases] : null;
            final status = nextDay == null
                ? 'All chases sent'
                : inv.daysOverdue >= nextDay
                    ? 'Chase #${chases+1} pending today'
                    : 'Chase #${chases+1} in ${nextDay - inv.daysOverdue}d';
            final color = nextDay == null ? AppColors.green
                : inv.daysOverdue >= nextDay ? AppColors.accent : AppColors.yellow;
            return _invoiceAutomationCard(inv, status, color);
          }),
          const SizedBox(height: 20),
        ],

        // ── STRIPE INTEGRATION ───────────────────────────
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Container(width: 36, height: 36,
                  decoration: BoxDecoration(color: const Color(0xFFEEF2FF), borderRadius: BorderRadius.circular(10)),
                  child: const Icon(Icons.payment, color: Color(0xFF6366F1), size: 20)),
              const SizedBox(width: 12),
              const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Stripe Auto-Payment', style: TextStyle(fontFamily: 'Syne',
                    fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.ink)),
                Text('Invoices mark as paid automatically when client pays online',
                    style: TextStyle(fontFamily: 'Syne', fontSize: 11, color: AppColors.muted)),
              ])),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: AppColors.yellowBg, borderRadius: BorderRadius.circular(20)),
                child: const Text('Setup needed', style: TextStyle(fontFamily: 'Syne',
                    fontSize: 10, fontWeight: FontWeight.w600, color: AppColors.yellow)),
              ),
            ]),
            const SizedBox(height: 14),
            const Divider(color: AppColors.border),
            const SizedBox(height: 12),
            const Text('To enable Stripe auto-payment:', style: TextStyle(fontFamily: 'Syne',
                fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.ink)),
            const SizedBox(height: 8),
            _setupStep('1', 'Create a Stripe account at stripe.com'),
            _setupStep('2', 'Add STRIPE_WEBHOOK_SECRET to Vercel env vars'),
            _setupStep('3', 'Set webhook URL to: your-api.vercel.app/api/webhook-stripe'),
            _setupStep('4', 'Add invoice_num to Stripe payment metadata'),
          ]),
        ),
        const SizedBox(height: 80),
      ]),
    );
  }

  Widget _statPill(String value, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(children: [
        Text(value, style: TextStyle(fontFamily: 'Syne', fontSize: 18,
            fontWeight: FontWeight.w800, color: color)),
        Text(label, style: TextStyle(fontFamily: 'Syne', fontSize: 9,
            color: color.withOpacity(0.8))),
      ]),
    );
  }

  Widget _ruleCard({required IconData icon, required Color color, required Color bg,
      required String title, required String desc}) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(children: [
        Container(width: 36, height: 36,
            decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, size: 18, color: color)),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: const TextStyle(fontFamily: 'Syne', fontSize: 13,
              fontWeight: FontWeight.w700, color: AppColors.ink)),
          Text(desc, style: const TextStyle(fontFamily: 'Syne', fontSize: 11,
              color: AppColors.muted, height: 1.5)),
        ])),
      ]),
    );
  }

  Widget _invoiceAutomationCard(Invoice inv, String status, Color color) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(children: [
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(inv.client, style: const TextStyle(fontFamily: 'Syne', fontSize: 13,
              fontWeight: FontWeight.w600, color: AppColors.ink)),
          Text('${inv.num} · \$${inv.remaining.toStringAsFixed(2)} · due ${inv.due}',
              style: const TextStyle(fontFamily: 'Syne', fontSize: 11, color: AppColors.muted)),
        ])),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: color.withOpacity(0.12),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(status, style: TextStyle(fontFamily: 'Syne', fontSize: 10,
              fontWeight: FontWeight.w600, color: color)),
        ),
      ]),
    );
  }

  Widget _setupStep(String num, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(children: [
        Container(width: 20, height: 20,
            decoration: BoxDecoration(color: AppColors.surface2, borderRadius: BorderRadius.circular(10)),
            alignment: Alignment.center,
            child: Text(num, style: const TextStyle(fontFamily: 'Syne', fontSize: 10,
                fontWeight: FontWeight.w700, color: AppColors.muted))),
        const SizedBox(width: 8),
        Expanded(child: Text(text, style: const TextStyle(fontFamily: 'Syne',
            fontSize: 12, color: AppColors.muted))),
      ]),
    );
  }
}
