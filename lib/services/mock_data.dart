// Backend hazır olana kadar uygulamayı uçtan uca denemek için örnek veri.
// Gerçek API bağlanınca servislerdeki `useMock` bayrağı kapatılır; bu dosya
// olduğu gibi kalabilir (testler için de kullanışlı).

import '../models/exhibit.dart';
import '../models/museum.dart';
import '../models/route_plan.dart';
import '../models/tourist_site.dart';

class MockData {
  MockData._();

  /// Çevrimdışı indirme ekranı için örnek müzeler.
  static final List<Museum> museums = [
    Museum(id: 'm1', name: 'Afrasiyab Müzesi', city: 'Samarkand'),
    Museum(id: 'm2', name: 'Buhara Devlet Müzesi', city: 'Bukhara'),
    Museum(id: 'm3', name: 'Uygulamalı Sanatlar Müzesi', city: 'Tashkent'),
    Museum(id: 'm4', name: 'Hiva İçan Kale Müzesi', city: 'Khiva'),
  ];

  /// QR ile açılan örnek objeler. Anahtar = exhibit id (QR payload'ındaki id).
  static final Map<String, Exhibit> exhibits = {
    'demo': Exhibit(
      id: 'demo',
      type: 'object',
      position: 'Salon 2, vitrin 4',
      museumId: 'm1', // Afrasiyab Müzesi
      translations: {
        'tr': Translation(
          langCode: 'tr',
          title: 'Uluğ Bey Astronomi Tableti',
          body:
              'Semerkant\'taki Uluğ Bey Rasathanesi\'nden bir gök gözlem '
              'tableti. 15. yüzyılda yıldız konumlarının şaşırtıcı bir '
              'doğrulukla ölçüldüğü dönemi temsil eder.',
          audio: AudioAsset(
            url: 'https://download.samplelib.com/mp3/sample-9s.mp3',
            durationSec: 9,
          ),
        ),
        'en': Translation(
          langCode: 'en',
          title: 'Ulugh Beg Astronomy Tablet',
          body:
              'A celestial observation tablet from the Ulugh Beg Observatory '
              'in Samarkand, marking the 15th-century era when star positions '
              'were measured with remarkable accuracy.',
          audio: AudioAsset(
            url: 'https://download.samplelib.com/mp3/sample-9s.mp3',
            durationSec: 9,
          ),
        ),
        'uz': Translation(
          langCode: 'uz',
          title: 'Ulugʻbek astronomiya plitasi',
          body:
              'Samarqanddagi Ulugʻbek rasadxonasidan osmon kuzatuv plitasi. '
              '15-asrda yulduzlar oʻrni ajoyib aniqlik bilan oʻlchangan davrni '
              'aks ettiradi.',
        ),
      },
    ),
  };

  /// Konuma göre öneri ekranı için örnek mekanlar.
  static final List<TouristSite> sites = [
    TouristSite(
      id: 's1',
      city: 'Samarkand',
      name: 'Registan Meydanı',
      lat: 39.6547,
      lng: 66.9758,
      category: 'square',
    ),
    TouristSite(
      id: 's2',
      city: 'Samarkand',
      name: 'Gur-i Emir Türbesi',
      lat: 39.6486,
      lng: 66.9690,
      category: 'mausoleum',
    ),
    TouristSite(
      id: 's3',
      city: 'Samarkand',
      name: 'Bibi Hanım Camii',
      lat: 39.6606,
      lng: 66.9817,
      category: 'mosque',
    ),
    TouristSite(
      id: 's4',
      city: 'Bukhara',
      name: 'Po-i Kalan Külliyesi',
      lat: 39.7756,
      lng: 64.4143,
      category: 'mosque',
    ),
    TouristSite(
      id: 's5',
      city: 'Bukhara',
      name: 'Lyab-i Hauz',
      lat: 39.7747,
      lng: 64.4194,
      category: 'square',
    ),
    TouristSite(
      id: 's6',
      city: 'Tashkent',
      name: 'Çorsu Pazarı',
      lat: 41.3262,
      lng: 69.2348,
      category: 'bazaar',
    ),
    TouristSite(
      id: 's7',
      city: 'Khiva',
      name: 'İçan Kale',
      lat: 41.3783,
      lng: 60.3639,
      category: 'madrasah',
    ),
  ];

  /// Rota ekranı için hazır gezi planları.
  static final List<RoutePlan> routes = [
    RoutePlan(
      id: 'r1',
      name: 'Klasik İpek Yolu — 4 gün',
      summary: 'Taşkent → Semerkant → Buhara → Hiva ana hattı.',
      stops: [
        RouteStop(
          city: 'Tashkent',
          title: 'Taşkent\'te varış',
          description:
              'Çorsu Pazarı ve eski şehirde ilk gün. Akşam hızlı tren bileti.',
          durationLabel: '1 gün',
        ),
        RouteStop(
          city: 'Samarkand',
          title: 'Semerkant\'ın anıtları',
          description:
              'Registan, Gur-i Emir ve Bibi Hanım. QR rehberiyle müze turu.',
          durationLabel: '1,5 gün',
        ),
        RouteStop(
          city: 'Bukhara',
          title: 'Buhara\'nın eski şehri',
          description: 'Po-i Kalan ve Lyab-i Hauz çevresinde yürüyüş.',
          durationLabel: '1 gün',
        ),
        RouteStop(
          city: 'Khiva',
          title: 'Hiva — İçan Kale',
          description: 'Surlarla çevrili müze-şehirde kapanış.',
          durationLabel: 'Yarım gün',
        ),
      ],
    ),
    RoutePlan(
      id: 'r2',
      name: 'Semerkant kısa molası — 1 gün',
      summary: 'Tek günde Semerkant\'ın öne çıkan üç anıtı.',
      stops: [
        RouteStop(
          city: 'Samarkand',
          title: 'Registan Meydanı',
          description: 'Üç medreseyle çevrili tarihi meydan.',
          durationLabel: '2 saat',
        ),
        RouteStop(
          city: 'Samarkand',
          title: 'Gur-i Emir',
          description: 'Timur\'un türbesi.',
          durationLabel: '1 saat',
        ),
        RouteStop(
          city: 'Samarkand',
          title: 'Bibi Hanım Camii',
          description: 'Dönemin en büyük camilerinden.',
          durationLabel: '1 saat',
        ),
      ],
    ),
  ];
}
