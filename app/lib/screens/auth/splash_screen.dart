import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../theme/app_theme.dart';
import '../../services/auth_service.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _logoCtrl;
  late Animation<double> _logoScale;
  late Animation<double> _logoFade;

  late AnimationController _textCtrl;
  late Animation<double> _textFade;
  late Animation<Offset> _textSlide;

  late AnimationController _tagCtrl;

  late AnimationController _dotsCtrl;

  late AnimationController _ringCtrl;
  late Animation<double> _ringRot;

  late AnimationController _glowCtrl;
  late Animation<double> _glowScale;

  late AnimationController _orb1Ctrl;
  late AnimationController _orb2Ctrl;
  late Animation<double> _orb1;
  late Animation<double> _orb2;

  @override
  void initState() {
    super.initState();
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.light);

    _logoCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _logoScale = Tween<double>(
      begin: 0.4,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _logoCtrl, curve: Curves.elasticOut));
    _logoFade = CurvedAnimation(
      parent: _logoCtrl,
      curve: const Interval(0.0, 0.5, curve: Curves.easeOut),
    );

    _textCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _textFade = CurvedAnimation(parent: _textCtrl, curve: Curves.easeOut);
    _textSlide = Tween<Offset>(
      begin: const Offset(0, 0.4),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _textCtrl, curve: Curves.easeOutCubic));

    _tagCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _dotsCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat();

    _ringCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat();
    _ringRot = Tween<double>(
      begin: 0,
      end: 2 * math.pi,
    ).animate(CurvedAnimation(parent: _ringCtrl, curve: Curves.linear));

    _glowCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);
    _glowScale = Tween<double>(
      begin: 0.9,
      end: 1.15,
    ).animate(CurvedAnimation(parent: _glowCtrl, curve: Curves.easeInOut));

    _orb1Ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3500),
    )..repeat(reverse: true);
    _orb2Ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 4200),
    )..repeat(reverse: true);
    _orb1 = Tween<double>(
      begin: -18,
      end: 18,
    ).animate(CurvedAnimation(parent: _orb1Ctrl, curve: Curves.easeInOut));
    _orb2 = Tween<double>(
      begin: 12,
      end: -20,
    ).animate(CurvedAnimation(parent: _orb2Ctrl, curve: Curves.easeInOut));

    _startSequence();
  }

  Future<void> _startSequence() async {
    _logoCtrl.forward();
    await Future.delayed(const Duration(milliseconds: 400));
    if (!mounted) return;
    _textCtrl.forward();
    await Future.delayed(const Duration(milliseconds: 300));
    if (!mounted) return;
    _tagCtrl.forward();
    await Future.delayed(const Duration(milliseconds: 3000));
    if (!mounted) return;
    final auth = context.read<AuthService>();
    context.go(auth.isLoggedIn ? '/dashboard' : '/login');
  }

  @override
  void dispose() {
    _logoCtrl.dispose();
    _textCtrl.dispose();
    _tagCtrl.dispose();
    _dotsCtrl.dispose();
    _ringCtrl.dispose();
    _glowCtrl.dispose();
    _orb1Ctrl.dispose();
    _orb2Ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: AppTheme.darkBg,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Background gradient
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Color(0xFF060E1A),
                  Color(0xFF0D1B2A),
                  Color(0xFF0A2040),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),

          // Orb top-right
          AnimatedBuilder(
            animation: _orb1,
            builder: (_, __) => Positioned(
              top: size.height * 0.08 + _orb1.value,
              right: -60,
              child: Container(
                width: 260,
                height: 260,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      AppTheme.primary.withOpacity(0.20),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Orb bottom-left
          AnimatedBuilder(
            animation: _orb2,
            builder: (_, __) => Positioned(
              bottom: size.height * 0.15 + _orb2.value,
              left: -80,
              child: Container(
                width: 300,
                height: 300,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      AppTheme.secondary.withOpacity(0.12),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Accent dots
          Positioned(
            top: size.height * 0.35,
            right: size.width * 0.12,
            child: Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppTheme.secondary.withOpacity(0.5),
              ),
            ),
          ),
          Positioned(
            top: size.height * 0.25,
            left: size.width * 0.15,
            child: Container(
              width: 5,
              height: 5,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppTheme.warning.withOpacity(0.4),
              ),
            ),
          ),

          // Center content
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Logo with ring + glow
                SizedBox(
                  width: 160,
                  height: 160,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Pulsing glow
                      ScaleTransition(
                        scale: _glowScale,
                        child: Container(
                          width: 130,
                          height: 130,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: RadialGradient(
                              colors: [
                                AppTheme.primary.withOpacity(0.30),
                                Colors.transparent,
                              ],
                            ),
                          ),
                        ),
                      ),

                      // Rotating dashed ring
                      AnimatedBuilder(
                        animation: _ringRot,
                        builder: (_, __) => Transform.rotate(
                          angle: _ringRot.value,
                          child: CustomPaint(
                            size: const Size(148, 148),
                            painter: _DashedRingPainter(),
                          ),
                        ),
                      ),

                      // Logo badge
                      ScaleTransition(
                        scale: _logoScale,
                        child: FadeTransition(
                          opacity: _logoFade,
                          child: Container(
                            width: 100,
                            height: 100,
                            decoration: BoxDecoration(
                              gradient: AppTheme.blueGradient,
                              borderRadius: BorderRadius.circular(28),
                              boxShadow: [
                                BoxShadow(
                                  color: AppTheme.primary.withOpacity(0.50),
                                  blurRadius: 32,
                                  offset: const Offset(0, 12),
                                ),
                                BoxShadow(
                                  color: AppTheme.primary.withOpacity(0.20),
                                  blurRadius: 60,
                                  spreadRadius: 4,
                                ),
                              ],
                            ),
                            child: const Center(
                              child: Text(
                                'B',
                                style: TextStyle(
                                  fontSize: 46,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.white,
                                  height: 1,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 32),

                // App name
                SlideTransition(
                  position: _textSlide,
                  child: FadeTransition(
                    opacity: _textFade,
                    child: const Text(
                      'BDOMate.AI',
                      style: TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                // Tagline pill
                FadeTransition(
                  opacity: _tagCtrl,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: Colors.white.withOpacity(0.14)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 7,
                          height: 7,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppTheme.secondary,
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'AI-Powered BDO Suite',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.white70,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.3,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 10),

                // University name
                FadeTransition(
                  opacity: _tagCtrl,
                  child: const Text(
                    'University of South Asia',
                    style: TextStyle(
                      fontSize: 12,
                      color: Color(0xFF475569),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Bottom animated dots
          Positioned(
            bottom: 60,
            left: 0,
            right: 0,
            child: Center(
              child: AnimatedBuilder(
                animation: _dotsCtrl,
                builder: (_, __) => Row(
                  mainAxisSize: MainAxisSize.min,
                  children: List.generate(3, (i) {
                    final delay = i / 3;
                    final anim = ((_dotsCtrl.value - delay) % 1.0).clamp(
                      0.0,
                      1.0,
                    );
                    final opacity = math.sin(anim * math.pi).clamp(0.2, 1.0);
                    final scale = 0.6 + (0.4 * math.sin(anim * math.pi));
                    return Container(
                      margin: const EdgeInsets.symmetric(horizontal: 5),
                      width: 8 * scale,
                      height: 8 * scale,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: i == 1
                            ? AppTheme.secondary.withOpacity(opacity)
                            : AppTheme.primary.withOpacity(opacity),
                      ),
                    );
                  }),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Dashed ring painter
class _DashedRingPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..color = AppTheme.primary.withOpacity(0.35);

    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    const dashCount = 24;
    const dashLength = 0.12;
    const gap = (2 * math.pi / dashCount) - dashLength;

    for (int i = 0; i < dashCount; i++) {
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        i * (dashLength + gap),
        dashLength,
        false,
        paint,
      );
    }

    // Teal dot on ring
    canvas.drawCircle(
      Offset(center.dx + radius, center.dy),
      3.5,
      Paint()..color = AppTheme.secondary.withOpacity(0.8),
    );
  }

  @override
  bool shouldRepaint(_DashedRingPainter old) => false;
}
