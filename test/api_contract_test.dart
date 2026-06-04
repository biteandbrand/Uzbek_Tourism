import 'package:flutter_test/flutter_test.dart';
import 'package:uzbek_tour_app/mock_api.dart';

// API sözleşmesi (docs/API.md). Bu anahtar kümeleri server/test/contract_test.dart
// ile BİREBİR AYNI tutulmalı; ikisi de aynı sözleşmeye karşı doğrular, böylece
// mock_server ile gerçek backend yanıtlarının şekli garanti olarak özdeş kalır.
const kMuseumKeys = {'id', 'name', 'city'};
const kSiteKeys = {'id', 'city', 'name', 'lat', 'lng', 'category'};
const kExhibitKeys = {'id', 'type', 'position', 'museum_id', 'translations'};
const kTranslationKeys = {'lang_code', 'title', 'body', 'audio'};
const kAudioKeys = {'url', 'duration_sec'};
const kRouteKeys = {'id', 'name', 'summary', 'stops'};
const kStopKeys = {'city', 'title', 'description', 'duration_label'};

Set<String> keysOf(Object? o) => (o as Map).keys.cast<String>().toSet();

void main() {
  group('mock_server sözleşmesi', () {
    test('/museums → museum şekli', () {
      final list = mockRoute('/museums', const {}) as List;
      expect(keysOf(list.first), kMuseumKeys);
    });

    test('/sites → site şekli', () {
      final list = mockRoute('/sites', const {}) as List;
      expect(keysOf(list.first), kSiteKeys);
    });

    test('/cities → düz string listesi', () {
      final list = mockRoute('/cities', const {}) as List;
      expect(list.first, isA<String>());
    });

    test('/exhibits/{id} → exhibit + translation + audio şekli', () {
      final e = mockRoute('/exhibits/demo', const {}) as Map;
      expect(keysOf(e), kExhibitKeys);
      final tr = (e['translations'] as List).first as Map; // demo 'en' → audio'lu
      expect(keysOf(tr), kTranslationKeys);
      expect(keysOf(tr['audio']), kAudioKeys);
    });

    test('/routes → route + stop şekli', () {
      final r = (mockRoute('/routes', const {}) as List).first as Map;
      expect(keysOf(r), kRouteKeys);
      expect(keysOf((r['stops'] as List).first), kStopKeys);
    });
  });
}
