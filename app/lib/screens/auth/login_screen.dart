import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../theme/app_theme.dart';
import '../../services/auth_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController(text: '');
  final _passCtrl = TextEditingController(text: '');
  bool _obscure = true;
  bool _remember = true;

  late AnimationController _entranceCtrl;
  late AnimationController _float1Ctrl;
  late AnimationController _float2Ctrl;
  late Animation<double> _cardSlide;
  late Animation<double> _cardFade;
  late Animation<double> _float1;
  late Animation<double> _float2;

  @override
  void initState() {
    super.initState();
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.light);

    _entranceCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _float1Ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3200),
    )..repeat(reverse: true);
    _float2Ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 4100),
    )..repeat(reverse: true);

    _cardSlide = Tween<double>(begin: 60, end: 0).animate(
      CurvedAnimation(parent: _entranceCtrl, curve: Curves.easeOutCubic),
    );
    _cardFade = CurvedAnimation(parent: _entranceCtrl, curve: Curves.easeOut);
    _float1 = Tween<double>(
      begin: -12,
      end: 12,
    ).animate(CurvedAnimation(parent: _float1Ctrl, curve: Curves.easeInOut));
    _float2 = Tween<double>(
      begin: 8,
      end: -16,
    ).animate(CurvedAnimation(parent: _float2Ctrl, curve: Curves.easeInOut));

    _entranceCtrl.forward();
  }

  @override
  void dispose() {
    _entranceCtrl.dispose();
    _float1Ctrl.dispose();
    _float2Ctrl.dispose();
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    HapticFeedback.mediumImpact();
    final auth = context.read<AuthService>();
    final success = await auth.login(_emailCtrl.text, _passCtrl.text);
    if (success && mounted) {
      context.go('/dashboard');
    } else if (mounted) {
      HapticFeedback.heavyImpact();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(auth.error ?? 'Login failed'),
          backgroundColor: AppTheme.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthService>();

    return Scaffold(
      backgroundColor: AppTheme.darkBg,
      // Ensures the screen resizes dynamically when keyboard displays
      resizeToAvoidBottomInset: true,
      body: Stack(
        children: [
          // ── Deep gradient background ──────────────────────────
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Color(0xFF0A1628),
                  Color(0xFF0D2045),
                  Color(0xFF0D1B2A),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),

          // ── Floating decorative orbs ──────────────────────────
          AnimatedBuilder(
            animation: _float1,
            builder: (_, __) => Positioned(
              top: 80 + _float1.value,
              right: -60,
              child: Container(
                width: 220,
                height: 220,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      AppTheme.primary.withOpacity(0.25),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
          ),

          AnimatedBuilder(
            animation: _float2,
            builder: (_, __) => Positioned(
              top: 160 + _float2.value,
              left: -80,
              child: Container(
                width: 260,
                height: 260,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      AppTheme.secondary.withOpacity(0.15),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
          ),

          Positioned(
            bottom: 120,
            right: -40,
            child: Container(
              width: 160,
              height: 160,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppTheme.warning.withOpacity(0.08),
              ),
            ),
          ),

          // ── Main content wrapper ────────────────────────────────
          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  // 🔑 Fixed: ClampingScrollPhysics prevents unwanted stretching layout overflows on bounce
                  physics: const ClampingScrollPhysics(),
                  child: ConstrainedBox(
                    // 🔑 Fixed: Restricts layout constraints to guarantee content always fills screen view accurately
                    constraints: BoxConstraints(
                      minHeight: constraints.maxHeight,
                    ),
                    child: IntrinsicHeight(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: AnimatedBuilder(
                          animation: Listenable.merge([_cardSlide, _cardFade]),
                          builder: (_, child) => Transform.translate(
                            offset: Offset(0, _cardSlide.value),
                            child: Opacity(
                              opacity: _cardFade.value,
                              child: child,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 36),

                              // Logo + app name
                              Row(
                                children: [
                                  Container(
                                    width: 48,
                                    height: 48,
                                    decoration: BoxDecoration(
                                      gradient: AppTheme.blueGradient,
                                      borderRadius: BorderRadius.circular(14),
                                      boxShadow: AppTheme.glowShadow,
                                    ),
                                    child: const Center(
                                      child: Text(
                                        'B',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w900,
                                          fontSize: 24,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  const Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'BDOMate.AI',
                                        style: TextStyle(
                                          fontSize: 22,
                                          fontWeight: FontWeight.w900,
                                          color: Colors.white,
                                          letterSpacing: 0.2,
                                        ),
                                      ),
                                      Text(
                                        'Business Development Suite',
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: Color(0xFF64748B),
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),

                              const SizedBox(height: 32),

                              const Text(
                                'Welcome back',
                                style: TextStyle(
                                  fontSize: 32,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 6),
                              const Text(
                                'Sign in to your account',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Color(0xFF64748B),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),

                              const SizedBox(height: 28),

                              // ── Form card ─────────────────────────────────
                              ClipRRect(
                                borderRadius: BorderRadius.circular(24),
                                child: BackdropFilter(
                                  filter: ImageFilter.blur(
                                    sigmaX: 10,
                                    sigmaY: 10,
                                  ),
                                  child: Container(
                                    padding: const EdgeInsets.all(24),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.06),
                                      borderRadius: BorderRadius.circular(24),
                                      border: Border.all(
                                        color: Colors.white.withOpacity(0.10),
                                        width: 1,
                                      ),
                                    ),
                                    child: Form(
                                      key: _formKey,
                                      child: Column(
                                        children: [
                                          _DarkTextField(
                                            controller: _emailCtrl,
                                            label: 'Email address',
                                            icon: Icons.email_outlined,
                                            keyboardType:
                                                TextInputType.emailAddress,
                                            validator: (v) =>
                                                (v?.isEmpty ?? true)
                                                ? 'Enter your email'
                                                : null,
                                          ),
                                          const SizedBox(height: 14),
                                          _DarkTextField(
                                            controller: _passCtrl,
                                            label: 'Password',
                                            icon: Icons.lock_outline_rounded,
                                            obscure: _obscure,
                                            suffixIcon: IconButton(
                                              icon: Icon(
                                                _obscure
                                                    ? Icons
                                                          .visibility_off_outlined
                                                    : Icons.visibility_outlined,
                                                color: const Color(0xFF64748B),
                                                size: 20,
                                              ),
                                              onPressed: () => setState(
                                                () => _obscure = !_obscure,
                                              ),
                                            ),
                                            validator: (v) =>
                                                (v?.length ?? 0) < 6
                                                ? 'Enter your password'
                                                : null,
                                          ),

                                          const SizedBox(height: 16),

                                          Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
                                            children: [
                                              GestureDetector(
                                                onTap: () => setState(
                                                  () => _remember = !_remember,
                                                ),
                                                child: Row(
                                                  children: [
                                                    AnimatedContainer(
                                                      duration: const Duration(
                                                        milliseconds: 200,
                                                      ),
                                                      width: 20,
                                                      height: 20,
                                                      decoration: BoxDecoration(
                                                        gradient: _remember
                                                            ? AppTheme
                                                                  .blueGradient
                                                            : null,
                                                        color: _remember
                                                            ? null
                                                            : Colors
                                                                  .transparent,
                                                        borderRadius:
                                                            BorderRadius.circular(
                                                              6,
                                                            ),
                                                        border: Border.all(
                                                          color: _remember
                                                              ? Colors
                                                                    .transparent
                                                              : Colors.white24,
                                                          width: 1.5,
                                                        ),
                                                      ),
                                                      child: _remember
                                                          ? const Icon(
                                                              Icons
                                                                  .check_rounded,
                                                              color:
                                                                  Colors.white,
                                                              size: 14,
                                                            )
                                                          : null,
                                                    ),
                                                    const SizedBox(width: 8),
                                                    const Text(
                                                      'Remember me',
                                                      style: TextStyle(
                                                        color: Color(
                                                          0xFF94A3B8,
                                                        ),
                                                        fontSize: 13,
                                                        fontWeight:
                                                            FontWeight.w500,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              TextButton(
                                                onPressed: () => context.go(
                                                  '/forgot-password',
                                                ),
                                                child: const Text(
                                                  'Forgot password?',
                                                  style: TextStyle(
                                                    color: AppTheme.primary,
                                                    fontSize: 13,
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),

                                          const SizedBox(height: 24),

                                          SizedBox(
                                            width: double.infinity,
                                            height: 52,
                                            child: DecoratedBox(
                                              decoration: BoxDecoration(
                                                gradient: AppTheme.blueGradient,
                                                borderRadius:
                                                    BorderRadius.circular(16),
                                                boxShadow: AppTheme.glowShadow,
                                              ),
                                              child: ElevatedButton(
                                                onPressed: auth.isLoading
                                                    ? null
                                                    : _login,
                                                style: ElevatedButton.styleFrom(
                                                  backgroundColor:
                                                      Colors.transparent,
                                                  shadowColor:
                                                      Colors.transparent,
                                                  shape: RoundedRectangleBorder(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          16,
                                                        ),
                                                  ),
                                                ),
                                                child: auth.isLoading
                                                    ? const SizedBox(
                                                        width: 22,
                                                        height: 22,
                                                        child:
                                                            CircularProgressIndicator(
                                                              color:
                                                                  Colors.white,
                                                              strokeWidth: 2.5,
                                                            ),
                                                      )
                                                    : const Text(
                                                        'Sign In',
                                                        style: TextStyle(
                                                          fontSize: 16,
                                                          fontWeight:
                                                              FontWeight.w800,
                                                          color: Colors.white,
                                                        ),
                                                      ),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ),

                              const Spacer(), // Pushes registration text downwards layout permitting
                              const SizedBox(height: 24),

                              // Register link
                              Center(
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Text(
                                      "Don't have an account? ",
                                      style: TextStyle(
                                        color: Color(0xFF64748B),
                                        fontSize: 14,
                                      ),
                                    ),
                                    GestureDetector(
                                      onTap: () => context.go('/register'),
                                      child: const Text(
                                        'Sign up',
                                        style: TextStyle(
                                          color: AppTheme.primary,
                                          fontSize: 14,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 24),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _DarkTextField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final IconData icon;
  final bool obscure;
  final Widget? suffixIcon;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;

  const _DarkTextField({
    required this.controller,
    required this.label,
    required this.icon,
    this.obscure = false,
    this.suffixIcon,
    this.keyboardType,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      obscureText: obscure,
      keyboardType: keyboardType,
      validator: validator,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 15,
        fontFamily: 'Nunito',
      ),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(
          color: Color(0xFF64748B),
          fontSize: 14,
          fontFamily: 'Nunito',
        ),
        prefixIcon: Icon(icon, color: const Color(0xFF64748B), size: 20),
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: Colors.white.withOpacity(0.07),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.12)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.12)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppTheme.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppTheme.error),
        ),
      ),
    );
  }
}
