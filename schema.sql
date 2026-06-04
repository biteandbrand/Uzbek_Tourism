-- Özbekistan Turizm Uygulaması — İçerik Veri Modeli (PostgreSQL)
-- Diyagramdaki ER modelinin doğrudan karşılığıdır.
-- Tüm DDL idempotenttir (IF NOT EXISTS) — migration tekrar çalıştırılabilir.

CREATE EXTENSION IF NOT EXISTS "pgcrypto";  -- gen_random_uuid() için

-- Diller (Özbekçe, Rusça, İngilizce, Çince, ...)
CREATE TABLE IF NOT EXISTS language (
    code        TEXT PRIMARY KEY,            -- 'uz', 'ru', 'en', 'zh', ...
    name        TEXT NOT NULL
);

-- Müzeler
CREATE TABLE IF NOT EXISTS museum (
    id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name        TEXT NOT NULL,
    city        TEXT NOT NULL,               -- 'Samarkand', 'Bukhara', 'Tashkent'
    lat         DOUBLE PRECISION NOT NULL,
    lng         DOUBLE PRECISION NOT NULL,
    created_at  TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Sergilenen birim: hem ODA hem OBJE aynı tabloda.
-- type = 'room' | 'object'.  parent_id ile obje, içinde olduğu odaya bağlanır.
CREATE TABLE IF NOT EXISTS exhibit (
    id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    museum_id   UUID NOT NULL REFERENCES museum(id) ON DELETE CASCADE,
    parent_id   UUID REFERENCES exhibit(id) ON DELETE SET NULL,  -- oda -> obje
    type        TEXT NOT NULL CHECK (type IN ('room', 'object')),
    position    TEXT,                        -- 'Salon 2, vitrin 4' gibi yer notu
    created_at  TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS idx_exhibit_museum ON exhibit(museum_id);
CREATE INDEX IF NOT EXISTS idx_exhibit_parent ON exhibit(parent_id);

-- Her exhibit için dile göre metin içeriği
CREATE TABLE IF NOT EXISTS translation (
    id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    exhibit_id  UUID NOT NULL REFERENCES exhibit(id) ON DELETE CASCADE,
    lang_code   TEXT NOT NULL REFERENCES language(code),
    title       TEXT NOT NULL,
    body        TEXT NOT NULL,               -- yazılı anlatım
    UNIQUE (exhibit_id, lang_code)
);
CREATE INDEX IF NOT EXISTS idx_translation_exhibit ON translation(exhibit_id);

-- Her çeviri için TTS ile üretilmiş ses dosyası
CREATE TABLE IF NOT EXISTS audio_asset (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    translation_id  UUID NOT NULL UNIQUE REFERENCES translation(id) ON DELETE CASCADE,
    url             TEXT NOT NULL,           -- CDN / object storage (R2) adresi
    duration_sec    INTEGER,
    tts_voice       TEXT,                    -- kullanılan ses modeli
    generated_at    TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Her exhibit için tek QR kod (payload uygulamada deep-link'e çözülür)
CREATE TABLE IF NOT EXISTS qr_code (
    id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    exhibit_id  UUID NOT NULL UNIQUE REFERENCES exhibit(id) ON DELETE CASCADE,
    payload     TEXT NOT NULL UNIQUE,        -- ör: 'uztour://exhibit/<id>'
    printed_at  TIMESTAMPTZ
);

-- Konuma göre önerilecek turistik mekanlar
CREATE TABLE IF NOT EXISTS tourist_site (
    id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    city        TEXT NOT NULL,
    name        TEXT NOT NULL,
    lat         DOUBLE PRECISION NOT NULL,
    lng         DOUBLE PRECISION NOT NULL,
    category    TEXT                         -- 'mosque', 'mausoleum', 'bazaar', ...
);
CREATE INDEX IF NOT EXISTS idx_site_city ON tourist_site(city);

-- Hazır gezi rotaları (GET /routes). RoutePlan modelinin karşılığı.
CREATE TABLE IF NOT EXISTS route (
    id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name        TEXT NOT NULL,               -- 'Klasik İpek Yolu — 4 gün'
    summary     TEXT NOT NULL,
    created_at  TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Bir rotanın sıralı durakları. RouteStop modelinin karşılığı.
CREATE TABLE IF NOT EXISTS route_stop (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    route_id        UUID NOT NULL REFERENCES route(id) ON DELETE CASCADE,
    ord             INTEGER NOT NULL,        -- duraklar arası sıra (0,1,2,...)
    city            TEXT NOT NULL,           -- 'Samarkand', 'Bukhara', ...
    title           TEXT NOT NULL,
    description     TEXT NOT NULL,
    duration_label  TEXT,                    -- 'Yarım gün', '2 saat' (opsiyonel)
    UNIQUE (route_id, ord)
);
CREATE INDEX IF NOT EXISTS idx_route_stop_route ON route_stop(route_id);

-- =====================================================================
-- ÖRNEK VERİ (seed) — mock_data.dart ile aynı içerik.
-- Idempotent: sabit UUID'ler + ON CONFLICT DO NOTHING (tekrar uygulanabilir).
-- Prod'da istenmezse bu bölüm silinebilir.
-- =====================================================================

INSERT INTO language (code, name) VALUES
    ('uz', 'Oʻzbekcha'),
    ('ru', 'Русский'),
    ('en', 'English'),
    ('zh', '中文'),
    ('tr', 'Türkçe')
ON CONFLICT (code) DO NOTHING;

INSERT INTO museum (id, name, city, lat, lng) VALUES
    ('11111111-0000-0000-0000-000000000001', 'Afrasiyab Müzesi', 'Samarkand', 39.6650, 66.9750),
    ('11111111-0000-0000-0000-000000000002', 'Buhara Devlet Müzesi', 'Bukhara', 39.7747, 64.4286),
    ('11111111-0000-0000-0000-000000000003', 'Uygulamalı Sanatlar Müzesi', 'Tashkent', 41.2995, 69.2401),
    ('11111111-0000-0000-0000-000000000004', 'Hiva İçan Kale Müzesi', 'Khiva', 41.3783, 60.3639)
ON CONFLICT (id) DO NOTHING;

INSERT INTO exhibit (id, museum_id, type, position) VALUES
    ('22222222-0000-0000-0000-000000000001',
     '11111111-0000-0000-0000-000000000001', 'object', 'Salon 2, vitrin 4')
ON CONFLICT (id) DO NOTHING;

INSERT INTO translation (id, exhibit_id, lang_code, title, body) VALUES
    ('33333333-0000-0000-0000-000000000001',
     '22222222-0000-0000-0000-000000000001', 'tr',
     'Uluğ Bey Astronomi Tableti',
     'Semerkant''taki Uluğ Bey Rasathanesi''nden bir gök gözlem tableti. 15. yüzyılda yıldız konumlarının şaşırtıcı bir doğrulukla ölçüldüğü dönemi temsil eder.'),
    ('33333333-0000-0000-0000-000000000002',
     '22222222-0000-0000-0000-000000000001', 'en',
     'Ulugh Beg Astronomy Tablet',
     'A celestial observation tablet from the Ulugh Beg Observatory in Samarkand, marking the 15th-century era when star positions were measured with remarkable accuracy.'),
    ('33333333-0000-0000-0000-000000000003',
     '22222222-0000-0000-0000-000000000001', 'uz',
     'Ulugʻbek astronomiya plitasi',
     'Samarqanddagi Ulugʻbek rasadxonasidan osmon kuzatuv plitasi. 15-asrda yulduzlar oʻrni ajoyib aniqlik bilan oʻlchangan davrni aks ettiradi.')
ON CONFLICT (exhibit_id, lang_code) DO NOTHING;

INSERT INTO audio_asset (id, translation_id, url, duration_sec, tts_voice) VALUES
    ('44444444-0000-0000-0000-000000000001',
     '33333333-0000-0000-0000-000000000001',
     'https://download.samplelib.com/mp3/sample-9s.mp3', 9, 'sample'),
    ('44444444-0000-0000-0000-000000000002',
     '33333333-0000-0000-0000-000000000002',
     'https://download.samplelib.com/mp3/sample-9s.mp3', 9, 'sample')
ON CONFLICT (translation_id) DO NOTHING;

INSERT INTO tourist_site (id, city, name, lat, lng, category) VALUES
    ('55555555-0000-0000-0000-000000000001', 'Samarkand', 'Registan Meydanı', 39.6547, 66.9758, 'square'),
    ('55555555-0000-0000-0000-000000000002', 'Samarkand', 'Gur-i Emir Türbesi', 39.6486, 66.9690, 'mausoleum'),
    ('55555555-0000-0000-0000-000000000003', 'Samarkand', 'Bibi Hanım Camii', 39.6606, 66.9817, 'mosque'),
    ('55555555-0000-0000-0000-000000000004', 'Bukhara', 'Po-i Kalan Külliyesi', 39.7756, 64.4143, 'mosque'),
    ('55555555-0000-0000-0000-000000000005', 'Bukhara', 'Lyab-i Hauz', 39.7747, 64.4194, 'square'),
    ('55555555-0000-0000-0000-000000000006', 'Tashkent', 'Çorsu Pazarı', 41.3262, 69.2348, 'bazaar'),
    ('55555555-0000-0000-0000-000000000007', 'Khiva', 'İçan Kale', 41.3783, 60.3639, 'madrasah')
ON CONFLICT (id) DO NOTHING;

INSERT INTO route (id, name, summary) VALUES
    ('66666666-0000-0000-0000-000000000001', 'Klasik İpek Yolu — 4 gün',
     'Taşkent → Semerkant → Buhara → Hiva ana hattı.'),
    ('66666666-0000-0000-0000-000000000002', 'Semerkant kısa molası — 1 gün',
     'Tek günde Semerkant''ın öne çıkan üç anıtı.')
ON CONFLICT (id) DO NOTHING;

INSERT INTO route_stop (id, route_id, ord, city, title, description, duration_label) VALUES
    ('77777777-0000-0000-0000-000000000001', '66666666-0000-0000-0000-000000000001', 0,
     'Tashkent', 'Taşkent''te varış', 'Çorsu Pazarı ve eski şehirde ilk gün. Akşam hızlı tren bileti.', '1 gün'),
    ('77777777-0000-0000-0000-000000000002', '66666666-0000-0000-0000-000000000001', 1,
     'Samarkand', 'Semerkant''ın anıtları', 'Registan, Gur-i Emir ve Bibi Hanım. QR rehberiyle müze turu.', '1,5 gün'),
    ('77777777-0000-0000-0000-000000000003', '66666666-0000-0000-0000-000000000001', 2,
     'Bukhara', 'Buhara''nın eski şehri', 'Po-i Kalan ve Lyab-i Hauz çevresinde yürüyüş.', '1 gün'),
    ('77777777-0000-0000-0000-000000000004', '66666666-0000-0000-0000-000000000001', 3,
     'Khiva', 'Hiva — İçan Kale', 'Surlarla çevrili müze-şehirde kapanış.', 'Yarım gün'),
    ('77777777-0000-0000-0000-000000000005', '66666666-0000-0000-0000-000000000002', 0,
     'Samarkand', 'Registan Meydanı', 'Üç medreseyle çevrili tarihi meydan.', '2 saat'),
    ('77777777-0000-0000-0000-000000000006', '66666666-0000-0000-0000-000000000002', 1,
     'Samarkand', 'Gur-i Emir', 'Timur''un türbesi.', '1 saat'),
    ('77777777-0000-0000-0000-000000000007', '66666666-0000-0000-0000-000000000002', 2,
     'Samarkand', 'Bibi Hanım Camii', 'Dönemin en büyük camilerinden.', '1 saat')
ON CONFLICT (route_id, ord) DO NOTHING;
