import 'tts_interface.dart';
import 'tts_impl_io.dart' if (dart.library.html) 'tts_impl_web.dart';

export 'tts_interface.dart';

TtsInterface createTts() {
  return getTts();
}
