# FlutterFlow AI — Uzbek Tour hazırlık paketi

Amaç: Claude Code'daki Flutter projesine dokunmadan, FlutterFlow'da aynı veri
modeli ve aynı backend API sözleşmesi üzerine görsel/demo hattını kurmak.
İki proje veri katmanında uyumlu kalır.

FlutterFlow AI prompt'larını İngilizce bıraktım (AI üretici İngilizcede daha
iyi sonuç veriyor); uygulama içi metinler çok dilli kalır.

---

## 1. Yetenek haritası (neyi nasıl yapıyoruz)

| Özellik | FlutterFlow'da durum | Yaklaşım |
|---|---|---|
| QR okuma | Native "Scan Barcode/QR code" aksiyonu var | Aksiyonu butona bağla, dönen string'i bir custom function ile `id`'ye çevir |
| Sesli anlatım | Native AudioPlayer widget'ı (URL'den oynatır) | Path'i `translation.audio.url`'e bağla |
| Yazılı anlatım | Text widget | `translation.body`'ye bağla |
| Çok dillilik | App State `langCode` + data type içinde `List<Translation>` | Aktif dile göre çeviriyi seç (custom function) |
| Öneri / mekan | REST API + ListView | `/sites` uç noktalarına bağla |
| Harita | Google Map native; Yandex native DEĞİL | Demo'da pin/harita aç; gerçek transit/araç rotası + Yandex sonradan custom |
| Çevrimdışı | Gerçek dosya önbelleği FF'de zayıf | Demo'da online kalsın; "indirildi" işaretini App State listesinde tut |

---

## 2. Custom Data Types (FlutterFlow → Data Types)

Dart modellerinin birebir karşılığı. FlutterFlow Map tutmadığı için
`translations` bir **List** olarak tanımlanır (dile göre filtrelenir).

**AudioAsset**
- `url` : String
- `durationSec` : Integer

**Translation**
- `langCode` : String
- `title` : String
- `body` : String
- `audio` : AudioAsset (Data Type)

**Exhibit**
- `id` : String
- `type` : String            // 'room' | 'object'
- `position` : String
- `museumId` : String
- `translations` : List<Translation>

**Museum**
- `id` : String
- `name` : String
- `city` : String

**TouristSite**
- `id` : String
- `city` : String
- `name` : String
- `lat` : Double
- `lng` : Double
- `category` : String

**RouteStop**
- `city` : String
- `title` : String
- `description` : String
- `durationLabel` : String

**RoutePlan**
- `id` : String
- `name` : String
- `summary` : String
- `stops` : List<RouteStop>

---

## 3. App State değişkenleri

- `langCode` : String — kalıcı (Persisted), varsayılan `en`
- `downloadedMuseumIds` : List<String> — kalıcı (demo için "indirildi" işareti)

---

## 4. REST API yapılandırması (FlutterFlow → API Calls)

Base URL'i bir kez tanımla (ör. `https://api.uztour.example`). Her çağrının
JSON yanıtını yukarıdaki data type'lara eşle (Response & Test → Data Type).

| Ad | Method | Path | Döndürür |
|---|---|---|---|
| getMuseums | GET | `/museums` | List<Museum> |
| getMuseumExhibits | GET | `/museums/[museumId]/exhibits` | List<Exhibit> |
| getExhibit | GET | `/exhibits/[exhibitId]` | Exhibit |
| getSitesByCity | GET | `/sites?city=[city]` | List<TouristSite> |
| getAllSites | GET | `/sites` | List<TouristSite> |
| getCities | GET | `/cities` | List<String> |
| getRoutes | GET | `/routes` | List<RoutePlan> |

`[museumId]`, `[exhibitId]`, `[city]` → API çağrısında Variable olarak tanımla.

---

## 5. Custom Functions (FlutterFlow → Custom Functions)

### exhibitIdFromPayload
QR payload `uztour://exhibit/<id>` → `id`. Bizimki değilse null döner.

```dart
String? exhibitIdFromPayload(String payload) {
  final uri = Uri.tryParse(payload.trim());
  if (uri == null || uri.scheme != 'uztour') return null;
  if (uri.host != 'exhibit') return null;
  return uri.pathSegments.isNotEmpty ? uri.pathSegments.first : null;
}
```

