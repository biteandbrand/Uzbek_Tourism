import 'package:shelf/shelf.dart';
import 'package:test/test.dart';
import 'package:uztour_server/middleware.dart';

void main() {
  group('RateLimiter', () {
    test('pencere kotası dolana kadar izin verir', () {
      final rl = RateLimiter(maxRequests: 2, window: const Duration(minutes: 1));
      expect(rl.allow('ip'), isTrue);
      expect(rl.allow('ip'), isTrue);
      expect(rl.allow('ip'), isFalse); // 3. istek engellenir
    });

    test('farklı anahtarlar bağımsız sayılır', () {
      final rl = RateLimiter(maxRequests: 1, window: const Duration(minutes: 1));
      expect(rl.allow('a'), isTrue);
      expect(rl.allow('b'), isTrue);
      expect(rl.allow('a'), isFalse);
    });

    test('pencere dolunca kota sıfırlanır', () {
      var now = DateTime(2026, 1, 1, 12, 0, 0);
      final rl = RateLimiter(
        maxRequests: 1,
        window: const Duration(seconds: 60),
        clock: () => now,
      );
      expect(rl.allow('ip'), isTrue);
      expect(rl.allow('ip'), isFalse);
      now = now.add(const Duration(seconds: 61)); // pencere geçti
      expect(rl.allow('ip'), isTrue);
    });
  });

  group('corsHeaders', () {
    Handler ok() => (Request r) => Response.ok('hi');

    test('yanıta CORS başlığı ekler', () async {
      final handler = corsHeaders(origin: '*')(ok());
      final res = await handler(Request('GET', Uri.parse('http://x/museums')));
      expect(res.headers['access-control-allow-origin'], '*');
    });

    test('OPTIONS preflight 200 ve başlıklarla yanıtlanır', () async {
      final handler = corsHeaders()(ok());
      final res = await handler(Request('OPTIONS', Uri.parse('http://x/museums')));
      expect(res.statusCode, 200);
      expect(res.headers['access-control-allow-methods'], contains('GET'));
    });
  });

  group('rateLimit middleware', () {
    test('kota aşılınca 429 döner', () async {
      final rl = RateLimiter(maxRequests: 1, window: const Duration(minutes: 1));
      final handler = rateLimit(rl)((r) => Response.ok('ok'));
      final req = Request('GET', Uri.parse('http://x/'),
          headers: {'x-forwarded-for': '1.2.3.4'});
      expect((await handler(req)).statusCode, 200);
      expect((await handler(req)).statusCode, 429);
    });
  });
}
