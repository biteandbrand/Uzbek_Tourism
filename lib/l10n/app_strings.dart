import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';
import '../state/locale_controller.dart';
import '../state/ui_locale_controller.dart';

/// Arayüz (UI) metinleri — içerik dilinden ayrı; içerik (exhibit) çok dilli
/// gelirken arayüz de seçili dile göre gösterilir.
///
/// Şu an doğru yazılabilen **tr** ve **en** mevcut; uz/ru/zh için çeviri
/// eklenene kadar İngilizceye düşülür. Yeni dil: bir [AppStrings] örneği
/// tanımlayıp [of] içine bağlamak yeterli.
class AppStrings {
  // Ana ekran
  final String appTitle;
  final String contentLanguage;
  final String appLanguage;
  final String followContentLanguage;
  final String qrTitle;
  final String qrSubtitle;
  final String routesTitle;
  final String routesSubtitle;
  final String recommendationsTitle;
  final String recommendationsSubtitle;
  final String museumsTitle;
  final String museumsSubtitle;
  final String museumsReadyFmt; // '{n}'

  // Ortak
  final String retry;
  final String cancel;

  // Rota
  final String routesError;
  final String routesEmpty;
  final String cityRecommendationsFmt; // '{city}'

  // Öneri
  final String byCity;
  final String nearby;
  final String cityLabel;
  final String recommendationsError;
  final String nearbyError;
  final String recommendationsEmpty;
  final String mapOpenFailed;
  // Kategoriler
  final String catMosque;
  final String catMausoleum;
  final String catBazaar;
  final String catMadrasah;
  final String catSquare;
  final String catPlace;

  // Müzeler
  final String searchHint;
  final String clearTooltip;
  final String resultsCountFmt; // '{n}'
  final String downloadAllTooltip;
  final String deleteAllTooltip;
  final String downloadTooltip;
  final String deleteOfflineTooltip;
  final String tapToScan;
  final String museumsEmpty;
  final String museumsError;
  final String deleteDialogTitle;
  final String deleteDialogBodyFmt; // '{name}'
  final String delete;
  final String downloadFirstFmt; // '{name}'
  final String download;
  final String downloadFailedFmt; // '{error}'

  // QR
  final String qrAppBar;
  final String simulateDemo;
  final String errorFmt; // '{error}'
  final String wrongMuseumTitle;
  final String wrongMuseumBody;
  final String open;
  final String cameraPermissionNeeded;
  final String cameraStartFailed;
  final String openSettings;

  // Detay
  final String objectFallback;
  final String noContentForLang;
  final String contentFallbackFmt; // '{lang}'
  final String noAudio;
  final String audioLoading;
  final String audioError;

  const AppStrings({
    required this.appTitle,
    required this.contentLanguage,
    required this.appLanguage,
    required this.followContentLanguage,
    required this.qrTitle,
    required this.qrSubtitle,
    required this.routesTitle,
    required this.routesSubtitle,
    required this.recommendationsTitle,
    required this.recommendationsSubtitle,
    required this.museumsTitle,
    required this.museumsSubtitle,
    required this.museumsReadyFmt,
    required this.retry,
    required this.cancel,
    required this.routesError,
    required this.routesEmpty,
    required this.cityRecommendationsFmt,
    required this.byCity,
    required this.nearby,
    required this.cityLabel,
    required this.recommendationsError,
    required this.nearbyError,
    required this.recommendationsEmpty,
    required this.mapOpenFailed,
    required this.catMosque,
    required this.catMausoleum,
    required this.catBazaar,
    required this.catMadrasah,
    required this.catSquare,
    required this.catPlace,
    required this.searchHint,
    required this.clearTooltip,
    required this.resultsCountFmt,
    required this.downloadAllTooltip,
    required this.deleteAllTooltip,
    required this.downloadTooltip,
    required this.deleteOfflineTooltip,
    required this.tapToScan,
    required this.museumsEmpty,
    required this.museumsError,
    required this.deleteDialogTitle,
    required this.deleteDialogBodyFmt,
    required this.delete,
    required this.downloadFirstFmt,
    required this.download,
    required this.downloadFailedFmt,
    required this.qrAppBar,
    required this.simulateDemo,
    required this.errorFmt,
    required this.wrongMuseumTitle,
    required this.wrongMuseumBody,
    required this.open,
    required this.cameraPermissionNeeded,
    required this.cameraStartFailed,
    required this.openSettings,
    required this.objectFallback,
    required this.noContentForLang,
    required this.contentFallbackFmt,
    required this.noAudio,
    required this.audioLoading,
    required this.audioError,
  });

