import 'package:test/test.dart';
import 'package:uztour_server/database.dart';
import 'package:uztour_server/repository.dart';

/// SQL'e göre sabit satır döndüren sahte DB (Postgres gerekmez).
class FakeDb implements Database {
  FakeDb(this.responder);

  final List<Map<String, dynamic>> Function(String sql, Map<String, dynamic> p)
      responder;
  final List<String> seen = [];

  @override
  Future<List<Map<String, dynamic>>> query(
    String sql, [
    Map<String, dynamic> params = const {},
  ]) async {
    seen.add(sql);
    return responder(sql, params);
  }

  @override
  Future<void> close() async {}
}

void main() {
  group('Repository', () {
    test('museums() id/name/city haritalar', () async {
      final repo = Repository(FakeDb((sql, p) => [
            {'id': 'm1', 'name': 'Afrasiyab', 'city': 'Samarkand'},
          ]));
      final out = await repo.museums();
      expect(out, [
        {'id': 'm1', 'name': 'Afrasiyab', 'city': 'Samarkand'},
      ]);
    });

    test('cities() string listesi döndürür', () async {
      final repo = Repository(FakeDb((sql, p) => [
            {'city': 'Bukhara'},
            {'city': 'Samarkand'},
          ]));
      expect(await repo.cities(), ['Bukhara', 'Samarkand']);
    });

    test('sites(city) WHERE city kullanır ve lat/lng double olur', () async {
      late Map<String, dynamic> captured;
      final repo = Repository(FakeDb((sql, p) {
        captured = p;
        expect(sql, contains('WHERE city = @city'));
        return [
          {
            'id': 's1',
            'city': 'Samarkand',
            'name': 'Registan',
            'lat': 39,
            'lng': 66,
            'category': 'square',
          },
        ];
      }));
      final out = await repo.sites(city: 'Samarkand');
      expect(captured['city'], 'Samarkand');
      expect(out.single['lat'], isA<double>());
      expect(out.single['name'], 'Registan');
    });

    test('exhibit() çevirileri + iç içe audio kurar (yoksa audio anahtarı yok)',
        () async {
      final repo = Repository(FakeDb((sql, p) {
        if (sql.contains('FROM exhibit WHERE id')) {
          return [
            {'id': 'e1', 'type': 'object', 'position': 'P', 'museum_id': 'm1'},
          ];
        }
        if (sql.contains('FROM translation')) {
          return [
            {
              'lang_code': 'en',
              'title': 'T',
              'body': 'B',
              'audio_url': 'https://r2/a.mp3',
              'audio_duration': 9,
            },
            {
              'lang_code': 'tr',
              'title': 'TR',
              'body': 'BR',
              'audio_url': null,
              'audio_duration': null,
            },
          ];
        }
        return [];
      }));

      final e = await repo.exhibit('e1');
      expect(e!['id'], 'e1');
      expect(e['museum_id'], 'm1');
      final tr = e['translations'] as List;
      expect(tr, hasLength(2));
      expect((tr[0] as Map)['audio'], {'url': 'https://r2/a.mp3', 'duration_sec': 9});
      expect((tr[1] as Map).containsKey('audio'), isFalse); // ses yok
    });

    test('exhibit() bulunamazsa null', () async {
      final repo = Repository(FakeDb((sql, p) => []));
      expect(await repo.exhibit('yok'), isNull);
    });

    test('routes() durakları ord sırasına göre kurar', () async {
      final repo = Repository(FakeDb((sql, p) {
        if (sql.contains('FROM route_stop')) {
          return [
            {
              'city': 'Tashkent',
              'title': 'Varış',
              'description': 'D',
              'duration_label': '1 gün',
            },
          ];
        }
        if (sql.contains('FROM route')) {
          return [
            {'id': 'r1', 'name': 'Rota', 'summary': 'özet'},
          ];
        }
        return [];
      }));

      final out = await repo.routes();
      expect(out.single['name'], 'Rota');
      final stops = out.single['stops'] as List;
      expect((stops.single as Map)['city'], 'Tashkent');
      expect((stops.single as Map)['duration_label'], '1 gün');
    });
  });
}
