import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/auth_service.dart';
import '../services/email_service.dart';
import '../theme/app_theme.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});
  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  // Steps: 1=enter email, 2=enter code, 3=new password
  int _step = 1;
  final _emailCtrl   = TextEditingController();
  final _newPassCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  final List<TextEditingController> _codeCtrls =
      List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _codeNodes =
      List.generate(6, (_) => FocusNode());

  bool _loading  = false;
  bool _obscure1 = true;
  bool _obscure2 = true;
  String? _error;
  String? _resetCode;
  int _resendSeconds = 60;
  bool _canResend = false;

  @override
  void dispose() {
    _emailCtrl.dispose(); _newPassCtrl.dispose(); _confirmCtrl.dispose();
    for (final c in _codeCtrls) c.dispose();
    for (final n in _codeNodes) n.dispose();
    super.dispose();
  }

  String get _enteredCode => _codeCtrls.map((c) => c.text).join();

  void _startTimer() {
    setState(() { _resendSeconds = 60; _canResend = false; });
    Future.doWhile(() async {
      await Future.delayed(const Duration(seconds: 1));
      if (!mounted) return false;
      setState(() => _resendSeconds--);
      if (_resendSeconds <= 0) { setState(() => _canResend = true); return false; }
      return true;
    });
  }

  // Step 1 — send reset code
  Future<void> _sendCode() async {
    if (_emailCtrl.text.trim().isEmpty) {
      setState(() => _error = 'Please enter your email.'); return;
    }
    setState(() { _error = null; _loading = true; });

    // Check account exists
    final profile = await AuthService.getProfileByEmail(_emailCtrl.text.trim().toLowerCase());
    if (!mounted) return;
    if (profile == null) {
      setState(() { _error = 'No account found with this email.'; _loading = false; }); return;
    }

    // Generate and store reset code
    _resetCode = await AuthService.saveResetCode(_emailCtrl.text.trim().toLowerCase());

    // Send email
    await EmailService.sendResetEmail(
      toEmail: _emailCtrl.text.trim(),
      toName: profile.ownerName,
      code: _resetCode!,
    );

    print('[ChaseIt] RESET CODE: $_resetCode');
    setState(() { _loading = false; _step = 2; });
    _startTimer();
  }

  // Step 2 — verify code
  Future<void> _verifyCode() async {
    if (_enteredCode.length < 6) {
      setState(() => _error = 'Enter the full 6-digit code.'); return;
    }
    setState(() { _error = null; _loading = true; });

    final valid = await AuthService.verifyResetCode(
      email: _emailCtrl.text.trim().toLowerCase(),
      code: _enteredCode,
    );
    setState(() => _loading = false);
    if (!valid) {
      setState(() => _error = 'Invalid code. Please try again.');
      for (final c in _codeCtrls) c.clear();
      _codeNodes[0].requestFocus();
      return;
    }
    setState(() => _step = 3);
  }

  // Step 3 — set new password
  Future<void> _resetPassword() async {
    if (_newPassCtrl.text.length < 6) {
      setState(() => _error = 'Password must be at least 6 characters.'); return;
    }
    if (_newPassCtrl.text != _confirmCtrl.text) {
      setState(() => _error = 'Passwords do not match.'); return;
    }
    setState(() { _error = null; _loading = true; });

    await AuthService.resetPassword(
      email: _emailCtrl.text.trim().toLowerCase(),
      newPassword: _newPassCtrl.text,
    );

    setState(() => _loading = false);
    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Password reset! Please sign in.'),
          backgroundColor: AppColors.green,
        ),
      );
    }
  }

  Future<void> _resend() async {
    _resetCode = await AuthService.saveResetCode(_emailCtrl.text.trim().toLowerCase());
    await EmailService.sendResetEmail(
      toEmail: _emailCtrl.text.trim(),
      toName: '',
      code: _resetCode!,
    );
    print('[ChaseIt] RESET CODE: $_resetCode');
    _startTimer();
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Code resent!'), backgroundColor: AppColors.green),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: AppColors.bg,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.ink),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 440),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Icon
                Container(
                  width: 72, height: 72,
                  decoration: BoxDecoration(
                    color: AppColors.accent.withOpacity(0.1),
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.accent.withOpacity(0.3), width: 2),
                  ),
                  child: Icon(
                    _step == 1 ? Icons.lock_reset_outlined
                        : _step == 2 ? Icons.mark_email_unread_outlined
                        : Icons.lock_open_outlined,
                    size: 34, color: AppColors.accent,
                  ),
                ),
                const SizedBox(height: 20),

                // Step indicators
                Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  for (int i = 1; i <= 3; i++) ...[
                    Container(
                      width: 28, height: 28,
                      decoration: BoxDecoration(
                        color: _step >= i ? AppColors.accent : AppColors.surface2,
                        shape: BoxShape.circle,
                      ),
                      alignment: Alignment.center,
                      child: Text('$i', style: TextStyle(
                          fontFamily: 'Syne', fontSize: 12, fontWeight: FontWeight.w700,
                          color: _step >= i ? Colors.white : AppColors.muted)),
                    ),
                    if (i < 3) Container(width: 30, height: 2,
                        color: _step > i ? AppColors.accent : AppColors.border2),
                  ],
                ]),
                const SizedBox(height: 20),

                Text(
                  _step == 1 ? 'Forgot Password'
                      : _step == 2 ? 'Check your email'
                      : 'Set new password',
                  style: const TextStyle(fontFamily: 'Syne', fontSize: 22,
                      fontWeight: FontWeight.w800, color: AppColors.ink, letterSpacing: -0.5),
                ),
                const SizedBox(height: 8),
                Text(
                  _step == 1 ? 'Enter your email and we\'ll send a reset code.'
                      : _step == 2 ? 'Enter the 6-digit code sent to ${_emailCtrl.text}'
                      : 'Choose a new password for your account.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontFamily: 'Syne', fontSize: 13,
                      color: AppColors.muted, height: 1.6),
                ),
                const SizedBox(height: 28),

                // ── STEP 1 — EMAIL ──
                if (_step == 1) ...[
                  _label('Email Address'),
                  TextField(
                    controller: _emailCtrl,
                    keyboardType: TextInputType.emailAddress,
                    style: const TextStyle(fontFamily: 'Syne', fontSize: 14, color: AppColors.ink),
                    decoration: const InputDecoration(
                      hintText: 'your@email.com',
                      prefixIcon: Icon(Icons.email_outlined, size: 18, color: AppColors.muted),
                    ),
                  ),
                  const SizedBox(height: 20),
                  _submitBtn('Send Reset Code', _sendCode),
                ],

                // ── STEP 2 — CODE ──
                if (_step == 2) ...[
                  Row(mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(6, (i) => Container(
                      width: 44, height: 54,
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppColors.border2),
                      ),
                      child: TextField(
                        controller: _codeCtrls[i],
                        focusNode: _codeNodes[i],
                        textAlign: TextAlign.center,
                        keyboardType: TextInputType.number,
                        maxLength: 1,
                        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                        style: const TextStyle(fontFamily: 'Syne', fontSize: 20,
                            fontWeight: FontWeight.w800, color: AppColors.ink),
                        decoration: const InputDecoration(
                            counterText: '', border: InputBorder.none, contentPadding: EdgeInsets.zero),
                        onChanged: (v) {
                          if (v.length == 1 && i < 5) _codeNodes[i + 1].requestFocus();
                          if (v.isEmpty && i > 0) _codeNodes[i - 1].requestFocus();
                          if (_enteredCode.length == 6) _verifyCode();
                        },
                      ),
                    )),
                  ),
                  const SizedBox(height: 20),
                  _submitBtn('Verify Code', _verifyCode),
                  const SizedBox(height: 14),
                  Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                    const Text("Didn't get it? ",
                        style: TextStyle(fontFamily: 'Syne', fontSize: 13, color: AppColors.muted)),
                    _canResend
                        ? GestureDetector(onTap: _resend,
                            child: const Text('Resend',
                                style: TextStyle(fontFamily: 'Syne', fontSize: 13,
                                    fontWeight: FontWeight.w700, color: AppColors.accent)))
                        : Text('Resend in ${_resendSeconds}s',
                            style: const TextStyle(fontFamily: 'Syne', fontSize: 13, color: AppColors.muted2)),
                  ]),
                ],

                // ── STEP 3 — NEW PASSWORD ──
                if (_step == 3) ...[
                  _label('New Password'),
                  TextField(
                    controller: _newPassCtrl,
                    obscureText: _obscure1,
                    style: const TextStyle(fontFamily: 'Syne', fontSize: 14, color: AppColors.ink),
                    decoration: InputDecoration(
                      hintText: 'At least 6 characters',
                      prefixIcon: const Icon(Icons.lock_outline, size: 18, color: AppColors.muted),
                      suffixIcon: GestureDetector(
                        onTap: () => setState(() => _obscure1 = !_obscure1),
                        child: Icon(_obscure1 ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                            size: 18, color: AppColors.muted),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  _label('Confirm Password'),
                  TextField(
                    controller: _confirmCtrl,
                    obscureText: _obscure2,
                    style: const TextStyle(fontFamily: 'Syne', fontSize: 14, color: AppColors.ink),
                    decoration: InputDecoration(
                      hintText: 'Repeat your password',
                      prefixIcon: const Icon(Icons.lock_outline, size: 18, color: AppColors.muted),
                      suffixIcon: GestureDetector(
                        onTap: () => setState(() => _obscure2 = !_obscure2),
                        child: Icon(_obscure2 ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                            size: 18, color: AppColors.muted),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  _submitBtn('Reset Password', _resetPassword),
                ],

                // Error
                if (_error != null) ...[
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.accentBg,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.accent.withOpacity(0.3)),
                    ),
                    child: Row(children: [
                      const Icon(Icons.error_outline, size: 16, color: AppColors.accent),
                      const SizedBox(width: 8),
                      Expanded(child: Text(_error!,
                          style: const TextStyle(fontFamily: 'Syne', fontSize: 13, color: AppColors.accent))),
                    ]),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _label(String text) => Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: Align(alignment: Alignment.centerLeft,
      child: Text(text.toUpperCase(),
          style: const TextStyle(fontFamily: 'Syne', fontSize: 9,
              color: AppColors.muted, letterSpacing: 1.0))),
  );

  Widget _submitBtn(String label, VoidCallback onTap) => SizedBox(
    width: double.infinity, height: 50,
    child: ElevatedButton(
      onPressed: _loading ? null : onTap,
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.accent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      child: _loading
          ? const SizedBox(width: 20, height: 20,
              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
          : Text(label, style: const TextStyle(fontFamily: 'Syne', fontSize: 15,
              fontWeight: FontWeight.w700, color: Colors.white)),
    ),
  );
}
