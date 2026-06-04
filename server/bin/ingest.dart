import 'dart:io';
import 'package:uztour_server/database.dart';
import 'package:uztour_server/env.dart';
import 'package:uztour_server/r2.dart';
import 'package:uztour_server/tts.dart';

/// Sesi olmayan çeviriler için TTS üretip R2'ye yükler ve audio_asset yazar.
///
/// Kullanım (operatör, DATABASE_URL + TTS_* + R2_* ayarlıyken):
///   cd server && dart run bin/ingest.dart
///
/// TTS/R2 yapılandırması yoksa kuru çalışma: ne üretir ne yükler, sadece raporlar.
Future<void> main(List<String> args) async {
  final db = await PostgresDatabase.connect(Env.databaseUrl);
  final tts = TtsProvider.fromEnv();
  final r2 = R2Uploader.fromEnv();

  try {
    final rows = await db.query(
      'SELECT t.id, t.lang_code, t.body '
      'FROM translation t '
      'LEFT JOIN audio_asset a ON a.translation_id = t.id '
      'WHERE a.id IS NULL ORDER BY t.exhibit_id, t.lang_code',
    );
    if (rows.isEmpty) {
      stdout.writeln('Ses bekleyen çeviri yok.');
      return;
    }
    stdout.writeln('${rows.length} çeviri işlenecek (TTS: ${tts.voiceLabel}).');

    var done = 0;
    for (final t in rows) {
      final id = '${t['id']}';
      final lang = t['lang_code'] as String;
      final body = t['body'] as String;

      final bytes = await tts.synthesize(body, lang);
      if (bytes == null) {
        stdout.writeln('• $id ($lang): TTS yok — atlandı (kuru çalışma).');
        continue;
      }
      if (r2 == null) {
        stdout.writeln('• $id ($lang): R2 yapılandırması yok — yükleme atlandı.');
        continue;
      }
      final url = await r2.upload('audio/$id-$lang.mp3', bytes);
      await db.query(
        'INSERT INTO audio_asset (translation_id, url, tts_voice) '
        'VALUES (@tid, @url, @voice) '
        'ON CONFLICT (translation_id) DO UPDATE '
        'SET url = EXCLUDED.url, tts_voice = EXCLUDED.tts_voice, '
        'generated_at = now()',
        {'tid': id, 'url': url, 'voice': tts.voiceLabel},
      );
      done++;
      stdout.writeln('✓ $id ($lang) → $url');
    }
    stdout.writeln('Bitti: $done ses yüklendi.');
  } finally {
    await db.close();
  }
}
