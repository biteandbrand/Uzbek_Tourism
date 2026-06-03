import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'app_config.dart';
import 'theme.dart';
import 'l10n/app_strings.dart';
import 'services/content_service.dart';
import 'state/locale_controller.dart';
import 'state/offline_controller.dart';
import 'state/ui_locale_controller.dart';
import 'screens/museums_screen.dart';
import 'screens/qr_scanner_screen.dart';
import 'screens/recommendations_screen.dart';
import 'screens/route_screen.dart';

void main() => runApp(const UzbekTourApp());

class UzbekTourApp extends StatelessWidget {
  const UzbekTourApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => LocaleController()),
        ChangeNotifierProvider(create: (_) => UiLocaleController()),
        ChangeNotifierProvider(
          create: (_) =>
              OfflineController(ContentService(useMock: kUseMock))
                ..ensureLoaded(),
        ),
      ],
      child: MaterialApp(
        title: 'Uzbek Tour',
        theme: buildAppTheme(),
        home: const HomeScreen(),
      ),
    );
  }
}

/// Ana ekran: içerik dili seçimi + üç özelliğe (QR, rota, öneri) giriş.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  void _push(BuildContext context, Widget screen) {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => screen));
  }

  @override
  Widget build(BuildContext context) {
    final locale = context.watch<LocaleController>();
    final s = context.strings;
    final offlineCount = context.watch<OfflineController>().count;
    return Scaffold(
      appBar: AppBar(title: Text(s.appTitle)),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 8),
            Text(s.contentLanguage,
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              // value: reaktif (state'le güncellenir); initialValue tek seferlik.
              // ignore: deprecated_member_use
              value: locale.langCode,
              decoration: const InputDecoration(border: OutlineInputBorder()),
              items: LocaleController.supported.entries
                  .map((e) =>
                      DropdownMenuItem(value: e.key, child: Text(e.value)))
                  .toList(),
              onChanged: (v) {
                if (v != null) context.read<LocaleController>().setLang(v);
              },
            ),
            const SizedBox(height: 12),
            Text(s.appLanguage, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              // ignore: deprecated_member_use
              value: context.watch<UiLocaleController>().override ?? 'auto',
              decoration: const InputDecoration(border: OutlineInputBorder()),
              items: [
                DropdownMenuItem(
                    value: 'auto', child: Text(s.followContentLanguage)),
                for (final code in AppStrings.supportedUiLanguages)
                  DropdownMenuItem(
                      value: code,
                      child: Text(LocaleController.supported[code] ?? code)),
              ],
              onChanged: (v) => context
                  .read<UiLocaleController>()
                  .setOverride(v == 'auto' ? null : v),
            ),
            const SizedBox(height: 24),
            _FeatureCard(
              icon: Icons.qr_code_scanner,
              title: s.qrTitle,
              subtitle: s.qrSubtitle,
              onTap: () => _push(context, const QrScannerScreen()),
            ),
            _FeatureCard(
              icon: Icons.route,
              title: s.routesTitle,
              subtitle: s.routesSubtitle,
              onTap: () => _push(context, const RouteScreen()),
            ),
            _FeatureCard(
              icon: Icons.recommend,
              title: s.recommendationsTitle,
              subtitle: s.recommendationsSubtitle,
              onTap: () => _push(context, const RecommendationsScreen()),
            ),
            _FeatureCard(
              icon: Icons.download_for_offline,
              title: s.museumsTitle,
              subtitle: offlineCount > 0
                  ? s.museumsReady(offlineCount)
                  : s.museumsSubtitle,
              onTap: () => _push(context, const MuseumsScreen()),
            ),
          ],
        ),
      ),
    );
  }
}

class _FeatureCard extends StatelessWidget {
  const _FeatureCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Icon(icon, size: 32),
        title: Text(title, style: Theme.of(context).textTheme.titleMedium),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}
