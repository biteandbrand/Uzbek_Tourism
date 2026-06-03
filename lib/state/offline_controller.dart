import 'package:flutter/foundation.dart';
import '../services/content_service.dart';

/// Çevrimdışı indirilmiş müzelerin uygulama geneli durumu.
/// Kalıcılık `ContentService`'in işaretçi dosyasında; bu sınıf bellekteki
/// kopyayı tutup dinleyicileri (ana ekran özeti, müze listesi) günceller.
class OfflineController extends ChangeNotifier {
  OfflineController(this._content);

  final ContentService _content;
  final Set<String> _ids = {};
  final Set<String> _downloading = {};
  final Map<String, double> _progress = {};
  bool _loaded = false;

  int get count => _ids.length;
  bool isDownloaded(String id) => _ids.contains(id);
  bool isDownloading(String id) => _downloading.contains(id);

  /// İndirme ilerlemesi (0.0–1.0); indirilmiyorsa null.
  double? progressOf(String id) => _progress[id];

  /// İlk kullanımda kalıcı işaretleri yükler (tekrar çağrı ucuz).
  Future<void> ensureLoaded() async {
    if (_loaded) return;
    _loaded = true;
    _ids.addAll(await _content.downloadedMuseums());
    notifyListeners();
  }

  /// Müze içeriğini indirir; ilerleme/işaret durumunu yönetir.
  /// Hata olursa durum temizlenir ve hata yeniden fırlatılır (UI göstersin).
  Future<void> download(String id) async {
    if (_downloading.contains(id) || _ids.contains(id)) return;
    _downloading.add(id);
    _progress[id] = 0;
    notifyListeners();
    try {
      await _content.prefetchMuseum(id, onProgress: (p) {
        _progress[id] = p;
        notifyListeners();
      });
      _ids.add(id);
    } finally {
      _downloading.remove(id);
      _progress.remove(id);
      notifyListeners();
    }
  }

  Future<void> remove(String id) async {
    await _content.clearMuseum(id);
    if (_ids.remove(id)) notifyListeners();
  }

  Future<void> clearAll() async {
    await _content.clearAll();
    if (_ids.isNotEmpty) {
      _ids.clear();
      notifyListeners();
    }
  }
}