### pickTranslation
Aktif dile göre çeviriyi seçer; yoksa İngilizce, o da yoksa ilk çeviri.

```dart
TranslationStruct? pickTranslation(
    List<TranslationStruct> translations, String langCode) {
  if (translations.isEmpty) return null;
  return translations.firstWhere(
    (t) => t.langCode == langCode,
    orElse: () => translations.firstWhere(
      (t) => t.langCode == 'en',
      orElse: () => translations.first,
    ),
  );
}
```
> Not: Data type adın FlutterFlow'da `Translation` ise, üretilen sınıf adı
> genelde `TranslationStruct` olur. Derleyici ne diyorsa ona göre düzelt.

---

## 6. Ekran ekran FlutterFlow AI prompt'ları

Her birini FlutterFlow'da "Generate Page with AI" (veya AI agent) alanına ayrı
ayrı yapıştır. Üretildikten sonra veri bağlama/aksiyonları elle bağlarsın.

### A) Home / language
```
Create a clean mobile home page named "Home". Vertical layout, generous padding.
Top: app title "Uzbek Tour". Below it a dropdown labelled "Language" with options
English, O'zbekcha, Русский, 中文, Türkçe. At the bottom, a large primary button
with a QR icon labelled "Scan museum QR". Use a calm palette: deep teal primary
(#0F6E56), terracotta accent (#D85A30), warm off-white background. Sans-serif,
large readable type.
```
Bağlama: dropdown → App State `langCode`. Buton aksiyonu: Scan Barcode/QR code →
sonucu `exhibitIdFromPayload` ile çevir → getExhibit çağır → Exhibit detail'e git.

### B) Museums (offline)
```
Create a mobile page named "Museums". An app bar titled "Museums". A scrollable
list of cards; each card shows a museum icon on the left, the museum name as
title, the city as subtitle, and a download icon button on the right. Minimal,
clean, rounded cards.
```
Bağlama: liste → getMuseums. İndir ikonu → `downloadedMuseumIds`'e ekle (demo).
Karta dokunma → QR ekranına git (museumId parametresiyle).

### C) Exhibit detail
```
Create a mobile page named "ExhibitDetail" that takes an Exhibit parameter.
Layout top to bottom: a small muted text for the position note, a large title,
an audio player with play/pause and a progress bar, then a long body paragraph
of description text. Padding 20. Clean and readable.
```
Bağlama: `pickTranslation(exhibit.translations, langCode)` ile aktif çeviri →
title, body, ve AudioPlayer.Path = `audio.url`.

### D) Recommendations
```
Create a mobile page named "Recommendations". App bar titled "Nearby". Under it,
a segmented control with two options: "By city" and "Near me". When "By city",
show a city dropdown below. Then a scrollable list; each row has a category icon,
the place name as title, the category as subtitle, and a distance label + map
icon on the right. Clean list with dividers.
```
Bağlama: şehir dropdown → getCities; liste → getSitesByCity / getAllSites.
"Near me" → cihaz konumu + mesafe. Satıra dokunma → Launch URL (harita).

### E) Routes
```
Create a mobile page named "Routes". App bar titled "Routes". A list of expandable
cards; each card title is the route name, subtitle is a short summary. Expanding
shows a numbered list of stops, each stop with a circular number, a title, a
city + duration line, and a short description. Clean, card-based.
```
Bağlama: liste → getRoutes; genişleyen içerik → `plan.stops`.

---

## 7. Bilinen sınırlar (Claude Code uygulamasına kıyasla)

- Gerçek çevrimdışı önbellek (müzeye girerken tüm içeriği cihaza indirme) FF'de
  zahmetli; demo için online kalmak en pratiği.
- Yandex rota/transit motoru native değil — bu, her iki projede de sonraki adım
  (custom widget / Action). Demo'da mekanı dış harita uygulamasında açmak yeterli.
- Karmaşık iş mantığında FF AI yüzeysel kalabilir; üretimden sonra elle bağlama
  şart.
