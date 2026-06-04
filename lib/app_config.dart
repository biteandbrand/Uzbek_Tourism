// Uygulama genelinde basit yapılandırma — derleme ortamından (--dart-define)
// okunur, böylece kod değiştirmeden mock/prod arasında geçilir.
//
// Varsayılanlar yerel geliştirme/test içindir: mock açık. Prod derlemesi:
//   flutter run --dart-define=USE_MOCK=false \
//               --dart-define=API_BASE=https://<railway-url>
//
// Android emülatöründe yerel sunucu için API_BASE=http://10.0.2.2:8080,
// iOS simülatöründe http://localhost:8080.

/// Mock veri mi kullanılsın? Varsayılan true (test/yerel). Prod: USE_MOCK=false.
const bool kUseMock = bool.fromEnvironment('USE_MOCK', defaultValue: true);

/// API kök adresi. Prod'da Railway URL'i --dart-define ile verilir.
const String kApiBase = String.fromEnvironment(
  'API_BASE',
  defaultValue: 'https://api.uztour.example',
);