  String museumsReady(int n) => museumsReadyFmt.replaceFirst('{n}', '$n');
  String cityRecommendations(String city) =>
      cityRecommendationsFmt.replaceFirst('{city}', city);
  String resultsCount(int n) => resultsCountFmt.replaceFirst('{n}', '$n');
  String deleteDialogBody(String name) =>
      deleteDialogBodyFmt.replaceFirst('{name}', name);
  String downloadFirst(String name) =>
      downloadFirstFmt.replaceFirst('{name}', name);
  String downloadFailed(Object e) =>
      downloadFailedFmt.replaceFirst('{error}', '$e');
  String error(Object e) => errorFmt.replaceFirst('{error}', '$e');
  String contentFallback(String lang) =>
      contentFallbackFmt.replaceFirst('{lang}', lang);

  /// Kategori kodunu yerelleştirilmiş etikete çevirir.
  String category(String? code) {
    switch (code) {
      case 'mosque':
        return catMosque;
      case 'mausoleum':
        return catMausoleum;
      case 'bazaar':
        return catBazaar;
      case 'madrasah':
        return catMadrasah;
      case 'square':
        return catSquare;
      default:
        return catPlace;
    }
  }

  /// Tam çevirisi olan arayüz dilleri (seçici bunlardan üretilir).
  /// Yeni dil eklerken hem buraya hem [of] içine eklenir.
  static const supportedUiLanguages = ['en', 'tr'];

  static AppStrings of(String langCode) => langCode == 'tr' ? _tr : _en;

  static const _en = AppStrings(
    appTitle: 'Uzbek Tour',
    contentLanguage: 'Content language',
    appLanguage: 'App language',
    followContentLanguage: 'Same as content',
    qrTitle: 'Scan QR at the museum',
    qrSubtitle: 'Audio + written guide for the object/room',
    routesTitle: 'Routes',
    routesSubtitle: 'Ready-made itineraries',
    recommendationsTitle: 'Recommendations',
    recommendationsSubtitle: 'Sights by city',
    museumsTitle: 'Museums (offline)',
    museumsSubtitle: 'Download museum content in advance',
    museumsReadyFmt: '{n} museums ready offline',
    retry: 'Retry',
    cancel: 'Cancel',
    routesError: 'Could not load routes',
    routesEmpty: 'No routes yet',
    cityRecommendationsFmt: '{city} recommendations',
    byCity: 'By city',
    nearby: 'Nearby',
    cityLabel: 'City',
    recommendationsError: 'Could not load recommendations',
    nearbyError: 'Could not get location/recommendations',
    recommendationsEmpty: 'No recommendations found',
    mapOpenFailed: 'Could not open map',
    catMosque: 'Mosque',
    catMausoleum: 'Mausoleum',
    catBazaar: 'Bazaar',
    catMadrasah: 'Madrasah',
    catSquare: 'Square',
    catPlace: 'Place',
    searchHint: 'Search museum or city',
    clearTooltip: 'Clear',
    resultsCountFmt: '{n} results',
    downloadAllTooltip: 'Download all',
    deleteAllTooltip: 'Delete all',
    downloadTooltip: 'Download offline',
    deleteOfflineTooltip: 'Delete offline content',
    tapToScan: 'Tap to scan QR',
    museumsEmpty: 'No museums found',
    museumsError: 'Could not load museums',
    deleteDialogTitle: 'Delete offline content',
    deleteDialogBodyFmt: 'Delete downloaded content for "{name}"?',
    delete: 'Delete',
    downloadFirstFmt: 'Download "{name}" content first',
    download: 'Download',
    downloadFailedFmt: 'Download failed: {error}',
    qrAppBar: 'Scan QR',
    simulateDemo: 'Simulate (demo)',
    errorFmt: 'Error: {error}',
    wrongMuseumTitle: 'Different museum',
    wrongMuseumBody:
        'This object does not seem to belong to the selected museum. Open anyway?',
    open: 'Open',
    cameraPermissionNeeded:
        'Camera permission is required to scan QR. You can enable it in settings.',
    cameraStartFailed: 'Could not start the camera.',
    openSettings: 'Open settings',
    objectFallback: 'Object',
    noContentForLang: 'No content for this language',
    contentFallbackFmt: 'Not available in the selected language; showing {lang}.',
    noAudio: 'No audio guide for this language',
    audioLoading: 'Loading audio…',
    audioError: 'Could not load the audio guide',
  );

