import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';

/// Çevrimdışı içerik deposu — exhibit önbelleği ve indirilen müze işaretleri.
/// Soyut tutulur ki testlerde bellek içi bir uyarlama enjekte edilebilsin.
abstract class OfflineStore {
  Future<String?> readExhibit(String id);
  Future<void> writeExhibit(String id, String json);
  Future<Set<String>> readDownloadedMuseums();
  Future<void> writeDownloadedMuseums(Set<String> ids);
}

/// Cihazda dosya tabanlı varsayılan uygulama (path_provider + dart:io).
class FileOfflineStore implements OfflineStore {
  Future<Directory> _dir() async {
    final base = await getApplicationDocumentsDirectory();
    return Directory('${base.path}/exhibits');
  }

  Future<File> _file(String name) async => File('${(await _dir()).path}/$name');

  @override
  Future<String?> readExhibit(String id) async {
    final f = await _file('$id.json');
    return await f.exists() ? f.readAsString() : null;
  }

  @override
  Future<void> writeExhibit(String id, String json) async {
    final f = await _file('$id.json');
    await f.create(recursive: true);
    await f.writeAsString(json);
  }

  @override
  Future<Set<String>> readDownloadedMuseums() async {
    try {
      final f = await _file('downloaded_museums.json');
      if (!await f.exists()) return {};
      return (jsonDecode(await f.readAsString()) as List).cast<String>().toSet();
    } catch (_) {
      return {}; // bozuk/eksik işaret indirilmemiş sayılır
    }
  }

  @override
  Future<void> writeDownloadedMuseums(Set<String> ids) async {
    final f = await _file('downloaded_museums.json');
    await f.create(recursive: true);
    await f.writeAsString(jsonEncode(ids.toList()));
  }
}
