// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'tts_interface.dart';

class WebTtsImpl implements TtsInterface {
  final html.SpeechSynthesis _synthesis = html.window.speechSynthesis!;
  
  String _language = 'en-US';
  double _rate = 1.0;
  double _volume = 1.0;
  double _pitch = 1.0;

  @override
  Future<void> setLanguage(String language) async {
    _language = language;
  }

  @override
  Future<void> setSpeechRate(double rate) async {
    // Web speech rate is usually 0.1 to 10, default 1
    // Mapping 0.0-1.0 (flutter_tts range) to 0.5-2.0 (reasonable web range)
    _rate = (rate * 1.5) + 0.5;
  }

  @override
  Future<void> setVolume(double volume) async {
    _volume = volume;
  }

  @override
  Future<void> setPitch(double pitch) async {
    _pitch = pitch;
  }

  @override
  Future<void> speak(String text) async {
    try {
      _synthesis.cancel(); // Stop current speech
      
      final utterance = html.SpeechSynthesisUtterance(text);
      utterance.lang = _language;
      utterance.rate = _rate;
      utterance.volume = _volume;
      utterance.pitch = _pitch;
      
      // On web, voices load asynchronously. Ensure we have voices before speaking.
      // ignore: unnecessary_null_comparison
      if (_synthesis.getVoices().isEmpty) {
        // Wait for voices to load using polling since onVoicesChanged might not be available
        Timer.periodic(const Duration(milliseconds: 100), (timer) {
          // Stop polling if voices are available or after 2 seconds (20 ticks)
          if (_synthesis.getVoices().isNotEmpty || timer.tick > 20) {
            timer.cancel();
            _speakUtterance(utterance);
          }
        });
      } else {
        _speakUtterance(utterance);
      }
      
      debugPrint('Web TTS: Queued "$text"');
    } catch (e) {
      debugPrint('Web TTS Error: $e');
    }
  }

  void _speakUtterance(html.SpeechSynthesisUtterance utterance) {
      // Try to select a better voice if available
      final voices = _synthesis.getVoices();
      try {
        // Fallback for voices[0] error: check if voices is empty first
        if (voices.isEmpty) {
          debugPrint('Web TTS: No voices available, speaking with default voice.');
          _synthesis.speak(utterance);
          return;
        }

        final preferredVoice = voices.firstWhere(
          (voice) => voice.lang == _language,
          orElse: () => voices.first // Fallback to first available voice
        );
        utterance.voice = preferredVoice;
      } catch (e) {
        // Ignore voice selection error
        debugPrint('Web TTS Voice selection error: $e');
      }
      _synthesis.speak(utterance);
  }

  @override
  Future<void> stop() async {
    _synthesis.cancel();
  }
}

TtsInterface getTts() {
  debugPrint('Creating WebTtsImpl');
  return WebTtsImpl();
}