  static const _tr = AppStrings(
    appTitle: 'Uzbek Tour',
    contentLanguage: 'İçerik dili',
    appLanguage: 'Uygulama dili',
    followContentLanguage: 'İçerikle aynı',
    qrTitle: 'Müzede QR okut',
    qrSubtitle: 'Obje/odanın sesli ve yazılı anlatımı',
    routesTitle: 'Rotalar',
    routesSubtitle: 'Hazır gezi planları',
    recommendationsTitle: 'Öneriler',
    recommendationsSubtitle: 'Şehre göre turistik mekanlar',
    museumsTitle: 'Müzeler (çevrimdışı)',
    museumsSubtitle: 'Müze içeriğini önceden indir',
    museumsReadyFmt: '{n} müze çevrimdışı hazır',
    retry: 'Yeniden dene',
    cancel: 'Vazgeç',
    routesError: 'Rotalar alınamadı',
    routesEmpty: 'Henüz rota yok',
    cityRecommendationsFmt: '{city} önerileri',
    byCity: 'Şehre göre',
    nearby: 'Yakınımdakiler',
    cityLabel: 'Şehir',
    recommendationsError: 'Öneriler alınamadı',
    nearbyError: 'Konum/öneri alınamadı',
    recommendationsEmpty: 'Öneri bulunamadı',
    mapOpenFailed: 'Harita açılamadı',
    catMosque: 'Cami',
    catMausoleum: 'Türbe',
    catBazaar: 'Pazar',
    catMadrasah: 'Medrese',
    catSquare: 'Meydan',
    catPlace: 'Mekan',
    searchHint: 'Müze veya şehir ara',
    clearTooltip: 'Temizle',
    resultsCountFmt: '{n} sonuç',
    downloadAllTooltip: 'Tümünü indir',
    deleteAllTooltip: 'Tümünü sil',
    downloadTooltip: 'Çevrimdışı indir',
    deleteOfflineTooltip: 'Çevrimdışı içeriği sil',
    tapToScan: 'QR okutmak için dokunun',
    museumsEmpty: 'Müze bulunamadı',
    museumsError: 'Müzeler alınamadı',
    deleteDialogTitle: 'Çevrimdışı içeriği sil',
    deleteDialogBodyFmt: '"{name}" için indirilen içerik silinsin mi?',
    delete: 'Sil',
    downloadFirstFmt: 'Önce "{name}" içeriğini indirin',
    download: 'İndir',
    downloadFailedFmt: 'İndirilemedi: {error}',
    qrAppBar: 'QR kodu okut',
    simulateDemo: 'Simüle et (demo)',
    errorFmt: 'Hata: {error}',
    wrongMuseumTitle: 'Farklı müze',
    wrongMuseumBody:
        'Bu obje seçtiğiniz müzeye ait görünmüyor. Yine de açılsın mı?',
    open: 'Aç',
    cameraPermissionNeeded:
        'QR okumak için kamera izni gerekiyor. İzni ayarlardan açabilirsiniz.',
    cameraStartFailed: 'Kamera başlatılamadı.',
    openSettings: 'Ayarları aç',
    objectFallback: 'Obje',
    noContentForLang: 'Bu dil için içerik yok',
    contentFallbackFmt: 'Bu içerik seçili dilde yok; {lang} dilinde gösteriliyor.',
    noAudio: 'Bu dil için sesli anlatım yok',
    audioLoading: 'Ses yükleniyor…',
    audioError: 'Sesli anlatım yüklenemedi',
  );
}

/// Arayüz metinlerine kısayol. Seçili içerik diline göre çözülür; dil değişince
/// dinleyen widget yeniden çizilir. (Arayüz dili ayrılırsa burası değişir.)
extension AppStringsX on BuildContext {
  /// build() içinde kullanın — dil değişince yeniden çizer.
  AppStrings get strings => AppStrings.of(
      watch<UiLocaleController>().resolve(watch<LocaleController>().langCode));

  /// Olay/geri-çağrılarda kullanın (dinlemez).
  AppStrings get stringsRead => AppStrings.of(
      read<UiLocaleController>().resolve(read<LocaleController>().langCode));
}
