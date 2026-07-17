import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/app_theme.dart';
import '../../state/profile_service.dart';
import '../drill_intro_screen.dart';
import '../home_screen.dart';
import '../sar/sar_home_screen.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  final bool sarMode;
  const LoginScreen({super.key, this.sarMode = false});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _loading = false;
  bool _obscure = true;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _signIn() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      await Supabase.instance.client.auth.signInWithPassword(
        email: _email.text.trim(),
        password: _password.text,
      );
      final profile = await ProfileService.fetchProfile();

      if (widget.sarMode) {
        if (profile?.isSar != true) {
          await Supabase.instance.client.auth.signOut();
          if (!mounted) return;
          setState(() => _loading = false);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('This account is not authorized for SAR access.'),
            ),
          );
          return;
        }
        if (!mounted) return;
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const SarHomeScreen()),
          (_) => false,
        );
        return;
      }

      final done = profile?.hasCompletedSimulation ?? false;
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (_) =>
              done ? const HomeScreen() : const DrillIntroScreen(),
        ),
        (_) => false,
      );
    } on AuthException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(e.message)));
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not sign in. Check your network.')),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final sar = widget.sarMode;
    return Scaffold(
      backgroundColor: QColors.cream,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 28),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (sar)
                    const Icon(Icons.shield_moon,
                            size: 76, color: QColors.orangeDark)
                        .animate()
                        .scale(
                          begin: const Offset(0.7, 0.7),
                          duration: 600.ms,
                          curve: Curves.elasticOut,
                        )
                  else
                    Image.asset('assets/images/Quaky_Logo.png', width: 150)
                        .animate()
                        .scale(
                          begin: const Offset(0.7, 0.7),
                          duration: 600.ms,
                          curve: Curves.elasticOut,
                        ),
                  const SizedBox(height: 10),
                  Text(
                    sar ? 'SAR Personnel Login' : 'Welcome back!',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w900,
                      color: QColors.brown,
                    ),
                  ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.3),
                  const SizedBox(height: 28),
                  TextFormField(
                    controller: _email,
                    keyboardType: TextInputType.emailAddress,
                    decoration: InputDecoration(
                      labelText: 'Email',
                      prefixIcon: const Icon(Icons.alternate_email),
                      focusedBorder: sar
                          ? OutlineInputBorder(
                              borderRadius: BorderRadius.circular(18),
                              borderSide: const BorderSide(
                                  color: QColors.orangeDark, width: 2.5),
                            )
                          : null,
                    ),
                    validator: (v) => (v == null || !v.contains('@'))
                        ? 'Enter a valid email'
                        : null,
                  ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.3),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _password,
                    obscureText: _obscure,
                    decoration: InputDecoration(
                      labelText: 'Password',
                      prefixIcon: const Icon(Icons.lock_outline),
                      focusedBorder: sar
                          ? OutlineInputBorder(
                              borderRadius: BorderRadius.circular(18),
                              borderSide: const BorderSide(
                                  color: QColors.orangeDark, width: 2.5),
                            )
                          : null,
                      suffixIcon: IconButton(
                        icon: Icon(
                            _obscure ? Icons.visibility : Icons.visibility_off),
                        onPressed: () => setState(() => _obscure = !_obscure),
                      ),
                    ),
                    validator: (v) => (v == null || v.length < 6)
                        ? 'At least 6 characters'
                        : null,
                  ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.3),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    style: sar
                        ? ElevatedButton.styleFrom(
                            backgroundColor: QColors.orangeDark)
                        : null,
                    onPressed: _loading ? null : _signIn,
                    child: _loading
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              color: Colors.white,
                            ),
                          )
                        : Text(sar ? 'Login' : 'Sign in'),
                  ).animate().fadeIn(delay: 500.ms).slideY(begin: 0.3),
                  const SizedBox(height: 12),
                  if (sar)
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text(
                        '← Back to citizen sign in',
                        style: TextStyle(
                          color: QColors.brownSoft,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ).animate().fadeIn(delay: 600.ms)
                  else ...[
                    TextButton(
                      onPressed: () => Navigator.of(context).push(
                        MaterialPageRoute(
                            builder: (_) => const RegisterScreen()),
                      ),
                      child: const Text(
                        'New here? Create an account',
                        style: TextStyle(
                          color: QColors.brownSoft,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ).animate().fadeIn(delay: 600.ms),
                    TextButton.icon(
                      onPressed: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const LoginScreen(sarMode: true),
                        ),
                      ),
                      icon: const Icon(Icons.shield_outlined,
                          size: 18, color: QColors.brownSoft),
                      label: const Text(
                        'Search & Rescue personnel',
                        style: TextStyle(
                          color: QColors.brownSoft,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ).animate().fadeIn(delay: 700.ms),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
