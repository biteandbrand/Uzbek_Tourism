import 'package:flutter/foundation.dart';

/// Arayüz (UI) dili. İçerik dilinden bağımsız seçilebilir; varsayılan olarak
/// içerik dilini izler (`override == null`).
class UiLocaleController extends ChangeNotifier {
  String? _override;

  /// Seçili arayüz dili; null ise içerik dili izlenir.
  String? get override => _override;

  void setOverride(String? code) {
    if (code == _override) return;
    _override = code;
    notifyListeners();
  }

  /// Etkin arayüz dili: override varsa o, yoksa içerik dili.
  String resolve(String contentLang) => _override ?? contentLang;
}
