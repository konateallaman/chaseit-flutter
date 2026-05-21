import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'register_screen.dart';
import 'login_screen.dart';

class LandingScreen extends StatelessWidget {
  const LandingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    final isWide = w >= 700;
    return Scaffold(
      backgroundColor: const Color(0xFF0F0D0A),
      body: SingleChildScrollView(
        child: Column(children: [
          _nav(context),
          _hero(context, isWide),
          _statsBar(),
          _features(isWide),
          _howItWorks(isWide),
          _pricing(context, isWide),
          _cta(context),
          _footer(),
        ]),
      ),
    );
  }

  // ── NAV ─────────────────────────────────────────────────
  Widget _nav(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width >= 500;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF0F0D0A),
        border: Border(bottom: BorderSide(color: Colors.white.withOpacity(0.07))),
      ),
      child: Row(children: [
        // Logo
        Row(children: [
          Container(width: 28, height: 28,
              decoration: BoxDecoration(color: AppColors.accent, borderRadius: BorderRadius.circular(7)),
              child: const Icon(Icons.timer_outlined, size: 14, color: Colors.white)),
          const SizedBox(width: 7),
          const Text('ChaseIt', style: TextStyle(fontFamily: 'Syne', fontSize: 16,
              fontWeight: FontWeight.w800, color: Colors.white, letterSpacing: -0.5)),
        ]),
        const Spacer(),
        // Sign in — text only on small screens
        MouseRegion(
          cursor: SystemMouseCursors.click,
          child: GestureDetector(
            onTap: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const LoginScreen())),
            child: Text(
              'Sign in',
              style: TextStyle(fontFamily: 'Syne', fontSize: 13,
                  color: Colors.white.withOpacity(0.6)),
            ),
          ),
        ),
        const SizedBox(width: 10),
        // Get started button
        MouseRegion(
          cursor: SystemMouseCursors.click,
          child: GestureDetector(
            onTap: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const RegisterScreen())),
            child: Container(
              padding: EdgeInsets.symmetric(
                  horizontal: isWide ? 14 : 10, vertical: 7),
              decoration: BoxDecoration(
                  color: AppColors.accent, borderRadius: BorderRadius.circular(8)),
              child: Text(
                isWide ? 'Get started' : 'Start',
                style: const TextStyle(fontFamily: 'Syne', fontSize: 12,
                    fontWeight: FontWeight.w700, color: Colors.white),
              ),
            ),
          ),
        ),
      ]),
    );
  }

  Widget _navLink(String label, VoidCallback onTap) {
    return _HoverTextBtn(label: label, onTap: onTap);
  }

  Widget _navBtn(String label, VoidCallback onTap) {
    return _HoverBtn(label: label, onTap: onTap,
        bg: AppColors.accent, hoverBg: const Color(0xFFC0390D));
  }

  // ── HERO ────────────────────────────────────────────────
  Widget _hero(BuildContext context, bool isWide) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 24, vertical: isWide ? 80 : 52),
      color: const Color(0xFF0F0D0A),
      child: Column(children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.accent.withOpacity(0.5)),
            borderRadius: BorderRadius.circular(20),
            color: AppColors.accent.withOpacity(0.08),
          ),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Container(width: 6, height: 6,
                decoration: const BoxDecoration(color: AppColors.accent, shape: BoxShape.circle)),
            const SizedBox(width: 6),
            const Text('AI-powered invoice follow-ups', style: TextStyle(fontFamily: 'Syne',
                fontSize: 12, color: AppColors.accent, fontWeight: FontWeight.w600)),
          ]),
        ),
        const SizedBox(height: 24),
        Text('Stop chasing.\nStart collecting.',
            textAlign: TextAlign.center,
            style: TextStyle(fontFamily: 'Syne', fontSize: isWide ? 56 : 34,
                fontWeight: FontWeight.w800, color: Colors.white,
                letterSpacing: -1.5, height: 1.1)),
        const SizedBox(height: 18),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 500),
          child: Text(
            'ChaseIt automates invoice follow-ups via Email, SMS, and WhatsApp using AI — so you get paid faster without the awkward conversations.',
            textAlign: TextAlign.center,
            style: TextStyle(fontFamily: 'Syne', fontSize: isWide ? 16 : 14,
                color: Colors.white.withOpacity(0.5), height: 1.7),
          ),
        ),
        const SizedBox(height: 32),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 340),
          child: _HoverBtn(
            label: 'Start free — no card needed',
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const RegisterScreen())),
            bg: AppColors.accent, hoverBg: const Color(0xFFC0390D),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            fontSize: 14,
            fullWidth: true,
            trailing: const Icon(Icons.arrow_forward, size: 15, color: Colors.white),
          ),
        ),
        const SizedBox(height: 16),
        Text('Free forever · No credit card · Cancel anytime',
            style: TextStyle(fontFamily: 'Syne', fontSize: 12, color: Colors.white.withOpacity(0.3))),
        const SizedBox(height: 52),
        _appPreview(),
      ]),
    );
  }

  Widget _appPreview() {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 360),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF1C1815),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withOpacity(0.09)),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.5),
              blurRadius: 40, offset: const Offset(0, 20))],
        ),
        child: Column(children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.04),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Row(children: [
              Container(width: 7, height: 7,
                  decoration: const BoxDecoration(color: AppColors.accent, shape: BoxShape.circle)),
              const SizedBox(width: 7),
              Text('Dashboard', style: TextStyle(fontFamily: 'Syne', fontSize: 12,
                  fontWeight: FontWeight.w700, color: Colors.white.withOpacity(0.8))),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                decoration: BoxDecoration(color: AppColors.accent, borderRadius: BorderRadius.circular(20)),
                child: const Text('Run Chasers (3)', style: TextStyle(fontFamily: 'Syne',
                    fontSize: 9, fontWeight: FontWeight.w700, color: Colors.white)),
              ),
            ]),
          ),
          Padding(padding: const EdgeInsets.all(12), child: Row(children: [
            _previewStat('Outstanding', '\$12,400', AppColors.accent),
            const SizedBox(width: 8),
            _previewStat('Collected', '\$8,200', AppColors.green),
          ])),
          Padding(padding: const EdgeInsets.fromLTRB(12, 0, 12, 14), child: Column(children: [
            _previewInvoice('Acme Corp', '\$3,500', 'Overdue 14d', AppColors.accent),
            const SizedBox(height: 7),
            _previewInvoice('Blue Sky Agency', '\$1,200', 'Pending', AppColors.yellow),
            const SizedBox(height: 7),
            _previewInvoice('TechStart Inc', '\$8,000', 'Fully Paid', AppColors.green),
          ])),
        ]),
      ),
    );
  }

  Widget _previewStat(String label, String value, Color color) => Expanded(
    child: Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: Colors.white.withOpacity(0.05), borderRadius: BorderRadius.circular(10)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: TextStyle(fontFamily: 'Syne', fontSize: 9, color: Colors.white.withOpacity(0.4))),
        const SizedBox(height: 4),
        Text(value, style: TextStyle(fontFamily: 'Syne', fontSize: 16, fontWeight: FontWeight.w800, color: color)),
      ]),
    ),
  );

  Widget _previewInvoice(String client, String amount, String status, Color color) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
    decoration: BoxDecoration(color: Colors.white.withOpacity(0.04), borderRadius: BorderRadius.circular(10)),
    child: Row(children: [
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(client, style: const TextStyle(fontFamily: 'Syne', fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white)),
        Text(amount, style: const TextStyle(fontFamily: 'Syne', fontSize: 14, fontWeight: FontWeight.w800, color: Colors.white)),
      ])),
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(color: color.withOpacity(0.15), borderRadius: BorderRadius.circular(20)),
        child: Text(status, style: TextStyle(fontFamily: 'Syne', fontSize: 9, fontWeight: FontWeight.w700, color: color)),
      ),
    ]),
  );

  // ── STATS ───────────────────────────────────────────────
  Widget _statsBar() {
    final items = [
      {'v': '2,400+', 'l': 'Happy users'},
      {'v': '\$2.4M+', 'l': 'Collected'},
      {'v': '94%', 'l': 'Recovery rate'},
      {'v': '< 48h', 'l': 'Avg payment'},
    ];
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 24),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.03),
        border: Border.symmetric(horizontal: BorderSide(color: Colors.white.withOpacity(0.07))),
      ),
      child: Wrap(alignment: WrapAlignment.center, spacing: 40, runSpacing: 16,
        children: items.map((s) => Column(mainAxisSize: MainAxisSize.min, children: [
          Text(s['v']!, style: const TextStyle(fontFamily: 'Syne', fontSize: 24,
              fontWeight: FontWeight.w800, color: Colors.white, letterSpacing: -0.8)),
          const SizedBox(height: 3),
          Text(s['l']!, style: TextStyle(fontFamily: 'Syne', fontSize: 12,
              color: Colors.white.withOpacity(0.4))),
        ])).toList()),
    );
  }

  // ── FEATURES ────────────────────────────────────────────
  Widget _features(bool isWide) {
    final items = [
      [Icons.auto_awesome, 'AI-powered messages', 'Claude AI writes personalized follow-ups that sound human. Tone escalates automatically.'],
      [Icons.send_outlined, 'Email, SMS & WhatsApp', 'Reach clients on every channel. One-click bulk sending across all overdue invoices.'],
      [Icons.payments_outlined, 'Partial payments', 'Track deposits and installments. See exactly how much is still owed on every invoice.'],
      [Icons.schedule_outlined, 'Chase sequences', 'Gentle, Firm, or Urgent — automated follow-ups sent at exactly the right time.'],
      [Icons.people_outline, 'Client management', 'Full client directory with invoice history, payment totals, and outstanding balances.'],
      [Icons.phone_iphone_outlined, 'Works everywhere', 'iOS, Android, and Web from one codebase. Your data syncs across all devices.'],
    ];
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 60, horizontal: 24),
      child: Column(children: [
        _eyebrow('FEATURES'),
        const SizedBox(height: 12),
        Text('Everything you need\nto get paid on time',
            textAlign: TextAlign.center,
            style: TextStyle(fontFamily: 'Syne', fontSize: isWide ? 32 : 26,
                fontWeight: FontWeight.w800, color: Colors.white, letterSpacing: -1, height: 1.15)),
        const SizedBox(height: 40),
        Wrap(spacing: 12, runSpacing: 12, alignment: WrapAlignment.center,
          children: items.map((f) => ConstrainedBox(
            constraints: BoxConstraints(maxWidth: isWide ? 290 : double.infinity, minWidth: 260),
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.04),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white.withOpacity(0.08)),
              ),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Container(width: 42, height: 42,
                  decoration: BoxDecoration(color: AppColors.accent.withOpacity(0.12), borderRadius: BorderRadius.circular(11)),
                  child: Icon(f[0] as IconData, size: 20, color: AppColors.accent)),
                const SizedBox(height: 14),
                Text(f[1] as String, style: const TextStyle(fontFamily: 'Syne', fontSize: 14, fontWeight: FontWeight.w700, color: Colors.white)),
                const SizedBox(height: 6),
                Text(f[2] as String, style: TextStyle(fontFamily: 'Syne', fontSize: 12, color: Colors.white.withOpacity(0.45), height: 1.65)),
              ]),
            ),
          )).toList()),
      ]),
    );
  }

  // ── HOW IT WORKS ────────────────────────────────────────
  Widget _howItWorks(bool isWide) {
    final steps = [
      ['01', 'Create an invoice', 'Add your client, amount, and due date. Choose Gentle, Firm, or Urgent.'],
      ['02', 'AI writes the message', 'Hit Chase — AI instantly generates a personalized follow-up.'],
      ['03', 'Send on any channel', 'Email, SMS, or WhatsApp. Or bulk-chase all overdue invoices at once.'],
      ['04', 'Get paid faster', 'Track payments, record partials, watch your collections grow.'],
    ];
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 60, horizontal: 24),
      decoration: BoxDecoration(color: Colors.white.withOpacity(0.02)),
      child: Column(children: [
        _eyebrow('HOW IT WORKS'),
        const SizedBox(height: 12),
        Text('From invoice to payment\nin 4 steps',
            textAlign: TextAlign.center,
            style: TextStyle(fontFamily: 'Syne', fontSize: isWide ? 32 : 26,
                fontWeight: FontWeight.w800, color: Colors.white, letterSpacing: -1, height: 1.15)),
        const SizedBox(height: 40),
        Wrap(spacing: 12, runSpacing: 12, alignment: WrapAlignment.center,
          children: steps.map((s) => ConstrainedBox(
            constraints: BoxConstraints(maxWidth: isWide ? 260 : double.infinity, minWidth: 240),
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white.withOpacity(0.08))),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(s[0], style: TextStyle(fontFamily: 'Syne', fontSize: 38, fontWeight: FontWeight.w800,
                    color: Colors.white.withOpacity(0.07), letterSpacing: -2)),
                const SizedBox(height: 8),
                Text(s[1], style: const TextStyle(fontFamily: 'Syne', fontSize: 15, fontWeight: FontWeight.w700, color: Colors.white)),
                const SizedBox(height: 7),
                Text(s[2], style: TextStyle(fontFamily: 'Syne', fontSize: 12, color: Colors.white.withOpacity(0.45), height: 1.65)),
              ]),
            ),
          )).toList()),
      ]),
    );
  }

  // ── PRICING ─────────────────────────────────────────────
  Widget _pricing(BuildContext context, bool isWide) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 60, horizontal: 24),
      child: Column(children: [
        _eyebrow('PRICING'),
        const SizedBox(height: 12),
        Text('Simple, honest pricing', textAlign: TextAlign.center,
            style: TextStyle(fontFamily: 'Syne', fontSize: isWide ? 32 : 26,
                fontWeight: FontWeight.w800, color: Colors.white, letterSpacing: -1)),
        const SizedBox(height: 8),
        Text("Start free. Upgrade when you're ready.",
            style: TextStyle(fontFamily: 'Syne', fontSize: 14, color: Colors.white.withOpacity(0.4))),
        const SizedBox(height: 40),
        Wrap(spacing: 12, runSpacing: 12, alignment: WrapAlignment.center, children: [
          _priceCard(context, 'Free', '\$0', 'forever', false,
              ['10 invoices / month', 'Email follow-ups', 'Client management', 'Dashboard analytics'],
              'Get started free'),
          _priceCard(context, 'Creator', '\$29', '/month', true,
              ['Unlimited invoices', 'Email + SMS + WhatsApp', 'AI message generation', 'Bulk chase runner', 'Custom sequences'],
              'Start Creator plan'),
          _priceCard(context, 'Agency', '\$79', '/month', false,
              ['Everything in Creator', '5 team seats', '10 client profiles', 'White-label reports', 'Dedicated support'],
              'Start Agency plan'),
        ]),
      ]),
    );
  }

  Widget _priceCard(BuildContext context, String name, String price, String period,
      bool featured, List<String> features, String cta) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 270, minWidth: 250),
      child: Container(
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          color: featured ? AppColors.accent : Colors.white.withOpacity(0.04),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: featured ? AppColors.accent : Colors.white.withOpacity(0.09), width: featured ? 2 : 1),
          boxShadow: featured ? [BoxShadow(color: AppColors.accent.withOpacity(0.28), blurRadius: 28, offset: const Offset(0, 10))] : null,
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          if (featured) Container(
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
            margin: const EdgeInsets.only(bottom: 10),
            decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(20)),
            child: const Text('MOST POPULAR', style: TextStyle(fontFamily: 'Syne', fontSize: 8, fontWeight: FontWeight.w700, color: Colors.white, letterSpacing: 1.0)),
          ),
          Text(name, style: TextStyle(fontFamily: 'Syne', fontSize: 13, fontWeight: FontWeight.w600, color: Colors.white.withOpacity(featured ? 0.7 : 0.45))),
          const SizedBox(height: 6),
          Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Text(price, style: const TextStyle(fontFamily: 'Syne', fontSize: 34, fontWeight: FontWeight.w800, color: Colors.white, letterSpacing: -1)),
            const SizedBox(width: 3),
            Padding(padding: const EdgeInsets.only(bottom: 5),
                child: Text(period, style: TextStyle(fontFamily: 'Syne', fontSize: 12, color: Colors.white.withOpacity(0.4)))),
          ]),
          const SizedBox(height: 16),
          Divider(color: Colors.white.withOpacity(featured ? 0.2 : 0.07)),
          const SizedBox(height: 14),
          ...features.map((f) => Padding(
            padding: const EdgeInsets.only(bottom: 9),
            child: Row(children: [
              Icon(Icons.check_circle_outline, size: 14, color: featured ? Colors.white : AppColors.green),
              const SizedBox(width: 8),
              Expanded(child: Text(f, style: TextStyle(fontFamily: 'Syne', fontSize: 12,
                  color: Colors.white.withOpacity(featured ? 0.85 : 0.5)))),
            ]),
          )),
          const SizedBox(height: 18),
          _HoverBtn(
            label: cta,
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const RegisterScreen())),
            bg: featured ? Colors.white : Colors.white.withOpacity(0.08),
            hoverBg: featured ? const Color(0xFFF0EDE8) : Colors.white.withOpacity(0.15),
            fgColor: featured ? AppColors.accent : Colors.white,
            fullWidth: true,
          ),
        ]),
      ),
    );
  }

  // ── CTA ─────────────────────────────────────────────────
  Widget _cta(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 60, horizontal: 24),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [AppColors.accent.withOpacity(0.12), Colors.transparent],
            begin: Alignment.topCenter, end: Alignment.bottomCenter),
        border: Border.symmetric(horizontal: BorderSide(color: AppColors.accent.withOpacity(0.18))),
      ),
      child: Column(children: [
        const Text('Ready to get paid\nwithout the chase?',
            textAlign: TextAlign.center,
            style: TextStyle(fontFamily: 'Syne', fontSize: 32, fontWeight: FontWeight.w800,
                color: Colors.white, letterSpacing: -1, height: 1.15)),
        const SizedBox(height: 14),
        Text('Join thousands of freelancers and agencies who collect faster with ChaseIt.',
            textAlign: TextAlign.center,
            style: TextStyle(fontFamily: 'Syne', fontSize: 14, color: Colors.white.withOpacity(0.4))),
        const SizedBox(height: 28),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 320),
          child: _HoverBtn(
            label: 'Create your free account →',
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const RegisterScreen())),
            bg: AppColors.accent, hoverBg: const Color(0xFFC0390D),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            fontSize: 14,
            fullWidth: true,
            shadow: true,
          ),
        ),
        const SizedBox(height: 12),
        Text('Free forever · No credit card · Cancel anytime',
            style: TextStyle(fontFamily: 'Syne', fontSize: 11, color: Colors.white.withOpacity(0.25))),
      ]),
    );
  }

  // ── FOOTER ──────────────────────────────────────────────
  Widget _footer() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 24),
      decoration: BoxDecoration(border: Border(top: BorderSide(color: Colors.white.withOpacity(0.07)))),
      child: Column(children: [
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Container(width: 22, height: 22,
              decoration: BoxDecoration(color: AppColors.accent, borderRadius: BorderRadius.circular(6)),
              child: const Icon(Icons.timer_outlined, size: 12, color: Colors.white)),
          const SizedBox(width: 7),
          const Text('ChaseIt', style: TextStyle(fontFamily: 'Syne', fontSize: 14, fontWeight: FontWeight.w800, color: Colors.white)),
        ]),
        const SizedBox(height: 10),
        Text('© 2026 ChaseIt · Built with Claude AI · Houston, TX',
            style: TextStyle(fontFamily: 'Syne', fontSize: 11, color: Colors.white.withOpacity(0.22))),
      ]),
    );
  }

  Widget _eyebrow(String text) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
    decoration: BoxDecoration(border: Border.all(color: Colors.white.withOpacity(0.1)),
        borderRadius: BorderRadius.circular(20)),
    child: Text(text, style: TextStyle(fontFamily: 'Syne', fontSize: 10, fontWeight: FontWeight.w700,
        color: Colors.white.withOpacity(0.35), letterSpacing: 1.5)),
  );
}

