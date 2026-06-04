# Claude Code görev tarifi — backend'i canlıya alma

Bunu olduğu gibi Claude Code'a ver. Amaç: mevcut prototipi gerçek bir backend'e
bağlamak. Uygulama kodu zaten `docs/API.md` sözleşmesine ve `schema.sql`'e göre
yazıldı; bu sözleşmeyi BOZMA.

---

## Bağlam (repo'da hâlihazırda var)
- `tool/mock_server.dart` — `docs/API.md`'yi taklit eden yerel sahte sunucu.
- `docs/API.md` — istemcinin beklediği uç noktalar ve JSON yanıt şekilleri.
- `schema.sql` — PostgreSQL şeması.
- `lib/app_config.dart` — `kUseMock` ve `kApiBase`.
- Uygulama servisleri şu uç noktaları çağırıyor: `/museums`,
  `/museums/{id}/exhibits`, `/exhibits/{id}`, `/sites`, `/sites?city=`,
  `/cities`, `/routes`.

## Kesin kurallar (bunları bozma)
- Yanıt JSON şekillerini `docs/API.md` / `mock_server.dart` ile BİREBİR aynı tut;
  böylece Flutter tarafında servis/parsing kodu değişmesin.
- API **ses/görsel dosyası servis ETMEZ**. `audio_asset.url` yalnızca R2'deki
  herkese açık URL'i tutar; medya doğrudan R2'den akar (egress maliyeti için).
- Secret'ları repoya yazma. Her şey ortam değişkeninden gelir; bir
  `.env.example` üret (gerçek değerler boş).
- Mevcut testleri kırma; `mock_server.dart` yerel geliştirme/test için kalsın.

---

## Görevler

### 1. API servisi
- Repoda `server/` klasörü oluştur. API'yi **Dart + shelf** ile yaz
  (`mock_server.dart`'ın yönlendirmesini temel al, tek dil kalsın). Başka bir
  stack'i (Node/FastAPI) daha uygun görürsen, yazmadan önce kısaca gerekçesini
  belirt.
- `mock_server.dart`'taki sahte verinin yerine Postgres sorgularını koy.
- Tüm `docs/API.md` uç noktalarını DB'den okuyacak şekilde implement et.

### 2. Veritabanı
- Postgres'e `DATABASE_URL` ortam değişkeniyle bağlan (`postgres` paketi).
- Açılışta ya da ayrı bir `server/migrate.dart` script'iyle `schema.sql`'i
  çalıştıran bir migrasyon yolu ekle. Tekrar çalıştırmaya dayanıklı olsun
  (IF NOT EXISTS / idempotent).
- İsteğe bağlı: `schema.sql`'e `route` / `route_stop` tablolarını ekle
  (şu an rotalar mock'tan geliyordu).

### 3. Medya + içerik alma (TTS → R2)
- `server/` içinde bir ingestion yolu ekle (CLI script `server/ingest.dart`
  ya da auth'lu bir admin endpoint): girdi olarak exhibit metni + dil alır,
  TTS sağlayıcısını (`TTS_API_KEY` / `TTS_PROVIDER`) çağırıp mp3 üretir,
  **R2'ye (S3 uyumlu API)** yükler ve dönen herkese açık URL'i ilgili
  `audio_asset.url`'e yazar.
- TTS adımını takılabilir (pluggable) tut; sağlayıcı anahtarı yoksa yüklemeyi
  atlayıp sadece kaydı yazsın (kuru çalışma modu).
- R2 erişimi `R2_*` ortam değişkenlerinden; S3 uyumlu SDK kullan.

### 4. Railway deploy
- Railway'in otomatik algılayabilmesi için gerekli yapılandırmayı ekle
  (start komutu / Procfile / `railway.json`), kök dizin `server/`.
- Bir `server/README.md` (RUNBOOK) yaz: insanın (proje sahibinin) yapması
  gereken adımları madde madde listele — Railway projesi + managed Postgres
  oluşturma, R2 bucket açma, ortam değişkenlerini Railway'e girme, deploy.

### 5. Flutter app'i canlıya bağla
- `lib/app_config.dart`'ta `kApiBase`'i Railway URL'inden okunabilir yap ve
  prod için `kUseMock=false`. Yerel/test için mock yolu korunsun
  (ör. derleme ortamına göre seçilen bir bayrak).

### 6. Test ve doğrulama
- DB destekli uç noktalar için testler ekle (test Postgres ya da mevcut
  enjekte edilebilir desen). Mevcut `flutter test` ve `flutter analyze` geçmeli.
- Yerelde doğrula: yerel Postgres + `schema.sql` + `dart run server` →
  uç noktaları çağır, şekillerin `docs/API.md` ile aynı olduğunu doğrula →
  uygulamayı `kUseMock=false` + yerel `kApiBase` ile çalıştır.

---

## Beklenen ortam değişkenleri (`.env.example` üret)
```
DATABASE_URL=
PORT=8080
ADMIN_TOKEN=                 # ingestion/admin endpoint'leri için
R2_ACCOUNT_ID=
R2_ACCESS_KEY_ID=
R2_SECRET_ACCESS_KEY=
R2_BUCKET=
R2_PUBLIC_BASE_URL=          # ör. https://media.uztour.example
TTS_PROVIDER=                # ör. elevenlabs
TTS_API_KEY=
```

## Güvenlik
- Okuma uç noktaları (museums/exhibits/sites/routes) herkese açık olabilir.
- Ingestion / admin uç noktaları `ADMIN_TOKEN` ile korunsun.

## Kabul kriterleri
1. `dart run server` yerelde ayağa kalkıyor, `schema.sql` uygulanıyor.
2. Tüm `docs/API.md` uç noktaları DB'den doğru şekilde yanıt veriyor;
   JSON şekilleri değişmemiş.
3. `kUseMock=false` ile uygulama yerel API'ye bağlanıp çalışıyor.
4. `ingest` ile bir örnek ses R2'ye yükleniyor ve `audio_asset.url` doğru URL'i
   gösteriyor; uygulama o sesi oynatıyor.
5. `flutter analyze` + `flutter test` temiz.
6. `server/README.md` insanın deploy adımlarını net listeliyor.

## Sınır (insanın yapacakları — sen)
Bunları Claude Code yapmaz; o yalnızca kod + RUNBOOK üretir:
- Railway hesabı + projesi + managed Postgres oluşturma.
- Cloudflare R2 bucket'ı + erişim anahtarları.
- TTS sağlayıcı hesabı + API key.
- Bu secret'ları Railway ortam değişkenlerine girme ve deploy'u onaylama.
