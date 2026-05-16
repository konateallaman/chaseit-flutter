import 'package:flutter/material.dart';
import '../models/user_profile.dart';
import '../services/auth_service.dart';
import '../theme/app_theme.dart';
import 'account_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});
  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  UserProfile? _profile;
  bool _notifyPaid = true;
  bool _dailySummary = false;
  bool _autoSend = false;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final p = await AuthService.getProfile();
    if (mounted) setState(() => _profile = p);
  }

  void _openAccount() async {
    if (_profile == null) return;
    final updated = await Navigator.push<UserProfile>(
      context,
      MaterialPageRoute(builder: (_) => AccountScreen(profile: _profile!)),
    );
    if (updated != null) setState(() => _profile = updated);
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

        // ── PROFILE CARD ──
        if (_profile != null)
          GestureDetector(
            onTap: _openAccount,
            child: Container(
              padding: const EdgeInsets.all(18),
              margin: const EdgeInsets.only(bottom: 14),
              decoration: BoxDecoration(
                color: AppColors.ink,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(children: [
                // Avatar
                Container(
                  width: 48, height: 48,
                  decoration: BoxDecoration(
                    color: AppColors.accent,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    _profile!.businessName.isNotEmpty
                        ? _profile!.businessName[0].toUpperCase()
                        : '?',
                    style: const TextStyle(fontFamily: 'Syne', fontSize: 22,
                        fontWeight: FontWeight.w800, color: Colors.white),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(_profile!.businessName,
                      style: const TextStyle(fontFamily: 'Syne', fontSize: 15,
                          fontWeight: FontWeight.w700, color: Colors.white)),
                  Text(_profile!.ownerName,
                      style: const TextStyle(fontFamily: 'Syne', fontSize: 12,
                          color: Color(0x80FFFFFF))),
                  Text(_profile!.email,
                      style: const TextStyle(fontFamily: 'Syne', fontSize: 11,
                          color: Color(0x60FFFFFF))),
                ])),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: AppColors.accent,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    _profile!.plan[0].toUpperCase() + _profile!.plan.substring(1),
                    style: const TextStyle(fontFamily: 'Syne', fontSize: 10,
                        fontWeight: FontWeight.w700, color: Colors.white),
                  ),
                ),
              ]),
            ),
          ),

        // Manage account button
        GestureDetector(
          onTap: _openAccount,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            margin: const EdgeInsets.only(bottom: 14),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
            ),
            child: const Row(children: [
              Icon(Icons.manage_accounts_outlined, size: 18, color: AppColors.accent),
              SizedBox(width: 10),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Manage Account', style: TextStyle(fontFamily: 'Syne', fontSize: 14,
                    fontWeight: FontWeight.w700, color: AppColors.ink)),
                Text('Edit profile, change password, delete account',
                    style: TextStyle(fontFamily: 'Syne', fontSize: 11, color: AppColors.muted)),
              ])),
              Icon(Icons.chevron_right, color: AppColors.muted2),
            ]),
          ),
        ),

        // ── INTEGRATIONS ──
        _sectionCard('Integrations', [
          _integrationRow('SendGrid', 'Email delivery'),
          _integrationRow('Twilio SMS', 'SMS follow-ups'),
          _integrationRow('WhatsApp Business', 'WhatsApp messages'),
          _integrationRow('Stripe', 'Payment links in invoices'),
        ]),
        const SizedBox(height: 14),

        // ── NOTIFICATIONS ──
        _sectionCard('Notifications', [
          _toggleRow('Email me when invoice is paid', 'Get notified on collection',
              _notifyPaid, (v) => setState(() => _notifyPaid = v)),
          _toggleRow('Daily overdue summary', 'Morning digest of unpaid invoices',
              _dailySummary, (v) => setState(() => _dailySummary = v)),
          _toggleRow('Auto-send chase sequences', 'Send without manual approval',
              _autoSend, (v) => setState(() => _autoSend = v)),
        ]),
        const SizedBox(height: 14),

        // ── PRO CARD ──
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
                colors: [AppColors.accent, Color(0xFFC0390D)],
                begin: Alignment.topLeft, end: Alignment.bottomRight),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Upgrade to Pro',
                style: TextStyle(fontFamily: 'Syne', fontSize: 16,
                    fontWeight: FontWeight.w800, color: Colors.white)),
            const SizedBox(height: 4),
            const Text('Unlimited invoices + live SMS + WhatsApp sending',
                style: TextStyle(fontFamily: 'Syne', fontSize: 12, color: Color(0xBFFFFFFF))),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white, foregroundColor: AppColors.accent),
                onPressed: () {},
                child: const Text('Go Pro — \$49/mo',
                    style: TextStyle(fontFamily: 'Syne', fontWeight: FontWeight.w700)),
              ),
            ),
          ]),
        ),
        const SizedBox(height: 40),
      ]),
    );
  }

  Widget _sectionCard(String title, List<Widget> children) {
    return Container(
      decoration: BoxDecoration(color: AppColors.surface,
          borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.border)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
          child: Text(title,
              style: const TextStyle(fontFamily: 'Syne', fontSize: 13,
                  fontWeight: FontWeight.w700, color: AppColors.ink)),
        ),
        ...children,
      ]),
    );
  }

  Widget _integrationRow(String name, String sub) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
      decoration: const BoxDecoration(border: Border(top: BorderSide(color: AppColors.border))),
      child: Row(children: [
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(name, style: const TextStyle(fontFamily: 'Syne', fontSize: 13,
              fontWeight: FontWeight.w500, color: AppColors.ink)),
          Text(sub, style: const TextStyle(fontFamily: 'Syne', fontSize: 11, color: AppColors.muted)),
        ])),
        GestureDetector(
          onTap: () => ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Coming soon — add API key in Vercel env vars'),
                backgroundColor: AppColors.ink)),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(color: AppColors.blueBg, borderRadius: BorderRadius.circular(20)),
            child: const Text('Configure →',
                style: TextStyle(fontFamily: 'Syne', fontSize: 11,
                    fontWeight: FontWeight.w600, color: AppColors.blue)),
          ),
        ),
      ]),
    );
  }

  Widget _toggleRow(String label, String sub, bool val, ValueChanged<bool> onChanged) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
      decoration: const BoxDecoration(border: Border(top: BorderSide(color: AppColors.border))),
      child: Row(children: [
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label, style: const TextStyle(fontFamily: 'Syne', fontSize: 13,
              fontWeight: FontWeight.w500, color: AppColors.ink)),
          Text(sub, style: const TextStyle(fontFamily: 'Syne', fontSize: 11, color: AppColors.muted)),
        ])),
        Switch(value: val, onChanged: onChanged, activeColor: AppColors.green),
      ]),
    );
  }
}
