import '../models/tourist_site.dart';
import 'location_service.dart';

/// Bir mekan + verilen konuma uzaklığı (metre).
typedef RankedSite = ({TouristSite site, double distanceMeters});

/// Mekanları [from] konumuna göre en yakından en uzağa sıralar.
/// UI'dan bağımsız, saf fonksiyon — birim testiyle sabitlenebilir.
List<RankedSite> rankSitesByDistance(
  List<TouristSite> sites,
  GeoPoint from,
  LocationService location,
) {
  final ranked = sites
      .map((s) => (
            site: s,
            distanceMeters:
                location.distanceMeters(from, GeoPoint(s.lat, s.lng)),
          ))
      .toList()
    ..sort((a, b) => a.distanceMeters.compareTo(b.distanceMeters));
  return ranked;
}
