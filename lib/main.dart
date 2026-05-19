import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import 'models/client.dart';
import 'models/user_profile.dart';
import 'services/app_state.dart';
import 'services/auth_service.dart';
import 'theme/app_theme.dart';
import 'screens/dashboard_screen.dart';
import 'screens/invoices_screen.dart';
import 'screens/clients_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/invoice_form_screen.dart';
import 'screens/chase_screen.dart';
import 'screens/login_screen.dart';
import 'screens/register_screen.dart';
import 'screens/account_screen.dart';
import 'screens/landing_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final registered = await AuthService.isRegistered();
  final loggedIn   = await AuthService.isLoggedIn();

  String route = '/landing';
  if (registered && loggedIn)  route = '/home';
  if (registered && !loggedIn) route = '/login';

  runApp(
    ChangeNotifierProvider(
      create: (_) => AppState()..loadData(),
      child: ChaseItApp(initialRoute: route),
    ),
  );
}

class ChaseItApp extends StatelessWidget {
  final String initialRoute;
  const ChaseItApp({super.key, this.initialRoute = '/home'});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ChaseIt',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.theme,
      initialRoute: initialRoute,
      routes: {
        '/landing':  (_) => const LandingScreen(),
        '/home':     (_) => const MainShell(),
        '/login':    (_) => const LoginScreen(),
        '/register': (_) => const RegisterScreen(),
      },
    );
  }
}

// ── MAIN SHELL ───────────────────────────────────────────
class MainShell extends StatefulWidget {
  const MainShell({super.key});
  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _tab = 0;

  final _labels = ['Dashboard', 'Invoices', 'Clients', 'Settings'];
  final _icons  = [
    Icons.grid_view_rounded,
    Icons.receipt_long_rounded,
    Icons.people_rounded,
    Icons.settings_rounded,
  ];

  Widget _screen() {
    switch (_tab) {
      case 0: return const DashboardScreen();
      case 1: return const InvoicesScreen();
      case 2: return const ClientsScreen();
      case 3: return const SettingsScreen();
      default: return const DashboardScreen();
    }
  }

