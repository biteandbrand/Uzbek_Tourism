import 'package:flutter/foundation.dart';

/// Kullanıcının seçtiği içerik dili — uygulama genelinde paylaşılır.
/// QR içeriği, sesli/yazılı anlatım hep bu dile göre açılır.
class LocaleController extends ChangeNotifier {
  LocaleController([this._langCode = 'en']);

  String _langCode;
  String get langCode => _langCode;

  /// Desteklenen içerik dilleri (kod → görünen ad).
  static const supported = {
    'uz': 'Oʻzbekcha',
    'ru': 'Русский',
    'en': 'English',
    'zh': '中文',
    'tr': 'Türkçe',
  };

  void setLang(String code) {
    if (code == _langCode || !supported.containsKey(code)) return;
    _langCode = code;
    notifyListeners();
  }
}
