import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'env.dart';

/// Metni sese çeviren takılabilir sağlayıcı. Anahtar yoksa [NullTts] döner
/// (kuru çalışma: ses üretilmez, yalnızca kayıt akışı denenir).
abstract class TtsProvider {
  /// mp3 baytları; sağlayıcı yoksa null.
  Future<Uint8List?> synthesize(String text, String langCode);

  /// audio_asset.tts_voice'a yazılacak etiket.
  String get voiceLabel;

  static TtsProvider fromEnv() {
    final provider = Env.maybe('TTS_PROVIDER');
    final key = Env.maybe('TTS_API_KEY');
    if (provider == null || key == null) return NullTts();
    switch (provider.toLowerCase()) {
      case 'elevenlabs':
        return ElevenLabsTts(
          apiKey: key,
          voiceId: Env.maybe('TTS_VOICE_ID') ?? 'JBFqnCBsd6RMkjVDRZzb',
        );
      default:
        return NullTts();
    }
  }
}

/// Sağlayıcı yapılandırılmamış — kuru çalışma.
class NullTts implements TtsProvider {
  @override
  String get voiceLabel => 'dry-run';

  @override
  Future<Uint8List?> synthesize(String text, String langCode) async => null;
}

/// ElevenLabs TTS (çok dilli model).
class ElevenLabsTts implements TtsProvider {
  ElevenLabsTts({
    required this.apiKey,
    required this.voiceId,
    this.modelId = 'eleven_multilingual_v2',
  });

  final String apiKey;
  final String voiceId;
  final String modelId;

  @override
  String get voiceLabel => 'elevenlabs:$voiceId';

  @override
  Future<Uint8List?> synthesize(String text, String langCode) async {
    final res = await http.post(
      Uri.parse('https://api.elevenlabs.io/v1/text-to-speech/$voiceId'),
      headers: {
        'xi-api-key': apiKey,
        'content-type': 'application/json',
        'accept': 'audio/mpeg',
      },
      body: jsonEncode({'text': text, 'model_id': modelId}),
    );
    if (res.statusCode != 200) {
      throw Exception('TTS hatası (${res.statusCode}): ${res.body}');
    }
    return res.bodyBytes;
  }
}
