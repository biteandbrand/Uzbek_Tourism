import 'database.dart';

/// DB satırlarını docs/API.md'deki JSON şekillerine dönüştürür.
/// Şekiller mock_server.dart ve Flutter modelleriyle BİREBİR aynı tutulmalı.
class Repository {
  Repository(this.db);

  final Database db;

  /// GET /museums
  Future<List<Map<String, dynamic>>> museums() async {
    final rows = await db.query('SELECT id, name, city FROM museum ORDER BY name');
    return rows
        .map((r) => {
              'id': '${r['id']}',
              'name': r['name'],
              'city': r['city'],
            })
        .toList();
  }

  /// GET /cities
  Future<List<String>> cities() async {
    final rows =
        await db.query('SELECT DISTINCT city FROM tourist_site ORDER BY city');
    return rows.map((r) => r['city'] as String).toList();
  }

  /// GET /sites  ve  GET /sites?city=
  Future<List<Map<String, dynamic>>> sites({String? city}) async {
    const cols = 'SELECT id, city, name, lat, lng, category FROM tourist_site';
    final rows = city == null
        ? await db.query('$cols ORDER BY name')
        : await db.query('$cols WHERE city = @city ORDER BY name', {'city': city});
    return rows
        .map((r) => {
              'id': '${r['id']}',
              'city': r['city'],
              'name': r['name'],
              'lat': (r['lat'] as num).toDouble(),
              'lng': (r['lng'] as num).toDouble(),
              'category': r['category'],
            })
        .toList();
  }

  /// GET /exhibits/{id}
  Future<Map<String, dynamic>?> exhibit(String id) async {
    final rows = await db.query(
      'SELECT id, type, position, museum_id FROM exhibit WHERE id = @id',
      {'id': id},
    );
    if (rows.isEmpty) return null;
    return _exhibitJson(rows.first);
  }

  /// GET /museums/{id}/exhibits
  Future<List<Map<String, dynamic>>> museumExhibits(String museumId) async {
    final rows = await db.query(
      'SELECT id, type, position, museum_id FROM exhibit '
      'WHERE museum_id = @id ORDER BY created_at',
      {'id': museumId},
    );
    final out = <Map<String, dynamic>>[];
    for (final r in rows) {
      out.add(await _exhibitJson(r));
    }
    return out;
  }

  /// Bir exhibit satırını çevirileri + ses varlığıyla birlikte JSON'a çevirir.
  Future<Map<String, dynamic>> _exhibitJson(Map<String, dynamic> r) async {
    final exhibitId = '${r['id']}';
    final trRows = await db.query(
      'SELECT t.lang_code, t.title, t.body, a.url AS audio_url, '
      'a.duration_sec AS audio_duration '
      'FROM translation t '
      'LEFT JOIN audio_asset a ON a.translation_id = t.id '
      'WHERE t.exhibit_id = @id ORDER BY t.lang_code',
      {'id': exhibitId},
    );
    return {
      'id': exhibitId,
      'type': r['type'],
      'position': r['position'],
      'museum_id': r['museum_id'] == null ? null : '${r['museum_id']}',
      'translations': trRows.map((t) {
        return {
          'lang_code': t['lang_code'],
          'title': t['title'],
          'body': t['body'],
          if (t['audio_url'] != null)
            'audio': {
              'url': t['audio_url'],
              'duration_sec': t['audio_duration'],
            },
        };
      }).toList(),
    };
  }

  /// GET /routes
  Future<List<Map<String, dynamic>>> routes() async {
    final routeRows =
        await db.query('SELECT id, name, summary FROM route ORDER BY created_at');
    final out = <Map<String, dynamic>>[];
    for (final r in routeRows) {
      final id = '${r['id']}';
      final stops = await db.query(
        'SELECT city, title, description, duration_label '
        'FROM route_stop WHERE route_id = @id ORDER BY ord',
        {'id': id},
      );
      out.add({
        'id': id,
        'name': r['name'],
        'summary': r['summary'],
        'stops': stops
            .map((s) => {
                  'city': s['city'],
                  'title': s['title'],
                  'description': s['description'],
                  'duration_label': s['duration_label'],
                })
            .toList(),
      });
    }
    return out;
  }
}
