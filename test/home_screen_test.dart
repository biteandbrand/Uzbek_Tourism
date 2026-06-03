import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:uzbek_tour_app/main.dart';
import 'package:uzbek_tour_app/services/content_service.dart';
import 'package:uzbek_tour_app/services/offline_store.dart';
import 'package:uzbek_tour_app/state/locale_controller.dart';
import 'package:uzbek_tour_app/state/offline_controller.dart';
import 'package:uzbek_tour_app/state/ui_locale_controller.dart';

/// path_provider'a ihtiyaç bırakmayan bellek içi depo.
class _MemStore implements OfflineStore {
  @override
  Future<String?> readExhibit(String id) async => null;
  @override
  Future<void> writeExhibit(String id, String json) async {}
  @override
  Future<Set<String>> readDownloadedMuseums() async => {};
  @override
  Future<void> writeDownloadedMuseums(Set<String> ids) async {}
}

Widget _harness(LocaleController locale) {
  return MultiProvider(
    providers: [
      ChangeNotifierProvider.value(value: locale),
      ChangeNotifierProvider(create: (_) => UiLocaleController()),
      ChangeNotifierProvider.value(
        value: OfflineController(
            ContentService(useMock: true, store: _MemStore())),
      ),
    ],
    child: const MaterialApp(home: HomeScreen()),
  );
}

void main() {
  testWidgets('ana ekran dört özelliği gösterir', (tester) async {
    await tester.pumpWidget(_harness(LocaleController()));
    await tester.pumpAndSettle();

    // Varsayılan içerik dili 'en' → arayüz İngilizce.
    expect(find.text('Scan QR at the museum'), findsOneWidget);
    expect(find.text('Routes'), findsOneWidget);
    expect(find.text('Recommendations'), findsOneWidget);
    expect(find.text('Museums (offline)'), findsOneWidget);
    expect(find.text('English'), findsOneWidget);
  });

  testWidgets('dil seçimi arayüzü ve LocaleController\'ı günceller',
      (tester) async {
    final locale = LocaleController();
    await tester.pumpWidget(_harness(locale));
    await tester.pumpAndSettle();

    // İlk dropdown içerik dili (ikincisi arayüz dili).
    await tester.tap(find.byType(DropdownButtonFormField<String>).first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Türkçe').last);
    await tester.pumpAndSettle();

    expect(locale.langCode, 'tr');
    // Arayüz dili içeriği izlediği için Türkçeleşir.
    expect(find.text('Müzede QR okut'), findsOneWidget);
  });
}
