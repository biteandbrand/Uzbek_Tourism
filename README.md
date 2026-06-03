# Uzbek Tour — prototip iskeleti

Özbekistan turizm asistanının **QR → sesli + yazılı anlatım** akışını gösteren
minimal Flutter iskeleti. Üç ana özelliğin (müze QR, rota, öneri) tümü ana
ekrandan erişilebilir; en ayırt edici olan müze QR akışı uçtan uca kuruludur.

## Durum

Prototip; çekirdek akışlar mock veriyle uçtan uca çalışır. **CI yeşil** — her
push/PR'da `flutter analyze` temiz geçer ve **tüm testler başarılı**. Gerçek
cihazda denemek için aşağıdaki "Platform kurulumu" adımlarını izleyin.

**Hazır (✓)**
- Dört özellik: müze QR → sesli/yazılı anlatım, rotalar, öneriler (şehre/konuma
  göre, haritada açma), çevrimdışı müze indirme.
- Çevrimdışı: `prefetchMuseum` (ilerleme % + kalıcı işaret), indirilene dokun → QR,
  yanlış müze uyarısı.
- Durum yönetimi `provider`: içerik dili, ayrı **arayüz dili**, çevrimdışı durum.
- Çok dilli içerik + arayüz (tr/en tam; uz/ru/zh İngilizceye düşer) ve içerik
  fallback bilgisi.
- Enjekte edilebilir, test edilebilir servisler (`http.Client` + soyut `OfflineStore`
  + konum alıcısı); ortak hata/boş/banner widget'ları; tek tema dosyası.
- **11 test dosyası** (birim + 3 widget; eklenti-bağımsız), `flutter_lints`,
  GitHub Actions CI (`analyze` + `test`, **yeşil**).
- `docs/API.md` backend sözleşmesi + `tool/mock_server.dart` yerel sahte sunucu.

**Açık / sonraki adımlar**
- `flutter create .` ile platform iskeleti, ardından gerçek cihaz/emülatörde
  uçtan uca deneme (kamera, ses, konum, harita izinleri).
- Gerçek backend (`docs/API.md` sözleşmesine göre); `kUseMock=false` + `kApiBase`.
- uz/ru/zh **arayüz** çevirileri (gerçek çevirmenle; altyapı hazır).
- `route`/`route_stop` tablolarını `schema.sql`'e ekleme.

## Proje yapısı

```
lib/
  main.dart                       # ana ekran: dil seçimi + 4 özellik
  app_config.dart                 # kUseMock + kApiBase
  theme.dart                      # uygulama teması (tohum rengi)
  l10n/
    app_strings.dart              # arayüz metinleri (tr/en; eksikte İngilizce)
  state/
    locale_controller.dart        # içerik dili (provider ile paylaşılır)
    ui_locale_controller.dart     # arayüz dili (içeriği izler ya da ayrı seçilir)
    offline_controller.dart       # çevrimdışı müze durumu + indirme ilerlemesi
  models/
    exhibit.dart                  # Exhibit / Translation / AudioAsset
    tourist_site.dart             # öneri mekanı
    route_plan.dart               # RoutePlan / RouteStop
    museum.dart                   # offline indirme için müze
  services/
    content_service.dart          # QR içeriği: önbellek → API; prefetchMuseum
    offline_store.dart            # önbellek/işaret deposu (soyut; dosya tabanlı)
    discovery_service.dart        # rota / öneri / müze verisi (API veya mock)
    location_service.dart         # konum (geolocator) + Haversine mesafe
    ranking.dart                  # mekanları konuma göre sıralayan saf fonksiyon
    mock_data.dart                # örnek exhibit / mekan / rota / müze verisi
  widgets/
    error_retry.dart              # ortak "hata + yeniden dene" görünümü
    empty_state.dart              # ortak "boş liste" görünümü
  screens/
    qr_scanner_screen.dart        # QR okuma (mock modda "Simüle et" butonu)
    exhibit_detail_screen.dart    # yazılı + sesli anlatım (yükleniyor/hata durumu)
    route_screen.dart             # rota planları (durak → şehir önerileri)
    recommendations_screen.dart   # şehre/konuma göre öneriler (haritada aç)
    museums_screen.dart           # çevrimdışı indir/sil; indirilene dokun → QR
```

## Mock mod

`lib/app_config.dart` içindeki `kUseMock` **prototipte `true`**: QR, rota ve öneri
akışları `mock_data.dart`'tan beslenir, backend gerekmez. QR ekranındaki
**"Simüle et (demo)"** butonu kamerasız test için örnek bir objeyi açar. Gerçek
API bağlanınca `kUseMock = false` yapılır.

## Akış

1. `main.dart` — kullanıcı içerik dilini seçer (uz/ru/en/zh/tr).
2. `qr_scanner_screen.dart` — `mobile_scanner` ile QR okutulur.
   Payload formatı: `uztour://exhibit/<id>`.
3. `content_service.dart` — payload çözülür, exhibit içeriği **önce yerel
   önbellekten** (offline), yoksa API'den getirilir.
4. `exhibit_detail_screen.dart` — seçili dilde yazılı metin gösterilir ve
   `just_audio` ile sesli anlatım oynatılır.

Öneri ekranında iki mod vardır: **şehre göre** ya da **yakınımdakiler**
(`geolocator` ile konum alınır, mekanlar uzaklığa göre sıralanıp mesafe
gösterilir). Mock modda konum Semerkant merkezi olarak sabittir.

## Çalıştırma

```bash
flutter pub get
flutter run
```