  // ── ADD CLIENT DIALOG ───────────────────────────────────
  void _showAddClientDialog(BuildContext context) {
    final bizCtrl   = TextEditingController();
    final nameCtrl  = TextEditingController();
    final emailCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();

    showDialog(
      context: context,
      barrierDismissible: true,
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
                const Text('Add Client', style: TextStyle(fontFamily: 'Syne',
                    fontSize: 17, fontWeight: FontWeight.w800, color: AppColors.ink)),
                GestureDetector(
                  onTap: () => Navigator.pop(ctx),
                  child: Container(width: 28, height: 28,
                      decoration: BoxDecoration(color: AppColors.surface2, borderRadius: BorderRadius.circular(7)),
                      child: const Icon(Icons.close, size: 15, color: AppColors.muted)),
                ),
              ]),
              const SizedBox(height: 20),
              _dialogField('Business Name', 'Acme Corp', bizCtrl),
              const SizedBox(height: 12),
              _dialogField('Contact Name', 'John Smith', nameCtrl),
              const SizedBox(height: 12),
              _dialogField('Email', 'john@acme.com', emailCtrl, type: TextInputType.emailAddress),
              const SizedBox(height: 12),
              _dialogField('Phone', '+1 555 000 0000', phoneCtrl, type: TextInputType.phone),
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
                    final name  = nameCtrl.text.trim();
                    final email = emailCtrl.text.trim();
                    final phone = phoneCtrl.text.trim();
                    if (biz.isEmpty || email.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                          content: Text('Business name and email are required'),
                          backgroundColor: AppColors.accent));
                      return;
                    }
                    Navigator.pop(ctx);
                    await context.read<AppState>().createClient(Client(
                      id: const Uuid().v4(), biz: biz, name: name, email: email, phone: phone,
                    ));
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                          content: Text('$biz added!'), backgroundColor: AppColors.green));
                    }
                  },
                  child: const Text('Save Client'),
                )),
              ]),
            ],
          ),
        ),
      ),
    );
  }

  Widget _dialogField(String label, String hint, TextEditingController ctrl, {TextInputType? type}) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label.toUpperCase(), style: const TextStyle(fontFamily: 'Syne',
          fontSize: 9, color: AppColors.muted, letterSpacing: 1.0)),
      const SizedBox(height: 5),
      TextField(
        controller: ctrl, keyboardType: type,
        style: const TextStyle(fontFamily: 'Syne', fontSize: 13, color: AppColors.ink),
        decoration: InputDecoration(hintText: hint),
      ),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final state        = context.watch<AppState>();
    final overdueCount = state.overdueInvoices.length;
    final isWide       = MediaQuery.of(context).size.width >= 700;

    if (isWide) {
      return _wideLayout(context, state, overdueCount);
    }
    return _mobileLayout(context, state, overdueCount);
  }

  // ── WIDE LAYOUT ─────────────────────────────────────────
  Widget _wideLayout(BuildContext context, AppState state, int overdueCount) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: Row(children: [
        // Sidebar
        Container(
          width: 200,
          color: AppColors.ink,
          child: Column(children: [
            // Logo
            Container(
              padding: const EdgeInsets.fromLTRB(18, 28, 18, 18),
              decoration: const BoxDecoration(
                  border: Border(bottom: BorderSide(color: Color(0x12FFFFFF)))),
              child: Row(children: [
                Container(width: 30, height: 30,
                    decoration: BoxDecoration(color: AppColors.accent, borderRadius: BorderRadius.circular(8)),
                    child: const Icon(Icons.timer_outlined, size: 16, color: Colors.white)),
                const SizedBox(width: 10),
                const Text('ChaseIt', style: TextStyle(fontFamily: 'Syne', fontSize: 17,
                    fontWeight: FontWeight.w800, color: Colors.white, letterSpacing: -0.5)),
              ]),
            ),
            // Nav
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 14),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Padding(padding: EdgeInsets.only(left: 8, bottom: 6, top: 4),
                      child: Text('MAIN', style: TextStyle(fontFamily: 'Syne', fontSize: 9,
                          color: Color(0x33FFFFFF), letterSpacing: 1.5))),
                  ...[0, 1, 2].map(_sidebarItem),
                  const Padding(padding: EdgeInsets.only(left: 8, bottom: 6, top: 14),
                      child: Text('ACCOUNT', style: TextStyle(fontFamily: 'Syne', fontSize: 9,
                          color: Color(0x33FFFFFF), letterSpacing: 1.5))),
                  _sidebarItem(3),
                ]),
              ),
            ),
            // Pro card
            Padding(
              padding: const EdgeInsets.all(10),
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [AppColors.accent, Color(0xFFC0390D)],
                      begin: Alignment.topLeft, end: Alignment.bottomRight),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Text('Upgrade to Pro', style: TextStyle(fontFamily: 'Syne',
                      fontSize: 12, fontWeight: FontWeight.w700, color: Colors.white)),
                  const SizedBox(height: 3),
                  const Text('Unlimited + SMS + WhatsApp live',
                      style: TextStyle(fontFamily: 'Syne', fontSize: 10, color: Color(0xBFFFFFFF))),
                  const SizedBox(height: 10),
                  SizedBox(width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.white,
                          foregroundColor: AppColors.accent,
                          padding: const EdgeInsets.symmetric(vertical: 6),
                          textStyle: const TextStyle(fontFamily: 'Syne', fontSize: 11, fontWeight: FontWeight.w700)),
                      onPressed: () {},
                      child: const Text('Go Pro — \$49/mo'),
                    ),
                  ),
                ]),
              ),
            ),
          ]),
        ),
        // Content
        Expanded(child: Column(children: [
          // Topbar
          Container(
            height: 58,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            decoration: const BoxDecoration(
              color: AppColors.surface,
              border: Border(bottom: BorderSide(color: AppColors.border)),
            ),
            child: Row(children: [
              Text(_labels[_tab], style: const TextStyle(fontFamily: 'Syne',
                  fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.ink)),
              const Spacer(),
              if (overdueCount > 0) ...[
                _TopbarBtn(
                  label: 'Run Chasers ($overdueCount)',
                  icon: Icons.auto_awesome,
                  color: AppColors.yellow,
                  bg: AppColors.yellowBg,
                  onTap: () => Navigator.push(context, MaterialPageRoute(
                      builder: (_) => BulkChaseScreen(invoices: state.overdueInvoices))),
                ),
                const SizedBox(width: 8),
              ],
              _TopbarBtn(
                label: 'Add Client',
                icon: Icons.person_add_outlined,
                color: AppColors.muted,
                bg: AppColors.surface2,
                onTap: () => _showAddClientDialog(context),
                outlined: true,
              ),
              const SizedBox(width: 8),
              _TopbarBtn(
                label: 'New Invoice',
                icon: Icons.add,
                color: Colors.white,
                bg: AppColors.accent,
                onTap: () => Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const InvoiceFormScreen())),
              ),
            ]),
          ),
          Expanded(child: _screen()),
        ])),
      ]),
    );
  }

  // ── MOBILE LAYOUT ───────────────────────────────────────
  Widget _mobileLayout(BuildContext context, AppState state, int overdueCount) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        titleSpacing: 16,
        title: Row(children: [
          Container(width: 26, height: 26,
              decoration: BoxDecoration(color: AppColors.accent, borderRadius: BorderRadius.circular(7)),
              child: const Icon(Icons.timer_outlined, size: 14, color: Colors.white)),
          const SizedBox(width: 8),
          const Text('ChaseIt', style: TextStyle(fontFamily: 'Syne', fontSize: 17,
              fontWeight: FontWeight.w800, color: AppColors.ink, letterSpacing: -0.5)),
        ]),
        actions: [
          if (overdueCount > 0)
            IconButton(
              onPressed: () => Navigator.push(context, MaterialPageRoute(
                  builder: (_) => BulkChaseScreen(invoices: state.overdueInvoices))),
              tooltip: 'Run Chasers',
              icon: Stack(clipBehavior: Clip.none, children: [
                const Icon(Icons.auto_awesome, color: AppColors.yellow, size: 22),
                Positioned(right: -4, top: -4,
                  child: Container(width: 15, height: 15,
                      decoration: const BoxDecoration(color: AppColors.accent, shape: BoxShape.circle),
                      alignment: Alignment.center,
                      child: Text('$overdueCount', style: const TextStyle(
                          fontSize: 8, fontWeight: FontWeight.w800, color: Colors.white))),
                ),
              ]),
            ),
          IconButton(
            onPressed: () => _showAddClientDialog(context),
            tooltip: 'Add Client',
            icon: const Icon(Icons.person_add_outlined, color: AppColors.muted, size: 22),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 10),
            child: GestureDetector(
              onTap: () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const InvoiceFormScreen())),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(color: AppColors.accent, borderRadius: BorderRadius.circular(8)),
                child: const Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(Icons.add, size: 14, color: Colors.white),
                  SizedBox(width: 4),
                  Text('Invoice', style: TextStyle(fontFamily: 'Syne',
                      fontSize: 12, fontWeight: FontWeight.w700, color: Colors.white)),
                ]),
              ),
            ),
          ),
        ],
      ),
      body: _screen(),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: AppColors.surface,
          border: Border(top: BorderSide(color: AppColors.border)),
        ),
        child: SafeArea(
          child: SizedBox(
            height: 56,
            child: Row(
              children: List.generate(4, (i) {
                final active    = _tab == i;
                final showBadge = i == 1 && state.overdueInvoices.isNotEmpty;
                return Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _tab = i),
                    behavior: HitTestBehavior.opaque,
                    child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                      Stack(clipBehavior: Clip.none, children: [
                        Icon(_icons[i], size: 22,
                            color: active ? AppColors.accent : AppColors.muted2),
                        if (showBadge)
                          Positioned(right: -5, top: -3,
                            child: Container(width: 14, height: 14,
                                decoration: const BoxDecoration(
                                    color: AppColors.accent, shape: BoxShape.circle),
                                alignment: Alignment.center,
                                child: Text('${state.overdueInvoices.length}',
                                    style: const TextStyle(fontSize: 8,
                                        fontWeight: FontWeight.w700, color: Colors.white))),
                          ),
                      ]),
                      const SizedBox(height: 3),
                      Text(_labels[i], style: TextStyle(fontFamily: 'Syne', fontSize: 10,
                          fontWeight: FontWeight.w500,
                          color: active ? AppColors.accent : AppColors.muted2)),
                    ]),
                  ),
                );
              }),
            ),
          ),
        ),
      ),
    );
  }

  // ── SIDEBAR ITEM ────────────────────────────────────────
  Widget _sidebarItem(int i) {
    final active = _tab == i;
    return _SidebarItem(
      icon: _icons[i],
      label: _labels[i],
      active: active,
      onTap: () => setState(() => _tab = i),
    );
  }
}

