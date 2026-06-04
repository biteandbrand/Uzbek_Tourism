import 'dart:io';
import 'package:postgres/postgres.dart';
import 'package:uztour_server/database.dart';
import 'package:uztour_server/env.dart';

/// schema.sql'i idempotent uygular (IF NOT EXISTS). Tekrar çalıştırılabilir.
///
/// Kullanım (repo kökü erişilebilirken, DATABASE_URL managed Postgres'i gösterir):
///   cd server && dart run bin/migrate.dart
///   dart run bin/migrate.dart /path/to/schema.sql   # özel yol
Future<void> main(List<String> args) async {
  final path = _resolveSchemaPath(args.isNotEmpty ? args.first : Env.maybe('SCHEMA_PATH'));
  final sql = await File(path).readAsString();
  stdout.writeln('Şema uygulanıyor: $path');

  final (endpoint, sslMode) = PostgresDatabase.endpointFromUrl(Env.databaseUrl);
  final conn = await Connection.open(
    endpoint,
    settings: ConnectionSettings(sslMode: sslMode),
  );
  try {
    // Simple query mode: tek istekte birden çok statement çalıştırır.
    await conn.execute(sql, queryMode: QueryMode.simple);
    stdout.writeln('Migration tamam.');
  } finally {
    await conn.close();
  }
}

/// schema.sql'i bulur: argüman/SCHEMA_PATH, sonra cwd'den yukarı doğru arama.
String _resolveSchemaPath(String? override) {
  if (override != null && File(override).existsSync()) return override;

  var dir = Directory.current;
  for (var i = 0; i < 6; i++) {
    final candidate = File('${dir.path}${Platform.pathSeparator}schema.sql');
    if (candidate.existsSync()) return candidate.path;
    final parent = dir.parent;
    if (parent.path == dir.path) break;
    dir = parent;
  }
  throw StateError(
    'schema.sql bulunamadı. Yolu argüman veya SCHEMA_PATH ile verin.',
  );
}
