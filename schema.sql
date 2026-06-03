-- Özbekistan Turizm Uygulaması — İçerik Veri Modeli (PostgreSQL)
-- Diyagramdaki ER modelinin doğrudan karşılığıdır.

CREATE EXTENSION IF NOT EXISTS "pgcrypto";  -- gen_random_uuid() için

-- Diller (Özbekçe, Rusça, İngilizce, Çince, ...)
CREATE TABLE language (
    code        TEXT PRIMARY KEY,            -- 'uz', 'ru', 'en', 'zh', ...
    name        TEXT NOT NULL
);

-- Müzeler
CREATE TABLE museum (
    id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name        TEXT NOT NULL,
    city        TEXT NOT NULL,               -- 'Samarkand', 'Bukhara', 'Tashkent'
    lat         DOUBLE PRECISION NOT NULL,
    lng         DOUBLE PRECISION NOT NULL,
    created_at  TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Sergilenen birim: hem ODA hem OBJE aynı tabloda.
-- type = 'room' | 'object'.  parent_id ile obje, içinde olduğu odaya bağlanır.
CREATE TABLE exhibit (
    id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    museum_id   UUID NOT NULL REFERENCES museum(id) ON DELETE CASCADE,
    parent_id   UUID REFERENCES exhibit(id) ON DELETE SET NULL,  -- oda -> obje
    type        TEXT NOT NULL CHECK (type IN ('room', 'object')),
    position    TEXT,                        -- 'Salon 2, vitrin 4' gibi yer notu
    created_at  TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX idx_exhibit_museum ON exhibit(museum_id);
CREATE INDEX idx_exhibit_parent ON exhibit(parent_id);

-- Her exhibit için dile göre metin içeriği
CREATE TABLE translation (
    id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    exhibit_id  UUID NOT NULL REFERENCES exhibit(id) ON DELETE CASCADE,
    lang_code   TEXT NOT NULL REFERENCES language(code),
    title       TEXT NOT NULL,
    body        TEXT NOT NULL,               -- yazılı anlatım
    UNIQUE (exhibit_id, lang_code)
);
CREATE INDEX idx_translation_exhibit ON translation(exhibit_id);

-- Her çeviri için TTS ile üretilmiş ses dosyası
CREATE TABLE audio_asset (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    translation_id  UUID NOT NULL UNIQUE REFERENCES translation(id) ON DELETE CASCADE,
    url             TEXT NOT NULL,           -- CDN / object storage adresi
    duration_sec    INTEGER,
    tts_voice       TEXT,                    -- kullanılan ses modeli
    generated_at    TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Her exhibit için tek QR kod (payload uygulamada deep-link'e çözülür)
CREATE TABLE qr_code (
    id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    exhibit_id  UUID NOT NULL UNIQUE REFERENCES exhibit(id) ON DELETE CASCADE,
    payload     TEXT NOT NULL UNIQUE,        -- ör: 'uztour://exhibit/<id>'
    printed_at  TIMESTAMPTZ
);

-- Konuma göre önerilecek turistik mekanlar
CREATE TABLE tourist_site (
    id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    city        TEXT NOT NULL,
    name        TEXT NOT NULL,
    lat         DOUBLE PRECISION NOT NULL,
    lng         DOUBLE PRECISION NOT NULL,
    category    TEXT                         -- 'mosque', 'mausoleum', 'bazaar', ...
);
CREATE INDEX idx_site_city ON tourist_site(city);
