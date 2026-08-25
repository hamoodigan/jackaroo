// Generates the game's sound effects as .wav files into assets/sounds/.
//
//     dart run tool/make_sounds.dart
//
// Every sound is synthesized from sine waves and noise — no downloads, no
// copyright worries. Tweak numbers and re-run to taste.
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

const sampleRate = 22050;

void main() {
  final outDir = Directory('assets/sounds')..createSync(recursive: true);
  save('${outDir.path}/card.wav', cardFlick());
  save('${outDir.path}/deal.wav', dealShuffle());
  save('${outDir.path}/move.wav', moveTick());
  save('${outDir.path}/capture.wav', captureZap());
  save('${outDir.path}/swap.wav', swapWhoosh());
  save('${outDir.path}/home.wav', homeChime());
  save('${outDir.path}/win.wav', winFanfare());
  save('${outDir.path}/music.wav', musicLoop());
  stdout.writeln('Wrote 8 sounds into ${outDir.path}');
}

/// A crisp paper flick for picking / playing a card.
List<double> cardFlick() {
  final rng = Random(3);
  final s = silence(0.12);
  mix(s, 0, noise(rng, 0.08, decay: 70), gain: 0.5);
  mix(s, 0, tone(1800, 0.05, decay: 90), gain: 0.15);
  return s;
}

/// Several quick flicks — cards being dealt.
List<double> dealShuffle() {
  final rng = Random(11);
  final s = silence(0.5);
  for (final t in [0.0, 0.09, 0.18, 0.27, 0.36]) {
    mix(s, t, noise(rng, 0.06, decay: 80), gain: 0.4);
  }
  return s;
}

/// Soft tick for every cell a marble hops over.
List<double> moveTick() {
  final s = silence(0.06);
  mix(s, 0, tone(1050, 0.06, decay: 60), gain: 0.35);
  return s;
}

/// Falling pitch — a marble being burned.
List<double> captureZap() {
  final s = silence(0.3);
  mix(s, 0, sweep(880, 200, 0.28, decay: 8), gain: 0.6);
  return s;
}

/// Two crossing sweeps — the Jack swap.
List<double> swapWhoosh() {
  final s = silence(0.35);
  mix(s, 0, sweep(400, 900, 0.3, decay: 7), gain: 0.35);
  mix(s, 0.03, sweep(900, 400, 0.3, decay: 7), gain: 0.35);
  return s;
}

/// Bright two-note chime — a marble reaching home.
List<double> homeChime() {
  final s = silence(0.5);
  mix(s, 0, tone(783.99, 0.25, decay: 8), gain: 0.4);
  mix(s, 0.12, tone(1174.66, 0.38, decay: 6), gain: 0.4);
  return s;
}

/// Rising arpeggio for the winning team.
List<double> winFanfare() {
  final s = silence(1.2);
  const notes = [523.25, 659.25, 783.99, 1046.5, 1318.5];
  for (var i = 0; i < notes.length; i++) {
    final long = i == notes.length - 1;
    mix(s, i * 0.15, tone(notes[i], long ? 0.6 : 0.18, decay: long ? 4 : 12),
        gain: 0.45);
  }
  return s;
}

/// Gentle looping background: soft pad + arpeggio, ~20s.
List<double> musicLoop() {
  const beat = 60 / 96;
  const chords = [
    [220.00, 261.63, 329.63], // Am
    [174.61, 220.00, 261.63], // F
    [261.63, 329.63, 392.00], // C
    [196.00, 246.94, 293.66], // G
  ];
  const beatsPerChord = 8;
  final total = chords.length * beatsPerChord * beat;
  final s = silence(total);
  for (var c = 0; c < chords.length; c++) {
    final start = c * beatsPerChord * beat;
    for (final f in chords[c]) {
      mix(s, start, tone(f, beatsPerChord * beat, decay: 0.5), gain: 0.06);
    }
    const pattern = [0, 2, 1, 2, 0, 1, 2, 1];
    for (var k = 0; k < beatsPerChord * 2; k++) {
      final f = chords[c][pattern[k % pattern.length]] * 2;
      mix(s, start + k * beat / 2, tone(f, beat / 2, decay: 6), gain: 0.14);
    }
  }
  return s;
}

// ── synth helpers ─────────────────────────────────────────────────────────

List<double> silence(double seconds) =>
    List.filled((seconds * sampleRate).round(), 0);

List<double> tone(double freq, double seconds, {double decay = 5}) {
  final n = (seconds * sampleRate).round();
  return List.generate(n, (i) {
    final t = i / sampleRate;
    return sin(2 * pi * freq * t) * exp(-decay * t);
  });
}

List<double> sweep(double f1, double f2, double seconds, {double decay = 5}) {
  final n = (seconds * sampleRate).round();
  var phase = 0.0;
  return List.generate(n, (i) {
    final t = i / sampleRate;
    final f = f1 + (f2 - f1) * (i / n);
    phase += 2 * pi * f / sampleRate;
    return sin(phase) * exp(-decay * t);
  });
}

List<double> noise(Random rng, double seconds, {double decay = 20}) {
  final n = (seconds * sampleRate).round();
  return List.generate(n, (i) {
    final t = i / sampleRate;
    return (rng.nextDouble() * 2 - 1) * exp(-decay * t);
  });
}

void mix(List<double> dst, double atSeconds, List<double> src,
    {double gain = 1}) {
  final start = (atSeconds * sampleRate).round();
  for (var i = 0; i < src.length && start + i < dst.length; i++) {
    dst[start + i] += src[i] * gain;
  }
}

void save(String path, List<double> samples) {
  final n = samples.length;
  final dataSize = n * 2;
  final b = BytesBuilder();
  void str(String s) => b.add(s.codeUnits);
  void u32(int v) => b.add(
      Uint8List(4)..buffer.asByteData().setUint32(0, v, Endian.little));
  void u16(int v) => b.add(
      Uint8List(2)..buffer.asByteData().setUint16(0, v, Endian.little));
  str('RIFF');
  u32(36 + dataSize);
  str('WAVEfmt ');
  u32(16);
  u16(1);
  u16(1);
  u32(sampleRate);
  u32(sampleRate * 2);
  u16(2);
  u16(16);
  str('data');
  u32(dataSize);
  final data = ByteData(dataSize);
  for (var i = 0; i < n; i++) {
    data.setInt16(
        i * 2, (samples[i].clamp(-1.0, 1.0) * 32767).round(), Endian.little);
  }
  b.add(data.buffer.asUint8List());
  File(path).writeAsBytesSync(b.toBytes());
}
