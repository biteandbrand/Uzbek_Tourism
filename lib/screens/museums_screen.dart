import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../app_config.dart';
import '../l10n/app_strings.dart';
import '../models/museum.dart';
import '../services/discovery_service.dart';
import '../state/offline_controller.dart';
import '../widgets/empty_state.dart';
import '../widgets/error_retry.dart';
import 'qr_scanner_screen.dart';

/// Çevrimdışı kullanım: müze seçilip içeriği önceden cihaza indirilir.
/// Müze içi zayıf sinyalde QR yine de açılabilsin diye.
class MuseumsScreen extends StatefulWidget {
  const MuseumsScreen({super.key});

  @override
  State<MuseumsScreen> createState() => _MuseumsScreenState();
}

class _MuseumsScreenState extends State<MuseumsScreen> {
  final _discovery = DiscoveryService(useMock: kUseMock);
  late Future<List<Museum>> _museums;
  final _searchController = TextEditingController();
  String _query = '';

  OfflineController get _offline => context.read<OfflineController>();

  @override
  void initState() {
    super.initState();
    _museums = _discovery.museums();
  }

  void _reload() => setState(() => _museums = _discovery.museums());

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _download(Museum m) async {
    final messenger = ScaffoldMessenger.of(context);
    final s = context.stringsRead;
    try {
      await _offline.download(m.id);
    } catch (e) {
      if (mounted) {
        messenger.showSnackBar(
            SnackBar(content: Text(s.downloadFailed(e))));
      }
    }
  }

  Future<void> _downloadAll() async {
    for (final m in await _museums) {
      await _download(m);
    }
  }

  Future<void> _delete(Museum m) async {
    final s = context.stringsRead;
    final offline = _offline; // context.read'i await'ten önce al
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(s.deleteDialogTitle),
        content: Text(s.deleteDialogBody(m.name)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(s.cancel)),
          FilledButton(
              onPressed: () => Navigator.pop(ctx, true), child: Text(s.delete)),
        ],
      ),
    );
    if (ok == true) await offline.remove(m.id);
  }

  void _onTapMuseum(Museum m) {
    if (_offline.isDownloaded(m.id)) {
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => QrScannerScreen(museumId: m.id)),
      );
    } else if (!_offline.isDownloading(m.id)) {
      final s = context.stringsRead;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(s.downloadFirst(m.name)),
          action:
              SnackBarAction(label: s.download, onPressed: () => _download(m)),
        ),
      );
    }
  }

  Widget _trailing(Museum m, OfflineController offline) {
    if (offline.isDownloading(m.id)) {
      final p = offline.progressOf(m.id);
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(
                strokeWidth: 2, value: (p == null || p == 0) ? null : p),
          ),
          if (p != null && p > 0)
            Padding(
              padding: const EdgeInsets.only(left: 8),
              child: Text('${(p * 100).round()}%'),
            ),
        ],
      );
    }
    if (offline.isDownloaded(m.id)) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.offline_pin, color: Colors.green),
          IconButton(
            icon: const Icon(Icons.delete_outline),
            tooltip: context.stringsRead.deleteOfflineTooltip,
            onPressed: () => _delete(m),
          ),
        ],
      );
    }
    return IconButton(
      icon: const Icon(Icons.download_for_offline_outlined),
      tooltip: context.stringsRead.downloadTooltip,
      onPressed: () => _download(m),
    );
  }

  /// Aramayı uygular ve şehre göre gruplar (şehir → müzeler), şehirler sıralı.
  Map<String, List<Museum>> _grouped(List<Museum> all) {
    final q = _query.trim().toLowerCase();
    final filtered = q.isEmpty
        ? all
        : all
            .where((m) =>
                m.name.toLowerCase().contains(q) ||
                m.city.toLowerCase().contains(q))
            .toList();
    final map = <String, List<Museum>>{};
    for (final m in filtered) {
      (map[m.city] ??= []).add(m);
    }
    return {
      for (final city in map.keys.toList()..sort()) city: map[city]!,
    };
  }

  @override
  Widget build(BuildContext context) {
    final offline = context.watch<OfflineController>();
    final s = context.strings;
    return Scaffold(
      appBar: AppBar(
        title: Text(s.museumsTitle),
        actions: [
          IconButton(
            icon: const Icon(Icons.download),
            tooltip: s.downloadAllTooltip,
            onPressed: _downloadAll,
          ),
          if (offline.count > 0)
            IconButton(
              icon: const Icon(Icons.delete_sweep_outlined),
              tooltip: s.deleteAllTooltip,
              onPressed: () => _offline.clearAll(),
            ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.search),
                hintText: s.searchHint,
                border: const OutlineInputBorder(),
                isDense: true,
                suffixIcon: _query.isEmpty
                    ? null
                    : IconButton(
                        icon: const Icon(Icons.clear),
                        tooltip: s.clearTooltip,
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _query = '');
                        },
                      ),
              ),
              onChanged: (v) => setState(() => _query = v),
            ),
          ),
          Expanded(
            child: FutureBuilder<List<Museum>>(
              future: _museums,
              builder: (context, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snap.hasError) {
                  return ErrorRetry(message: s.museumsError, onRetry: _reload);
                }
                final groups = _grouped(snap.data ?? const []);
                if (groups.isEmpty) {
                  return EmptyState(
                      message: s.museumsEmpty, icon: Icons.museum);
                }
                final total =
                    groups.values.fold<int>(0, (a, b) => a + b.length);
                return ListView(
                  children: [
                    if (_query.trim().isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                        child: Text(s.resultsCount(total),
                            style: Theme.of(context).textTheme.bodySmall),
                      ),
                    for (final entry in groups.entries) ...[
                      _CityHeader(city: entry.key),
                      for (final m in entry.value)
                        ListTile(
                          leading: const Icon(Icons.museum),
                          title: Text(m.name),
                          subtitle: offline.isDownloaded(m.id)
                              ? Text(s.tapToScan)
                              : null,
                          trailing: _trailing(m, offline),
                          onTap: () => _onTapMuseum(m),
                        ),
                    ],
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _CityHeader extends StatelessWidget {
  const _CityHeader({required this.city});

  final String city;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      child: Text(
        city,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.bold,
            ),
      ),
    );
  }
}
