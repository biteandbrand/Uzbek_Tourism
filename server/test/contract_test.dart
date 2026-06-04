import 'package:test/test.dart';
import 'package:uztour_server/database.dart';
import 'package:uztour_server/repository.dart';

// API sözleşmesi (docs/API.md). Bu anahtar kümeleri kök test/api_contract_test.dart
// ile BİREBİR AYNI tutulmalı; ikisi de aynı sözleşmeye karşı doğrular, böylece
// gerçek backend ile mock_server yanıtlarının şekli garanti olarak özdeş kalır.
const kMuseumKeys = {'id', 'name', 'city'};
const kSiteKeys = {'id', 'city', 'name', 'lat', 'lng', 'category'};
const kExhibitKeys = {'id', 'type', 'position', 'museum_id', 'translations'};
const kTranslationKeys = {'lang_code', 'title', 'body', 'audio'};
const kAudioKeys = {'url', 'duration_sec'};
const kRouteKeys = {'id', 'name', 'summary', 'stops'};
const kStopKeys = {'city', 'title', 'description', 'duration_label'};

class FakeDb implements Database {
  FakeDb(this.responder);
  final List<Map<String, dynamic>> Function(String, Map<String, dynamic>)
      responder;
  @override
  Future<List<Map<String, dynamic>>> query(String sql,
          [Map<String, dynamic> p = const {}]) async =>
      responder(sql, p);
  @override
  Future<void> close() async {}
}

Set<String> keysOf(Object? o) => (o as Map).keys.cast<String>().toSet();

void main() {
  group('server (Repository) sözleşmesi', () {
    test('museums() → museum şekli', () async {
      final repo = Repository(
          FakeDb((s, p) => [{'id': 'm1', 'name': 'A', 'city': 'C'}]));
      expect(keysOf((await repo.museums()).first), kMuseumKeys);
    });

    test('sites() → site şekli', () async {
      final repo = Repository(FakeDb((s, p) => [
            {'id': 's1', 'city': 'C', 'name': 'N', 'lat': 1, 'lng': 2, 'category': 'square'},
          ]));
      expect(keysOf((await repo.sites()).first), kSiteKeys);
    });

    test('cities() → düz string listesi', () async {
      final repo = Repository(FakeDb((s, p) => [{'city': 'Bukhara'}]));
      expect((await repo.cities()).first, isA<String>());
    });

    test('exhibit() → exhibit + translation + audio şekli', () async {
      final repo = Repository(FakeDb((sql, p) {
        if (sql.contains('FROM exhibit')) {
          return [{'id': 'e1', 'type': 'object', 'position': 'P', 'museum_id': 'm1'}];
        }
        if (sql.contains('FROM translation')) {
          return [
            {'lang_code': 'en', 'title': 'T', 'body': 'B', 'audio_url': 'u', 'audio_duration': 9},
          ];
        }
        return [];
      }));
      final e = (await repo.exhibit('e1'))!;
      expect(keysOf(e), kExhibitKeys);
      final tr = (e['translations'] as List).first as Map;
      expect(keysOf(tr), kTranslationKeys);
      expect(keysOf(tr['audio']), kAudioKeys);
    });

    test('routes() → route + stop şekli', () async {
      final repo = Repository(FakeDb((sql, p) {
        if (sql.contains('FROM route_stop')) {
          return [{'city': 'C', 'title': 'T', 'description': 'D', 'duration_label': '1 gün'}];
        }
        if (sql.contains('FROM route')) {
          return [{'id': 'r1', 'name': 'N', 'summary': 'S'}];
        }
        return [];
      }));
      final r = (await repo.routes()).first;
      expect(keysOf(r), kRouteKeys);
      expect(keysOf((r['stops'] as List).first), kStopKeys);
    });
  });
}
