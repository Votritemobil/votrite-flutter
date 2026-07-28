import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/voting_provider.dart';
import '../services/tts_service.dart';
import '../theme.dart';
import 'ballot_screen.dart';

class VISettingsScreen extends StatefulWidget {
  const VISettingsScreen({super.key});

  @override
  State<VISettingsScreen> createState() => _VISettingsScreenState();
}

class _VISettingsScreenState extends State<VISettingsScreen> {
  double _speechRate = 0.45;
  double _textScale = 1.3;
  final _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _speechRate = TtsService().currentRate;
    Future.delayed(const Duration(milliseconds: 500), () {
      // A delayed announcement must never fire after the voter has left this
      // screen -- it would cut off whatever the next screen is saying.
      if (!mounted) return;
      TtsService().speak(
        'Accessibility settings. '
        'Adjust your voice speed and text size before voting. '
        'Use the sliders to change settings, then tap Continue at the bottom.',
      );
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  String _speedLabel(double rate) {
    if (rate <= 0.3) return 'Slow';
    if (rate <= 0.5) return 'Normal';
    if (rate <= 0.65) return 'Fast';
    return 'Very Fast';
  }

  String _sizeLabel(double scale) {
    if (scale <= 1.0) return 'Standard';
    if (scale <= 1.3) return 'Large';
    return 'Extra Large';
  }

  void _proceed() {
    final provider = context.read<VotingProvider>();
    provider.setViZoomScale(_textScale);
    TtsService().speak('Settings saved. Next, select your ballot.');
    Future.delayed(const Duration(seconds: 2), () {
      if (!mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const BallotScreen()),
      );
    });
  }

  KeyEventResult _handleKey(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;
    final key = event.logicalKey;

    if (key == LogicalKeyboardKey.keyJ || key == LogicalKeyboardKey.enter) {
      _proceed();
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.keyD || key == LogicalKeyboardKey.escape) {
      Navigator.maybePop(context);
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.keyL) {
      TtsService().speak(
        'Settings screen. Use the sliders to adjust voice speed and text size. '
        'Press J or Enter to continue to login. Press D to go back.',
      );
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    return Focus(
      focusNode: _focusNode,
      autofocus: true,
      onKeyEvent: _handleKey,
      child: Scaffold(
        appBar: AppBar(
          title: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Image.asset('assets/images/votrite_logo.png', width: 28, height: 28),
              const SizedBox(width: 8),
              const Text('Settings'),
            ],
          ),
        ),
        body: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Icon(Icons.settings_accessibility, size: 48, color: VotRiteTheme.primaryBlue),
              const SizedBox(height: 12),
              const Text(
                'Customize Your Experience',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: VotRiteTheme.darkBlue),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 28),
              Semantics(
                label: 'Voice speed: ${_speedLabel(_speechRate)}',
                slider: true,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Voice Speed: ${_speedLabel(_speechRate)}',
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.slow_motion_video, size: 20),
                        Expanded(
                          child: Slider(
                            value: _speechRate,
                            min: 0.2,
                            max: 0.8,
                            divisions: 6,
                            label: _speedLabel(_speechRate),
                            onChanged: (value) {
                              setState(() => _speechRate = value);
                              TtsService().setSpeechRate(value);
                              TtsService().speak('Voice speed: ${_speedLabel(value)}');
                            },
                          ),
                        ),
                        const Icon(Icons.speed, size: 20),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Semantics(
                label: 'Text size: ${_sizeLabel(_textScale)}',
                slider: true,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Text Size: ${_sizeLabel(_textScale)}',
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Text('A', style: TextStyle(fontSize: 14)),
                        Expanded(
                          child: Slider(
                            value: _textScale,
                            min: 1.0,
                            max: 1.6,
                            divisions: 3,
                            label: _sizeLabel(_textScale),
                            onChanged: (value) {
                              setState(() => _textScale = value);
                              TtsService().speak('Text size: ${_sizeLabel(value)}');
                            },
                          ),
                        ),
                        const Text('A', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: VotRiteTheme.lightGray,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: VotRiteTheme.primaryBlue.withOpacity(0.3)),
                ),
                child: Text(
                  'Preview: This is how text will appear during voting.',
                  style: TextStyle(fontSize: 14 * _textScale),
                  textAlign: TextAlign.center,
                ),
              ),
              const Spacer(),
              ElevatedButton(
                onPressed: _proceed,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 18),
                ),
                child: const Text('Continue to Ballot', style: TextStyle(fontSize: 18)),
              ),
              const SizedBox(height: 8),
              TextButton.icon(
                icon: const Icon(Icons.arrow_back, size: 18),
                label: const Text('Back', style: TextStyle(fontSize: 14)),
                onPressed: () => Navigator.maybePop(context),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
