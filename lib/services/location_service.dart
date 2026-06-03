import 'dart:math' as math;
import 'package:geolocator/geolocator.dart';

/// Basit konum noktası (servis dışına geolocator tipini sızdırmamak için).
class GeoPoint {
  final double lat;
  final double lng;
  const GeoPoint(this.lat, this.lng);
}

/// Konumu döndüren işlev — testlerde sahte/hata fırlatan biri enjekte edilebilir.
typedef PositionFetcher = Future<GeoPoint> Function();

/// Cihaz konumunu alır ve iki nokta arası mesafeyi hesaplar.
/// Mock modda sabit bir konum döndürür (GPS olmayan ortamda test için).
class LocationService {
  LocationService({this.useMock = false, PositionFetcher? fetcher})
      : _fetcher = fetcher;

  final bool useMock;
  final PositionFetcher? _fetcher;

  /// Mock konum: Semerkant merkezi (Registan civarı).
  static const _mockPoint = GeoPoint(39.6547, 66.9758);

  /// Geçerli konumu döndürür. İzin/servis sorunlarında Exception fırlatır.
  Future<GeoPoint> current() async {
    if (useMock) return _mockPoint;
    if (_fetcher != null) return _fetcher();
    return _geolocatorPosition();
  }

  Future<GeoPoint> _geolocatorPosition() async {
    if (!await Geolocator.isLocationServiceEnabled()) {
      throw Exception('Konum servisi kapalı');
    }
    var perm = await Geolocator.checkPermission();
    if (perm == LocationPermission.denied) {
      perm = await Geolocator.requestPermission();
    }
    if (perm == LocationPermission.denied ||
        perm == LocationPermission.deniedForever) {
      throw Exception('Konum izni verilmedi');
    }
    final pos = await Geolocator.getCurrentPosition();
    return GeoPoint(pos.latitude, pos.longitude);
  }

  /// İki nokta arasındaki kuş uçuşu mesafe (metre) — Haversine.
  /// Dart'ta hesaplanır; test ve mesafe sıralaması için eklenti gerektirmez.
  double distanceMeters(GeoPoint a, GeoPoint b) {
    const earthRadius = 6371000.0; // metre
    final dLat = _rad(b.lat - a.lat);
    final dLng = _rad(b.lng - a.lng);
    final h = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_rad(a.lat)) *
            math.cos(_rad(b.lat)) *
            math.sin(dLng / 2) *
            math.sin(dLng / 2);
    return 2 * earthRadius * math.asin(math.min(1.0, math.sqrt(h)));
  }

  double _rad(double deg) => deg * math.pi / 180.0;
}
