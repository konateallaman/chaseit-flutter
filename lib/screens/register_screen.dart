import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../theme/app_theme.dart';
import 'login_screen.dart';
import 'verify_email_screen.dart';
import '../services/email_service.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});
  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _bizCtrl     = TextEditingController();
  final _nameCtrl    = TextEditingController();
  final _emailCtrl   = TextEditingController();
  final _phoneCtrl   = TextEditingController();
  final _passCtrl    = TextEditingController();
  final _confirmCtrl = TextEditingController();
  bool _obscure = true;
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    for (final c in [_bizCtrl, _nameCtrl, _emailCtrl,
                     _phoneCtrl, _passCtrl, _confirmCtrl]) c.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    setState(() { _error = null; _loading = true; });

    // Basic validation
    if (_bizCtrl.text.trim().isEmpty) {
      setState(() { _error = 'Business name is required.'; _loading = false; }); return;
    }
    if (_nameCtrl.text.trim().isEmpty) {
      setState(() { _error = 'Your name is required.'; _loading = false; }); return;
    }
    if (_emailCtrl.text.trim().isEmpty || !_emailCtrl.text.contains('@')) {
      setState(() { _error = 'Valid email is required.'; _loading = false; }); return;
    }
    if (_passCtrl.text.length < 6) {
      setState(() { _error = 'Password must be at least 6 characters.'; _loading = false; }); return;
    }
    if (_passCtrl.text != _confirmCtrl.text) {
      setState(() { _error = 'Passwords do not match.'; _loading = false; }); return;
    }

    // Save pending registration and get verification code
    final code = await AuthService.savePendingRegistration(
      businessName: _bizCtrl.text,
      ownerName: _nameCtrl.text,
      email: _emailCtrl.text,
      password: _passCtrl.text,
      phone: _phoneCtrl.text,
    );

    // Send verification email
    final sent = await EmailService.sendVerificationEmail(
      toEmail: _emailCtrl.text.trim(),
      toName: _nameCtrl.text.trim(),
      code: code,
    );

    if (!mounted) return;
    setState(() => _loading = false);

    if (!sent) {
      // Email failed — still show verification screen with a warning
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not send email. Check your API key. Code shown in debug console.'),
          backgroundColor: AppColors.yellow,
          duration: Duration(seconds: 5),
        ),
      );
      // In debug/dev: print the code so you can test
      print('[ChaseIt] VERIFICATION CODE: $code');
    }

    // Go to verification screen regardless
    Navigator.push(context, MaterialPageRoute(
      builder: (_) => VerifyEmailScreen(
        email: _emailCtrl.text.trim(),
        name: _nameCtrl.text.trim(),
      ),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 20),
                  // Logo
                  Row(children: [
                    Container(
                      width: 36, height: 36,
                      decoration: BoxDecoration(
                        color: AppColors.accent,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.timer_outlined, size: 20, color: Colors.white),
                    ),
                    const SizedBox(width: 10),
                    const Text('ChaseIt',
                        style: TextStyle(fontFamily: 'Syne', fontSize: 22,
                            fontWeight: FontWeight.w800, color: AppColors.ink,
                            letterSpacing: -0.5)),
                  ]),
                  const SizedBox(height: 32),
                  const Text('Create your account',
                      style: TextStyle(fontFamily: 'Syne', fontSize: 24,
                          fontWeight: FontWeight.w800, color: AppColors.ink,
                          letterSpacing: -0.5)),
                  const SizedBox(height: 6),
                  const Text('Set up your business profile to get started.',
                      style: TextStyle(fontFamily: 'Syne', fontSize: 14,
                          color: AppColors.muted)),
                  const SizedBox(height: 28),

                  _label('Business Name *'),
                  _field(_bizCtrl, 'Acme Corp', Icons.business_outlined),
                  const SizedBox(height: 14),

                  _label('Your Full Name *'),
                  _field(_nameCtrl, 'John Smith', Icons.person_outline),
                  const SizedBox(height: 14),

                  _label('Email Address *'),
                  _field(_emailCtrl, 'john@acme.com', Icons.email_outlined,
                      type: TextInputType.emailAddress),
                  const SizedBox(height: 14),

                  _label('Phone (optional)'),
                  _field(_phoneCtrl, '+1 555 000 0000', Icons.phone_outlined,
                      type: TextInputType.phone),
                  const SizedBox(height: 14),

                  _label('Password *'),
                  _passField(_passCtrl, 'At least 6 characters'),
                  const SizedBox(height: 14),

                  _label('Confirm Password *'),
                  _passField(_confirmCtrl, 'Repeat your password'),
                  const SizedBox(height: 20),

                  if (_error != null)
                    Container(
                      padding: const EdgeInsets.all(12),
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: AppColors.accentBg,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppColors.accent.withOpacity(0.3)),
                      ),
                      child: Row(children: [
                        const Icon(Icons.error_outline, size: 16, color: AppColors.accent),
                        const SizedBox(width: 8),
                        Expanded(child: Text(_error!,
                            style: const TextStyle(fontFamily: 'Syne',
                                fontSize: 13, color: AppColors.accent))),
                      ]),
                    ),

                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _loading ? null : _register,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.accent,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      child: _loading
                          ? const SizedBox(width: 20, height: 20,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white))
                          : const Text('Create Account',
                              style: TextStyle(fontFamily: 'Syne', fontSize: 15,
                                  fontWeight: FontWeight.w700, color: Colors.white)),
                    ),
                  ),
                  const SizedBox(height: 20),

                  Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                    const Text('Already have an account? ',
                        style: TextStyle(fontFamily: 'Syne', fontSize: 13,
                            color: AppColors.muted)),
                    GestureDetector(
                      onTap: () => Navigator.pushReplacement(context,
                          MaterialPageRoute(builder: (_) => const LoginScreen())),
                      child: const Text('Sign in',
                          style: TextStyle(fontFamily: 'Syne', fontSize: 13,
                              fontWeight: FontWeight.w700, color: AppColors.accent)),
                    ),
                  ]),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _label(String text) => Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: Text(text.toUpperCase(),
        style: const TextStyle(fontFamily: 'Syne', fontSize: 9,
            color: AppColors.muted, letterSpacing: 1.0)),
  );

  Widget _field(TextEditingController ctrl, String hint, IconData icon,
      {TextInputType? type}) {
    return TextField(
      controller: ctrl,
      keyboardType: type,
      style: const TextStyle(fontFamily: 'Syne', fontSize: 14, color: AppColors.ink),
      decoration: InputDecoration(
        hintText: hint,
        prefixIcon: Icon(icon, size: 18, color: AppColors.muted),
      ),
    );
  }

  Widget _passField(TextEditingController ctrl, String hint) {
    return TextField(
      controller: ctrl,
      obscureText: _obscure,
      style: const TextStyle(fontFamily: 'Syne', fontSize: 14, color: AppColors.ink),
      decoration: InputDecoration(
        hintText: hint,
        prefixIcon: const Icon(Icons.lock_outline, size: 18, color: AppColors.muted),
        suffixIcon: GestureDetector(
          onTap: () => setState(() => _obscure = !_obscure),
          child: Icon(
            _obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined,
            size: 18, color: AppColors.muted,
          ),
        ),
      ),
    );
  }
}
