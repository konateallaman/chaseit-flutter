import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/auth_service.dart';
import '../theme/app_theme.dart';

class VerifyEmailScreen extends StatefulWidget {
  final String email;
  final String name;
  const VerifyEmailScreen({super.key, required this.email, required this.name});
  @override
  State<VerifyEmailScreen> createState() => _VerifyEmailScreenState();
}

class _VerifyEmailScreenState extends State<VerifyEmailScreen> {
  final List<TextEditingController> _ctrls = List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _nodes = List.generate(6, (_) => FocusNode());
  bool _loading = false;
  bool _resending = false;
  String? _error;
  int _resendSeconds = 60;
  bool _canResend = false;

  @override
  void initState() {
    super.initState();
    _startResendTimer();
  }

  void _startResendTimer() {
    setState(() { _resendSeconds = 60; _canResend = false; });
    Future.doWhile(() async {
      await Future.delayed(const Duration(seconds: 1));
      if (!mounted) return false;
      setState(() => _resendSeconds--);
      if (_resendSeconds <= 0) {
        setState(() => _canResend = true);
        return false;
      }
      return true;
    });
  }

  String get _code => _ctrls.map((c) => c.text).join();

  void _onDigitEntered(int index, String value) {
    if (value.length == 1 && index < 5) {
      _nodes[index + 1].requestFocus();
    }
    if (value.isEmpty && index > 0) {
      _nodes[index - 1].requestFocus();
    }
    // Auto-submit when all 6 filled
    if (_code.length == 6) _verify();
  }

  Future<void> _verify() async {
    if (_code.length < 6) {
      setState(() => _error = 'Please enter the full 6-digit code.');
      return;
    }
    setState(() { _error = null; _loading = true; });
    final err = await AuthService.verifyAndCreateAccount(_code);
    if (!mounted) return;
    setState(() => _loading = false);
    if (err != null) {
      setState(() => _error = err);
      // Clear fields on wrong code
      for (final c in _ctrls) c.clear();
      _nodes[0].requestFocus();
    } else {
      Navigator.of(context).pushReplacementNamed('/home');
    }
  }

  Future<void> _resend() async {
    setState(() => _resending = true);
    // In production: call email service again
    await Future.delayed(const Duration(seconds: 1));
    if (!mounted) return;
    setState(() => _resending = false);
    _startResendTimer();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Code resent to ${widget.email}'),
          backgroundColor: AppColors.green),
    );
  }

  @override
  void dispose() {
    for (final c in _ctrls) c.dispose();
    for (final n in _nodes) n.dispose();
    super.dispose();
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
                  child: const Icon(Icons.mark_email_unread_outlined,
                      size: 34, color: AppColors.accent),
                ),
                const SizedBox(height: 24),
                const Text('Check your email',
                    style: TextStyle(fontFamily: 'Syne', fontSize: 24,
                        fontWeight: FontWeight.w800, color: AppColors.ink, letterSpacing: -0.5)),
                const SizedBox(height: 10),
                RichText(
                  textAlign: TextAlign.center,
                  text: TextSpan(
                    style: const TextStyle(fontFamily: 'Syne', fontSize: 14,
                        color: AppColors.muted, height: 1.6),
                    children: [
                      const TextSpan(text: 'We sent a 6-digit code to\n'),
                      TextSpan(text: widget.email,
                          style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.ink)),
                    ],
                  ),
                ),
                const SizedBox(height: 36),

                // 6-digit input
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(6, (i) => Container(
                    width: 46, height: 56,
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: _nodes[i].hasFocus ? AppColors.accent : AppColors.border2,
                        width: _nodes[i].hasFocus ? 2 : 1,
                      ),
                    ),
                    child: TextField(
                      controller: _ctrls[i],
                      focusNode: _nodes[i],
                      textAlign: TextAlign.center,
                      keyboardType: TextInputType.number,
                      maxLength: 1,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      style: const TextStyle(fontFamily: 'Syne', fontSize: 22,
                          fontWeight: FontWeight.w800, color: AppColors.ink),
                      decoration: const InputDecoration(
                        counterText: '',
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.zero,
                      ),
                      onChanged: (v) => _onDigitEntered(i, v),
                    ),
                  )),
                ),
                const SizedBox(height: 24),

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
                    onPressed: _loading ? null : _verify,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.accent,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: _loading
                        ? const SizedBox(width: 20, height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Text('Verify Email',
                            style: TextStyle(fontFamily: 'Syne', fontSize: 15,
                                fontWeight: FontWeight.w700, color: Colors.white)),
                  ),
                ),
                const SizedBox(height: 20),

                // Resend
                Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  const Text("Didn't receive it? ",
                      style: TextStyle(fontFamily: 'Syne', fontSize: 13, color: AppColors.muted)),
                  _canResend
                      ? GestureDetector(
                          onTap: _resending ? null : _resend,
                          child: Text(_resending ? 'Sending...' : 'Resend code',
                              style: const TextStyle(fontFamily: 'Syne', fontSize: 13,
                                  fontWeight: FontWeight.w700, color: AppColors.accent)),
                        )
                      : Text('Resend in ${_resendSeconds}s',
                          style: const TextStyle(fontFamily: 'Syne', fontSize: 13,
                              color: AppColors.muted2)),
                ]),
                const SizedBox(height: 8),
                Text('Check your spam folder if you don\'t see it.',
                    style: const TextStyle(fontFamily: 'Syne', fontSize: 12, color: AppColors.muted2)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
