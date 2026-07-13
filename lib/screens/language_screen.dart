import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/voting_provider.dart';
import '../services/tts_service.dart';
import '../theme.dart';
import 'mode_screen.dart';

class LanguageScreen extends StatefulWidget {
  const LanguageScreen({super.key});

  @override
  State<LanguageScreen> createState() => _LanguageScreenState();
}

class _LanguageScreenState extends State<LanguageScreen> {
  String? _selectedLang;

  // 'label' is what the voter reads on the card, so it is written in that
  // language -- someone who only reads Chinese has to be able to find their own
  // language here. 'spoken' is what the TTS voice says; it stays in English
  // because the engine is still on the English voice at this point and would
  // mangle a Chinese string.
  static const _languages = [
    {'code': 'en', 'label': 'English', 'spoken': 'English'},
    {'code': 'es', 'label': 'Español', 'spoken': 'Español'},
    {'code': 'zh-CN', 'label': '中文', 'spoken': 'Chinese'},
  ];

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 300), () {
      TtsService().speakAlways(
        'Choose your language. '
        'Press 1 for English. '
        'Press 2 for Español. '
        'Press 3 for Chinese.',
      );
    });
  }

  void _selectLanguage(String code) {
    setState(() => _selectedLang = code);
    final spoken = _languages.firstWhere((l) => l['code'] == code)['spoken']!;
    TtsService().speakAlways('$spoken selected.');
    context.read<VotingProvider>().setLanguage(code);
    Future.delayed(const Duration(milliseconds: 400), () {
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const ModeScreen()),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Focus(
      autofocus: true,
      onKeyEvent: (node, event) {
        if (event is! KeyDownEvent) return KeyEventResult.ignored;
        if (event.logicalKey == LogicalKeyboardKey.digit1 ||
            event.logicalKey == LogicalKeyboardKey.numpad1) {
          _selectLanguage('en');
          return KeyEventResult.handled;
        }
        if (event.logicalKey == LogicalKeyboardKey.digit2 ||
            event.logicalKey == LogicalKeyboardKey.numpad2) {
          _selectLanguage('es');
          return KeyEventResult.handled;
        }
        if (event.logicalKey == LogicalKeyboardKey.digit3 ||
            event.logicalKey == LogicalKeyboardKey.numpad3) {
          _selectLanguage('zh-CN');
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
              Positioned(
                top: 0, left: 0, right: 0,
                child: Container(height: 5, color: const Color(0xFFB31942)),
              ),
              Positioned(
                top: 8, left: 0, right: 0,
                child: Container(height: 2, color: const Color(0xFFB31942).withOpacity(0.4)),
              ),
              Positioned(
                bottom: 0, left: 0, right: 0,
                child: Container(height: 5, color: const Color(0xFFB31942)),
              ),
              Positioned(
                bottom: 8, left: 0, right: 0,
                child: Container(height: 2, color: const Color(0xFFB31942).withOpacity(0.4)),
              ),
              SafeArea(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                  child: Column(
                    children: [
                      const SizedBox(height: 4),
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
                        'Choose your language',
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
                            'SELECT LANGUAGE',
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
                      _LanguageCard(
                        icon: Icons.language,
                        title: 'English',
                        subtitle: 'Tap to continue in English',
                        accentColor: VotRiteTheme.primaryBlue,
                        isSelected: _selectedLang == 'en',
                        onTap: () => _selectLanguage('en'),
                      ),
                      const SizedBox(height: 10),
                      _LanguageCard(
                        icon: Icons.language,
                        title: 'Español',
                        subtitle: 'Toque para continuar en español',
                        accentColor: const Color(0xFFE65100),
                        isSelected: _selectedLang == 'es',
                        onTap: () => _selectLanguage('es'),
                      ),
                      const SizedBox(height: 10),
                      _LanguageCard(
                        icon: Icons.language,
                        title: '中文',
                        subtitle: '点按以继续使用中文',
                        accentColor: const Color(0xFFB31942),
                        isSelected: _selectedLang == 'zh-CN',
                        onTap: () => _selectLanguage('zh-CN'),
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

class _LanguageCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color accentColor;
  final bool isSelected;
  final VoidCallback onTap;

  const _LanguageCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.accentColor,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.white.withOpacity(0.12),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? Colors.white : Colors.white.withOpacity(0.2),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: isSelected ? accentColor : accentColor.withOpacity(0.3),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                isSelected ? Icons.check : icon,
                color: Colors.white,
                size: 22,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: isSelected ? VotRiteTheme.darkBlue : Colors.white,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 10,
                      color: isSelected
                          ? VotRiteTheme.darkBlue.withOpacity(0.6)
                          : Colors.white70,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              size: 14,
              color: isSelected ? VotRiteTheme.primaryBlue : Colors.white54,
            ),
          ],
        ),
      ),
    );
  }
}
