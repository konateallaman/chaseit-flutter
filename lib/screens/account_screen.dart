import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../services/image_service.dart';
import '../models/user_profile.dart';
import '../services/auth_service.dart';
import '../theme/app_theme.dart';

class AccountScreen extends StatefulWidget {
  final UserProfile profile;
  const AccountScreen({super.key, required this.profile});
  @override
  State<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> {
  late final TextEditingController _bizCtrl;
  late final TextEditingController _nameCtrl;
  late final TextEditingController _emailCtrl;
  late final TextEditingController _phoneCtrl;
  final _currPassCtrl = TextEditingController();
  final _newPassCtrl = TextEditingController();
  final _confirmPassCtrl = TextEditingController();
  bool _saving = false;
  bool _changingPass = false;
  bool _obscureCurr = true;
  bool _obscureNew = true;
  bool _obscureConfirm = true;
  bool _emailVerified = false;
  bool _verificationSent = false;
  String? _avatarInitials;

  @override
  void initState() {
    super.initState();
    final p = widget.profile;
    _bizCtrl  = TextEditingController(text: p.businessName);
    _nameCtrl = TextEditingController(text: p.ownerName);
    _emailCtrl = TextEditingController(text: p.email);
    _phoneCtrl = TextEditingController(text: p.phone);
    _avatarInitials = _getInitials(p.businessName.isNotEmpty ? p.businessName : p.ownerName);
    // Simulate email verified for existing accounts
    _emailVerified = widget.profile.createdAt.isNotEmpty;
  }

  String _getInitials(String name) {
    final words = name.trim().split(' ');
    return words.take(2).map((w) => w.isNotEmpty ? w[0].toUpperCase() : '').join();
  }

  @override
  void dispose() {
    for (final c in [_bizCtrl, _nameCtrl, _emailCtrl, _phoneCtrl,
                     _currPassCtrl, _newPassCtrl, _confirmPassCtrl]) c.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    setState(() => _saving = true);
    final updated = UserProfile(
      id: widget.profile.id,
      businessName: _bizCtrl.text.trim(),
      ownerName: _nameCtrl.text.trim(),
      email: _emailCtrl.text.trim(),
      phone: _phoneCtrl.text.trim(),
      plan: widget.profile.plan,
      createdAt: widget.profile.createdAt,
    );
    final err = await AuthService.updateProfile(updated);
    setState(() => _saving = false);
    if (!mounted) return;
    if (err != null) {
      _showSnack(err, AppColors.accent);
    } else {
      setState(() => _avatarInitials = _getInitials(updated.businessName.isNotEmpty ? updated.businessName : updated.ownerName));
      _showSnack('Profile updated!', AppColors.green);
      Navigator.pop(context, updated);
    }
  }

  Future<void> _changePassword() async {
    if (_newPassCtrl.text != _confirmPassCtrl.text) {
      _showSnack('New passwords do not match.', AppColors.accent); return;
    }
    setState(() => _changingPass = true);
    final err = await AuthService.changePassword(
      currentPassword: _currPassCtrl.text,
      newPassword: _newPassCtrl.text,
    );
    setState(() => _changingPass = false);
    if (!mounted) return;
    if (err != null) {
      _showSnack(err, AppColors.accent);
    } else {
      _currPassCtrl.clear(); _newPassCtrl.clear(); _confirmPassCtrl.clear();
      _showSnack('Password changed!', AppColors.green);
    }
  }

  void _sendVerification() {
    setState(() => _verificationSent = true);
    _showSnack('Verification email sent to ${_emailCtrl.text}', AppColors.blue);
    // In production: call your backend to send a verification email
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() => _emailVerified = true);
    });
  }

  Future<void> _logout() async {
    final ok = await _confirm('Sign Out', 'Are you sure you want to sign out?', 'Sign Out');
    if (ok != true) return;
    await AuthService.logout();
    if (mounted) Navigator.of(context).pushReplacementNamed('/login');
  }

  Future<void> _deleteAccount() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Account',
            style: TextStyle(fontFamily: 'Syne', fontWeight: FontWeight.w800, color: AppColors.accent)),
        content: const Text(
            'This permanently deletes your account, all invoices, and all client data. This cannot be undone.',
            style: TextStyle(fontFamily: 'Syne', fontSize: 14)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.accent),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete Everything', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (ok != true) return;
    await AuthService.deleteAccount();
    if (mounted) Navigator.of(context).pushReplacementNamed('/register');
  }

  Future<bool?> _confirm(String title, String msg, String action) => showDialog<bool>(
    context: context,
    builder: (_) => AlertDialog(
      title: Text(title, style: const TextStyle(fontFamily: 'Syne', fontWeight: FontWeight.w700)),
      content: Text(msg, style: const TextStyle(fontFamily: 'Syne', fontSize: 14)),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
        TextButton(onPressed: () => Navigator.pop(context, true),
            child: Text(action, style: const TextStyle(color: AppColors.accent, fontWeight: FontWeight.w700))),
      ],
    ),
  );

  void _showSnack(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg, style: const TextStyle(fontFamily: 'Syne')),
            backgroundColor: color));
  }

  bool _uploadingAvatar = false;

  Future<void> _changeAvatar() async {
    // Show picker options
    final choice = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (_) => SafeArea(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const SizedBox(height: 8),
          Container(width: 36, height: 4,
              decoration: BoxDecoration(color: AppColors.border2, borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 16),
          const Text('Choose photo', style: TextStyle(fontFamily: 'Syne', fontSize: 16,
              fontWeight: FontWeight.w700, color: AppColors.ink)),
          const SizedBox(height: 16),
          ListTile(
            leading: const Icon(Icons.camera_alt_outlined, color: AppColors.accent),
            title: const Text('Take a photo', style: TextStyle(fontFamily: 'Syne')),
            onTap: () => Navigator.pop(context, 'camera'),
          ),
          ListTile(
            leading: const Icon(Icons.photo_library_outlined, color: AppColors.accent),
            title: const Text('Choose from gallery', style: TextStyle(fontFamily: 'Syne')),
            onTap: () => Navigator.pop(context, 'gallery'),
          ),
          const SizedBox(height: 8),
        ]),
      ),
    );
    if (choice == null) return;

    final picker = ImagePicker();
    final XFile? picked = await picker.pickImage(
      source: choice == 'camera' ? ImageSource.camera : ImageSource.gallery,
      imageQuality: 80,
      maxWidth: 400,
      maxHeight: 400,
    );
    if (picked == null) return;

    setState(() => _uploadingAvatar = true);

    try {
      final bytes = await picked.readAsBytes();
      final url = await ImageService.uploadAvatar(
        imageBytes: bytes,
        userId: widget.profile.id,
      );

      if (url != null) {
        await AuthService.updateAvatarUrl(url);
        setState(() {
          // Update local profile display
        });
        _showSnack('Profile picture updated!', AppColors.green);
      } else {
        _showSnack('Upload failed. Check your Cloudinary config.', AppColors.accent);
      }
    } catch (e) {
      _showSnack('Error: $e', AppColors.accent);
    } finally {
      if (mounted) setState(() => _uploadingAvatar = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width >= 700;

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        title: const Text('My Account', style: TextStyle(fontFamily: 'Syne')),
        backgroundColor: AppColors.surface,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.ink),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Center(
        child: ConstrainedBox(
          // ← KEY FIX: max width on wide screens
          constraints: const BoxConstraints(maxWidth: 560),
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(
              horizontal: isWide ? 0 : 16,
              vertical: 20,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [

                // ── AVATAR ──────────────────────────────
                Center(
                  child: Column(children: [
                    GestureDetector(
                      onTap: _uploadingAvatar ? null : _changeAvatar,
                      child: Stack(children: [
                        Container(
                          width: 88, height: 88,
                          decoration: BoxDecoration(
                            color: AppColors.accent,
                            shape: BoxShape.circle,
                            boxShadow: [BoxShadow(color: AppColors.accent.withOpacity(0.3),
                                blurRadius: 16, offset: const Offset(0, 6))],
                          ),
                          child: _uploadingAvatar
                            ? const Center(child: SizedBox(width: 28, height: 28,
                                child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white)))
                            : widget.profile.avatarUrl.isNotEmpty
                              ? ClipOval(child: Image.network(widget.profile.avatarUrl,
                                  width: 88, height: 88, fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => Center(child: Text(_avatarInitials ?? '?',
                                      style: const TextStyle(fontFamily: 'Syne', fontSize: 32,
                                          fontWeight: FontWeight.w800, color: Colors.white)))))
                              : Center(child: Text(_avatarInitials ?? '?',
                                  style: const TextStyle(fontFamily: 'Syne', fontSize: 32,
                                      fontWeight: FontWeight.w800, color: Colors.white))),
                        ),
                        Positioned(
                          bottom: 0, right: 0,
                          child: Container(
                            width: 26, height: 26,
                            decoration: BoxDecoration(
                              color: AppColors.ink,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 2),
                            ),
                            child: const Icon(Icons.camera_alt_outlined, size: 13, color: Colors.white),
                          ),
                        ),
                      ]),
                    ),
                    const SizedBox(height: 10),
                    Text(_bizCtrl.text.isNotEmpty ? _bizCtrl.text : 'Your Business',
                        style: const TextStyle(fontFamily: 'Syne', fontSize: 16,
                            fontWeight: FontWeight.w700, color: AppColors.ink)),
                    const SizedBox(height: 2),
                    // Email verification badge
                    Row(mainAxisSize: MainAxisSize.min, children: [
                      Text(_emailCtrl.text,
                          style: const TextStyle(fontFamily: 'Syne', fontSize: 12, color: AppColors.muted)),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                        decoration: BoxDecoration(
                          color: _emailVerified ? AppColors.greenBg : AppColors.yellowBg,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(mainAxisSize: MainAxisSize.min, children: [
                          Icon(_emailVerified ? Icons.verified : Icons.warning_amber_outlined,
                              size: 10,
                              color: _emailVerified ? AppColors.green : AppColors.yellow),
                          const SizedBox(width: 3),
                          Text(_emailVerified ? 'Verified' : 'Unverified',
                              style: TextStyle(fontFamily: 'Syne', fontSize: 9,
                                  fontWeight: FontWeight.w700,
                                  color: _emailVerified ? AppColors.green : AppColors.yellow)),
                        ]),
                      ),
                    ]),
                  ]),
                ),
                const SizedBox(height: 28),

                // ── BUSINESS PROFILE ────────────────────
                _card('Business Profile', Icons.business_outlined, [
                  _field('Business Name', _bizCtrl, Icons.business_outlined),
                  const SizedBox(height: 12),
                  _field('Your Name', _nameCtrl, Icons.person_outline),
                  const SizedBox(height: 12),
                  // Email with verify button
                  _labelText('Email'),
                  const SizedBox(height: 5),
                  Row(children: [
                    Expanded(
                      child: TextField(
                        controller: _emailCtrl,
                        keyboardType: TextInputType.emailAddress,
                        style: const TextStyle(fontFamily: 'Syne', fontSize: 13, color: AppColors.ink),
                        decoration: const InputDecoration(
                          prefixIcon: Icon(Icons.email_outlined, size: 16, color: AppColors.muted),
                        ),
                      ),
                    ),
                    if (!_emailVerified) ...[
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: _verificationSent ? null : _sendVerification,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                          decoration: BoxDecoration(
                            color: _verificationSent ? AppColors.surface2 : AppColors.blueBg,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: AppColors.border2),
                          ),
                          child: Text(
                            _verificationSent ? 'Sent ✓' : 'Verify',
                            style: TextStyle(fontFamily: 'Syne', fontSize: 12, fontWeight: FontWeight.w700,
                                color: _verificationSent ? AppColors.muted : AppColors.blue),
                          ),
                        ),
                      ),
                    ] else ...[
                      const SizedBox(width: 8),
                      const Icon(Icons.verified, color: AppColors.green, size: 22),
                    ],
                  ]),
                  if (!_emailVerified) ...[
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.yellowBg,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppColors.yellow.withOpacity(0.2)),
                      ),
                      child: const Row(children: [
                        Icon(Icons.info_outline, size: 14, color: AppColors.yellow),
                        SizedBox(width: 6),
                        Expanded(child: Text(
                          'Verify your email to enable email follow-ups and account recovery.',
                          style: TextStyle(fontFamily: 'Syne', fontSize: 11, color: AppColors.yellow),
                        )),
                      ]),
                    ),
                  ],
                  const SizedBox(height: 12),
                  _field('Phone', _phoneCtrl, Icons.phone_outlined, type: TextInputType.phone),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _saving ? null : _saveProfile,
                      child: _saving
                          ? const SizedBox(width: 18, height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : const Text('Save Changes'),
                    ),
                  ),
                ]),
                const SizedBox(height: 14),

                // ── SUBSCRIPTION ────────────────────────
                _card('Subscription', Icons.star_outline, [
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                    Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(
                        widget.profile.plan == 'free' ? 'Free Plan'
                            : widget.profile.plan == 'creator' ? 'Creator Plan' : 'Agency Plan',
                        style: const TextStyle(fontFamily: 'Syne', fontSize: 15,
                            fontWeight: FontWeight.w700, color: AppColors.ink),
                      ),
                      Text(
                        widget.profile.plan == 'free' ? '10 invoices / month'
                            : widget.profile.plan == 'creator' ? 'Unlimited · \$29/mo' : 'Agency · \$79/mo',
                        style: const TextStyle(fontFamily: 'Syne', fontSize: 12, color: AppColors.muted),
                      ),
                    ]),
                    if (widget.profile.plan == 'free')
                      GestureDetector(
                        onTap: () {},
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(color: AppColors.accent, borderRadius: BorderRadius.circular(8)),
                          child: const Text('Upgrade',
                              style: TextStyle(fontFamily: 'Syne', fontSize: 12,
                                  fontWeight: FontWeight.w700, color: Colors.white)),
                        ),
                      ),
                  ]),
                ]),
                const SizedBox(height: 14),

                // ── CHANGE PASSWORD ──────────────────────
                _card('Change Password', Icons.lock_outline, [
                  _passField('Current Password', _currPassCtrl, _obscureCurr,
                      () => setState(() => _obscureCurr = !_obscureCurr)),
                  const SizedBox(height: 12),
                  _passField('New Password', _newPassCtrl, _obscureNew,
                      () => setState(() => _obscureNew = !_obscureNew)),
                  const SizedBox(height: 12),
                  _passField('Confirm New Password', _confirmPassCtrl, _obscureConfirm,
                      () => setState(() => _obscureConfirm = !_obscureConfirm)),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _changingPass ? null : _changePassword,
                      style: ElevatedButton.styleFrom(backgroundColor: AppColors.ink),
                      child: _changingPass
                          ? const SizedBox(width: 18, height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : const Text('Update Password', style: TextStyle(color: Colors.white)),
                    ),
                  ),
                ]),
                const SizedBox(height: 14),

                // ── ACCOUNT ─────────────────────────────
                _card('Account', Icons.manage_accounts_outlined, [
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                    const Text('Member since',
                        style: TextStyle(fontFamily: 'Syne', fontSize: 13, color: AppColors.muted)),
                    Text(widget.profile.createdAt.split('T')[0],
                        style: const TextStyle(fontFamily: 'Syne', fontSize: 13,
                            fontWeight: FontWeight.w600, color: AppColors.ink)),
                  ]),
                  const SizedBox(height: 14),
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                    const Text('Email status',
                        style: TextStyle(fontFamily: 'Syne', fontSize: 13, color: AppColors.muted)),
                    Row(children: [
                      Icon(_emailVerified ? Icons.check_circle : Icons.cancel_outlined,
                          size: 14, color: _emailVerified ? AppColors.green : AppColors.yellow),
                      const SizedBox(width: 4),
                      Text(_emailVerified ? 'Verified' : 'Not verified',
                          style: TextStyle(fontFamily: 'Syne', fontSize: 13, fontWeight: FontWeight.w600,
                              color: _emailVerified ? AppColors.green : AppColors.yellow)),
                    ]),
                  ]),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: _logout,
                      icon: const Icon(Icons.logout, size: 16),
                      label: const Text('Sign Out'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.muted,
                        side: const BorderSide(color: AppColors.border2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: _deleteAccount,
                      icon: const Icon(Icons.delete_forever_outlined, size: 16),
                      label: const Text('Delete Account'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.accent,
                        side: BorderSide(color: AppColors.accent.withOpacity(0.4)),
                      ),
                    ),
                  ),
                ]),

                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _card(String title, IconData icon, List<Widget> children) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Icon(icon, size: 16, color: AppColors.accent),
          const SizedBox(width: 7),
          Text(title, style: const TextStyle(fontFamily: 'Syne', fontSize: 14,
              fontWeight: FontWeight.w700, color: AppColors.ink)),
        ]),
        const SizedBox(height: 14),
        const Divider(color: AppColors.border, height: 1),
        const SizedBox(height: 14),
        ...children,
      ]),
    );
  }

  Widget _labelText(String text) => Text(text.toUpperCase(),
      style: const TextStyle(fontFamily: 'Syne', fontSize: 9,
          color: AppColors.muted, letterSpacing: 1.0));

  Widget _field(String label, TextEditingController ctrl, IconData icon,
      {TextInputType? type}) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _labelText(label),
      const SizedBox(height: 5),
      TextField(
        controller: ctrl,
        keyboardType: type,
        style: const TextStyle(fontFamily: 'Syne', fontSize: 13, color: AppColors.ink),
        decoration: InputDecoration(
            prefixIcon: Icon(icon, size: 16, color: AppColors.muted)),
      ),
    ]);
  }

  Widget _passField(String label, TextEditingController ctrl, bool obscure, VoidCallback toggle) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _labelText(label),
      const SizedBox(height: 5),
      TextField(
        controller: ctrl,
        obscureText: obscure,
        style: const TextStyle(fontFamily: 'Syne', fontSize: 13, color: AppColors.ink),
        decoration: InputDecoration(
          prefixIcon: const Icon(Icons.lock_outline, size: 16, color: AppColors.muted),
          suffixIcon: GestureDetector(
            onTap: toggle,
            child: Icon(obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                size: 16, color: AppColors.muted),
          ),
        ),
      ),
    ]);
  }
}
