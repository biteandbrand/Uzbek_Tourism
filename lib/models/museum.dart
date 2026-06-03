// Müze — schema.sql'deki museum tablosu (öneri/offline için sade alt küme).

class Museum {
  final String id;
  final String name;
  final String city;

  Museum({required this.id, required this.name, required this.city});

  factory Museum.fromJson(Map<String, dynamic> j) => Museum(
        id: j['id'] as String,
        name: j['name'] as String,
        city: j['city'] as String,
      );
}
