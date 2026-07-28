import 'package:flutter/material.dart';
import '../services/tts_service.dart';
import '../theme.dart';

class HelpScreen extends StatelessWidget {
  const HelpScreen({super.key});

  static void show(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => const HelpScreen(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) => Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: VotRiteTheme.primaryBlue,
              borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Row(
              children: [
                Image.asset('assets/images/votrite_logo.png', width: 28, height: 28),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'Accessibility Guide',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Semantics(
                  label: 'Close help',
                  button: true,
                  child: IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              controller: scrollController,
              padding: const EdgeInsets.all(16),
              children: [
                _buildSection(
                  'With External Keyboard',
                  Icons.keyboard,
                  [
                    _HelpItem('F', 'Select a candidate'),
                    _HelpItem('K', 'Deselect a candidate'),
                    _HelpItem('J or Enter', 'Next race / Continue'),
                    _HelpItem('D or Escape', 'Go back'),
                    _HelpItem('S', 'Read all selections aloud'),
                    _HelpItem('L', 'Read help instructions'),
                    _HelpItem('W', 'Write-in a candidate'),
                    _HelpItem('Z', 'Skip current race'),
                    _HelpItem('Arrow Up/Down', 'Navigate between candidates'),
                  ],
                ),
                const SizedBox(height: 24),
                _buildSection(
                  'With Screen Reader (VoiceOver / TalkBack)',
                  Icons.record_voice_over,
                  [
                    _HelpItem('Swipe Right', 'Move to next item'),
                    _HelpItem('Swipe Left', 'Move to previous item'),
                    _HelpItem('Double Tap', 'Select / activate item'),
                    _HelpItem('2-Finger Swipe Down', 'Read entire page'),
                    _HelpItem('3-Finger Swipe', 'Scroll the page'),
                    _HelpItem('Rotor (2-finger twist)', 'Change navigation mode'),
                  ],
                ),
                const SizedBox(height: 24),
                _buildSection(
                  'Review & Cast Your Vote',
                  Icons.how_to_vote,
                  [
                    _HelpItem('Navigate', 'Swipe or use arrow keys to review each selection'),
                    _HelpItem('Edit', 'Double tap Edit or press F to change a race'),
                    _HelpItem('Cast Ballot', 'Press J or double tap Cast Ballot when ready'),
                    _HelpItem('Read Summary', 'Press S to hear all your selections read aloud'),
                  ],
                ),
                const SizedBox(height: 24),
                _buildSection(
                  'Propositions',
                  Icons.ballot,
                  [
                    _HelpItem('F', 'Vote Yes / For'),
                    _HelpItem('K', 'Vote No / Against'),
                    _HelpItem('J', 'Next proposition'),
                    _HelpItem('D', 'Previous proposition'),
                    _HelpItem('S', 'Re-read current proposition'),
                  ],
                ),
                const SizedBox(height: 32),
                Semantics(
                  label: 'Read all help aloud',
                  button: true,
                  child: ElevatedButton.icon(
                    onPressed: () => _readAllHelp(),
                    icon: const Icon(Icons.volume_up),
                    label: const Text('Read All Help Aloud', style: TextStyle(fontSize: 14)),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection(String title, IconData icon, List<_HelpItem> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Semantics(
          header: true,
          child: Row(
            children: [
              Icon(icon, color: VotRiteTheme.primaryBlue, size: 24),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: VotRiteTheme.primaryBlue,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        ...items.map((item) => Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Semantics(
            label: '${item.key}: ${item.description}',
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 120,
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: VotRiteTheme.primaryBlue.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    item.key,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      color: VotRiteTheme.primaryBlue,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    item.description,
                    style: const TextStyle(fontSize: 13),
                  ),
                ),
              ],
            ),
          ),
        )),
      ],
    );
  }

  void _readAllHelp() {
    TtsService().speakAlways(
      'Accessibility Guide. '
      'With External Keyboard: '
      'F to select a candidate. K to deselect. J or Enter for next race. '
      'D or Escape to go back. S to read all selections. L for help. '
      'W to write in a candidate. Z to skip. Arrow keys to navigate. '
      'With Screen Reader: '
      'Swipe right for next item. Swipe left for previous. '
      'Double tap to select or activate. '
      'Two finger swipe down to read the entire page. '
      'Three finger swipe to scroll. '
      'Rotor gesture, two finger twist, to change navigation mode. '
      'On the Review page: '
      'Navigate through your selections. Double tap Edit or press F to change a race. '
      'Press J or double tap Cast Ballot when ready. Press S for a summary. '
      'For Propositions: '
      'F for Yes or For. K for No or Against. J for next. D for previous. S to re-read.',
    );
  }
}

class _HelpItem {
  final String key;
  final String description;
  const _HelpItem(this.key, this.description);
}
