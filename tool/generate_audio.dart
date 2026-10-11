// ignore_for_file: avoid_print
import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';

void main() {
  final dir = Directory('assets/audio');
  if (!dir.existsSync()) {
    dir.createSync(recursive: true);
  }

  // Generate pleasant soft sounds
  _createWav(File('assets/audio/whoosh.wav'), durationSec: 0.18, freqStart: 450, freqEnd: 150);
  _createWav(File('assets/audio/tap.wav'), durationSec: 0.08, freqStart: 600, freqEnd: 600);
  _createWav(File('assets/audio/error.wav'), durationSec: 0.15, freqStart: 180, freqEnd: 140);
  _createWav(File('assets/audio/win.wav'), durationSec: 0.35, freqStart: 523.25, freqEnd: 784.0);

  print('Audio assets generated successfully.');
}

void _createWav(File file, {
  required double durationSec,
  required double freqStart,
  required double freqEnd,
}) {
  const sampleRate = 22050;
  final numSamples = (sampleRate * durationSec).toInt();
  final byteLength = numSamples * 2;
  final buffer = ByteData(44 + byteLength);

  // RIFF header
  buffer.setUint8(0, 0x52); // 'R'
  buffer.setUint8(1, 0x49); // 'I'
  buffer.setUint8(2, 0x46); // 'F'
  buffer.setUint8(3, 0x46); // 'F'
  buffer.setUint32(4, 36 + byteLength, Endian.little);
  buffer.setUint8(8, 0x57); // 'W'
  buffer.setUint8(9, 0x41); // 'A'
  buffer.setUint8(10, 0x56); // 'V'
  buffer.setUint8(11, 0x45); // 'E'

  // fmt chunk
  buffer.setUint8(12, 0x66); // 'f'
  buffer.setUint8(13, 0x6D); // 'm'
  buffer.setUint8(14, 0x74); // 't'
  buffer.setUint8(15, 0x20); // ' '
  buffer.setUint32(16, 16, Endian.little); // chunk length
  buffer.setUint16(20, 1, Endian.little);  // PCM format
  buffer.setUint16(22, 1, Endian.little);  // 1 channel (mono)
  buffer.setUint32(24, sampleRate, Endian.little); // sample rate
  buffer.setUint32(28, sampleRate * 2, Endian.little); // byte rate
  buffer.setUint16(32, 2, Endian.little);  // block align
  buffer.setUint16(34, 16, Endian.little); // bits per sample

  // data chunk
  buffer.setUint8(36, 0x64); // 'd'
  buffer.setUint8(37, 0x61); // 'a'
  buffer.setUint8(38, 0x74); // 't'
  buffer.setUint8(39, 0x61); // 'a'
  buffer.setUint32(40, byteLength, Endian.little);

  // Audio samples (smooth frequency sweep with cosine envelope for gentle pop-free audio)
  for (int i = 0; i < numSamples; i++) {
    final t = i / numSamples;
    final freq = freqStart + (freqEnd - freqStart) * t;
    // Envelope: sine window to prevent click/pop
    final envelope = math.sin(math.pi * t);
    final sampleVal = (math.sin(2 * math.pi * freq * (i / sampleRate)) * envelope * 0.4 * 32767).toInt();
    buffer.setInt16(44 + i * 2, sampleVal.clamp(-32768, 32767), Endian.little);
  }

  file.writeAsBytesSync(buffer.buffer.asUint8List());
}
