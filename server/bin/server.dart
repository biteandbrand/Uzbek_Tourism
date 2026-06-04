import 'dart:io';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as io;
import 'package:uztour_server/api.dart';
import 'package:uztour_server/database.dart';
import 'package:uztour_server/env.dart';
import 'package:uztour_server/middleware.dart';
import 'package:uztour_server/repository.dart';

/// API sunucusu giriş noktası. Postgres'e bağlanır ve shelf'i başlatır.
Future<void> main() async {
  final db = await PostgresDatabase.connect(Env.databaseUrl);
  final repo = Repository(db);

  final limiter = RateLimiter(
    maxRequests: Env.rateLimitMax,
    window: Duration(seconds: Env.rateWindowSec),
  );

  final handler = const Pipeline()
      .addMiddleware(logRequests())
      .addMiddleware(corsHeaders(origin: Env.corsOrigin))
      .addMiddleware(rateLimit(limiter))
      .addHandler(buildApi(repo));

  final server = await io.serve(handler, InternetAddress.anyIPv4, Env.port);
  stdout.writeln('uztour-server → http://${server.address.host}:${server.port}');
}
