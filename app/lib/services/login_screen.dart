// lib/screens/auth/login_screen.dart
//
// FIX 1 — Frontend email validator uses a proper regex (not just !v.contains('@')).
// FIX 1 — On failed login the backend's error message (e.g. "Invalid credentials")
//          is shown in a styled SnackBar — the user is never silently logged in.

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../theme/app_theme.dart';
import '../../services/auth_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey    = GlobalKey<FormState>();
  final _emailCtrl  = TextEditingController();
  final _passCtrl   = TextEditingController();
  bool  _obscure    = true;
  bool  _rememberMe = false;

  // FIX 1 — RFC-5322-lite regex; catches "user@", "@domain.com", "nodomain", etc.
  static final _emailRegex = RegExp(
    r'^[a-zA-Z0-9._%+\-]+@[a-zA-Z0-9.\-]+\.[a-zA-Z]{2,}$',
  );

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    final auth    = context.read<AuthService>();
    final success = await auth.login(_emailCtrl.text.trim(), _passCtrl.text);

    if (!mounted) return;

    if (success) {
      context.go('/dashboard');
    } else {
      // FIX 1 — always shows the error; never navigates on failure
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error_outline, color: Colors.white, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  auth.error ?? 'Login failed. Please try again.',
                  style: const TextStyle(fontSize: 14),
                ),
              ),
            ],
          ),
          backgroundColor: AppTheme.error,
          behavior:        SnackBarBehavior.floating,
          shape:           RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          margin:          const EdgeInsets.all(12),
          duration:        const Duration(seconds: 4),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthService>();

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [AppTheme.gradientStart, AppTheme.gradientEnd],
            begin:  Alignment.topLeft,
            end:    Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // ── Header ─────────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      Container(
                        padding:    const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color:        Colors.white,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Text(
                          'P+',
                          style: TextStyle(
                            fontSize:   18,
                            fontWeight: FontWeight.w900,
                            color:      AppTheme.primary,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        'PartnerPlus.AI',
                        style: TextStyle(
                          fontSize:   20,
                          fontWeight: FontWeight.w800,
                          color:      Colors.white,
                        ),
                      ),
                    ]),
                    const SizedBox(height: 32),
                    const Text(
                      'Welcome Back!',
                      style: TextStyle(
                        fontSize:   30,
                        fontWeight: FontWeight.w800,
                        color:      Colors.white,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Sign in to your BDO dashboard',
                      style: TextStyle(
                        fontSize: 15,
                        color:    Colors.white.withOpacity(0.8),
                      ),
                    ),
                  ],
                ),
              ),

              // ── Form card ──────────────────────────────────────────────
              Expanded(
                child: Container(
                  decoration: const BoxDecoration(
                    color:        AppTheme.surface,
                    borderRadius: BorderRadius.only(
                      topLeft:  Radius.circular(32),
                      topRight: Radius.circular(32),
                    ),
                  ),
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(28),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const SizedBox(height: 8),

                          // Email field
                          TextFormField(
                            controller:   _emailCtrl,
                            keyboardType: TextInputType.emailAddress,
                            decoration: const InputDecoration(
                              labelText:  'Email Address',
                              prefixIcon: Icon(Icons.email_outlined),
                            ),
                            // FIX 1 — proper regex replaces the old !v.contains('@') check
                            validator: (v) {
                              if (v == null || v.trim().isEmpty) {
                                return 'Email is required';
                              }
                              if (!_emailRegex.hasMatch(v.trim())) {
                                return 'Enter a valid email (e.g. name@domain.com)';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),

                          // Password field
                          TextFormField(
                            controller:  _passCtrl,
                            obscureText: _obscure,
                            decoration: InputDecoration(
                              labelText:  'Password',
                              prefixIcon: const Icon(Icons.lock_outline),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscure
                                      ? Icons.visibility_outlined
                                      : Icons.visibility_off_outlined,
                                ),
                                onPressed: () =>
                                    setState(() => _obscure = !_obscure),
                              ),
                            ),
                            validator: (v) =>
                                v == null || v.length < 6
                                    ? 'Password must be at least 6 characters'
                                    : null,
                          ),
                          const SizedBox(height: 12),

                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(children: [
                                Checkbox(
                                  value:       _rememberMe,
                                  onChanged:   (v) =>
                                      setState(() => _rememberMe = v ?? false),
                                  activeColor: AppTheme.primary,
                                ),
                                const Text(
                                  'Remember me',
                                  style: TextStyle(fontSize: 13),
                                ),
                              ]),
                              TextButton(
                                onPressed: () => context.push('/forgot-password'),
                                child: const Text(
                                  'Forgot Password?',
                                  style: TextStyle(fontSize: 13),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),

                          // Sign In button
                          ElevatedButton(
                            onPressed: auth.isLoading ? null : _login,
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                            ),
                            child: auth.isLoading
                                ? const SizedBox(
                                    height: 20,
                                    width:  20,
                                    child:  CircularProgressIndicator(
                                      color:       Colors.white,
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Text(
                                    'Sign In',
                                    style: TextStyle(
                                      fontSize:   16,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                          ),
                          const SizedBox(height: 24),

                          const Row(children: [
                            Expanded(child: Divider()),
                            Padding(
                              padding: EdgeInsets.symmetric(horizontal: 12),
                              child:   Text(
                                'OR',
                                style: TextStyle(
                                  color:    AppTheme.textSecondary,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                            Expanded(child: Divider()),
                          ]),
                          const SizedBox(height: 20),

                          OutlinedButton.icon(
                            onPressed: () {},
                            icon:  const Icon(Icons.account_circle_outlined),
                            label: const Text('Continue with University SSO'),
                          ),
                          const SizedBox(height: 28),

                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Text(
                                "Don't have an account? ",
                                style: TextStyle(color: AppTheme.textSecondary),
                              ),
                              TextButton(
                                onPressed: () => context.go('/register'),
                                child: const Text(
                                  'Sign Up',
                                  style: TextStyle(
                                    color:      AppTheme.primary,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Center(
                            child: Text(
                              'University of South Asia – BDO Portal',
                              style: TextStyle(
                                fontSize: 11,
                                color:    AppTheme.textSecondary.withOpacity(0.6),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
