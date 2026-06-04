import 'dart:typed_data';
import 'package:minio/minio.dart';
import 'env.dart';

/// Cloudflare R2'ye (S3 uyumlu) medya yükler. API medya servis etmez; yalnızca
/// herkese açık URL üretilip audio_asset.url'e yazılır.
class R2Uploader {
  R2Uploader(this._minio, this._bucket, this._publicBase);

  final Minio _minio;
  final String _bucket;
  final String _publicBase;

  /// Tüm R2_* değişkenleri yoksa null (yükleme atlanır).
  static R2Uploader? fromEnv() {
    final account = Env.maybe('R2_ACCOUNT_ID');
    final key = Env.maybe('R2_ACCESS_KEY_ID');
    final secret = Env.maybe('R2_SECRET_ACCESS_KEY');
    final bucket = Env.maybe('R2_BUCKET');
    final publicBase = Env.maybe('R2_PUBLIC_BASE_URL');
    if (account == null ||
        key == null ||
        secret == null ||
        bucket == null ||
        publicBase == null) {
      return null;
    }
    final minio = Minio(
      endPoint: '$account.r2.cloudflarestorage.com',
      accessKey: key,
      secretKey: secret,
      region: 'auto',
      useSSL: true,
    );
    return R2Uploader(minio, bucket, publicBase);
  }

  /// Baytları [key] altında yükler, herkese açık URL'i döndürür.
  Future<String> upload(
    String key,
    Uint8List bytes, {
    String contentType = 'audio/mpeg',
  }) async {
    await _minio.putObject(
      _bucket,
      key,
      Stream<Uint8List>.value(bytes),
      size: bytes.length,
      metadata: {'Content-Type': contentType},
    );
    final base = _publicBase.endsWith('/')
        ? _publicBase.substring(0, _publicBase.length - 1)
        : _publicBase;
    return '$base/$key';
  }
}
