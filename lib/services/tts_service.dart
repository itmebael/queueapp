import 'tts_wrapper.dart';

class TtsService {
  static final TtsService _instance = TtsService._internal();
  factory TtsService() => _instance;
  
  late final TtsInterface _tts;
  
  TtsService._internal() {
    _tts = createTts();
  }

  // Speak text using platform-specific TTS
  Future<void> speak(String text) async {
    try {
      await _tts.speak(text);
    } catch (e) {
      print('TTS Error: $e');
    }
  }

  // Announce queue completion
  Future<void> announceQueueCompletion(String userName, String department) async {
    final message = '$userName, your queue for $department department is now complete.';
    await speak(message);
  }

  // Announce queue position
  Future<void> announceQueuePosition(String userName, int position) async {
    final message = '$userName, you are now number $position in the queue.';
    await speak(message);
  }
}