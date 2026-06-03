import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:uzbek_tour_app/services/content_service.dart';
import 'package:uzbek_tour_app/services/offline_store.dart';

/// Testler için bellek içi depo (path_provider'a ihtiyaç bırakmaz).
class MemoryStore implements OfflineStore {
  final Map<String, String> exhibits = {};
  Set<String> museums = {};

  @override
  Future<String?> readExhibit(String id) async => exhibits[id];

  @override
  Future<void> writeExhibit(String id, String json) async =>
      exhibits[id] = json;

  @override
  Future<Set<String>> readDownloadedMuseums() async => {...museums};

  @override
  Future<void> writeDownloadedMuseums(Set<String> ids) async =>
      museums = {...ids};
}

Map<String, dynamic> _exhibitJson(String id) => {
      'id': id,
      'type': 'object',
      'museum_id': 'm1',
      'translations': [
        {'lang_code': 'en', 'title': 'Title $id', 'body': 'Body'},
      ],
    };

void main() {
  group('ContentService (API + önbellek yolu)', () {
    test('getExhibit ağdan çeker, ayrıştırır ve önbelleğe yazar', () async {
      var calls = 0;
      final client = MockClient((req) async {
        calls++;
        expect(req.url.path, '/exhibits/e1');
        return http.Response(jsonEncode(_exhibitJson('e1')), 200);
      });
      final store = MemoryStore();
      final svc = ContentService(useMock: false, client: client, store: store);

      final ex = await svc.getExhibit('e1');
      expect(ex.localized('en')?.title, 'Title e1');
      expect(store.exhibits.containsKey('e1'), isTrue);
      expect(calls, 1);
    });

    test('getExhibit ikinci çağrıda önbellekten okur (ağ yok)', () async {
      var calls = 0;
      final client = MockClient((req) async {
        calls++;
        return http.Response(jsonEncode(_exhibitJson('e1')), 200);
      });
      final store = MemoryStore();
      final svc = ContentService(useMock: false, client: client, store: store);

      await svc.getExhibit('e1');
      await svc.getExhibit('e1');
      expect(calls, 1); // ikinci çağrı önbellekten geldi
    });

    test('prefetchMuseum objeleri yazar ve müzeyi işaretler', () async {
      final client = MockClient((req) async {
        expect(req.url.path, '/museums/m1/exhibits');
        return http.Response(
            jsonEncode([_exhibitJson('e1'), _exhibitJson('e2')]), 200);
      });
      final store = MemoryStore();
      final svc = ContentService(useMock: false, client: client, store: store);

      await svc.prefetchMuseum('m1');
      expect(store.exhibits.keys, containsAll(['e1', 'e2']));
      expect(await svc.downloadedMuseums(), {'m1'});
    });

    test('200 dışı yanıt hata fırlatır', () {
      final client = MockClient((req) async => http.Response('x', 404));
      final svc = ContentService(
          useMock: false, client: client, store: MemoryStore());
      expect(svc.getExhibit('e1'), throwsException);
    });
  });
}
