import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/voting_provider.dart';
import '../services/tts_service.dart';
import '../theme.dart';
import 'race_screen.dart';
import 'splash_screen.dart';

class LoginScreen extends StatefulWidget {
  final bool accessibilityMode;
  const LoginScreen({super.key, this.accessibilityMode = false});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _pinController = TextEditingController();
  final _pinFocusNode = FocusNode();
  bool _loading = false;
  String? _error;
  bool _obscurePin = true;

  @override
  void initState() {
    super.initState();
    _pinController.addListener(_onPinChanged);
    Future.delayed(const Duration(milliseconds: 500), () {
      TtsService().speak(
        'Secure voter login. '
        'Tap the PIN field in the center of the screen to open the number pad. '
        'Type your 5 digit PIN. The app will log you in automatically after you enter your PIN. '
        'Or swipe left after entering your PIN to log in.',
      );
    });
  }

  @override
  void dispose() {
    _pinController.removeListener(_onPinChanged);
    _pinController.dispose();
    _pinFocusNode.dispose();
    super.dispose();
  }

  void _onPinChanged() {
    final val = _pinController.text.trim();
    if (val.length >= 5 && RegExp(r'^\d+$').hasMatch(val)) {
      _pinFocusNode.unfocus();
      TtsService().speak('PIN entered. Logging in now.');
      Future.delayed(const Duration(milliseconds: 800), () {
        if (mounted && !_loading) _login();
      });
    }
  }

