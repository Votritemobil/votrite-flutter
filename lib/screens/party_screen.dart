import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../models/party.dart';
import '../providers/voting_provider.dart';
import '../services/tts_service.dart';
import '../theme.dart';
import 'package:cached_network_image/cached_network_image.dart';

class PartyScreen extends StatefulWidget {
  const PartyScreen({super.key});

  @override
  State<PartyScreen> createState() => _PartyScreenState();
}

class _PartyScreenState extends State<PartyScreen> {
  final _focusNode = FocusNode();
  List<Party> _parties = [];
  bool _loading = true;
  int _highlightedIndex = -1;

  @override
  void initState() {
    super.initState();
    _loadParties();
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _loadParties() async {
    final provider = context.read<VotingProvider>();
    try {
      final parties = await provider.fetchParties();
      setState(() {
        _parties = parties;
        _loading = false;
      });
      TtsService().speak(
        '${parties.length} parties available. Press F to select, arrow keys to navigate.',
      );
    } catch (e) {
      setState(() => _loading = false);
    }
  }

  void _selectParty(Party party) {
    TtsService().speak('Selected ${party.partyName}. Loading candidates.');
    Navigator.pop(context, {'party_id': party.partyId, 'party_name': party.partyName});
  }

  KeyEventResult _handleKey(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;
    final key = event.logicalKey;

    if (key == LogicalKeyboardKey.keyF) {
      if (_parties.isEmpty) return KeyEventResult.handled;
      if (_highlightedIndex < 0) {
        setState(() => _highlightedIndex = 0);
        TtsService().speak(_parties[0].partyName);
      } else {
        _selectParty(_parties[_highlightedIndex]);
      }
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.keyJ || key == LogicalKeyboardKey.enter) {
      if (_highlightedIndex >= 0) {
        _selectParty(_parties[_highlightedIndex]);
      }
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.keyD || key == LogicalKeyboardKey.escape) {
      Navigator.pop(context);
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.arrowDown || key == LogicalKeyboardKey.keyK) {
      if (_parties.isNotEmpty) {
        setState(() {
          _highlightedIndex = (_highlightedIndex + 1).clamp(0, _parties.length - 1);
        });
        TtsService().speak(_parties[_highlightedIndex].partyName);
      }
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.arrowUp) {
      if (_parties.isNotEmpty) {
        setState(() {
          _highlightedIndex = (_highlightedIndex - 1).clamp(0, _parties.length - 1);
        });
        TtsService().speak(_parties[_highlightedIndex].partyName);
      }
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.keyL) {
      TtsService().speak(
        'Party selection screen. Arrow keys to navigate. F to select. J to confirm. D to go back.',
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
        appBar: AppBar(title: const Text('Select Party')),
        body: _loading
            ? const Center(child: CircularProgressIndicator())
            : _parties.isEmpty
                ? const Center(child: Text('No parties available'))
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _parties.length,
                    itemBuilder: (context, index) {
                      final party = _parties[index];
                      final isHighlighted = index == _highlightedIndex;
                      return Semantics(
                        label: party.partyName,
                        child: Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          elevation: isHighlighted ? 4 : 1,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: isHighlighted
                                ? const BorderSide(color: VotRiteTheme.primaryBlue, width: 2)
                                : BorderSide.none,
                          ),
                          child: ListTile(
                            contentPadding: const EdgeInsets.all(16),
                            leading: party.partyLogo.isNotEmpty
                                ? CachedNetworkImage(
                                    imageUrl: party.partyLogo,
                                    width: 48,
                                    height: 48,
                                    placeholder: (context, url) => const CircularProgressIndicator(),
                                    errorWidget: (context, url, error) => const Icon(Icons.groups, size: 48),
                                  )
                                : const Icon(Icons.groups, size: 48, color: VotRiteTheme.primaryBlue),
                            title: Text(
                              party.partyName,
                              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                            ),
                            trailing: isHighlighted
                                ? const Icon(Icons.arrow_forward_ios, color: VotRiteTheme.primaryBlue)
                                : null,
                            onTap: () => _selectParty(party),
                          ),
                        ),
                      );
                    },
                  ),
      ),
    );
  }
}
