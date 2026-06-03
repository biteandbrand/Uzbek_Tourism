// Önceden hazırlanmış gezi rotası. Backend'de tablo karşılığı opsiyonel;
// prototipte mock veriden gelir, ileride bir 'route' + 'route_stop' tablosuna
// taşınabilir.

/// Rotanın tek bir durağı (bir şehir / mekan).
class RouteStop {
  final String city;
  final String title;
  final String description;

  /// 'Yarım gün', '2 saat' gibi serbest süre etiketi.
  final String? durationLabel;

  RouteStop({
    required this.city,
    required this.title,
    required this.description,
    this.durationLabel,
  });

  factory RouteStop.fromJson(Map<String, dynamic> j) => RouteStop(
        city: j['city'] as String,
        title: j['title'] as String,
        description: j['description'] as String,
        durationLabel: j['duration_label'] as String?,
      );
}

/// Birden çok duraktan oluşan rota (ör. "Klasik İpek Yolu — 5 gün").
class RoutePlan {
  final String id;
  final String name;
  final String summary;
  final List<RouteStop> stops;

  RoutePlan({
    required this.id,
    required this.name,
    required this.summary,
    required this.stops,
  });

  factory RoutePlan.fromJson(Map<String, dynamic> j) => RoutePlan(
        id: j['id'] as String,
        name: j['name'] as String,
        summary: j['summary'] as String,
        stops: (j['stops'] as List)
            .cast<Map<String, dynamic>>()
            .map(RouteStop.fromJson)
            .toList(),
      );
}
