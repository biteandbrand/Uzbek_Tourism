import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:uzbek_tour_app/screens/recommendations_screen.dart';
import 'package:uzbek_tour_app/state/locale_controller.dart';
import 'package:uzbek_tour_app/state/ui_locale_controller.dart';

// Şehir modu mock veriden okur; konum/harita eklentilerini çağırmaz
// (yalnızca "Yakınımdakiler" sekmesi konum ister, dokunma harita açar).
Widget _harness() => MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => LocaleController()),
        ChangeNotifierProvider(create: (_) => UiLocaleController()),
      ],
      child: const MaterialApp(home: RecommendationsScreen()),
    );

void main() {
  testWidgets('öneri ekranı şehir modunda mock mekanları gösterir',
      (tester) async {
    await tester.pumpWidget(_harness());
    await tester.pumpAndSettle();

    // İki segment (varsayılan dil en).
    expect(find.text('By city'), findsOneWidget);
    expect(find.text('Nearby'), findsOneWidget);

    // İlk şehir alfabetik 'Bukhara'; mekanlarından biri listelenir.
    expect(find.text('Po-i Kalan Külliyesi'), findsOneWidget);
  });

  testWidgets('başka şehre geçince o şehrin mekanları gelir', (tester) async {
    await tester.pumpWidget(_harness());
    await tester.pumpAndSettle();

    // Şehir açılır menüsünü aç ve Samarkand'ı seç.
    await tester.tap(find.byType(DropdownButtonFormField<String>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Samarkand').last);
    await tester.pumpAndSettle();

    expect(find.text('Registan Meydanı'), findsOneWidget);
  });
}
