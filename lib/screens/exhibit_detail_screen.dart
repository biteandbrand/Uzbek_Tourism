import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:provider/provider.dart';
import '../models/exhibit.dart';
import '../l10n/app_strings.dart';
import '../state/locale_controller.dart';
import '../widgets/empty_state.dart';

enum _AudioStatus { none, loading, ready, error }

/// QR okunduktan sonra: yazılı anlatım + sesli anlatım (oynat/duraklat).
class ExhibitDetailScreen extends StatefulWidget {
  const ExhibitDetailScreen({super.key, required this.exhibit});

  final Exhibit exhibit;

  @override
  State<ExhibitDetailScreen> createState() => _ExhibitDetailScreenState();
}

class _ExhibitDetailScreenState extends State<ExhibitDetailScreen> {
  final _player = AudioPlayer();
  _AudioStatus _status = _AudioStatus.none;
  // Aktif içerik dili; uygulama genelinde değişince güncellenir.
  String _langCode = '';

  ({Translation translation, bool isFallback})? get _localized =>
      widget.exhibit.localizedWith(_langCode);
  Translation? get _content => _localized?.translation;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // listen:true — dil değişince bu yeniden çağrılır ve ses yenilenir.
    final lang = Provider.of<LocaleController>(context).langCode;
    if (lang != _langCode) {
      _langCode = lang;
      _loadAudio();
    }
  }

  Future<void> _loadAudio() async {
    final url = _content?.audio?.url;
    if (url == null) {
      if (mounted) setState(() => _status = _AudioStatus.none);
      return;
    }
    setState(() => _status = _AudioStatus.loading);
    try {
      await _player.stop();
      await _player.setUrl(url);
      if (mounted) setState(() => _status = _AudioStatus.ready);
    } catch (_) {
      // ses yüklenemese de (ağ/eklenti) yazılı içerik gösterilmeye devam eder
      if (mounted) setState(() => _status = _AudioStatus.error);
    }
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final localized = _localized;
    final content = localized?.translation;
    final s = context.strings;
    return Scaffold(
      appBar: AppBar(title: Text(content?.title ?? s.objectFallback)),
      body: content == null
          ? EmptyState(message: s.noContentForLang)
          : ListView(
              padding: const EdgeInsets.all(20),
              children: [
                if (localized!.isFallback)
                  _FallbackBanner(
                    message: s.contentFallback(
                        LocaleController.supported[content.langCode] ??
                            content.langCode),
                  ),
                if (widget.exhibit.position != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Text(widget.exhibit.position!,
                        style: Theme.of(context).textTheme.bodySmall),
                  ),
                Text(content.title,
                    style: Theme.of(context).textTheme.headlineSmall),
                const SizedBox(height: 16),
                _AudioBar(
                  player: _player,
                  status: _status,
                  onRetry: _loadAudio,
                ),
                const SizedBox(height: 20),
                Text(content.body,
                    style: Theme.of(context).textTheme.bodyLarge),
              ],
            ),
    );
  }
}

/// İçerik seçili dilde olmayıp başka dilde gösterildiğinde uyarı.
class _FallbackBanner extends StatelessWidget {
  const _FallbackBanner({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: scheme.secondaryContainer,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(Icons.translate, size: 18, color: scheme.onSecondaryContainer),
          const SizedBox(width: 8),
          Expanded(
            child: Text(message,
                style: TextStyle(color: scheme.onSecondaryContainer)),
          ),
        ],
      ),
    );
  }
}

class _AudioBar extends StatelessWidget {
  const _AudioBar({
    required this.player,
    required this.status,
    required this.onRetry,
  });

  final AudioPlayer player;
  final _AudioStatus status;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final s = context.strings;
    switch (status) {
      case _AudioStatus.none:
        return Text(s.noAudio, style: Theme.of(context).textTheme.bodySmall);
      case _AudioStatus.loading:
        return Row(
          children: [
            const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2)),
            const SizedBox(width: 12),
            Text(s.audioLoading),
          ],
        );
      case _AudioStatus.error:
        return Row(
          children: [
            Icon(Icons.error_outline,
                color: Theme.of(context).colorScheme.error),
            const SizedBox(width: 8),
            Expanded(child: Text(s.audioError)),
            TextButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: Text(s.retry),
            ),
          ],
        );
      case _AudioStatus.ready:
        return _player(context);
    }
  }

  Widget _player(BuildContext context) {
    return StreamBuilder<PlayerState>(
      stream: player.playerStateStream,
      builder: (context, snapshot) {
        final playing = snapshot.data?.playing ?? false;
        return Row(
          children: [
            IconButton.filled(
              iconSize: 32,
              onPressed: () => playing ? player.pause() : player.play(),
              icon: Icon(playing ? Icons.pause : Icons.play_arrow),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: StreamBuilder<Duration>(
                stream: player.positionStream,
                builder: (context, posSnap) {
                  final total = player.duration ?? Duration.zero;
                  final pos = posSnap.data ?? Duration.zero;
                  final maxMs = total.inMilliseconds.toDouble();
                  final value =
                      pos.inMilliseconds.toDouble().clamp(0.0, maxMs);
                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Slider(
                        value: value,
                        max: maxMs == 0 ? 1.0 : maxMs,
                        onChanged: maxMs == 0
                            ? null
                            : (v) => player
                                .seek(Duration(milliseconds: v.round())),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(_fmt(pos),
                                style: Theme.of(context).textTheme.bodySmall),
                            Text(_fmt(total),
                                style: Theme.of(context).textTheme.bodySmall),
                          ],
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }
}

/// Süreyi m:ss biçiminde gösterir.
String _fmt(Duration d) {
  final m = d.inMinutes;
  final s = d.inSeconds % 60;
  return '$m:${s.toString().padLeft(2, '0')}';
}
