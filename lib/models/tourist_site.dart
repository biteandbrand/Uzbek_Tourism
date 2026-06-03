// Konuma göre önerilecek turistik mekan — schema.sql'deki tourist_site tablosu.

class TouristSite {
  final String id;
  final String city;
  final String name;
  final double lat;
  final double lng;

  /// 'mosque' | 'mausoleum' | 'bazaar' | 'madrasah' | 'square' ...
  final String? category;

  TouristSite({
    required this.id,
    required this.city,
    required this.name,
    required this.lat,
    required this.lng,
    this.category,
  });

  factory TouristSite.fromJson(Map<String, dynamic> j) => TouristSite(
        id: j['id'] as String,
        city: j['city'] as String,
        name: j['name'] as String,
        lat: (j['lat'] as num).toDouble(),
        lng: (j['lng'] as num).toDouble(),
        category: j['category'] as String?,
      );
}
