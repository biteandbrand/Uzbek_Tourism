// docs/API.md'deki uç noktaları taklit eden basit yerel sunucu.
// `kUseMock = false` yolunu cihazsız/elle denemek için kullanılır.
// Veri ve yönlendirme lib/mock_api.dart'tadır (sözleşme testiyle paylaşılır).
//
// Çalıştırma:
//   dart run tool/mock_server.dart            # http://localhost:8080
//   dart run tool/mock_server.dart 9000       # özel port
//
// Sonra uygulamayı:
//   flutter run --dart-define=USE_MOCK=false --dart-define=API_BASE=http://10.0.2.2:8080

import 'dart:convert';
import 'dart:io';
import 'package:uzbek_tour_app/mock_api.dart';

void main(List<String> args) async {
  final port = args.isNotEmpty ? int.tryParse(args.first) ?? 8080 : 8080;
  final server = await HttpServer.bind(InternetAddress.loopbackIPv4, port);
  stdout.writeln('Mock API → http://localhost:$port');

  await for (final req in server) {
    final path = req.uri.path;
    final res = req.response..headers.contentType = ContentType.json;
    try {
      final body = mockRoute(path, req.uri.queryParameters);
      if (body == null) {
        res.statusCode = HttpStatus.notFound;
        res.write(jsonEncode({'error': 'not found', 'path': path}));
      } else {
        res.write(jsonEncode(body));
      }
    } catch (e) {
      res.statusCode = HttpStatus.internalServerError;
      res.write(jsonEncode({'error': '$e'}));
    }
    await res.close();
    stdout.writeln('${req.method} $path → ${res.statusCode}');
  }
}
