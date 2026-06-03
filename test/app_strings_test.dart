import 'package:flutter_test/flutter_test.dart';
import 'package:uzbek_tour_app/l10n/app_strings.dart';

void main() {
  group('AppStrings.of', () {
    test('tr ve en farklı metin döndürür', () {
      expect(AppStrings.of('tr').qrTitle, isNot(AppStrings.of('en').qrTitle));
      expect(AppStrings.of('tr').qrTitle, 'Müzede QR okut');
      expect(AppStrings.of('en').qrTitle, 'Scan QR at the museum');
    });

    test('çevirisi olmayan dil İngilizceye düşer', () {
      expect(AppStrings.of('zh').qrTitle, AppStrings.of('en').qrTitle);
      expect(AppStrings.of('uz').routesTitle, AppStrings.of('en').routesTitle);
    });
  });

  group('biçimleme yardımcıları', () {
    final tr = AppStrings.of('tr');

    test('museumsReady sayıyı yerleştirir', () {
      expect(tr.museumsReady(3), '3 müze çevrimdışı hazır');
    });

    test('resultsCount sayıyı yerleştirir', () {
      expect(tr.resultsCount(5), '5 sonuç');
    });

    test('downloadFirst adı yerleştirir', () {
      expect(tr.downloadFirst('Afrasiyab'), 'Önce "Afrasiyab" içeriğini indirin');
    });

    test('cityRecommendations şehri yerleştirir', () {
      expect(tr.cityRecommendations('Buhara'), 'Buhara önerileri');
    });

    test('category bilinen ve bilinmeyen kodları çevirir', () {
      expect(tr.category('mosque'), 'Cami');
      expect(tr.category('mausoleum'), 'Türbe');
      expect(tr.category(null), 'Mekan');
      expect(tr.category('bilinmeyen'), 'Mekan');
    });

    test('error mesajı biçimler', () {
      expect(AppStrings.of('en').error('boom'), 'Error: boom');
    });
  });

  group('supportedUiLanguages', () {
    test('en ve tr içerir', () {
      expect(AppStrings.supportedUiLanguages, containsAll(['en', 'tr']));
    });

    test('listedeki her dil bir AppStrings çözer', () {
      for (final code in AppStrings.supportedUiLanguages) {
        expect(AppStrings.of(code), isA<AppStrings>());
      }
    });
  });
}
