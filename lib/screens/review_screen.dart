import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/voting_provider.dart';
import '../services/tts_service.dart';
import '../theme.dart';
import 'help_screen.dart';
import 'proposition_screen.dart';
import 'race_screen.dart';
import 'finish_screen.dart';
import 'splash_screen.dart';

class ReviewScreen extends StatefulWidget {
  const ReviewScreen({super.key});

  @override
  State<ReviewScreen> createState() => _ReviewScreenState();
}

class _ReviewScreenState extends State<ReviewScreen> {
  final _focusNode = FocusNode();
  int _highlightedIndex = -1;

  @override
  void initState() {
    super.initState();
    _announceReview();
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  void _announceReview() {
    final provider = context.read<VotingProvider>();
    final summary = <String>[];
    for (final result in provider.raceResults) {
      final names = result.selectedCandidates.map((c) => c.candidateName).join(', ');
      summary.add('${result.raceName}: ${names.isEmpty ? "No selection" : names}');
    }
    for (final prop in provider.propositions) {
      final vote = prop.vote == 1 ? prop.yesLabel : prop.vote == 2 ? prop.noLabel : 'No vote';
      summary.add('${prop.propTitle}: $vote');
    }
    TtsService().speak(
      'Review your votes. ${provider.raceResults.length} races'
      '${provider.propositions.isNotEmpty ? " and ${provider.propositions.length} propositions" : ""}. '
      '${summary.join(". ")}. '
      'Tap any item to change your vote. '
      'Swipe left to cast your ballot.',
    );
  }

  Future<void> _castBallot() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cast Your Ballot'),
        content: const Text(
          'Are you sure you want to submit your votes? This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: VotRiteTheme.successGreen),
            child: const Text('Cast Ballot'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    TtsService().speak('Submitting your votes. Please wait.');
    final provider = context.read<VotingProvider>();
    final success = await provider.submitAllVotes();

    if (!mounted) return;
    if (success) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const FinishScreen()),
        (route) => false,
      );
    } else {
      TtsService().speak('Error submitting votes. Please try again.');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to submit. Please try again.')),
      );
    }
  }

  KeyEventResult _handleKey(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;
    final key = event.logicalKey;
    final provider = context.read<VotingProvider>();
    final totalItems = provider.raceResults.length + provider.propositions.length;

    if (key == LogicalKeyboardKey.arrowDown || key == LogicalKeyboardKey.keyK) {
      setState(() {
        _highlightedIndex = (_highlightedIndex + 1).clamp(0, totalItems - 1);
      });
      _announceItem(_highlightedIndex);
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.arrowUp) {
      setState(() {
        _highlightedIndex = (_highlightedIndex - 1).clamp(0, totalItems - 1);
      });
      _announceItem(_highlightedIndex);
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.keyF) {
      if (_highlightedIndex >= 0 && _highlightedIndex < provider.raceResults.length) {
        provider.goToRace(_highlightedIndex);
        Navigator.push(context, MaterialPageRoute(builder: (_) => const RaceScreen()));
      }
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.keyJ || key == LogicalKeyboardKey.enter) {
      _castBallot();
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.keyD || key == LogicalKeyboardKey.escape) {
      Navigator.maybePop(context);
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.keyS) {
      if (_highlightedIndex >= 0) {
        _announceItem(_highlightedIndex);
      } else {
        _announceReview();
      }
      return KeyEventResult.handled;
    }
    // Z silences the voice guidance instantly, on every screen.
    if (key == LogicalKeyboardKey.keyZ) {
      TtsService().stop();
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.keyL) {
      TtsService().speak(
        'Review screen. Tap any item to change your vote. '
        'Swipe left to cast your ballot.',
      );
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  void _announceItem(int index) {
    final provider = context.read<VotingProvider>();
    if (index < provider.raceResults.length) {
      final result = provider.raceResults[index];
      final names = result.selectedCandidates.map((c) => c.candidateName).join(', ');
      TtsService().speak(
        '${result.raceName}. ${names.isEmpty ? "No selection" : "Selected: $names"}. Press F to change.',
      );
    } else {
      final propIdx = index - provider.raceResults.length;
      if (propIdx < provider.propositions.length) {
        final prop = provider.propositions[propIdx];
        final vote = prop.vote == 1 ? prop.yesLabel : prop.vote == 2 ? prop.noLabel : 'No vote';
        // Read the actual question, not just its title. A sighted voter can re-read
        // the proposition on this screen before casting; previously a blind voter
        // heard only "School Modernization Bond. Vote: Yes." and had no way to hear
        // back WHAT they had voted on.
        TtsService().speak(
          '${prop.propTitle}. ${prop.propText} '
          'Your vote: $vote. Press F to change.',
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<VotingProvider>();

    return Focus(
      focusNode: _focusNode,
      autofocus: true,
      onKeyEvent: _handleKey,
      child: GestureDetector(
        onHorizontalDragEnd: (details) {
          if (details.primaryVelocity != null && details.primaryVelocity! < -200) {
            _castBallot();
          }
        },
        child: Scaffold(
        appBar: AppBar(
          title: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Image.asset('assets/images/votrite_logo.png', width: 28, height: 28),
              const SizedBox(width: 8),
              const Text('Review Your Votes'),
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
        body: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              color: VotRiteTheme.accentGold.withValues(alpha: 0.15),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.info_outline, color: VotRiteTheme.darkBlue, size: 18),
                  SizedBox(width: 6),
                  Text(
                    'Tap any item to change your vote',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  const Text(
                    'Races',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: VotRiteTheme.darkBlue),
                  ),
                  const SizedBox(height: 8),
                  ...provider.raceResults.asMap().entries.map((entry) {
                    final idx = entry.key;
                    final result = entry.value;
                    final isHighlighted = idx == _highlightedIndex;
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                        side: isHighlighted
                            ? const BorderSide(color: VotRiteTheme.accentGold, width: 2)
                            : BorderSide.none,
                      ),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(8),
                        onTap: () {
                          provider.goToRace(idx);
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const RaceScreen()),
                          );
                        },
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      result.raceName,
                                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: provider.scaledFont(13)),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      result.selectedCandidates.isEmpty
                                          ? 'No selection'
                                          : result.selectedCandidates.map((c) => c.candidateName).join(', '),
                                      style: TextStyle(
                                        fontSize: provider.scaledFont(12),
                                        color: result.selectedCandidates.isEmpty
                                            ? VotRiteTheme.errorRed
                                            : VotRiteTheme.successGreen,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                decoration: BoxDecoration(
                                  color: VotRiteTheme.primaryBlue,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.edit, color: Colors.white, size: 16),
                                    SizedBox(width: 4),
                                    Text('Edit', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }),
                  if (provider.propositions.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    const Text(
                      'Propositions',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: VotRiteTheme.darkBlue),
                    ),
                    const SizedBox(height: 8),
                    ...provider.propositions.asMap().entries.map((entry) {
                      final idx = entry.key + provider.raceResults.length;
                      final prop = entry.value;
                      final isHighlighted = idx == _highlightedIndex;
                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                          side: isHighlighted
                              ? const BorderSide(color: VotRiteTheme.accentGold, width: 2)
                              : BorderSide.none,
                        ),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(8),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const PropositionScreen()),
                            );
                          },
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        prop.propTitle,
                                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: provider.scaledFont(13)),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        prop.vote == 0
                                            ? 'No vote'
                                            : prop.vote == 1
                                                ? prop.yesLabel
                                                : prop.noLabel,
                                        style: TextStyle(
                                          fontSize: provider.scaledFont(12),
                                          color: prop.vote == 0 ? VotRiteTheme.errorRed : VotRiteTheme.successGreen,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: VotRiteTheme.primaryBlue,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: const Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.edit, color: Colors.white, size: 16),
                                      SizedBox(width: 4),
                                      Text('Edit', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }),
                  ],
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  ElevatedButton.icon(
                    onPressed: provider.isSubmitting ? null : _castBallot,
                    icon: provider.isSubmitting
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                          )
                        : const Icon(Icons.how_to_vote),
                    label: Text(
                      provider.isSubmitting ? 'Submitting...' : 'Cast Ballot',
                      style: const TextStyle(fontSize: 14),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: VotRiteTheme.successGreen,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: TextButton(
                          onPressed: () => Navigator.maybePop(context),
                          child: const Text('Go Back', style: TextStyle(fontSize: 14)),
                        ),
                      ),
                      Expanded(
                        child: TextButton(
                          onPressed: () async {
                            final confirmed = await showDialog<bool>(
                              context: context,
                              builder: (ctx) => AlertDialog(
                                title: const Text('Cancel Ballot?'),
                                content: const Text(
                                  'Are you sure you want to cancel? All your selections will be discarded.',
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(ctx, false),
                                    child: const Text('No, Keep Voting'),
                                  ),
                                  ElevatedButton(
                                    onPressed: () => Navigator.pop(ctx, true),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: VotRiteTheme.errorRed,
                                    ),
                                    child: const Text('Yes, Cancel'),
                                  ),
                                ],
                              ),
                            );
                            if (confirmed == true && mounted) {
                              context.read<VotingProvider>().reset();
                              Navigator.pushAndRemoveUntil(
                                context,
                                MaterialPageRoute(builder: (_) => const SplashScreen()),
                                (route) => false,
                              );
                            }
                          },
                          child: const Text(
                            'Cancel Ballot',
                            style: TextStyle(fontSize: 14, color: VotRiteTheme.errorRed),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            VotRiteTheme.footer(),
          ],
        ),
        ),
      ),
    );
  }
}
