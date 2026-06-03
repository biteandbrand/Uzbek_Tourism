import 'package:flutter_test/flutter_test.dart';
import 'package:uzbek_tour_app/models/exhibit.dart';
import 'package:uzbek_tour_app/services/content_service.dart';

void main() {
  group('exhibitIdFromPayload', () {
    test('geçerli payload id döndürür', () {
      expect(ContentService.exhibitIdFromPayload('uztour://exhibit/abc123'),
          'abc123');
    });

    test('baştaki/sondaki boşlukları yok sayar', () {
      expect(ContentService.exhibitIdFromPayload('  uztour://exhibit/xyz  '),
          'xyz');
    });

    test('yanlış şema null döndürür', () {
      expect(ContentService.exhibitIdFromPayload('https://exhibit/abc'),
          isNull);
    });

    test('yanlış host null döndürür', () {
      expect(ContentService.exhibitIdFromPayload('uztour://museum/abc'),
          isNull);
    });

    test('id yoksa null döndürür', () {
      expect(ContentService.exhibitIdFromPayload('uztour://exhibit/'), isNull);
    });

    test('çözülemeyen metin null döndürür', () {
      expect(ContentService.exhibitIdFromPayload('   '), isNull);
    });
  });

  group('Exhibit.localized', () {
    final exhibit = Exhibit.fromJson({
      'id': 'e1',
      'type': 'object',
      'translations': [
        {'lang_code': 'en', 'title': 'EN', 'body': 'en body'},
        {'lang_code': 'tr', 'title': 'TR', 'body': 'tr body'},
      ],
    });

    test('istenen dili döndürür', () {
      expect(exhibit.localized('tr')?.title, 'TR');
    });

    test('dil yoksa İngilizceye düşer', () {
      expect(exhibit.localized('zh')?.title, 'EN');
    });

    test('İngilizce de yoksa ilk çeviriye düşer', () {
      final noEn = Exhibit.fromJson({
        'id': 'e2',
        'type': 'object',
        'translations': [
          {'lang_code': 'uz', 'title': 'UZ', 'body': 'uz body'},
        ],
      });
      expect(noEn.localized('zh')?.title, 'UZ');
    });
  });
}
