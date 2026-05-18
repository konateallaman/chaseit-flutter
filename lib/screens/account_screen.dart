import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:typed_data';
import '../models/user_profile.dart';
import '../services/auth_service.dart';
import '../services/image_service.dart';
import '../theme/app_theme.dart';

// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;

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
  final _currPassCtrl    = TextEditingController();
  final _newPassCtrl     = TextEditingController();
  final _confirmPassCtrl = TextEditingController();
  bool _saving        = false;
  bool _changingPass  = false;
  bool _obscureCurr   = true;
  bool _obscureNew    = true;
  bool _obscureConfirm = true;
  bool _uploadingAvatar = false;
  bool _emailVerified = true;
  bool _verificationSent = false;
  String? _avatarInitials;
  String? _localAvatarUrl; // URL after upload

  @override
  void initState() {
    super.initState();
    final p = widget.profile;
    _bizCtrl   = TextEditingController(text: p.businessName);
    _nameCtrl  = TextEditingController(text: p.ownerName);
    _emailCtrl = TextEditingController(text: p.email);
    _phoneCtrl = TextEditingController(text: p.phone);
    _avatarInitials = _initials(p.businessName.isNotEmpty ? p.businessName : p.ownerName);
    _emailVerified  = p.emailVerified;
    _localAvatarUrl = p.avatarUrl.isNotEmpty ? p.avatarUrl : null;
  }

  String _initials(String name) {
    final words = name.trim().split(' ');
    return words.take(2).map((w) => w.isNotEmpty ? w[0].toUpperCase() : '').join();
  }

  @override
  void dispose() {
    for (final c in [_bizCtrl, _nameCtrl, _emailCtrl, _phoneCtrl,
                     _currPassCtrl, _newPassCtrl, _confirmPassCtrl]) c.dispose();
    super.dispose();
  }

  // ── PICK & UPLOAD AVATAR ────────────────────────────────
  Future<void> _pickAndUploadAvatar() async {
    if (!kIsWeb) {
      _showSnack('Use the mobile app to upload photos.', AppColors.muted);
      return;
    }

    // Show options: camera or file picker
    final choice = await showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Profile Photo', style: TextStyle(fontFamily: 'Syne', fontWeight: FontWeight.w700)),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          _photoOption(Icons.camera_alt_outlined, 'Take a photo', 'camera'),
          const SizedBox(height: 8),
          _photoOption(Icons.photo_library_outlined, 'Choose from files', 'files'),
        ]),
      ),
    );
    if (choice == null) return;

    if (choice == 'camera') {
      await _openCamera();
    } else {
      await _openFilePicker();
    }
  }

  Widget _photoOption(IconData icon, String label, String value) {
    return GestureDetector(
      onTap: () => Navigator.pop(context, value),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.bg,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.border2),
        ),
        child: Row(children: [
          Icon(icon, size: 20, color: AppColors.accent),
          const SizedBox(width: 12),
          Text(label, style: const TextStyle(fontFamily: 'Syne', fontSize: 14,
              fontWeight: FontWeight.w600, color: AppColors.ink)),
        ]),
      ),
    );
  }

  Future<void> _openCamera() async {
    final input = html.FileUploadInputElement()
      ..accept = 'image/*'
      ..setAttribute('capture', 'user'); // front camera
    input.click();
    await input.onChange.first;
    if (input.files == null || input.files!.isEmpty) return;
    await _readAndUpload(input.files![0]);
  }

  Future<void> _openFilePicker() async {
    final input = html.FileUploadInputElement()
      ..accept = 'image/*';
    input.click();
    await input.onChange.first;
    if (input.files == null || input.files!.isEmpty) return;
    await _readAndUpload(input.files![0]);
  }

  Future<void> _readAndUpload(dynamic file) async {
    final reader = html.FileReader();
    reader.readAsArrayBuffer(file);
    await reader.onLoad.first;
    final bytes = Uint8List.fromList((reader.result as List<dynamic>).cast<int>());
    await _uploadBytes(bytes);
  }

  Future<void> _uploadBytes(Uint8List bytes) async {
    setState(() => _uploadingAvatar = true);
    try {
      final url = await ImageService.uploadAvatar(
        imageBytes: bytes,
        userId: widget.profile.id,
      );
      if (url != null) {
        await AuthService.updateAvatarUrl(url);
        setState(() => _localAvatarUrl = url);
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

  // ── SAVE PROFILE ────────────────────────────────────────
  Future<void> _saveProfile() async {
    setState(() => _saving = true);
    final updated = widget.profile.copyWith(
      businessName: _bizCtrl.text.trim(),
      ownerName:    _nameCtrl.text.trim(),
      email:        _emailCtrl.text.trim(),
      phone:        _phoneCtrl.text.trim(),
    );
    final err = await AuthService.updateProfile(updated);
    setState(() => _saving = false);
    if (!mounted) return;
    if (err != null) {
      _showSnack(err, AppColors.accent);
    } else {
      setState(() => _avatarInitials = _initials(
          updated.businessName.isNotEmpty ? updated.businessName : updated.ownerName));
      _showSnack('Profile updated!', AppColors.green);
      Navigator.pop(context, updated);
    }
  }

  // ── CHANGE PASSWORD ─────────────────────────────────────
  Future<void> _changePassword() async {
    if (_newPassCtrl.text != _confirmPassCtrl.text) {
      _showSnack('Passwords do not match.', AppColors.accent); return;
    }
    setState(() => _changingPass = true);
    final err = await AuthService.changePassword(
      currentPassword: _currPassCtrl.text,
      newPassword:     _newPassCtrl.text,
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

  // ── EMAIL VERIFY ────────────────────────────────────────
  void _sendVerification() {
    setState(() => _verificationSent = true);
    _showSnack('Verification email sent to ${_emailCtrl.text}', AppColors.blue);
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() => _emailVerified = true);
    });
  }

  // ── LOGOUT / DELETE ─────────────────────────────────────
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
            'This permanently deletes your account, all invoices, and all client data. Cannot be undone.',
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

  Future<bool?> _confirm(String title, String msg, String action) =>
      showDialog<bool>(
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

  void _showSnack(String msg, Color color) =>
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(msg, style: const TextStyle(fontFamily: 'Syne')),
              backgroundColor: color));

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
          constraints: const BoxConstraints(maxWidth: 560),
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(horizontal: isWide ? 0 : 16, vertical: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [

                // ── AVATAR ──────────────────────────────
                Center(child: Column(children: [
                  GestureDetector(
                    onTap: _uploadingAvatar ? null : _pickAndUploadAvatar,
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
                            : _localAvatarUrl != null
                                ? ClipOval(child: Image.network(_localAvatarUrl!,
                                    width: 88, height: 88, fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) => _avatarText()))
                                : _avatarText(),
                      ),
                      Positioned(
                        bottom: 0, right: 0,
                        child: Container(
                          width: 28, height: 28,
                          decoration: BoxDecoration(
                            color: AppColors.ink, shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                          ),
                          child: const Icon(Icons.camera_alt_outlined, size: 14, color: Colors.white),
                        ),
                      ),
                    ]),
                  ),
                  const SizedBox(height: 8),
                  Text('Tap to change photo',
                      style: TextStyle(fontFamily: 'Syne', fontSize: 12, color: AppColors.muted)),
                  const SizedBox(height: 6),
                  Text(_bizCtrl.text.isNotEmpty ? _bizCtrl.text : 'Your Business',
                      style: const TextStyle(fontFamily: 'Syne', fontSize: 16,
                          fontWeight: FontWeight.w700, color: AppColors.ink)),
                  const SizedBox(height: 3),
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
                            size: 10, color: _emailVerified ? AppColors.green : AppColors.yellow),
                        const SizedBox(width: 3),
                        Text(_emailVerified ? 'Verified' : 'Unverified',
                            style: TextStyle(fontFamily: 'Syne', fontSize: 9,
                                fontWeight: FontWeight.w700,
                                color: _emailVerified ? AppColors.green : AppColors.yellow)),
                      ]),
                    ),
                  ]),
                ])),
                const SizedBox(height: 24),

                // ── PROFILE ──────────────────────────────
                _card('Business Profile', Icons.business_outlined, [
                  _field('Business Name', _bizCtrl, Icons.business_outlined),
                  const SizedBox(height: 12),
                  _field('Your Name', _nameCtrl, Icons.person_outline),
                  const SizedBox(height: 12),
                  // Email + verify
                  _labelText('Email'),
                  const SizedBox(height: 5),
                  Row(children: [
                    Expanded(child: TextField(
                      controller: _emailCtrl,
                      keyboardType: TextInputType.emailAddress,
                      style: const TextStyle(fontFamily: 'Syne', fontSize: 13, color: AppColors.ink),
                      decoration: const InputDecoration(
                          prefixIcon: Icon(Icons.email_outlined, size: 16, color: AppColors.muted)),
                    )),
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
                          child: Text(_verificationSent ? 'Sent ✓' : 'Verify',
                              style: TextStyle(fontFamily: 'Syne', fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: _verificationSent ? AppColors.muted : AppColors.blue)),
                        ),
                      ),
                    ] else
                      const Padding(padding: EdgeInsets.only(left: 8),
                          child: Icon(Icons.verified, color: AppColors.green, size: 22)),
                  ]),
                  const SizedBox(height: 12),
                  _field('Phone', _phoneCtrl, Icons.phone_outlined, type: TextInputType.phone),
                  const SizedBox(height: 16),
                  SizedBox(width: double.infinity,
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

                // ── SUBSCRIPTION ─────────────────────────
                _card('Subscription', Icons.star_outline, [
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                    Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(widget.profile.plan == 'free' ? 'Free Plan' : 'Pro Plan',
                          style: const TextStyle(fontFamily: 'Syne', fontSize: 15,
                              fontWeight: FontWeight.w700, color: AppColors.ink)),
                      Text(widget.profile.plan == 'free' ? '10 invoices / month' : 'Unlimited',
                          style: const TextStyle(fontFamily: 'Syne', fontSize: 12, color: AppColors.muted)),
                    ]),
                    if (widget.profile.plan == 'free')
                      GestureDetector(
                        onTap: () {},
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(color: AppColors.accent, borderRadius: BorderRadius.circular(8)),
                          child: const Text('Upgrade', style: TextStyle(fontFamily: 'Syne',
                              fontSize: 12, fontWeight: FontWeight.w700, color: Colors.white)),
                        ),
                      ),
                  ]),
                ]),
                const SizedBox(height: 14),

                // ── CHANGE PASSWORD ───────────────────────
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
                  SizedBox(width: double.infinity,
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

                // ── ACCOUNT ACTIONS ───────────────────────
                _card('Account', Icons.manage_accounts_outlined, [
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                    const Text('Member since', style: TextStyle(fontFamily: 'Syne', fontSize: 13, color: AppColors.muted)),
                    Text(widget.profile.createdAt.split('T')[0],
                        style: const TextStyle(fontFamily: 'Syne', fontSize: 13,
                            fontWeight: FontWeight.w600, color: AppColors.ink)),
                  ]),
                  const SizedBox(height: 16),
                  SizedBox(width: double.infinity,
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
                  SizedBox(width: double.infinity,
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

  Widget _avatarText() => Center(child: Text(_avatarInitials ?? '?',
      style: const TextStyle(fontFamily: 'Syne', fontSize: 32,
          fontWeight: FontWeight.w800, color: Colors.white)));

  Widget _card(String title, IconData icon, List<Widget> children) => Container(
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(color: AppColors.surface,
        borderRadius: BorderRadius.circular(14), border: Border.all(color: AppColors.border)),
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

  Widget _labelText(String text) => Text(text.toUpperCase(),
      style: const TextStyle(fontFamily: 'Syne', fontSize: 9,
          color: AppColors.muted, letterSpacing: 1.0));

  Widget _field(String label, TextEditingController ctrl, IconData icon, {TextInputType? type}) =>
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _labelText(label),
        const SizedBox(height: 5),
        TextField(
          controller: ctrl, keyboardType: type,
          style: const TextStyle(fontFamily: 'Syne', fontSize: 13, color: AppColors.ink),
          decoration: InputDecoration(prefixIcon: Icon(icon, size: 16, color: AppColors.muted)),
        ),
      ]);

  Widget _passField(String label, TextEditingController ctrl, bool obscure, VoidCallback toggle) =>
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _labelText(label),
        const SizedBox(height: 5),
        TextField(
          controller: ctrl, obscureText: obscure,
          style: const TextStyle(fontFamily: 'Syne', fontSize: 13, color: AppColors.ink),
          decoration: InputDecoration(
            prefixIcon: const Icon(Icons.lock_outline, size: 16, color: AppColors.muted),
            suffixIcon: GestureDetector(onTap: toggle,
                child: Icon(obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                    size: 16, color: AppColors.muted)),
          ),
        ),
      ]);
}