  Future<void> _login() async {
    final pin = _pinController.text.trim();
    if (pin.isEmpty) {
      setState(() => _error = 'Please enter your PIN code');
      TtsService().speak('Please enter your PIN code.');
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    final provider = context.read<VotingProvider>();
    try {
      final result = await provider.validatePin(provider.selectedBallot!.ballotId, pin);
      if (!mounted) return;

      if (result == null) {
        setState(() {
          _loading = false;
          _error = 'Invalid PIN code. Please try again.';
        });
        TtsService().speak('Invalid PIN code. Please try again.');
        return;
      }

      final isUsed = result['is_used']?.toString() == 'true';
      if (isUsed) {
        setState(() {
          _loading = false;
          _error = 'This PIN has already been used.';
        });
        TtsService().speak('This PIN has already been used.');
        return;
      }

      provider.setPin(pin);
      await provider.loadRacesAndPropositions();

      if (!mounted) return;
      TtsService().stop();
      Navigator.push(context, MaterialPageRoute(builder: (_) => const RaceScreen()));
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'Connection error. Please try again.';
      });
      TtsService().speak('Connection error. Please try again.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final ballotName = context.read<VotingProvider>().selectedBallot?.election ?? 'Ballot';

    return Focus(
      onKeyEvent: (node, event) {
        if (event is! KeyDownEvent) return KeyEventResult.ignored;
        if (event.logicalKey == LogicalKeyboardKey.keyL) {
          TtsService().speak(
            'Login screen. Tap the PIN field to open the number pad. '
            'Type your PIN digits. The app logs in automatically. '
            'Or swipe left to log in.',
          );
          return KeyEventResult.handled;
        }
        if (event.logicalKey == LogicalKeyboardKey.enter) {
          if (!_loading) _login();
          return KeyEventResult.handled;
        }
        return KeyEventResult.ignored;
      },
      child: GestureDetector(
        onHorizontalDragEnd: (details) {
          if (details.primaryVelocity != null && details.primaryVelocity! < -200) {
            if (!_loading) _login();
          }
        },
        child: Scaffold(
      resizeToAvoidBottomInset: true,
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
            stops: [0.0, 0.35, 1.0],
            colors: [Color(0xFF0A2463), Color(0xFF1565C0), Colors.white],
          ),
        ),
        child: SafeArea(
          child: Stack(
            children: [
              Positioned(
                top: 8,
                right: 8,
                child: PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert, color: Colors.white70),
                  onSelected: (value) {
                    if (value == 'start_over') {
                      context.read<VotingProvider>().reset();
                      Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(builder: (_) => const SplashScreen()),
                        (route) => false,
                      );
                    }
                  },
                  itemBuilder: (_) => [
                    const PopupMenuItem(
                      value: 'start_over',
                      child: Row(
                        children: [
                          Icon(Icons.refresh, size: 20, color: VotRiteTheme.primaryBlue),
                          SizedBox(width: 8),
                          Text('Start Over'),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 28),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                        // Stars row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      3,
                      (i) => Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 5),
                        child: Icon(Icons.star, size: 14, color: VotRiteTheme.accentGold.withOpacity(0.7)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Logo with glow
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFB31942).withOpacity(0.2),
                          blurRadius: 16,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: Image.asset(
                        'assets/images/votrite_logo.png',
                        width: 80,
                        height: 80,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          width: 80, height: 80,
                          color: VotRiteTheme.white,
                          child: const Icon(Icons.how_to_vote, size: 40, color: VotRiteTheme.darkBlue),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    ballotName,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(width: 20, height: 2, color: const Color(0xFFB31942).withOpacity(0.6)),
                      const SizedBox(width: 8),
                      Text(
                        'SECURE VOTER LOGIN',
                        style: TextStyle(
                          fontSize: 11,
                          color: VotRiteTheme.accentGold.withOpacity(0.9),
                          letterSpacing: 2,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(width: 20, height: 2, color: const Color(0xFFB31942).withOpacity(0.6)),
                    ],
                  ),
                  const SizedBox(height: 20),
                  // PIN card
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: VotRiteTheme.primaryBlue.withOpacity(0.15),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.lock_outline, size: 20, color: VotRiteTheme.primaryBlue.withOpacity(0.6)),
                            const SizedBox(width: 8),
                            const Text(
                              'Enter your PIN code',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: VotRiteTheme.darkBlue,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        SizedBox(
                          width: 260,
                          child: TextField(
                            controller: _pinController,
                            focusNode: _pinFocusNode,
                            autofocus: false,
                            obscureText: _obscurePin,
                            keyboardType: TextInputType.number,
                            textInputAction: TextInputAction.done,
                            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                            textAlign: TextAlign.center,
                            style: const TextStyle(fontSize: 18, letterSpacing: 6),
                            maxLength: 10,
                            decoration: InputDecoration(
                              hintText: '-----',
                              hintStyle: const TextStyle(letterSpacing: 8, color: Colors.grey),
                              counterText: '',
                              filled: true,
                              fillColor: Colors.grey.shade50,
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: Colors.grey.shade300),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(color: VotRiteTheme.primaryBlue, width: 2),
                              ),
                              suffixIcon: IconButton(
                                icon: Icon(_obscurePin ? Icons.visibility : Icons.visibility_off),
                                onPressed: () => setState(() => _obscurePin = !_obscurePin),
                              ),
                            ),
                            onSubmitted: (_) => _login(),
                          ),
                        ),
                        if (_error != null) ...[
                          const SizedBox(height: 14),
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Colors.red.shade50,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.red.shade200),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.error_outline, color: VotRiteTheme.errorRed, size: 18),
                                const SizedBox(width: 8),
                                Flexible(child: Text(_error!, style: const TextStyle(color: VotRiteTheme.errorRed, fontSize: 13))),
                              ],
                            ),
                          ),
                        ],
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _loading ? null : _login,
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                            child: _loading
                                ? const SizedBox(
                                    height: 20, width: 20,
                                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                                  )
                                : const Text('Login', style: TextStyle(fontSize: 16)),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  TextButton.icon(
                    icon: const Icon(Icons.arrow_back, size: 18),
                    label: const Text('Back', style: TextStyle(fontSize: 13)),
                    onPressed: () => Navigator.maybePop(context),
                  ),
                        const SizedBox(height: 8),
                        VotRiteTheme.footer(color: Colors.grey),
                        const SizedBox(height: 8),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      ),
    );
  }
}
