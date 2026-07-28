import 'dart:async';
import 'dart:io' show Platform;
import 'package:flutter_tts/flutter_tts.dart';
import 'package:shared_preferences/shared_preferences.dart';

class TtsService {
  static final TtsService _instance = TtsService._internal();
  factory TtsService() => _instance;
  TtsService._internal();

  final FlutterTts _tts = FlutterTts();
  bool _initialized = false;
  bool _initInProgress = false;
  bool _enabled = false;
  bool _speaking = false;
  double _currentRate = 0.45;

  bool get enabled => _enabled;
  double get currentRate => _currentRate;

  Future<void> init() async {
    if (_initialized || _initInProgress) return;
    _initInProgress = true;

    try {
      if (Platform.isIOS) {
        await _tts.setSharedInstance(true).timeout(const Duration(seconds: 3), onTimeout: () {});
        await _tts.setIosAudioCategory(
          IosTextToSpeechAudioCategory.playback,
          [IosTextToSpeechAudioCategoryOptions.defaultToSpeaker],
          IosTextToSpeechAudioMode.voicePrompt,
        ).timeout(const Duration(seconds: 3), onTimeout: () {});
      }

      await _tts.setLanguage('en-US');
      await _tts.awaitSpeakCompletion(false);
      await _tts.setVolume(1.0);
      await _tts.setPitch(0.85);

      _tts.setCompletionHandler(() => _speaking = false);
      _tts.setCancelHandler(() => _speaking = false);
      _tts.setErrorHandler((_) => _speaking = false);

      final prefs = await SharedPreferences.getInstance();
      final rate = prefs.getDouble('tts_rate') ?? 0.45;
      _currentRate = rate;
      await _tts.setSpeechRate(rate);
      _enabled = prefs.getBool('accessibility_mode') ?? false;
      _initialized = true;
    } catch (_) {}
    _initInProgress = false;
  }

  Future<void> _ensureInit() async {
    if (!_initialized && !_initInProgress) {
      await init().timeout(const Duration(seconds: 5), onTimeout: () {});
    }
  }

  Future<void> setEnabled(bool value) async {
    _enabled = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('accessibility_mode', value);
  }

  Future<void> setSpeechRate(double rate) async {
    _currentRate = rate;
    await _ensureInit();
    try {
      await _tts.setSpeechRate(rate);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setDouble('tts_rate', rate);
    } catch (_) {}
  }

  // Every request to say something takes a ticket. speak() has to await init and
  // await the previous utterance stopping, and those awaits can take seconds -- so
  // by the time an utterance is actually handed to the engine, the voter may have
  // moved to a different screen, or pressed Z for silence. Without this check the
  // stale utterance still fires and talks over whatever is happening now: pressing
  // Continue on the settings screen would cut off "Settings saved, next select your
  // ballot" and read out the instructions for the screen just left. If a newer
  // request (or a stop) has come in while we were waiting, the old one is dropped.
  int _seq = 0;

  Future<void> _speakInternal(String text) async {
    final ticket = ++_seq;
    await _ensureInit();
    if (ticket != _seq) return;
    try {
      if (_speaking) await _tts.stop().timeout(const Duration(seconds: 1), onTimeout: () {});
      if (ticket != _seq) return;
      _speaking = true;
      await _tts.speak(text).timeout(const Duration(seconds: 3), onTimeout: () {});
    } catch (_) {
      _speaking = false;
    }
  }

  Future<void> speak(String text) async {
    if (!_enabled) return;
    await _speakInternal(text);
  }

  Future<void> speakAlways(String text) async {
    await _speakInternal(text);
  }

  Future<void> stop() async {
    // Bump the ticket first: this cancels any utterance that is still waiting on an
    // await inside _speakInternal, so silence stays silent. Z means silence NOW.
    _seq++;
    try {
      _speaking = false;
      await _tts.stop().timeout(const Duration(seconds: 1), onTimeout: () {});
    } catch (_) {}
  }
}