// ── SIDEBAR ITEM WIDGET ──────────────────────────────────
class _SidebarItem extends StatefulWidget {
  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback onTap;
  const _SidebarItem({required this.icon, required this.label,
      required this.active, required this.onTap});
  @override
  State<_SidebarItem> createState() => _SidebarItemState();
}

class _SidebarItemState extends State<_SidebarItem> {
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
          margin: const EdgeInsets.only(bottom: 2),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
          decoration: BoxDecoration(
            color: widget.active
                ? Colors.white.withOpacity(0.12)
                : _hovered ? Colors.white.withOpacity(0.06) : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(children: [
            Icon(widget.icon, size: 15,
                color: widget.active ? Colors.white : Colors.white.withOpacity(0.45)),
            const SizedBox(width: 9),
            Text(widget.label, style: TextStyle(fontFamily: 'Syne', fontSize: 13,
                fontWeight: FontWeight.w500,
                color: widget.active ? Colors.white : Colors.white.withOpacity(0.45))),
          ]),
        ),
      ),
    );
  }
}

// ── TOPBAR BUTTON WIDGET ─────────────────────────────────
class _TopbarBtn extends StatefulWidget {
  final String label;
  final IconData icon;
  final Color color;
  final Color bg;
  final VoidCallback onTap;
  final bool outlined;
  const _TopbarBtn({required this.label, required this.icon, required this.color,
      required this.bg, required this.onTap, this.outlined = false});
  @override
  State<_TopbarBtn> createState() => _TopbarBtnState();
}

class _TopbarBtnState extends State<_TopbarBtn> {
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
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: widget.outlined
                ? (_hovered ? AppColors.surface2 : Colors.transparent)
                : (_hovered ? widget.bg.withOpacity(0.75) : widget.bg),
            borderRadius: BorderRadius.circular(8),
            border: widget.outlined ? Border.all(color: AppColors.border2) : null,
          ),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Icon(widget.icon, size: 13, color: widget.color),
            const SizedBox(width: 5),
            Text(widget.label, style: TextStyle(fontFamily: 'Syne', fontSize: 12,
                fontWeight: FontWeight.w600, color: widget.color)),
          ]),
        ),
      ),
    );
  }
}