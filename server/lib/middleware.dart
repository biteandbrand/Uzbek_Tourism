import 'dart:convert';
import 'package:shelf/shelf.dart';

/// CORS başlıkları. API herkese açık ve salt-okunur (GET); preflight (OPTIONS)
/// doğrudan yanıtlanır. [origin] CORS_ORIGIN ile kısıtlanabilir.
Middleware corsHeaders({String origin = '*'}) {
  final headers = {
    'Access-Control-Allow-Origin': origin,
    'Access-Control-Allow-Methods': 'GET, OPTIONS',
    'Access-Control-Allow-Headers':
        'Origin, Content-Type, Accept, Authorization',
    'Access-Control-Max-Age': '86400',
  };
  return (Handler inner) {
    return (Request request) async {
      if (request.method == 'OPTIONS') {
        return Response.ok(null, headers: headers);
      }
      final response = await inner(request);
      return response.change(headers: headers);
    };
  };
}

/// Sabit pencere (fixed-window) rate limiter. Anahtar başına (IP) pencere
/// içinde [maxRequests] isteğe izin verir. Saat enjekte edilebilir (test için).
class RateLimiter {
  RateLimiter({
    this.maxRequests = 60,
    this.window = const Duration(minutes: 1),
    DateTime Function()? clock,
  }) : _now = clock ?? DateTime.now;

  final int maxRequests;
  final Duration window;
  final DateTime Function() _now;
  final Map<String, _Window> _windows = {};

  /// İzin verilirse true; pencere kotası dolduysa false.
  bool allow(String key) {
    final now = _now();
    final w = _windows[key];
    if (w == null || now.isAfter(w.resetAt)) {
      _windows[key] = _Window(now.add(window), 1);
      return true;
    }
    if (w.count >= maxRequests) return false;
    w.count++;
    return true;
  }
}

class _Window {
  _Window(this.resetAt, this.count);
  final DateTime resetAt;
  int count;
}

/// İstemci IP'sini (proxy arkasında X-Forwarded-For) belirler.
String clientIp(Request request) {
  final fwd = request.headers['x-forwarded-for'];
  if (fwd != null && fwd.isNotEmpty) return fwd.split(',').first.trim();
  final info = request.context['shelf.io.connection_info'];
  final addr = (info as dynamic)?.remoteAddress?.address;
  return addr is String ? addr : 'unknown';
}

/// IP başına rate-limit; aşılırsa 429 döner.
Middleware rateLimit(RateLimiter limiter) {
  return (Handler inner) {
    return (Request request) async {
      if (!limiter.allow(clientIp(request))) {
        return Response(
          429,
          body: jsonEncode({'error': 'rate limit exceeded'}),
          headers: const {'content-type': 'application/json; charset=utf-8'},
        );
      }
      return inner(request);
    };
  };
}
