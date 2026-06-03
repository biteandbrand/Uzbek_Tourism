import 'package:flutter_test/flutter_test.dart';
import 'package:uzbek_tour_app/models/exhibit.dart';

Exhibit _exhibit(List<String> langs) => Exhibit.fromJson({
      'id': 'e1',
      'type': 'object',
      'translations': [
        for (final l in langs)
          {'lang_code': l, 'title': l.toUpperCase(), 'body': 'body'},
      ],
    });

void main() {
  group('Exhibit.localizedWith', () {
    test('istenen dil varsa geri-dönüş değildir', () {
      final r = _exhibit(['en', 'tr']).localizedWith('tr');
      expect(r?.translation.title, 'TR');
      expect(r?.isFallback, isFalse);
    });

    test('istenen dil yoksa İngilizceye düşer (isFallback)', () {
      final r = _exhibit(['en', 'tr']).localizedWith('zh');
      expect(r?.translation.langCode, 'en');
      expect(r?.isFallback, isTrue);
    });

    test('İngilizce de yoksa ilk çeviriye düşer', () {
      final r = _exhibit(['uz']).localizedWith('zh');
      expect(r?.translation.langCode, 'uz');
      expect(r?.isFallback, isTrue);
    });

    test('localized aynı çeviriyi döndürür (uyumluluk)', () {
      final e = _exhibit(['en', 'tr']);
      expect(e.localized('tr')?.title, 'TR');
      expect(e.localized('zh')?.title, 'EN');
    });
  });
}
