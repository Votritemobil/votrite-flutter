import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:vibration/vibration.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/candidate.dart';
import '../models/race.dart';
import '../providers/voting_provider.dart';
import '../services/tts_service.dart';
import '../theme.dart';
import 'help_screen.dart';
import 'party_screen.dart';
import 'proposition_screen.dart';
import 'review_screen.dart';
import 'splash_screen.dart';

class RaceScreen extends StatefulWidget {
  const RaceScreen({super.key});

  @override
  State<RaceScreen> createState() => _RaceScreenState();
}

class _RaceScreenState extends State<RaceScreen> {
  final _focusNode = FocusNode();
  List<Candidate> _candidates = [];
  bool _loading = true;
  int _highlightedIndex = -1;
  int? _partyId;

  @override
  void initState() {
    super.initState();
    _loadCandidates();
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _loadCandidates() async {
    final provider = context.read<VotingProvider>();
    final race = provider.currentRace;
    if (race == null) return;

    if (race.raceType == 'P') {
      if (!mounted) return;
      final result = await Navigator.push<Map<String, dynamic>>(
        context,
        MaterialPageRoute(builder: (_) => const PartyScreen()),
      );
      if (result != null) {
        _partyId = result['party_id'] as int;
      }
    }

    setState(() => _loading = true);
    try {
      final candidates = await provider.fetchCandidates(race.raceId, partyId: _partyId);

      final existingResult = provider.raceResults[provider.currentRaceIndex];
      for (final c in candidates) {
        final match = existingResult.selectedCandidates
            .where((sc) => sc.candidateId == c.candidateId);
        if (match.isNotEmpty) {
          c.isSelected = true;
          c.rankValue = match.first.rankValue;
        }
      }

      setState(() {
        _candidates = candidates;
        _loading = false;
        _highlightedIndex = -1;
      });
      _announceRace(race);
    } catch (e) {
      setState(() => _loading = false);
    }
  }

  void _announceRace(Race race) {
    final tts = TtsService();
    final selected = _candidates.where((c) => c.isSelected).length;
    final remaining = race.maxNumOfVotes - selected;
    final numberedCandidates = _candidates.asMap().entries
        .map((e) => '${e.key + 1}. ${e.value.candidateName}')
        .join('. ');
    tts.speak(
      '${race.raceName}. '
      'Vote for no more than ${race.maxNumOfVotes}. '
      'Candidates listed: $numberedCandidates. '
      'You have $remaining choice${remaining != 1 ? "s" : ""} remaining. '
      'Tap a candidate to select them. '
      'Swipe left for next race, swipe right to go back.',
    );
  }

  void _toggleCandidate(int index) {
    final provider = context.read<VotingProvider>();
    final race = provider.currentRace!;

    setState(() {
      if (_candidates[index].isSelected) {
        _candidates[index].isSelected = false;
        _candidates[index].rankValue = 0;
        TtsService().speak('Deselected ${_candidates[index].candidateName}.');
      } else {
        final selectedCount = _candidates.where((c) => c.isSelected).length;
        if (selectedCount >= race.maxNumOfVotes) {
          TtsService().speak(
            'Maximum ${race.maxNumOfVotes} candidates allowed. Deselect one first.',
          );
          return;
        }
        _candidates[index].isSelected = true;
        if (race.raceType == 'R') {
          _candidates[index].rankValue = selectedCount + 1;
        }
        TtsService().speak('Selected ${_candidates[index].candidateName}.');
        Vibration.vibrate(duration: 50);
      }
    });
  }

  void _saveAndProceed() {
    final provider = context.read<VotingProvider>();
    final race = provider.currentRace!;
    final selected = _candidates.where((c) => c.isSelected).toList();

    if (selected.length < race.minNumOfVotes) {
      TtsService().speak(
        'Please select at least ${race.minNumOfVotes} candidates.',
      );
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Select at least ${race.minNumOfVotes} candidate(s)')),
      );
      return;
    }

    provider.saveRaceResult(
      provider.currentRaceIndex,
      partyId: _partyId,
      partyName: null,
      candidates: selected,
    );

    if (provider.currentRaceIndex < provider.races.length - 1) {
      provider.advanceRace();
      setState(() {
        _candidates = [];
        _loading = true;
        _highlightedIndex = -1;
        _partyId = null;
      });
      _loadCandidates();
    } else {
      if (provider.propositions.isNotEmpty) {
        Navigator.push(context, MaterialPageRoute(builder: (_) => const PropositionScreen()));
      } else {
        Navigator.push(context, MaterialPageRoute(builder: (_) => const ReviewScreen()));
      }
    }
  }

