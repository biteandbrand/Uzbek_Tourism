import 'dart:convert';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import 'repository.dart';

Response _json(Object? data, {int status = 200}) => Response(
      status,
      body: jsonEncode(data),
      headers: const {'content-type': 'application/json; charset=utf-8'},
    );

/// docs/API.md uç noktalarını sunan shelf handler'ı.
/// Okuma uç noktaları herkese açıktır (brief: museums/exhibits/sites/routes).
Handler buildApi(Repository repo) {
  final router = Router();

  // Liveness: süreç ayakta mı (DB'ye dokunmaz).
  router.get('/healthz', (Request r) => _json({'status': 'ok'}));

  // Readiness: DB'ye erişilebiliyor mu.
  router.get('/readyz', (Request r) async {
    try {
      await repo.db.query('SELECT 1');
      return _json({'status': 'ready'});
    } catch (_) {
      return _json({'status': 'unavailable'}, status: 503);
    }
  });

  router.get('/museums', (Request r) async => _json(await repo.museums()));

  router.get('/museums/<id>/exhibits',
      (Request r, String id) async => _json(await repo.museumExhibits(id)));

  router.get('/exhibits/<id>', (Request r, String id) async {
    final e = await repo.exhibit(id);
    return e == null ? _json({'error': 'not found'}, status: 404) : _json(e);
  });

  router.get('/sites', (Request r) async {
    final city = r.url.queryParameters['city'];
    return _json(await repo.sites(city: city));
  });

  router.get('/cities', (Request r) async => _json(await repo.cities()));

  router.get('/routes', (Request r) async => _json(await repo.routes()));

  return router.call;
}
