import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/voting_provider.dart';
import '../services/tts_service.dart';
import '../theme.dart';
import 'ballot_screen.dart';
import 'vi_settings_screen.dart';

class ModeScreen extends StatefulWidget {
  const ModeScreen({super.key});

  @override
  State<ModeScreen> createState() => _ModeScreenState();
}

class _ModeScreenState extends State<ModeScreen> {
  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 500), () {
      // A delayed announcement must never fire after the voter has left this
      // screen -- it would cut off whatever the next screen is saying.
      if (!mounted) return;
      TtsService().speakAlways(
        'Welcome to Vote Right Mobil. How would you like to vote? '
        'Tap the top option for Normal touchscreen Mode. '
        'Tap the bottom option for Visually Impaired mode with full voice guidance and swipe navigation.',
      );
    });
  }

  void _selectNormal() {
    context.read<VotingProvider>().setAccessibilityMode(false);
    TtsService().setEnabled(false);
    TtsService().stop();
    Navigator.push(context, MaterialPageRoute(builder: (_) => const BallotScreen()));
  }

  void _selectVI() {
    context.read<VotingProvider>().setAccessibilityMode(true);
    TtsService().setEnabled(true);
    TtsService().speak(
      'Visually impaired mode selected. Voice guidance enabled. '
      'Next, customize your voice speed and text size.',
    );
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        Navigator.push(context, MaterialPageRoute(builder: (_) => const VISettingsScreen()));
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Focus(
      autofocus: true,
      onKeyEvent: (node, event) {
        if (event is! KeyDownEvent) return KeyEventResult.ignored;
        if (event.logicalKey == LogicalKeyboardKey.digit1 || event.logicalKey == LogicalKeyboardKey.numpad1) {
          _selectNormal();
          return KeyEventResult.handled;
        }
        if (event.logicalKey == LogicalKeyboardKey.digit2 || event.logicalKey == LogicalKeyboardKey.numpad2) {
          _selectVI();
          return KeyEventResult.handled;
        }
        if (event.logicalKey == LogicalKeyboardKey.keyL) {
          TtsService().speakAlways(
            'Mode selection. Tap top button for Normal Mode. '
            'Tap bottom button for Visually Impaired mode.',
          );
          return KeyEventResult.handled;
        }
        return KeyEventResult.ignored;
      },
      child: Scaffold(
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
            colors: [Color(0xFF1565C0), Color(0xFF42A5F5), Color(0xFF1976D2)],
          ),
        ),
        child: Stack(
          children: [
            // Red stripe top
            Positioned(
              top: 0, left: 0, right: 0,
              child: Container(height: 5, color: const Color(0xFFB31942)),
            ),
            Positioned(
              top: 8, left: 0, right: 0,
              child: Container(height: 2, color: const Color(0xFFB31942).withOpacity(0.4)),
            ),
            // Red stripe bottom
            Positioned(
              bottom: 0, left: 0, right: 0,
              child: Container(height: 5, color: const Color(0xFFB31942)),
            ),
            Positioned(
              bottom: 8, left: 0, right: 0,
              child: Container(height: 2, color: const Color(0xFFB31942).withOpacity(0.4)),
            ),
            // Corner stars
            Positioned(
              top: 20, left: 16,
              child: Icon(Icons.star, size: 14, color: Colors.white.withOpacity(0.08)),
            ),
            Positioned(
              top: 40, left: 32,
              child: Icon(Icons.star, size: 10, color: Colors.white.withOpacity(0.06)),
            ),
            Positioned(
              top: 20, right: 16,
              child: Icon(Icons.star, size: 14, color: Colors.white.withOpacity(0.08)),
            ),
            Positioned(
              top: 40, right: 32,
              child: Icon(Icons.star, size: 10, color: Colors.white.withOpacity(0.06)),
            ),
            // Main content
            SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                child: Column(
                  children: [
                    const SizedBox(height: 4),
                    // Logo
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFB31942).withOpacity(0.2),
                            blurRadius: 12,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Image.asset(
                          'assets/images/votrite_logo.png',
                          width: 50,
                          height: 50,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            width: 50, height: 50,
                            color: VotRiteTheme.white,
                            child: const Icon(Icons.how_to_vote, size: 28, color: VotRiteTheme.darkBlue),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'VotRite',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        letterSpacing: 2,
                      ),
                    ),
                    const SizedBox(height: 2),
                    const Text(
                      'How would you like to vote?',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: Colors.white,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 2),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(width: 20, height: 2, color: const Color(0xFFB31942)),
                        const SizedBox(width: 6),
                        Text(
                          'SELECT YOUR MODE',
                          style: TextStyle(
                            fontSize: 9,
                            color: VotRiteTheme.accentGold.withOpacity(0.9),
                            letterSpacing: 2,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(width: 20, height: 2, color: const Color(0xFFB31942)),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _ModeCard(
                      icon: Icons.touch_app,
                      title: 'Normal Mode',
                      subtitle: 'Use touch screen to navigate and vote',
                      accentColor: VotRiteTheme.primaryBlue,
                      onTap: _selectNormal,
                    ),
                    const SizedBox(height: 10),
                    _ModeCard(
                      icon: Icons.accessibility_new,
                      title: 'Visually Impaired',
                      subtitle: 'Voice guidance with keyboard or touch',
                      accentColor: const Color(0xFFB31942),
                      onTap: _selectVI,
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(
                        3,
                        (i) => Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: Icon(Icons.star, size: 10, color: VotRiteTheme.accentGold.withOpacity(0.4)),
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Voterite Inc.',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.white.withOpacity(0.5),
                        letterSpacing: 1,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextButton.icon(
                      icon: const Icon(Icons.arrow_back, color: Colors.white70, size: 16),
                      label: const Text('Back', style: TextStyle(fontSize: 12, color: Colors.white70)),
                      onPressed: () => Navigator.maybePop(context),
                    ),
                  ],
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

class _ModeCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color accentColor;
  final VoidCallback onTap;

  const _ModeCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.accentColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      elevation: 6,
      shadowColor: accentColor.withOpacity(0.3),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: accentColor.withOpacity(0.2), width: 1.5),
          ),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [accentColor.withOpacity(0.15), accentColor.withOpacity(0.05)],
                  ),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: accentColor.withOpacity(0.2)),
                ),
                child: Icon(icon, size: 22, color: accentColor),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: accentColor == VotRiteTheme.primaryBlue
                            ? VotRiteTheme.darkBlue
                            : const Color(0xFF8B1A2B),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                    ),
                  ],
                ),
              ),
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: accentColor.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.arrow_forward_ios, size: 16, color: accentColor),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