  void _showWriteInDialog() {
    final provider = context.read<VotingProvider>();
    final race = provider.currentRace!;
    final writeInsUsed = _candidates.where((c) => c.candidateName.contains('(Write-In)')).length;
    if (writeInsUsed >= race.maxNumOfWriteIns) {
      TtsService().speak('Maximum write-in candidates reached.');
      return;
    }

    final remaining = race.maxNumOfWriteIns - writeInsUsed;
    TtsService().speak(
      'Write-in candidate. You have $remaining write-in slot${remaining > 1 ? "s" : ""} remaining. '
      'Type the candidate name, then press Enter to submit. Press Escape to cancel.',
    );

    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Write-In Candidate'),
        content: TextField(
          controller: controller,
          autofocus: true,
          autocorrect: false,
          enableSuggestions: false,
          textCapitalization: TextCapitalization.words,
          decoration: const InputDecoration(
            hintText: 'Enter candidate name',
            border: OutlineInputBorder(),
          ),
          onSubmitted: (value) async {
            final name = value.trim();
            if (name.isEmpty) {
              TtsService().speak('Please type a candidate name first.');
              return;
            }
            Navigator.pop(ctx);
            TtsService().speak('Submitting write-in candidate: $name. Please wait.');
            final success = await provider.addWriteInCandidate(
              race.raceId,
              name,
              partyId: _partyId,
            );
            if (success) {
              TtsService().speak('Write-in candidate $name added successfully. Press F to select.');
              Vibration.vibrate(duration: 100);
              _loadCandidates();
            } else {
              TtsService().speak('Failed to add write-in candidate. Press W to try again.');
            }
          },
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              TtsService().speak('Write-in cancelled. Returning to candidate list.');
            },
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final name = controller.text.trim();
              if (name.isEmpty) {
                TtsService().speak('Please type a candidate name first.');
                return;
              }
              Navigator.pop(ctx);
              TtsService().speak('Submitting write-in candidate: $name. Please wait.');
              final success = await provider.addWriteInCandidate(
                race.raceId,
                name,
                partyId: _partyId,
              );
              if (success) {
                TtsService().speak('Write-in candidate $name added successfully. Press F to select.');
                Vibration.vibrate(duration: 100);
                _loadCandidates();
              } else {
                TtsService().speak('Failed to add write-in candidate. Press W to try again.');
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  KeyEventResult _handleKey(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;
    final key = event.logicalKey;

    if (key == LogicalKeyboardKey.keyF) {
      if (_candidates.isEmpty) return KeyEventResult.handled;
      if (_highlightedIndex < 0) {
        setState(() => _highlightedIndex = 0);
        TtsService().speak(_candidates[0].candidateName);
      } else {
        _toggleCandidate(_highlightedIndex);
      }
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.keyJ || key == LogicalKeyboardKey.enter) {
      _saveAndProceed();
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.keyD || key == LogicalKeyboardKey.escape) {
      Navigator.maybePop(context);
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.keyK) {
      if (_highlightedIndex >= 0 && _highlightedIndex < _candidates.length) {
        if (_candidates[_highlightedIndex].isSelected) {
          _toggleCandidate(_highlightedIndex);
        } else {
          TtsService().speak('${_candidates[_highlightedIndex].candidateName} is not selected.');
        }
      }
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.arrowDown) {
      if (_candidates.isNotEmpty) {
        setState(() {
          _highlightedIndex = (_highlightedIndex + 1).clamp(0, _candidates.length - 1);
        });
        final c = _candidates[_highlightedIndex];
        final status = c.isSelected ? 'Selected' : 'Not selected';
        TtsService().speak('${c.candidateName}. ${c.partyName}. $status.');
      }
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.arrowUp) {
      if (_candidates.isNotEmpty) {
        setState(() {
          _highlightedIndex = (_highlightedIndex - 1).clamp(0, _candidates.length - 1);
        });
        final c = _candidates[_highlightedIndex];
        final status = c.isSelected ? 'Selected' : 'Not selected';
        TtsService().speak('${c.candidateName}. ${c.partyName}. $status.');
      }
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.keyS) {
      final selected = _candidates.where((c) => c.isSelected).toList();
      if (selected.isEmpty) {
        TtsService().speak('No candidates selected yet.');
      } else {
        final names = selected.map((c) => c.candidateName).join(', ');
        TtsService().speak('Selected: $names.');
      }
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.keyW) {
      final provider = context.read<VotingProvider>();
      final race = provider.currentRace;
      if (race != null && race.maxNumOfWriteIns > 0) {
        _showWriteInDialog();
      } else {
        TtsService().speak('Write-in candidates are not available for this race.');
      }
      return KeyEventResult.handled;
    }
    // Z is SILENCE, not "next". It used to call _saveAndProceed(), so a voter who
    // pressed Z to shut the voice up would instead have their selections committed
    // and be moved on to the next race without being told. J and Enter already
    // advance the ballot; Z must only ever stop the speech, immediately.
    if (key == LogicalKeyboardKey.keyZ) {
      TtsService().stop();
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.keyL) {
      final provider = context.read<VotingProvider>();
      final race = provider.currentRace;
      var help = 'Candidate selection screen. '
        'Tap a candidate to select or deselect them. '
        'Swipe left for next race, swipe right to go back.';
      if (race != null && race.maxNumOfWriteIns > 0) {
        help += ' Tap the write-in button at the bottom to add a candidate.';
      }
      TtsService().speak(help);
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<VotingProvider>();
    final race = provider.currentRace;

    return Focus(
      focusNode: _focusNode,
      autofocus: true,
      onKeyEvent: _handleKey,
      child: GestureDetector(
        onHorizontalDragEnd: (details) {
          if (details.primaryVelocity != null) {
            if (details.primaryVelocity! < -200) {
              _saveAndProceed();
            } else if (details.primaryVelocity! > 200) {
              Navigator.maybePop(context);
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
              Flexible(child: Text(race?.raceName ?? 'Contest', overflow: TextOverflow.ellipsis)),
            ],
          ),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.maybePop(context),
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
            PopupMenuButton<String>(
              onSelected: (value) {
                if (value == 'start_over') {
                  provider.reset();
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
          ],
        ),
        body: _loading
            ? const Center(child: CircularProgressIndicator())
            : Column(
                children: [
                  Semantics(
                    header: true,
                    label: 'Race ${provider.currentRaceIndex + 1} of ${provider.races.length}. '
                        '${race?.raceName ?? ""}. '
                        'Select ${race?.minNumOfVotes ?? 0} to ${race?.maxNumOfVotes ?? 1} candidates.',
                    child: Builder(
                      builder: (context) {
                        final selectedCount = _candidates.where((c) => c.isSelected).length;
                        final maxVotes = race?.maxNumOfVotes ?? 1;
                        final remaining = maxVotes - selectedCount;
                        return Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          color: VotRiteTheme.primaryBlue.withValues(alpha: 0.05),
                          child: Column(
                            children: [
                              Text(
                                'Race ${provider.currentRaceIndex + 1} of ${provider.races.length}',
                                style: TextStyle(fontSize: provider.scaledFont(12), color: Colors.grey),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                race?.raceName ?? '',
                                style: TextStyle(fontSize: provider.scaledFont(14), fontWeight: FontWeight.bold),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 2),
                              Text(
                                remaining > 0
                                    ? 'You have $remaining choice${remaining != 1 ? "s" : ""} remaining'
                                    : 'All choices made',
                                style: TextStyle(
                                  fontSize: provider.scaledFont(12),
                                  color: remaining > 0 ? VotRiteTheme.primaryBlue : VotRiteTheme.successGreen,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                  if (_candidates.length > 4)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.swipe_vertical, size: 16, color: Colors.grey.shade500),
                          const SizedBox(width: 4),
                          Text(
                            'Scroll for more candidates',
                            style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                          ),
                        ],
                      ),
                    ),
                  Expanded(
                    child: _candidates.isEmpty
                        ? const Center(child: Text('No candidates available'))
                        : ListView.builder(
                            padding: const EdgeInsets.all(8),
                            itemCount: _candidates.length,
                            itemBuilder: (context, index) {
                              final cand = _candidates[index];
                              final isHighlighted = index == _highlightedIndex;
                              return Semantics(
                                label: 'Candidate ${index + 1} of ${_candidates.length}. '
                                    '${cand.candidateName}. '
                                    '${cand.partyName.isNotEmpty ? "${cand.partyName}. " : ""}'
                                    '${cand.isSelected ? "Selected" : "Not selected"}. '
                                    'Double tap to ${cand.isSelected ? "deselect" : "select"}.',
                                selected: cand.isSelected,
                                button: true,
                                child: Card(
                                  margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  elevation: isHighlighted ? 4 : 1,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    side: isHighlighted
                                        ? const BorderSide(color: VotRiteTheme.accentGold, width: 2)
                                        : cand.isSelected
                                            ? const BorderSide(color: VotRiteTheme.successGreen, width: 2)
                                            : BorderSide.none,
                                  ),
                                  color: cand.isSelected
                                      ? VotRiteTheme.successGreen.withValues(alpha: 0.08)
                                      : null,
                                  child: ListTile(
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                    leading: Stack(
                                      children: [
                                        cand.photo.isNotEmpty
                                            ? CircleAvatar(
                                                radius: 22,
                                                backgroundColor: Colors.grey.shade200,
                                                backgroundImage: CachedNetworkImageProvider(cand.photo),
                                              )
                                            : CircleAvatar(
                                                radius: 22,
                                                backgroundColor: VotRiteTheme.primaryBlue,
                                                child: Text(
                                                  '${index + 1}',
                                                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                                                ),
                                              ),
                                        if (cand.isSelected)
                                          Positioned(
                                            right: 0,
                                            bottom: 0,
                                            child: Container(
                                              width: 18,
                                              height: 18,
                                              decoration: BoxDecoration(
                                                color: VotRiteTheme.successGreen,
                                                shape: BoxShape.circle,
                                                border: Border.all(color: Colors.white, width: 2),
                                              ),
                                              child: const Icon(Icons.check, color: Colors.white, size: 12),
                                            ),
                                          ),
                                      ],
                                    ),
                                    title: Text(
                                      cand.candidateName,
                                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: provider.scaledFont(13)),
                                    ),
                                    subtitle: cand.partyName.isNotEmpty
                                        ? Text(cand.partyName)
                                        : null,
                                    trailing: race?.raceType == 'R' && cand.isSelected
                                        ? CircleAvatar(
                                            radius: 16,
                                            backgroundColor: VotRiteTheme.accentGold,
                                            child: Text(
                                              '#${cand.rankValue}',
                                              style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 12,
                                                color: Colors.black,
                                              ),
                                            ),
                                          )
                                        : null,
                                    onTap: () {
                                      setState(() => _highlightedIndex = index);
                                      _toggleCandidate(index);
                                    },
                                  ),
                                ),
                              );
                            },
                          ),
                  ),
                  if (race != null && race.maxNumOfWriteIns > 0)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      child: OutlinedButton.icon(
                        onPressed: _showWriteInDialog,
                        icon: const Icon(Icons.edit),
                        label: const Text('Write-In Candidate'),
                      ),
                    ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
                    child: Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.maybePop(context),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                            ),
                            child: const Text('Back', style: TextStyle(fontSize: 14)),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _saveAndProceed,
                            child: Text(
                              provider.currentRaceIndex < provider.races.length - 1 ? 'Next Race' : 'Continue',
                              style: const TextStyle(fontSize: 14),
                            ),
                          ),
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
