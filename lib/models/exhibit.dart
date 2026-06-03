// Veri modeli sınıfları — schema.sql'deki tablolarla birebir.

class AudioAsset {
  final String url;
  final int? durationSec;

  AudioAsset({required this.url, this.durationSec});

  factory AudioAsset.fromJson(Map<String, dynamic> j) => AudioAsset(
        url: j['url'] as String,
        durationSec: j['duration_sec'] as int?,
      );
}

/// Bir exhibit'in tek bir dildeki içeriği (başlık + metin + ses).
class Translation {
  final String langCode;
  final String title;
  final String body;
  final AudioAsset? audio;

  Translation({
    required this.langCode,
    required this.title,
    required this.body,
    this.audio,
  });

  factory Translation.fromJson(Map<String, dynamic> j) => Translation(
        langCode: j['lang_code'] as String,
        title: j['title'] as String,
        body: j['body'] as String,
        audio: j['audio'] == null
            ? null
            : AudioAsset.fromJson(j['audio'] as Map<String, dynamic>),
      );
}

/// Oda ya da obje. type: 'room' | 'object'.
class Exhibit {
  final String id;
  final String type;
  final String? position;

  /// Ait olduğu müze (yanlış müzede okutma uyarısı için).
  final String? museumId;

  /// Dil koduna göre içerik. Tüm diller önceden indirilip burada tutulur
  /// (offline kullanım için).
  final Map<String, Translation> translations;

  Exhibit({
    required this.id,
    required this.type,
    this.position,
    this.museumId,
    required this.translations,
  });

  Translation? localized(String langCode) => localizedWith(langCode)?.translation;

  /// İstenen dildeki çeviri + bunun bir geri-dönüş olup olmadığı.
  /// Sıra: istenen dil → İngilizce → ilk çeviri. İstenen dil yoksa
  /// [isFallback] true olur ve kullanılan dil [Translation.langCode]'dadır.
  ({Translation translation, bool isFallback})? localizedWith(String langCode) {
    final exact = translations[langCode];
    if (exact != null) return (translation: exact, isFallback: false);
    final fallback = translations['en'] ?? translations.values.firstOrNull;
    if (fallback != null) return (translation: fallback, isFallback: true);
    return null;
  }

  factory Exhibit.fromJson(Map<String, dynamic> j) {
    final list = (j['translations'] as List).cast<Map<String, dynamic>>();
    return Exhibit(
      id: j['id'] as String,
      type: j['type'] as String,
      position: j['position'] as String?,
      museumId: j['museum_id'] as String?,
      translations: {
        for (final t in list) t['lang_code'] as String: Translation.fromJson(t),
      },
    );
  }
}

extension _FirstOrNull<E> on Iterable<E> {
  E? get firstOrNull => isEmpty ? null : first;
}
