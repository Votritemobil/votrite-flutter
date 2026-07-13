import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/voting_provider.dart';
import '../services/tts_service.dart';
import '../theme.dart';
import 'help_screen.dart';
import 'review_screen.dart';

class PropositionScreen extends StatefulWidget {
  const PropositionScreen({super.key});

  @override
  State<PropositionScreen> createState() => _PropositionScreenState();
}

class _PropositionScreenState extends State<PropositionScreen> {
  final _focusNode = FocusNode();
  int _currentPropIndex = 0;

  @override
  void initState() {
    super.initState();
    _announceCurrentProp();
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  void _announceCurrentProp() {
    final provider = context.read<VotingProvider>();
    if (provider.propositions.isEmpty) return;
    final prop = provider.propositions[_currentPropIndex];
    final currentVote = prop.vote == 1 ? 'Currently voted ${prop.yesLabel}' : prop.vote == 2 ? 'Currently voted ${prop.noLabel}' : 'No vote yet';
    final tts = TtsService();
    tts.speak(
      'Proposition ${_currentPropIndex + 1} of ${provider.propositions.length}. '
      '${prop.propTitle}. ${prop.propText}. '
      '$currentVote. '
      'Tap ${prop.yesLabel} or ${prop.noLabel} to vote. '
      'Swipe left for next. Swipe right for previous.',
    );
  }

  void _vote(int value) {
    final provider = context.read<VotingProvider>();
    final prop = provider.propositions[_currentPropIndex];
    if (prop.vote == value) {
      provider.savePropositionVote(prop.propositionId, 0);
      setState(() {});
      TtsService().speak('Cleared vote on ${prop.propTitle}.');
    } else {
      provider.savePropositionVote(prop.propositionId, value);
      setState(() {});
      final label = value == 1 ? prop.yesLabel : prop.noLabel;
      TtsService().speak('Voted $label on ${prop.propTitle}.');
    }
  }

  void _nextProp() {
    final provider = context.read<VotingProvider>();
    if (_currentPropIndex < provider.propositions.length - 1) {
      setState(() => _currentPropIndex++);
      _announceCurrentProp();
    } else {
      TtsService().speak('All propositions complete. Proceeding to review.');
      Navigator.push(context, MaterialPageRoute(builder: (_) => const ReviewScreen()));
    }
  }

  void _prevProp() {
    if (_currentPropIndex > 0) {
      setState(() => _currentPropIndex--);
      _announceCurrentProp();
    }
  }

  KeyEventResult _handleKey(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;
    final key = event.logicalKey;

    if (key == LogicalKeyboardKey.keyF) {
      _vote(1); // YES/FOR
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.keyK) {
      _vote(2); // NO/AGAINST
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.keyJ || key == LogicalKeyboardKey.enter) {
      _nextProp();
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.keyD || key == LogicalKeyboardKey.escape) {
      _prevProp();
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.keyS) {
      _announceCurrentProp();
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.keyL) {
      final provider = context.read<VotingProvider>();
      final prop = provider.propositions[_currentPropIndex];
      TtsService().speak(
        'Proposition screen. Tap ${prop.yesLabel} or ${prop.noLabel} to vote. '
        'Swipe left for next. Swipe right for previous.',
      );
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<VotingProvider>();
    if (provider.propositions.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Propositions')),
        body: const Center(child: Text('No propositions')),
      );
    }
    final prop = provider.propositions[_currentPropIndex];

    return Focus(
      focusNode: _focusNode,
      autofocus: true,
      onKeyEvent: _handleKey,
      child: GestureDetector(
        onHorizontalDragEnd: (details) {
          if (details.primaryVelocity != null) {
            if (details.primaryVelocity! < -200) {
              _nextProp();
            } else if (details.primaryVelocity! > 200) {
              _prevProp();
            }
          }
        },
        child: Scaffold(
        appBar: AppBar(
          title: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Image.asset('assets/images/votrite_logo.png', width: 28, height: 28),
              const SizedBox(width: 8),
              Text('Proposition ${_currentPropIndex + 1} of ${provider.propositions.length}'),
            ],
          ),
          actions: [
            Semantics(
              label: 'Open accessibility help guide',
              button: true,
              child: IconButton(
                icon: const Icon(Icons.help_outline),
                onPressed: () => HelpScreen.show(context),
              ),
            ),
          ],
        ),
        body: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              LinearProgressIndicator(
                value: (_currentPropIndex + 1) / provider.propositions.length,
                backgroundColor: Colors.grey.shade200,
                valueColor: const AlwaysStoppedAnimation(VotRiteTheme.primaryBlue),
              ),
              const SizedBox(height: 16),
              Semantics(
                header: true,
                label: 'Proposition ${_currentPropIndex + 1} of ${provider.propositions.length}. ${prop.propTitle}.',
                child: Text(
                  prop.propTitle,
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: VotRiteTheme.darkBlue),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 12),
              // The proposition text and the Yes/No buttons scroll together as one
              // block, packed to the top. Previously the text sat in an Expanded that
              // swallowed all the spare height, which stranded Yes/No at the very
              // bottom of the screen with a dead gap above them -- the voter had to
              // look far away from the question to answer it. Now the buttons sit
              // directly under the text they answer, and a long proposition simply
              // scrolls, carrying its buttons with it. Previous/Next stay pinned
              // below, so navigation never moves around.
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Semantics(
                        label: prop.propText,
                        readOnly: true,
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: VotRiteTheme.lightGray,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            prop.propText,
                            style: const TextStyle(fontSize: 13, height: 1.5),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: _VoteButton(
                              label: prop.yesLabel,
                              icon: Icons.thumb_up,
                              isSelected: prop.vote == 1,
                              color: VotRiteTheme.successGreen,
                              onTap: () => _vote(1),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _VoteButton(
                              label: prop.noLabel,
                              icon: Icons.thumb_down,
                              isSelected: prop.vote == 2,
                              color: VotRiteTheme.errorRed,
                              onTap: () => _vote(2),
                            ),
                          ),
                        ],
                      ),
                      if (prop.vote > 0)
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: TextButton(
                            onPressed: () {
                              final provider = context.read<VotingProvider>();
                              provider.savePropositionVote(prop.propositionId, 0);
                              setState(() {});
                              TtsService().speak('Cleared vote on ${prop.propTitle}.');
                            },
                            child: const Text('Clear Selection', style: TextStyle(fontSize: 12, color: Colors.grey)),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  if (_currentPropIndex > 0)
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _prevProp,
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        child: const Text('Previous', style: TextStyle(fontSize: 13)),
                      ),
                    ),
                  if (_currentPropIndex > 0) const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _nextProp,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: Text(
                        _currentPropIndex < provider.propositions.length - 1 ? 'Next' : 'Review',
                        style: const TextStyle(fontSize: 13),
                      ),
                    ),
                  ),
                ],
              ),
              VotRiteTheme.footer(),
            ],
          ),
        ),
        ),
      ),
    );
  }
}

class _VoteButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final Color color;
  final VoidCallback onTap;

  const _VoteButton({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Vote $label. ${isSelected ? "Currently selected." : "Double tap to vote $label."}',
      button: true,
      selected: isSelected,
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: isSelected ? color : Colors.grey.shade200,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? color : Colors.grey.shade400,
              width: isSelected ? 3 : 1,
            ),
          ),
          child: Column(
            children: [
              Icon(
                icon,
                size: 28,
                color: isSelected ? Colors.white : Colors.grey.shade600,
              ),
              const SizedBox(height: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: isSelected ? Colors.white : Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
