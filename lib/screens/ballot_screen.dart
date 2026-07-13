import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../models/ballot.dart';
import '../providers/voting_provider.dart';
import '../services/tts_service.dart';
import '../theme.dart';
import 'login_screen.dart';
import 'splash_screen.dart';

class BallotScreen extends StatefulWidget {
  const BallotScreen({super.key});

  @override
  State<BallotScreen> createState() => _BallotScreenState();
}

class _BallotScreenState extends State<BallotScreen> {
  final _searchController = TextEditingController();
  final _focusNode = FocusNode();
  List<Ballot> _ballots = [];
  bool _loading = true;
  int _selectedIndex = -1;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadBallots();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _loadBallots({String search = ''}) async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final provider = context.read<VotingProvider>();
      final ballots = await provider.fetchBallots(search: search);
      setState(() {
        _ballots = ballots;
        _loading = false;
        _selectedIndex = -1;
      });
      final ballotList = ballots.asMap().entries
          .map((e) => '${e.key + 1}. ${e.value.election}')
          .join('. ');
      TtsService().speak(
        'Welcome to Vote Right Mobil. '
        '${ballots.length} ballot${ballots.length != 1 ? "s" : ""} available. '
        '$ballotList. '
        'Tap a ballot to select it, or swipe up and down to scroll.',
      );
    } catch (e) {
      setState(() {
        _loading = false;
        _error = 'Unable to load ballots. Please check your connection.';
      });
    }
  }

  void _selectBallot(Ballot ballot) {
    final provider = context.read<VotingProvider>();
    provider.selectBallot(ballot);
    TtsService().speak('Selected: ${ballot.election}. Proceeding to login.');
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        TtsService().stop();
        Navigator.push(context, MaterialPageRoute(
          builder: (_) => LoginScreen(accessibilityMode: provider.accessibilityMode),
        ));
      }
    });
  }

  KeyEventResult _handleKey(FocusNode node, KeyEvent event) {
    if (!(ModalRoute.of(context)?.isCurrent ?? true)) return KeyEventResult.ignored;
    if (event is! KeyDownEvent) return KeyEventResult.ignored;
    final key = event.logicalKey;

    if (key == LogicalKeyboardKey.keyF) {
      if (_ballots.isEmpty) return KeyEventResult.handled;
      if (_selectedIndex < 0) {
        setState(() => _selectedIndex = 0);
        TtsService().speak(_ballots[0].election);
      } else {
        _selectBallot(_ballots[_selectedIndex]);
      }
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.keyJ || key == LogicalKeyboardKey.enter) {
      if (_selectedIndex >= 0 && _selectedIndex < _ballots.length) {
        _selectBallot(_ballots[_selectedIndex]);
      }
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.keyD || key == LogicalKeyboardKey.escape) {
      Navigator.maybePop(context);
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.arrowDown || key == LogicalKeyboardKey.keyK) {
      if (_ballots.isNotEmpty) {
        setState(() {
          _selectedIndex = (_selectedIndex + 1).clamp(0, _ballots.length - 1);
        });
        TtsService().speak(_ballots[_selectedIndex].election);
      }
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.arrowUp) {
      if (_ballots.isNotEmpty) {
        setState(() {
          _selectedIndex = (_selectedIndex - 1).clamp(0, _ballots.length - 1);
        });
        TtsService().speak(_ballots[_selectedIndex].election);
      }
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.keyS) {
      if (_selectedIndex >= 0 && _selectedIndex < _ballots.length) {
        final b = _ballots[_selectedIndex];
        TtsService().speak('${b.election}. ${b.board}. ${b.client}.');
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
        'Ballot selection screen. Tap a ballot to select it. Swipe up and down to scroll.',
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
              const Text('Select Ballot'),
            ],
          ),
          actions: [
            PopupMenuButton<String>(
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
          ],
        ),
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Semantics(
                label: 'Search ballots',
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search elections...',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _searchController.clear();
                        _loadBallots();
                      },
                    ),
                  ),
                  onSubmitted: (val) => _loadBallots(search: val),
                ),
              ),
            ),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : _error != null
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.error_outline, size: 48, color: VotRiteTheme.errorRed),
                              const SizedBox(height: 16),
                              Text(_error!, style: const TextStyle(fontSize: 13)),
                              const SizedBox(height: 16),
                              ElevatedButton(
                                onPressed: () => _loadBallots(),
                                child: const Text('Retry'),
                              ),
                            ],
                          ),
                        )
                      : _ballots.isEmpty
                          ? const Center(
                              child: Text('No active ballots found', style: TextStyle(fontSize: 14)),
                            )
                          : ListView.builder(
                              itemCount: _ballots.length,
                              itemBuilder: (context, index) {
                                final ballot = _ballots[index];
                                final isSelected = index == _selectedIndex;
                                return Semantics(
                                  label: 'Ballot ${index + 1} of ${_ballots.length}. '
                                      '${ballot.election}. ${ballot.board}. ${ballot.client}. '
                                      '${isSelected ? "Selected." : ""} '
                                      'Double tap to choose this ballot.',
                                  selected: isSelected,
                                  button: true,
                                  child: Card(
                                    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                                    elevation: isSelected ? 4 : 1,
                                    color: isSelected ? Colors.blue.shade50 : null,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                      side: isSelected
                                          ? const BorderSide(color: VotRiteTheme.primaryBlue, width: 2)
                                          : BorderSide.none,
                                    ),
                                    child: ListTile(
                                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                      leading: CircleAvatar(
                                        backgroundColor: VotRiteTheme.primaryBlue,
                                        child: Text(
                                          '${index + 1}',
                                          style: const TextStyle(color: VotRiteTheme.white, fontWeight: FontWeight.bold),
                                        ),
                                      ),
                                      title: Text(
                                        ballot.election,
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                      ),
                                      subtitle: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          const SizedBox(height: 4),
                                          Text(ballot.board),
                                          Text(ballot.client, style: const TextStyle(color: Colors.grey)),
                                        ],
                                      ),
                                      trailing: isSelected
                                          ? const Icon(Icons.check_circle, color: VotRiteTheme.primaryBlue)
                                          : const Icon(Icons.chevron_right),
                                      onTap: () {
                                        setState(() => _selectedIndex = index);
                                        _selectBallot(ballot);
                                      },
                                    ),
                                  ),
                                );
                              },
                            ),
            ),
            VotRiteTheme.footer(),
          ],
        ),
      ),
    );
  }
}
