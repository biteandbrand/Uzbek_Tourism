import 'package:flutter_test/flutter_test.dart';
import 'package:uzbek_tour_app/models/tourist_site.dart';
import 'package:uzbek_tour_app/services/location_service.dart';
import 'package:uzbek_tour_app/services/ranking.dart';

TouristSite _site(String id, double lat, double lng) =>
    TouristSite(id: id, city: 'X', name: id, lat: lat, lng: lng);

void main() {
  group('rankSitesByDistance', () {
    final location = LocationService();

    test('en yakından en uzağa sıralar', () {
      const me = GeoPoint(0, 0);
      final sites = [
        _site('uzak', 0, 1.0), // ~111 km
        _site('yakin', 0, 0.1), // ~11 km
        _site('orta', 0, 0.5), // ~55 km
      ];
      final ranked = rankSitesByDistance(sites, me, location);
      expect(ranked.map((r) => r.site.id).toList(), ['yakin', 'orta', 'uzak']);
      // mesafeler artan
      expect(ranked[0].distanceMeters, lessThan(ranked[1].distanceMeters));
      expect(ranked[1].distanceMeters, lessThan(ranked[2].distanceMeters));
    });

    test('boş liste boş döndürür', () {
      expect(rankSitesByDistance([], const GeoPoint(0, 0), location), isEmpty);
    });
  });
}