// ── HOVER BUTTON WIDGET ──────────────────────────────────
class _HoverBtn extends StatefulWidget {
  final String label;
  final VoidCallback onTap;
  final Color bg;
  final Color hoverBg;
  final Color fgColor;
  final EdgeInsets? padding;
  final double fontSize;
  final bool fullWidth;
  final bool shadow;
  final Widget? trailing;

  const _HoverBtn({
    required this.label,
    required this.onTap,
    required this.bg,
    required this.hoverBg,
    this.fgColor = Colors.white,
    this.padding,
    this.fontSize = 13,
    this.fullWidth = false,
    this.shadow = false,
    this.trailing,
  });

  @override
  State<_HoverBtn> createState() => _HoverBtnState();
}

class _HoverBtnState extends State<_HoverBtn> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final btn = MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          width: widget.fullWidth ? double.infinity : null,
          padding: widget.padding ?? const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
          decoration: BoxDecoration(
            color: _hovered ? widget.hoverBg : widget.bg,
            borderRadius: BorderRadius.circular(10),
            boxShadow: widget.shadow && _hovered ? [BoxShadow(
                color: widget.bg.withOpacity(0.4), blurRadius: 20, offset: const Offset(0, 8))] : null,
          ),
          child: Row(
            mainAxisSize: widget.fullWidth ? MainAxisSize.max : MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Flexible(
                child: Text(widget.label,
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                    style: TextStyle(fontFamily: 'Syne', fontSize: widget.fontSize,
                        fontWeight: FontWeight.w700, color: widget.fgColor)),
              ),
              if (widget.trailing != null) ...[const SizedBox(width: 8), widget.trailing!],
            ],
          ),
        ),
      ),
    );
    return btn;
  }
}

// ── HOVER TEXT BUTTON ────────────────────────────────────
class _HoverTextBtn extends StatefulWidget {
  final String label;
  final VoidCallback onTap;
  const _HoverTextBtn({required this.label, required this.onTap});
  @override
  State<_HoverTextBtn> createState() => _HoverTextBtnState();
}

class _HoverTextBtnState extends State<_HoverTextBtn> {
  bool _hovered = false;
  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            border: Border.all(color: _hovered ? Colors.white.withOpacity(0.3) : Colors.white.withOpacity(0.12)),
            borderRadius: BorderRadius.circular(8),
            color: _hovered ? Colors.white.withOpacity(0.05) : Colors.transparent,
          ),
          child: Text(widget.label, style: TextStyle(fontFamily: 'Syne', fontSize: 13,
              color: _hovered ? Colors.white : Colors.white.withOpacity(0.6))),
        ),
      ),
    );
  }
}