import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:uzbek_tour_app/services/discovery_service.dart';

/// JSON gövdeyi UTF-8 charset'iyle döndürür (Türkçe karakterler için şart;
/// charset verilmezse http.Response gövdeyi Latin-1 ile kodlar).
http.Response _json(Object data) => http.Response(
      jsonEncode(data),
      200,
      headers: {'content-type': 'application/json; charset=utf-8'},
    );

DiscoveryService _service(MockClient client) =>
    DiscoveryService(useMock: false, client: client);

void main() {
  group('DiscoveryService (API yolu)', () {
    test('museums() JSON listesini ayrıştırır', () async {
      final client = MockClient((req) async {
        expect(req.url.path, '/museums');
        return _json([
          {'id': 'm1', 'name': 'Afrasiyab', 'city': 'Samarkand'},
        ]);
      });
      final museums = await _service(client).museums();
      expect(museums, hasLength(1));
      expect(museums.first.name, 'Afrasiyab');
      expect(museums.first.city, 'Samarkand');
    });

    test('sitesForCity() şehri sorgu parametresine koyar', () async {
      final client = MockClient((req) async {
        expect(req.url.path, '/sites');
        expect(req.url.queryParameters['city'], 'Samarkand');
        return _json([
          {
            'id': 's1',
            'city': 'Samarkand',
            'name': 'Registan',
            'lat': 39.6,
            'lng': 66.9,
            'category': 'square',
          },
        ]);
      });
      final sites = await _service(client).sitesForCity('Samarkand');
      expect(sites.single.name, 'Registan');
      expect(sites.single.lat, 39.6);
    });

    test('routes() duraklarıyla ayrıştırır', () async {
      final client = MockClient((req) async {
        return _json([
          {
            'id': 'r1',
            'name': 'Test rota',
            'summary': 'özet',
            'stops': [
              {
                'city': 'Bukhara',
                'title': 'Durak',
                'description': 'açıklama',
                'duration_label': '1 gün',
              },
            ],
          },
        ]);
      });
      final routes = await _service(client).routes();
      expect(routes.single.stops.single.city, 'Bukhara');
      expect(routes.single.stops.single.durationLabel, '1 gün');
    });

    test('cities() string listesi döndürür', () async {
      final client = MockClient((req) async => _json(['Bukhara', 'Samarkand']));
      expect(await _service(client).cities(), ['Bukhara', 'Samarkand']);
    });

    test('200 dışı yanıt hata fırlatır', () {
      final client = MockClient((req) async => http.Response('nope', 500));
      expect(_service(client).museums(), throwsException);
    });
  });
}
