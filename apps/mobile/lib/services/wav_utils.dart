import 'dart:typed_data';

/// Wraps raw 16-bit PCM chunks (as produced by `record`'s `startStream`)
/// in a minimal 44-byte WAV header. Single shared implementation —
/// previously duplicated across session_provider, language_screen and
/// onboarding_screen.
Uint8List buildWav(List<Uint8List> chunks, {int sampleRate = 16000}) {
  final pcm = Uint8List.fromList(chunks.expand((c) => c).toList());
  final header = ByteData(44);
  void setStr(int offset, String s) {
    for (var i = 0; i < s.length; i++) {
      header.setUint8(offset + i, s.codeUnitAt(i));
    }
  }

  setStr(0, 'RIFF');
  header.setUint32(4, 36 + pcm.length, Endian.little);
  setStr(8, 'WAVE');
  setStr(12, 'fmt ');
  header.setUint32(16, 16, Endian.little);
  header.setUint16(20, 1, Endian.little); // PCM
  header.setUint16(22, 1, Endian.little); // mono
  header.setUint32(24, sampleRate, Endian.little);
  header.setUint32(28, sampleRate * 2, Endian.little);
  header.setUint16(32, 2, Endian.little);
  header.setUint16(34, 16, Endian.little);
  setStr(36, 'data');
  header.setUint32(40, pcm.length, Endian.little);
  final result = Uint8List(44 + pcm.length);
  result.setRange(0, 44, header.buffer.asUint8List());
  result.setRange(44, result.length, pcm);
  return result;
}
