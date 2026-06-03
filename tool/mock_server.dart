// docs/API.md'deki uç noktaları taklit eden basit yerel sunucu.
// `kUseMock = false` yolunu cihazsız/elle denemek için kullanılır.
//
// Çalıştırma:
//   dart run tool/mock_server.dart            # http://localhost:8080
//   dart run tool/mock_server.dart 9000       # özel port
//
// Sonra app_config.dart'ta:
//   kUseMock = false;
//   kApiBase = 'http://10.0.2.2:8080';  // Android emülatör; iOS sim: localhost
//
// Not: Bu dosya uygulama paketine dahil değildir; yalnızca geliştirme aracıdır.

import 'dart:convert';
import 'dart:io';

void main(List<String> args) async {
  final port = args.isNotEmpty ? int.tryParse(args.first) ?? 8080 : 8080;
  final server = await HttpServer.bind(InternetAddress.loopbackIPv4, port);
  stdout.writeln('Mock API → http://localhost:$port');

  await for (final req in server) {
    final path = req.uri.path;
    final res = req.response..headers.contentType = ContentType.json;
    try {
      final body = _route(path, req.uri.queryParameters);
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

Object? _route(String path, Map<String, String> query) {
  if (path == '/museums') return _museums;
  if (path == '/cities') return _cities;
  if (path == '/routes') return _routes;
  if (path == '/sites') {
    final city = query['city'];
    if (city == null) return _sites;
    return _sites.where((s) => s['city'] == city).toList();
  }
  if (path.startsWith('/museums/') && path.endsWith('/exhibits')) {
    final id = path.split('/')[2];
    return _exhibits.where((e) => e['museum_id'] == id).toList();
  }
  if (path.startsWith('/exhibits/')) {
    final id = path.split('/').last;
    return _exhibits.firstWhere((e) => e['id'] == id, orElse: () => {});
        // boş harita → çağıran 200 alır ama translations yok; gerçek backend 404 döner
  }
  return null;
}

const _museums = [
  {'id': 'm1', 'name': 'Afrasiyab Müzesi', 'city': 'Samarkand'},
  {'id': 'm2', 'name': 'Buhara Devlet Müzesi', 'city': 'Bukhara'},
];

const _cities = ['Bukhara', 'Khiva', 'Samarkand', 'Tashkent'];

const _sites = [
  {'id': 's1', 'city': 'Samarkand', 'name': 'Registan Meydanı', 'lat': 39.6547, 'lng': 66.9758, 'category': 'square'},
  {'id': 's2', 'city': 'Samarkand', 'name': 'Gur-i Emir', 'lat': 39.6486, 'lng': 66.9690, 'category': 'mausoleum'},
  {'id': 's3', 'city': 'Bukhara', 'name': 'Po-i Kalan', 'lat': 39.7756, 'lng': 64.4143, 'category': 'mosque'},
  {'id': 's4', 'city': 'Bukhara', 'name': 'Lyab-i Hauz', 'lat': 39.7747, 'lng': 64.4194, 'category': 'square'},
  {'id': 's5', 'city': 'Tashkent', 'name': 'Çorsu Pazarı', 'lat': 41.3262, 'lng': 69.2348, 'category': 'bazaar'},
  {'id': 's6', 'city': 'Khiva', 'name': 'İçan Kale', 'lat': 41.3783, 'lng': 60.3639, 'category': 'madrasah'},
];

const _routes = [
  {
    'id': 'r1',
    'name': 'Klasik İpek Yolu — 4 gün',
    'summary': 'Taşkent → Semerkant → Buhara → Hiva.',
    'stops': [
      {'city': 'Samarkand', 'title': 'Semerkant anıtları', 'description': 'Registan ve çevresi.', 'duration_label': '1,5 gün'},
      {'city': 'Bukhara', 'title': 'Buhara eski şehir', 'description': 'Po-i Kalan.', 'duration_label': '1 gün'},
    ],
  },
];

const _audio = {
  'url': 'https://download.samplelib.com/mp3/sample-9s.mp3',
  'duration_sec': 9,
};

const _exhibits = [
  {
    'id': 'demo',
    'type': 'object',
    'position': 'Salon 2, vitrin 4',
    'museum_id': 'm1',
    'translations': [
      {'lang_code': 'en', 'title': 'Ulugh Beg Tablet', 'body': 'A celestial observation tablet…', 'audio': _audio},
      {'lang_code': 'tr', 'title': 'Uluğ Bey Tableti', 'body': 'Bir gök gözlem tableti…', 'audio': _audio},
      {'lang_code': 'ru', 'title': 'Табличка Улугбека', 'body': 'Табличка астрономических наблюдений…', 'audio': _audio},
    ],
  },
  {
    // Yalnızca İngilizce + Türkçe — diğer dillerde fallback'i göstermek için.
    'id': 'a1b3',
    'type': 'room',
    'position': 'Salon 1',
    'museum_id': 'm1',
    'translations': [
      {'lang_code': 'en', 'title': 'Main Hall', 'body': 'The central hall of the museum.'},
      {'lang_code': 'tr', 'title': 'Ana Salon', 'body': 'Müzenin merkez salonu.'},
    ],
  },
  {
    // Yalnızca Türkçe — başka bir fallback senaryosu.
    'id': 'b2c4',
    'type': 'object',
    'museum_id': 'm2',
    'translations': [
      {'lang_code': 'tr', 'title': 'Buhara Halısı', 'body': 'El dokuması bir Buhara halısı.', 'audio': _audio},
    ],
  },
];
