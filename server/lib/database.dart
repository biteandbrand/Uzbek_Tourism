import 'package:postgres/postgres.dart';

/// Veritabanı soyutlaması — repository bunun üzerinden okur, böylece testlerde
/// Postgres yerine sahte bir uygulama enjekte edilebilir.
abstract class Database {
  /// Adlandırılmış parametreli (@ad) sorgu çalıştırır, satırları sütun-haritası
  /// listesi olarak döndürür.
  Future<List<Map<String, dynamic>>> query(
    String sql, [
    Map<String, dynamic> params = const {},
  ]);

  Future<void> close();
}

/// Postgres uygulaması (bağlantı havuzu).
class PostgresDatabase implements Database {
  PostgresDatabase(this._pool);

  final Pool _pool;

  /// DATABASE_URL'i (postgres://user:pass@host:port/db) Endpoint + SslMode'a çevirir.
  /// Yerel host'ta SSL kapalı, uzakta zorunlu. Migration script'iyle paylaşılır.
  static (Endpoint, SslMode) endpointFromUrl(String databaseUrl) {
    final uri = Uri.parse(databaseUrl);
    final userInfo = uri.userInfo.split(':');
    final endpoint = Endpoint(
      host: uri.host,
      port: uri.hasPort ? uri.port : 5432,
      database:
          uri.pathSegments.isNotEmpty ? uri.pathSegments.first : 'postgres',
      username: userInfo.isNotEmpty ? Uri.decodeComponent(userInfo.first) : null,
      password: userInfo.length > 1 ? Uri.decodeComponent(userInfo[1]) : null,
    );
    final isLocal = uri.host == 'localhost' || uri.host == '127.0.0.1';
    return (endpoint, isLocal ? SslMode.disable : SslMode.require);
  }

  /// DATABASE_URL'i ayrıştırıp bir bağlantı havuzuyla bağlanır.
  static Future<PostgresDatabase> connect(String databaseUrl) async {
    final (endpoint, sslMode) = endpointFromUrl(databaseUrl);
    final pool = Pool.withEndpoints(
      [endpoint],
      settings: PoolSettings(maxConnectionCount: 5, sslMode: sslMode),
    );
    return PostgresDatabase(pool);
  }

  @override
  Future<List<Map<String, dynamic>>> query(
    String sql, [
    Map<String, dynamic> params = const {},
  ]) async {
    final result = await _pool.execute(Sql.named(sql), parameters: params);
    return result.map((row) => row.toColumnMap()).toList();
  }

  @override
  Future<void> close() => _pool.close();
}
