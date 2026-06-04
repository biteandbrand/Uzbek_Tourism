import 'dart:io';

/// Ortam değişkenlerine erişim. Secret'lar repoda değil, ortamdan gelir.
class Env {
  static String? maybe(String key) {
    final v = Platform.environment[key];
    return (v == null || v.isEmpty) ? null : v;
  }

  static String require(String key) {
    final v = maybe(key);
    if (v == null) {
      throw StateError('Eksik ortam değişkeni: $key (bkz. .env.example)');
    }
    return v;
  }

  static int get port => int.tryParse(maybe('PORT') ?? '') ?? 8080;
  static String get databaseUrl => require('DATABASE_URL');
  static String? get adminToken => maybe('ADMIN_TOKEN');
}
