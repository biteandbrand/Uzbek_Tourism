// Uygulama genelinde basit yapılandırma.
//
// Gerçek backend bağlanınca `kUseMock` false yapılır; o zaman tüm servisler
// API'ye gider. Prototipte true: QR, rota ve öneri akışları örnek veriyle çalışır.
const bool kUseMock = true;

// Tüm servislerin kullandığı API kök adresi. Gerçek backend bağlanınca
// yalnızca burası değiştirilir.
const String kApiBase = 'https://api.uztour.example';
