import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../theme/app_theme.dart';
import 'register_screen.dart';
import 'forgot_password_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _obscure = true;
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    setState(() { _error = null; _loading = true; });
    final err = await AuthService.login(_emailCtrl.text, _passCtrl.text);
    if (!mounted) return;
    setState(() => _loading = false);
    if (err != null) {
      setState(() => _error = err);
    } else {
      Navigator.of(context).pushReplacementNamed('/home');
    }
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
                  const SizedBox(height: 40),
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
                  const SizedBox(height: 40),
                  const Text('Welcome back',
                      style: TextStyle(fontFamily: 'Syne', fontSize: 26,
                          fontWeight: FontWeight.w800, color: AppColors.ink,
                          letterSpacing: -0.5)),
                  const SizedBox(height: 6),
                  const Text('Sign in to your ChaseIt account.',
                      style: TextStyle(fontFamily: 'Syne', fontSize: 14, color: AppColors.muted)),
                  const SizedBox(height: 32),

                  _label('Email Address'),
                  TextField(
                    controller: _emailCtrl,
                    keyboardType: TextInputType.emailAddress,
                    style: const TextStyle(fontFamily: 'Syne', fontSize: 14, color: AppColors.ink),
                    decoration: const InputDecoration(
                      hintText: 'john@acme.com',
                      prefixIcon: Icon(Icons.email_outlined, size: 18, color: AppColors.muted),
                    ),
                  ),
                  const SizedBox(height: 14),

                  _label('Password'),
                  TextField(
                    controller: _passCtrl,
                    obscureText: _obscure,
                    onSubmitted: (_) => _login(),
                    style: const TextStyle(fontFamily: 'Syne', fontSize: 14, color: AppColors.ink),
                    decoration: InputDecoration(
                      hintText: 'Your password',
                      prefixIcon: const Icon(Icons.lock_outline, size: 18, color: AppColors.muted),
                      suffixIcon: GestureDetector(
                        onTap: () => setState(() => _obscure = !_obscure),
                        child: Icon(
                          _obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                          size: 18, color: AppColors.muted,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerRight,
                    child: GestureDetector(
                      onTap: () => Navigator.push(context,
                          MaterialPageRoute(builder: (_) => const ForgotPasswordScreen())),
                      child: const Text('Forgot password?',
                          style: TextStyle(fontFamily: 'Syne', fontSize: 13,
                              fontWeight: FontWeight.w600, color: AppColors.accent)),
                    ),
                  ),
                  const SizedBox(height: 16),

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
                      onPressed: _loading ? null : _login,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.accent,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      child: _loading
                          ? const SizedBox(width: 20, height: 20,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white))
                          : const Text('Sign In',
                              style: TextStyle(fontFamily: 'Syne', fontSize: 15,
                                  fontWeight: FontWeight.w700, color: Colors.white)),
                    ),
                  ),
                  const SizedBox(height: 20),

                  Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                    const Text("Don't have an account? ",
                        style: TextStyle(fontFamily: 'Syne', fontSize: 13,
                            color: AppColors.muted)),
                    GestureDetector(
                      onTap: () => Navigator.pushReplacement(context,
                          MaterialPageRoute(builder: (_) => const RegisterScreen())),
                      child: const Text('Register',
                          style: TextStyle(fontFamily: 'Syne', fontSize: 13,
                              fontWeight: FontWeight.w700, color: AppColors.accent)),
                    ),
                  ]),
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
}
