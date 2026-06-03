import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:uzbek_tour_app/screens/route_screen.dart';
import 'package:uzbek_tour_app/state/locale_controller.dart';
import 'package:uzbek_tour_app/state/ui_locale_controller.dart';

// RouteScreen kendi DiscoveryService(useMock: true)'unu kurar; mock veriden
// okur, eklenti (geolocator/url_launcher/just_audio) çağırmaz. Arayüz metinleri
// için dil provider'ları gerekir.
Widget _harness() => MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => LocaleController()),
        ChangeNotifierProvider(create: (_) => UiLocaleController()),
      ],
      child: const MaterialApp(home: RouteScreen()),
    );

void main() {
  testWidgets('rota ekranı mock rotaları kart olarak gösterir',
      (tester) async {
    await tester.pumpWidget(_harness());
    await tester.pumpAndSettle();

    expect(find.text('Klasik İpek Yolu — 4 gün'), findsOneWidget);
    expect(find.text('Semerkant kısa molası — 1 gün'), findsOneWidget);
  });

  testWidgets('rota kartı açılınca durakları gösterir', (tester) async {
    await tester.pumpWidget(_harness());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Semerkant kısa molası — 1 gün'));
    await tester.pumpAndSettle();

    expect(find.text('Registan Meydanı'), findsOneWidget);
    expect(find.text('Gur-i Emir'), findsOneWidget);
  });
}
