import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/voting_provider.dart';
import '../theme.dart';
import '../services/tts_service.dart';
import 'language_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _starController;
  late Animation<double> _fadeIn;
  late Animation<double> _starRotation;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _starController = AnimationController(
      duration: const Duration(seconds: 8),
      vsync: this,
    )..repeat();
    _fadeIn = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeIn),
    );
    _starRotation = Tween<double>(begin: 0.0, end: 2 * pi).animate(
      CurvedAnimation(parent: _starController, curve: Curves.linear),
    );
    _fadeController.forward();
    TtsService().init();
    TtsService().setEnabled(false);
    TtsService().stop();
    context.read<VotingProvider>().reset();
    Future.delayed(const Duration(milliseconds: 1500), () {
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const LanguageScreen()),
        );
      }
    });
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _starController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        // Fill the whole screen. Without this the Container sizes itself to its
        // child, so on any screen where the content is shorter than the display
        // the gradient stopped partway down and left a white band below it --
        // with the decorative bottom bar stranded in the middle of the screen.
        constraints: const BoxConstraints.expand(),
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF0A2463),
              Color(0xFF1565C0),
              Color(0xFF0D47A1),
            ],
          ),
        ),
        child: Stack(
          children: [
            // Decorative stars background
            AnimatedBuilder(
              animation: _starRotation,
              builder: (context, child) {
                return CustomPaint(
                  size: MediaQuery.of(context).size,
                  painter: _StarFieldPainter(_starRotation.value),
                );
              },
            ),
            // Red stripes at top
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Container(
                height: 6,
                color: const Color(0xFFB31942),
              ),
            ),
            Positioned(
              top: 10,
              left: 0,
              right: 0,
              child: Container(
                height: 3,
                color: const Color(0xFFB31942).withOpacity(0.5),
              ),
            ),
            // Red stripes at bottom
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                height: 6,
                color: const Color(0xFFB31942),
              ),
            ),
            Positioned(
              bottom: 10,
              left: 0,
              right: 0,
              child: Container(
                height: 3,
                color: const Color(0xFFB31942).withOpacity(0.5),
              ),
            ),
            // Main content
            Center(
              child: FadeTransition(
                opacity: _fadeIn,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Stars row above logo
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(
                        5,
                        (i) => Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 6),
                          child: Icon(
                            Icons.star,
                            size: 18,
                            color: VotRiteTheme.accentGold.withOpacity(0.7),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    // Logo
                    Container(
                      width: 140,
                      height: 140,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(28),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFB31942).withOpacity(0.3),
                            blurRadius: 30,
                            offset: const Offset(0, 8),
                          ),
                          BoxShadow(
                            color: Colors.blue.withOpacity(0.2),
                            blurRadius: 40,
                            spreadRadius: 5,
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(28),
                        child: Image.asset(
                          'assets/images/votrite_logo.png',
                          width: 140,
                          height: 140,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            color: VotRiteTheme.white,
                            child: const Icon(
                              Icons.how_to_vote,
                              size: 64,
                              color: VotRiteTheme.darkBlue,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 28),
                    // App name with flag-inspired styling
                    ShaderMask(
                      shaderCallback: (bounds) => const LinearGradient(
                        colors: [Colors.white, Color(0xFFE8E8E8), Colors.white],
                      ).createShader(bounds),
                      child: const Text(
                        'VotRite',
                        style: TextStyle(
                          fontSize: 30,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          letterSpacing: 3,
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    // Subtitle with red accent line
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 30,
                          height: 2,
                          color: const Color(0xFFB31942),
                        ),
                        const SizedBox(width: 12),
                        const Text(
                          'ACCESSIBLE MOBILE VOTING',
                          style: TextStyle(
                            fontSize: 11,
                            color: VotRiteTheme.accentGold,
                            letterSpacing: 3,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Container(
                          width: 30,
                          height: 2,
                          color: const Color(0xFFB31942),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Voterite Inc.',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.white.withOpacity(0.6),
                        letterSpacing: 1,
                      ),
                    ),
                    const SizedBox(height: 48),
                    // Loading indicator
                    SizedBox(
                      width: 36,
                      height: 36,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          VotRiteTheme.accentGold.withOpacity(0.8),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Stars row below
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(
                        3,
                        (i) => Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: Icon(
                            Icons.star,
                            size: 14,
                            color: VotRiteTheme.accentGold.withOpacity(0.5),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StarFieldPainter extends CustomPainter {
  final double rotation;
  _StarFieldPainter(this.rotation);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.04)
      ..style = PaintingStyle.fill;

    final positions = [
      Offset(size.width * 0.1, size.height * 0.15),
      Offset(size.width * 0.85, size.height * 0.1),
      Offset(size.width * 0.15, size.height * 0.85),
      Offset(size.width * 0.9, size.height * 0.8),
      Offset(size.width * 0.5, size.height * 0.05),
      Offset(size.width * 0.5, size.height * 0.95),
      Offset(size.width * 0.05, size.height * 0.5),
      Offset(size.width * 0.95, size.height * 0.5),
    ];

    for (int i = 0; i < positions.length; i++) {
      final p = positions[i];
      final starSize = 20.0 + (i % 3) * 10.0;
      canvas.save();
      canvas.translate(p.dx, p.dy);
      canvas.rotate(rotation + i * 0.5);
      _drawStar(canvas, paint, starSize);
      canvas.restore();
    }
  }

  void _drawStar(Canvas canvas, Paint paint, double size) {
    final path = Path();
    for (int i = 0; i < 5; i++) {
      final angle = (i * 4 * pi / 5) - pi / 2;
      final x = cos(angle) * size;
      final y = sin(angle) * size;
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_StarFieldPainter oldDelegate) =>
      oldDelegate.rotation != rotation;
}
