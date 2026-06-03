// `flutter create .` tarafından üretilen varsayılan (MyApp'e referans veren)
// şablon testinin yerini tutar. Gerçek widget testleri:
//   home_screen_test.dart, route_screen_test.dart, recommendations_screen_test.dart
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('yer tutucu — gerçek testler *_screen_test.dart dosyalarında', () {
    expect(true, isTrue);
  });
}
