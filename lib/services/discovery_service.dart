import 'dart:convert';
import 'package:http/http.dart' as http;
import '../app_config.dart';
import '../models/museum.dart';
import '../models/route_plan.dart';
import '../models/tourist_site.dart';
import 'mock_data.dart';

/// Rota (rota planları) ve öneri (konuma göre mekanlar) akışlarını besler.
/// İçerik servisinden ayrı tutulur; QR/offline mantığıyla işi yoktur.
class DiscoveryService {
  DiscoveryService({
    this.apiBase = kApiBase,
    this.useMock = false,
    http.Client? client,
  }) : _client = client ?? http.Client();

  final String apiBase;
  final bool useMock;
  final http.Client _client;

  /// Bir şehirdeki önerilen turistik mekanlar.
  Future<List<TouristSite>> sitesForCity(String city) async {
    if (useMock) {
      return MockData.sites.where((s) => s.city == city).toList();
    }
    final res = await _client.get(
        Uri.parse('$apiBase/sites?city=${Uri.encodeQueryComponent(city)}'));
    if (res.statusCode != 200) {
      throw Exception('Öneriler alınamadı (${res.statusCode})');
    }
    final list = (jsonDecode(res.body) as List).cast<Map<String, dynamic>>();
    return list.map(TouristSite.fromJson).toList();
  }

  /// Tüm mekanlar — "yakınımdakiler" için (konuma göre sıralanır).
  Future<List<TouristSite>> allSites() async {
    if (useMock) return List.of(MockData.sites);
    final res = await _client.get(Uri.parse('$apiBase/sites'));
    if (res.statusCode != 200) {
      throw Exception('Mekanlar alınamadı (${res.statusCode})');
    }
    final list = (jsonDecode(res.body) as List).cast<Map<String, dynamic>>();
    return list.map(TouristSite.fromJson).toList();
  }

  /// Öneri ekranındaki şehir seçimi için, mevcut şehirlerin listesi.
  Future<List<String>> cities() async {
    if (useMock) {
      final set = {for (final s in MockData.sites) s.city};
      return set.toList()..sort();
    }
    final res = await _client.get(Uri.parse('$apiBase/cities'));
    if (res.statusCode != 200) {
      throw Exception('Şehirler alınamadı (${res.statusCode})');
    }
    return (jsonDecode(res.body) as List).cast<String>();
  }

  /// Çevrimdışı indirme için müze listesi.
  Future<List<Museum>> museums() async {
    if (useMock) return List.of(MockData.museums);
    final res = await _client.get(Uri.parse('$apiBase/museums'));
    if (res.statusCode != 200) {
      throw Exception('Müzeler alınamadı (${res.statusCode})');
    }
    final list = (jsonDecode(res.body) as List).cast<Map<String, dynamic>>();
    return list.map(Museum.fromJson).toList();
  }

  /// Hazır gezi rotaları.
  Future<List<RoutePlan>> routes() async {
    if (useMock) return MockData.routes;
    final res = await _client.get(Uri.parse('$apiBase/routes'));
    if (res.statusCode != 200) {
      throw Exception('Rotalar alınamadı (${res.statusCode})');
    }
    final list = (jsonDecode(res.body) as List).cast<Map<String, dynamic>>();
    return list.map(RoutePlan.fromJson).toList();
  }
}
