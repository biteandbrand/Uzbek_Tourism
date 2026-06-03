import 'package:flutter_test/flutter_test.dart';
import 'package:uzbek_tour_app/services/location_service.dart';

void main() {
  group('LocationService', () {
    test('mock modda sabit Semerkant konumu döndürür', () async {
      final p = await LocationService(useMock: true).current();
      expect(p.lat, closeTo(39.65, 0.1));
      expect(p.lng, closeTo(66.98, 0.1));
    });

    test('enjekte edilen alıcının hatasını yansıtır', () {
      final svc = LocationService(
          fetcher: () async => throw Exception('izin yok'));
      expect(svc.current(), throwsException);
    });

    test('enjekte edilen konumu döndürür', () async {
      final svc = LocationService(fetcher: () async => const GeoPoint(0, 0));
      final p = await svc.current();
      expect(p.lat, 0);
    });

    test('distanceMeters bilinen mesafeyi yaklaşık verir', () {
      final svc = LocationService();
      // Registan (Semerkant) ↔ Po-i Kalan (Buhara) ~ 240 km
      const samarkand = GeoPoint(39.6547, 66.9758);
      const bukhara = GeoPoint(39.7756, 64.4143);
      final km = svc.distanceMeters(samarkand, bukhara) / 1000;
      expect(km, closeTo(220, 40));
    });

    test('aynı nokta için mesafe sıfır', () {
      final svc = LocationService();
      expect(svc.distanceMeters(const GeoPoint(10, 20), const GeoPoint(10, 20)),
          closeTo(0, 0.001));
    });
  });
}
