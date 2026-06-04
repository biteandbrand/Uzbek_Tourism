# Uzbek Tour — Backend (Dart + shelf)

`docs/API.md` sözleşmesini Postgres'ten sunan API. Medya (ses) API'den geçmez;
TTS ile üretilip Cloudflare R2'ye yüklenir, uygulama doğrudan R2'den akıtır.

## Yapı

```
server/
  bin/
    server.dart     # HTTP API (shelf)
    migrate.dart    # schema.sql'i idempotent uygular
    ingest.dart     # sesi olmayan çevirilere TTS → R2 → audio_asset.url
  lib/
    env.dart        # ortam değişkenleri
    database.dart   # Database soyutlaması + PostgresDatabase (havuz)
    repository.dart # DB → docs/API.md JSON şekilleri
    api.dart        # shelf_router uç noktaları
    tts.dart        # takılabilir TTS (ElevenLabs + kuru çalışma)
    r2.dart         # R2 (S3 uyumlu) yükleme
  railway.json / Procfile   # deploy
  .env.example
```

## Uç noktalar

`GET /healthz`, `/museums`, `/museums/{id}/exhibits`, `/exhibits/{id}`,
`/sites`, `/sites?city=`, `/cities`, `/routes` — yanıt şekilleri `docs/API.md`
ile birebir (Flutter parsing'i değişmez).

## Yerelde çalıştırma

```bash
# 1) Yerel Postgres (örnek)
createdb uztour
export DATABASE_URL="postgres://localhost:5432/uztour"

cd server
dart pub get
dart run bin/migrate.dart            # şemayı uygular (repo kökündeki schema.sql)
dart run bin/server.dart             # http://localhost:8080

# 2) Doğrula
curl localhost:8080/healthz
curl localhost:8080/museums

# 3) Uygulamayı bu API'ye bağla
cd ..
flutter run --dart-define=USE_MOCK=false --dart-define=API_BASE=http://10.0.2.2:8080
# (iOS simülatöründe API_BASE=http://localhost:8080)
```

> Veri girmeden tablolar boş döner. Örnek içerik eklemek için `schema.sql`'e
> uygun INSERT'ler kullanın ya da `tool/mock_server.dart`'taki örnekleri temel alın.

## Test ve analiz

```bash
cd server
dart pub get
dart analyze
dart test          # repository'yi sahte DB ile test eder (Postgres gerekmez)
```

---

## RUNBOOK — proje sahibinin yapacakları (Claude yapmaz)

Aşağıdakiler hesap/secret gerektirir; kod hazır, yalnızca bağlama kalır.

### 1. Railway (API + Postgres)
1. Railway'de yeni proje → "Deploy from GitHub repo" → bu repo.
2. Servis ayarları → **Root Directory = `server`**. (Nixpacks Dart'ı algılar;
   start komutu `railway.json`'dan gelir.)
3. Aynı projeye **Postgres** ekle (New → Database → PostgreSQL). Railway bir
   `DATABASE_URL` değişkeni üretir.
4. API servisinin **Variables** sekmesine ekle:
   - `DATABASE_URL` → Postgres servisinin değişkenine referans
     (`${{Postgres.DATABASE_URL}}`).
   - (R2/TTS değişkenleri — aşağıdaki adımlardan sonra.)
5. Deploy et. `https://<servis>.up.railway.app/healthz` → `{"status":"ok"}`.

### 2. Şema (migration)
Makinenden, repo çekiliyken, `DATABASE_URL`'i Railway Postgres'in **public**
bağlantısına ayarla ve çalıştır:
```bash
cd server
DATABASE_URL="<railway-public-postgres-url>" dart run bin/migrate.dart
```
(İdempotenttir; tekrar çalıştırılabilir.)

### 3. Cloudflare R2
1. R2'de bir bucket aç (ör. `uztour-media`), herkese açık erişim/Custom Domain
   ayarla (`R2_PUBLIC_BASE_URL`).
2. S3 uyumlu **Access Key ID / Secret** üret.
3. Railway Variables'a gir: `R2_ACCOUNT_ID`, `R2_ACCESS_KEY_ID`,
   `R2_SECRET_ACCESS_KEY`, `R2_BUCKET`, `R2_PUBLIC_BASE_URL`.

### 4. TTS
1. Bir TTS hesabı aç (ör. ElevenLabs), API key al.
2. Railway Variables: `TTS_PROVIDER=elevenlabs`, `TTS_API_KEY=...`,
   (opsiyonel) `TTS_VOICE_ID=...`.

### 5. Ses üretimi (ingest)
İçerik (exhibit + translation) DB'ye girdikten sonra, makinenden:
```bash
cd server
# .env'i doldur (DATABASE_URL public + R2_* + TTS_*), sonra ortama yükle
dart run bin/ingest.dart
```
Sesi olmayan her çeviri için mp3 üretir, R2'ye yükler, `audio_asset.url` yazar.

### 6. Uygulamayı prod'a bağla
```bash
flutter build apk --dart-define=USE_MOCK=false \
  --dart-define=API_BASE=https://<servis>.up.railway.app
```

## Güvenlik notları
- Okuma uç noktaları herkese açık (museums/exhibits/sites/routes).
- Ingestion yalnızca CLI'dır (ağ üzerinden açık değil); DB/secret erişimi olan
  operatör çalıştırır. İleride bir admin endpoint eklenirse `ADMIN_TOKEN` ile korunmalı.
- Secret'lar yalnızca ortam değişkenlerinde; repoda `.env` tutulmaz.
