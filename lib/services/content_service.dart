import 'dart:convert';
import 'package:http/http.dart' as http;
import '../app_config.dart';
import '../models/exhibit.dart';
import 'mock_data.dart';
import 'offline_store.dart';

/// İçerik servisi: QR payload'ını çözer, exhibit içeriğini getirir.
/// Önce yerel önbelleğe (offline) bakar, yoksa API'den çeker.
class ContentService {
  ContentService({
    this.apiBase = kApiBase,
    this.useMock = false,
    http.Client? client,
    OfflineStore? store,
  })  : _client = client ?? http.Client(),
        _store = store ?? FileOfflineStore();

  final String apiBase;

  /// Backend hazır değilken örnek veriden okur (geliştirme/test).
  final bool useMock;

  final http.Client _client;
  final OfflineStore _store;

  /// QR payload 'uztour://exhibit/<id>' formatında. id'yi çıkarır.
  static String? exhibitIdFromPayload(String payload) {
    final uri = Uri.tryParse(payload.trim());
    if (uri == null || uri.scheme != 'uztour') return null;
    if (uri.host != 'exhibit') return null;
    return uri.pathSegments.isNotEmpty ? uri.pathSegments.first : null;
  }

  /// Çevrimdışı indirilmiş müzelerin id'leri (oturumlar arası kalıcı).
  Future<Set<String>> downloadedMuseums() => _store.readDownloadedMuseums();

  Future<void> _markDownloaded(String museumId) async {
    final current = await downloadedMuseums();
    current.add(museumId);
    await _store.writeDownloadedMuseums(current);
  }

  /// Bir müzenin çevrimdışı işaretini kaldırır.
  Future<void> clearMuseum(String museumId) async {
    final current = await downloadedMuseums();
    current.remove(museumId);
    await _store.writeDownloadedMuseums(current);
  }

  /// Tüm çevrimdışı işaretleri temizler.
  Future<void> clearAll() => _store.writeDownloadedMuseums({});

  /// Bir müzeye girerken tüm müze içeriğini önceden indirip önbelleğe yazmak
  /// için kullanılır (sinyalin zayıf olduğu müze içi senaryosu).
  /// [onProgress] 0.0–1.0 arası ilerleme bildirir.
  Future<void> prefetchMuseum(
    String museumId, {
    void Function(double progress)? onProgress,
  }) async {
    if (useMock) {
      // Mock modda indirmeyi taklit ederiz; içerik zaten MockData'dan gelir.
      for (final p in [0.3, 0.6, 1.0]) {
        await Future<void>.delayed(const Duration(milliseconds: 300));
        onProgress?.call(p);
      }
      await _markDownloaded(museumId);
      return;
    }
    final res =
        await _client.get(Uri.parse('$apiBase/museums/$museumId/exhibits'));
    if (res.statusCode != 200) {
      throw Exception('Müze içeriği indirilemedi (${res.statusCode})');
    }
    final list = (jsonDecode(res.body) as List).cast<Map<String, dynamic>>();
    for (var i = 0; i < list.length; i++) {
      await _store.writeExhibit(list[i]['id'] as String, jsonEncode(list[i]));
      onProgress?.call((i + 1) / list.length);
    }
    await _markDownloaded(museumId);
  }

  /// QR okutulduğunda çağrılır. Önce önbellek, sonra ağ.
  Future<Exhibit> getExhibit(String exhibitId) async {
    if (useMock) {
      final mock = MockData.exhibits[exhibitId] ?? MockData.exhibits['demo'];
      if (mock == null) throw Exception('Örnek obje bulunamadı ($exhibitId)');
      return mock;
    }
    final cached = await _store.readExhibit(exhibitId);
    if (cached != null) {
      return Exhibit.fromJson(jsonDecode(cached) as Map<String, dynamic>);
    }
    final res = await _client.get(Uri.parse('$apiBase/exhibits/$exhibitId'));
    if (res.statusCode != 200) {
      throw Exception('Obje bulunamadı (${res.statusCode})');
    }
    await _store.writeExhibit(exhibitId, res.body);
    return Exhibit.fromJson(jsonDecode(res.body) as Map<String, dynamic>);
  }
}