> Not: Backend hazır olmadan denemek için `kUseMock = true` (varsayılan)
> bırakın; servisler `mock_data.dart`'tan okur. Gerçek backend bağlanınca
> `app_config.dart` içinde `kApiBase`'i ayarlayıp `kUseMock = false` yapın
> (API kök adresi tek yerden gelir).

## Test

```bash
flutter test
```

- `test/content_test.dart` — QR payload çözümleme ve `Exhibit.localized` dil
  geri-dönüş mantığı (saf Dart, eklenti gerektirmez).
- `test/discovery_service_test.dart` — `kUseMock=false` API yolu; enjekte edilen
  `http.Client` yerine `MockClient` ile JSON ayrıştırma doğrulanır.
- `test/content_service_api_test.dart` — `ContentService`'in ağ→önbellek yolu
  (`MockClient` + bellek içi `OfflineStore`): çekme, önbellekten okuma, prefetch.
- `test/location_service_test.dart` — Haversine mesafe, mock konum ve enjekte
  edilen alıcının hata yolu.
- `test/ranking_test.dart` — `rankSitesByDistance` sıralaması (saf fonksiyon).
- `test/home_screen_test.dart` — widget testi: ana ekran 4 kartı gösterir ve dil
  seçimi `LocaleController`'ı günceller.
- `test/route_screen_test.dart` — widget testi: rota ekranı mock rotaları/durakları
  gösterir (eklenti gerektirmez).
- `test/app_strings_test.dart` — dil geri-dönüşü (zh→en) ve biçimleme yardımcıları.
- `test/exhibit_test.dart` — `Exhibit.localizedWith` (geri-dönüş bayrağı dahil).
- `test/recommendations_screen_test.dart` — widget testi: şehir modu mock
  mekanları listeler, şehir değişimi yansır (eklenti gerektirmez).

Lint: `analysis_options.yaml` `package:flutter_lints/flutter.yaml`'ı içerir.

CI: her push/PR'da `.github/workflows/ci.yml` `flutter analyze` + `flutter test`
çalıştırır (önce `flutter create .` ile platform iskeleti üretilir).

## Önemli noktalar

- **Offline:** Müzeye girerken `prefetchMuseum()` ile tüm müze içeriği indirilip
  cihaza yazılır; QR sadece hangi objede olunduğunu belirler. Müze içi zayıf
  sinyalde kritik.
- **Çok dillilik:** Tek QR, kullanıcının seçtiği dile göre içeriği açar. Ses
  dosyaları TTS ile dil başına otomatik üretilir (bkz. `schema.sql`,
  `audio_asset.tts_voice`).
- **Oda vs obje:** İkisi de `exhibit` tablosunda `type` alanıyla tutulur, aynı
  QR/ses/metin mantığını paylaşır.

## Platform kurulumu

Bu depo el yazımı bir iskelet; tam platform yapısı (`android/` Gradle dosyaları,
`ios/Runner.xcodeproj` vb.) henüz yok. Önce iskeleti tamamlayın:

```bash
flutter create .   # eksik android/ios/web scaffolding'ini üretir
```

`flutter create .` mevcut dosyaların üzerine **yazmaz**; bu yüzden depodaki hazır
manifestler korunur:

- **Android** — `android/app/src/main/AndroidManifest.xml`
  - `CAMERA` izni (QR — mobile_scanner)
  - `ACCESS_FINE_LOCATION` / `ACCESS_COARSE_LOCATION` (yakındaki mekanlar — geolocator)
  - `mobile_scanner` için `android/app/build.gradle` içinde `minSdkVersion 21`.
- **iOS** — `ios/Runner/Info.plist`
  - `NSCameraUsageDescription` (QR)
  - `NSLocationWhenInUseUsageDescription` (konum)
  - `geolocator` için iOS dağıtım hedefi en az **12.0**.
  - `permission_handler` için `ios/Podfile`'da derlenecek izinleri belirtin
    (örn. `GCC_PREPROCESSOR_DEFINITIONS` içine `PERMISSION_CAMERA=1`);
    aksi halde `openAppSettings()` çalışsa da izin sorgusu derlenmez.

> `flutter create .` manifesti yine de kendi şablonuyla üretirse, yukarıdaki izin
> satırlarını üretilen dosyalara elle taşıyın.

## Yerelleştirme

İçerik (exhibit metni/sesi) çok dillidir. **Arayüz** metinleri de
`l10n/app_strings.dart` üzerinden gösterilir; tüm ekranlar `context.strings`
(build) / `context.stringsRead` (geri-çağrı) ile yerelleştirildi. Şu an **tr** ve
**en** tam; diğer diller (uz/ru/zh) çeviri eklenene kadar İngilizceye düşer. Yeni
dil: bir `AppStrings` örneği tanımlayıp `AppStrings.of` içine bağlamak yeterli.

**Arayüz dili içerik dilinden ayrıdır:** ana ekrandaki "Uygulama dili" seçici ile
arayüz dili içerikten bağımsız seçilebilir; varsayılan "İçerikle aynı"
(`UiLocaleController` içeriği izler).

## Şema ve API

- `schema.sql` — ER modelinin PostgreSQL karşılığı.
- `docs/API.md` — istemcinin beklediği uç noktalar ve örnek JSON yanıtları
  (model `fromJson` şekilleriyle ve şemayla uyumlu).
- `tool/mock_server.dart` — `docs/API.md`'yi taklit eden yerel sunucu; gerçek
  backend olmadan `kUseMock = false` yolunu denemek için:
  ```bash
  dart run tool/mock_server.dart
  # app_config.dart: kUseMock = false;
  #   kApiBase = 'http://10.0.2.2:8080' (Android emülatör) / 'http://localhost:8080' (iOS sim)
  ```
