# Uzbek Tour — Backend API sözleşmesi

İstemcinin (`kUseMock = false`) beklediği uç noktalar ve örnek JSON yanıtları.
Şekiller, modellerin `fromJson` ayrıştırmasıyla ve `schema.sql` ile birebir uyumludur.
Kök adres `app_config.dart` içindeki `kApiBase` ile verilir.

Genel kurallar:
- Tüm yanıtlar `application/json`, UTF-8.
- Başarı: `200`. Bulunamadı: `404`. İstemci 200 dışını hata sayar.
- Alan adları `snake_case` (Dart tarafı `lang_code`, `museum_id`, `duration_sec`,
  `duration_label` bekler).

---

## GET /exhibits/{id}

Tek bir exhibit'in **tüm dillerdeki** içeriği (offline için hepsi birden iner).
İstemci: `ContentService.getExhibit`.

```json
{
  "id": "a1b2",
  "type": "object",
  "position": "Salon 2, vitrin 4",
  "museum_id": "m1",
  "translations": [
    {
      "lang_code": "en",
      "title": "Ulugh Beg Astronomy Tablet",
      "body": "A celestial observation tablet from the Ulugh Beg Observatory…",
      "audio": { "url": "https://cdn.uztour/au/a1b2-en.mp3", "duration_sec": 64 }
    },
    {
      "lang_code": "tr",
      "title": "Uluğ Bey Astronomi Tableti",
      "body": "Semerkant'taki Uluğ Bey Rasathanesi'nden bir gök gözlem tableti…",
      "audio": { "url": "https://cdn.uztour/au/a1b2-tr.mp3", "duration_sec": 70 }
    }
  ]
}
```

Notlar:
- `type`: `"room"` | `"object"`.
- `position`, `museum_id`, `audio` ve `audio.duration_sec` opsiyoneldir (null olabilir).
- En az bir çeviri beklenir; istemci istenen dili bulamazsa `en`'e, o da yoksa
  ilk çeviriye düşer.

---

## GET /museums/{id}/exhibits

Bir müzenin tüm exhibit'leri — çevrimdışı ön-indirme (`prefetchMuseum`) bunu çeker
ve her exhibit'i tek tek önbelleğe yazar. Her eleman `/exhibits/{id}` ile aynı şekildedir.

```json
[
  { "id": "a1b2", "type": "object", "museum_id": "m1", "translations": [ … ] },
  { "id": "a1b3", "type": "room",   "museum_id": "m1", "translations": [ … ] }
]
```

---

## GET /museums

Çevrimdışı indirme ekranındaki müze listesi. İstemci: `DiscoveryService.museums`.

```json
[
  { "id": "m1", "name": "Afrasiyab Müzesi", "city": "Samarkand" },
  { "id": "m2", "name": "Buhara Devlet Müzesi", "city": "Bukhara" }
]
```

---

## GET /sites?city={city}

Bir şehrin önerilen turistik mekanları. İstemci: `DiscoveryService.sitesForCity`.
`city` parametresi URL-encode edilir.

```json
[
  { "id": "s1", "city": "Samarkand", "name": "Registan Meydanı", "lat": 39.6547, "lng": 66.9758, "category": "square" },
  { "id": "s2", "city": "Samarkand", "name": "Gur-i Emir Türbesi", "lat": 39.6486, "lng": 66.9690, "category": "mausoleum" }
]
```

`category`: `mosque` | `mausoleum` | `bazaar` | `madrasah` | `square` | null.

---

## GET /sites

Tüm mekanlar ("yakınımdakiler" konuma göre sıralar). Eleman şekli `/sites?city=` ile aynı.

---

## GET /cities

Öneri ekranındaki şehir seçimi için düz string listesi. İstemci: `DiscoveryService.cities`.

```json
["Bukhara", "Khiva", "Samarkand", "Tashkent"]
```

---

## GET /routes

Hazır gezi rotaları. İstemci: `DiscoveryService.routes`.

```json
[
  {
    "id": "r1",
    "name": "Klasik İpek Yolu — 4 gün",
    "summary": "Taşkent → Semerkant → Buhara → Hiva ana hattı.",
    "stops": [
      { "city": "Tashkent", "title": "Taşkent'te varış", "description": "Çorsu Pazarı ve eski şehir.", "duration_label": "1 gün" },
      { "city": "Samarkand", "title": "Semerkant'ın anıtları", "description": "Registan, Gur-i Emir, Bibi Hanım.", "duration_label": "1,5 gün" }
    ]
  }
]
```

`stops[].duration_label` opsiyoneldir.

---

## schema.sql ile eşleme

| Uç nokta            | Kaynak tablolar                                  |
|---------------------|--------------------------------------------------|
| `/exhibits/{id}`    | `exhibit` + `translation` + `audio_asset`        |
| `/museums/{id}/exhibits` | `exhibit` (museum_id'ye göre) + alt kaynaklar |
| `/museums`          | `museum`                                         |
| `/sites`            | `tourist_site`                                   |
| `/cities`           | `DISTINCT tourist_site.city` (veya `museum.city`)|
| `/routes`           | `route` + `route_stop` (ord'a göre sıralı)       |

> `route(id, name, summary)` ve `route_stop(route_id, ord, city, title,
> description, duration_label)` tabloları `schema.sql`'e eklendi. `/routes`
> yanıtındaki `stops` dizisi `route_stop`'tan `ord` sırasına göre üretilir.
> Prototipte rotalar hâlâ `mock_data.dart`'tan gelir (`kUseMock = true`).
