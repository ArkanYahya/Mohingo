/// A registry phrase's fill-in slots — `"My name is {name}."`.
final _placeholder = RegExp(r'\{(\w+)\}');

/// [text] as the device engine should speak it: each placeholder becomes a
/// pause. Bundled clips are keyed by the raw text and render the pause
/// themselves (see ADR 0008), so only the device fallback applies this.
String phraseForSpeech(String text) => text.replaceAll(_placeholder, '…');
