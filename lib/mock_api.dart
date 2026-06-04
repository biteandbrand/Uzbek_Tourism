// Yerel sahte API'nin örnek verisi + yönlendirmesi.
// `tool/mock_server.dart` (yerel HTTP sunucu) ve sözleşme testi bunu kullanır.
// Yanıt şekilleri docs/API.md ve server/ (gerçek backend) ile birebir aynıdır.
//
// Uygulamanın çalışma yolunda kullanılmaz (yalnızca dev aracı + test).

const mockMuseums = [
  {'id': 'm1', 'name': 'Afrasiyab Müzesi', 'city': 'Samarkand'},
  {'id': 'm2', 'name': 'Buhara Devlet Müzesi', 'city': 'Bukhara'},
];

const mockCities = ['Bukhara', 'Khiva', 'Samarkand', 'Tashkent'];

const mockSites = [
  {'id': 's1', 'city': 'Samarkand', 'name': 'Registan Meydanı', 'lat': 39.6547, 'lng': 66.9758, 'category': 'square'},
  {'id': 's2', 'city': 'Samarkand', 'name': 'Gur-i Emir', 'lat': 39.6486, 'lng': 66.9690, 'category': 'mausoleum'},
  {'id': 's3', 'city': 'Bukhara', 'name': 'Po-i Kalan', 'lat': 39.7756, 'lng': 64.4143, 'category': 'mosque'},
  {'id': 's4', 'city': 'Bukhara', 'name': 'Lyab-i Hauz', 'lat': 39.7747, 'lng': 64.4194, 'category': 'square'},
  {'id': 's5', 'city': 'Tashkent', 'name': 'Çorsu Pazarı', 'lat': 41.3262, 'lng': 69.2348, 'category': 'bazaar'},
  {'id': 's6', 'city': 'Khiva', 'name': 'İçan Kale', 'lat': 41.3783, 'lng': 60.3639, 'category': 'madrasah'},
];

const mockRoutes = [
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

const mockExhibits = [
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
    // Yalnızca Türkçe — başka bir fallback senaryosu. position null (server her
    // zaman position anahtarını döndürür).
    'id': 'b2c4',
    'type': 'object',
    'position': null,
    'museum_id': 'm2',
    'translations': [
      {'lang_code': 'tr', 'title': 'Buhara Halısı', 'body': 'El dokuması bir Buhara halısı.', 'audio': _audio},
    ],
  },
];

/// docs/API.md uç noktalarını sahte veriyle yanıtlar. Bulunamazsa null.
Object? mockRoute(String path, Map<String, String> query) {
  if (path == '/museums') return mockMuseums;
  if (path == '/cities') return mockCities;
  if (path == '/routes') return mockRoutes;
  if (path == '/sites') {
    final city = query['city'];
    if (city == null) return mockSites;
    return mockSites.where((s) => s['city'] == city).toList();
  }
  if (path.startsWith('/museums/') && path.endsWith('/exhibits')) {
    final id = path.split('/')[2];
    return mockExhibits.where((e) => e['museum_id'] == id).toList();
  }
  if (path.startsWith('/exhibits/')) {
    final id = path.split('/').last;
    return mockExhibits.firstWhere((e) => e['id'] == id, orElse: () => {});
  }
  return null;
}
