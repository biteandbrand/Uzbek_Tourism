import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:permission_handler/permission_handler.dart';
import '../app_config.dart';
import '../l10n/app_strings.dart';
import '../services/content_service.dart';
import 'exhibit_detail_screen.dart';

/// Müze objesi/odası üzerindeki QR kodu okutan ekran.
class QrScannerScreen extends StatefulWidget {
  const QrScannerScreen({super.key, this.museumId});

  /// Belirli bir müzeden açıldıysa: başka müzenin QR'ı okutulunca uyarılır.
  final String? museumId;

  @override
  State<QrScannerScreen> createState() => _QrScannerScreenState();
}

class _QrScannerScreenState extends State<QrScannerScreen> {
  final _service = ContentService(useMock: kUseMock);
  final _controller = MobileScannerController();
  bool _handling = false; // aynı kodu üst üste okumamak için

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _onDetect(BarcodeCapture capture) async {
    if (capture.barcodes.isEmpty) return;
    final raw = capture.barcodes.first.rawValue;
    if (raw == null) return;

    final exhibitId = ContentService.exhibitIdFromPayload(raw);
    if (exhibitId == null) return; // bizim QR'ımız değil
    await _open(exhibitId);
  }

  /// Bir exhibit id'sini yükleyip detay ekranına gider. Hem QR okunduğunda
  /// hem de mock moddaki "simüle et" butonundan çağrılır.
  Future<void> _open(String exhibitId) async {
    if (_handling) return; // aynı kodu üst üste okumamak için
    // context'e bağlı referanslar await'ten önce alınır (lint-temiz).
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final strings = context.stringsRead;
    setState(() => _handling = true);
    try {
      final exhibit = await _service.getExhibit(exhibitId);
      if (!mounted) return;
      // Farklı bir müzenin objesi okutulduysa kullanıcıya sor.
      final expected = widget.museumId;
      if (expected != null &&
          exhibit.museumId != null &&
          exhibit.museumId != expected) {
        final proceed = await _confirmWrongMuseum();
        if (proceed != true || !mounted) return;
      }
      await navigator.push(MaterialPageRoute(
        builder: (_) => ExhibitDetailScreen(exhibit: exhibit),
      ));
    } catch (e) {
      if (mounted) {
        messenger.showSnackBar(SnackBar(content: Text(strings.error(e))));
      }
    } finally {
      if (mounted) setState(() => _handling = false);
    }
  }

  Future<bool?> _confirmWrongMuseum() {
    final s = context.stringsRead;
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(s.wrongMuseumTitle),
        content: Text(s.wrongMuseumBody),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(s.cancel)),
          FilledButton(
              onPressed: () => Navigator.pop(ctx, true), child: Text(s.open)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = context.strings;
    return Scaffold(
      appBar: AppBar(title: Text(s.qrAppBar)),
      body: Stack(
        alignment: Alignment.center,
        children: [
          MobileScanner(
            controller: _controller,
            onDetect: _onDetect,
            errorBuilder: (context, error, child) => _ErrorView(
              error: error,
              onRetry: () => _controller.start(),
            ),
          ),
          // Basit hedef çerçevesi
          Container(
            width: 240,
            height: 240,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.white, width: 3),
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          if (_handling) const CircularProgressIndicator(),
        ],
      ),
      // Mock modda kamerasız denemek için: örnek bir QR okunmuş gibi davranır.
      floatingActionButton: kUseMock
          ? FloatingActionButton.extended(
              onPressed: _handling ? null : () => _open('demo'),
              icon: const Icon(Icons.bug_report),
              label: Text(s.simulateDemo),
            )
          : null,
    );
  }
}

/// Kamera başlatılamadığında gösterilir. İzin reddinde ayarlara yönlendirir.
class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.error, required this.onRetry});

  final MobileScannerException error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final s = context.strings;
    final denied =
        error.errorCode == MobileScannerErrorCode.permissionDenied;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(denied ? Icons.no_photography : Icons.error_outline,
                size: 48, color: Colors.white70),
            const SizedBox(height: 16),
            Text(
              denied ? s.cameraPermissionNeeded : s.cameraStartFailed,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white),
            ),
            const SizedBox(height: 16),
            denied
                ? FilledButton.icon(
                    onPressed: openAppSettings,
                    icon: const Icon(Icons.settings),
                    label: Text(s.openSettings),
                  )
                : FilledButton.icon(
                    onPressed: onRetry,
                    icon: const Icon(Icons.refresh),
                    label: Text(s.retry),
                  ),
          ],
        ),
      ),
    );
  }
}
