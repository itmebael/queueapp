import 'package:flutter/foundation.dart';

/// TTS Interface
abstract class TtsInterface {
  Future<void> setLanguage(String language);
  Future<void> setSpeechRate(double rate);
  Future<void> setVolume(double volume);
  Future<void> setPitch(double pitch);
  Future<void> speak(String text);
  Future<void> stop();
}

/// Stub implementation for platforms without TTS
class TtsStub implements TtsInterface {
  @override
  Future<void> setLanguage(String language) async {}

  @override
  Future<void> setSpeechRate(double rate) async {}

  @override
  Future<void> setVolume(double volume) async {}

  @override
  Future<void> setPitch(double pitch) async {}

  @override
  Future<void> speak(String text) async {
    // Log the message - TTS not available on this platform
    debugPrint('TTS (not available): $text');
  }

  @override
  Future<void> stop() async {}
}
