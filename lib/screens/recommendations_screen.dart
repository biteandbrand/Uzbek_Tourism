import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../app_config.dart';
import '../l10n/app_strings.dart';
import '../models/tourist_site.dart';
import '../services/discovery_service.dart';
import '../services/location_service.dart';
import '../services/ranking.dart';
import '../widgets/empty_state.dart';
import '../widgets/error_retry.dart';

/// Bir mekan + (yakınımdakiler modunda) konuma uzaklığı.
class _RankedSite {
  final TouristSite site;
  final double? distanceMeters;
  const _RankedSite(this.site, [this.distanceMeters]);
}

/// Öneri akışı: şehre göre ya da konuma göre ("yakınımdakiler") mekan listesi.
class RecommendationsScreen extends StatefulWidget {
  const RecommendationsScreen({super.key, this.initialCity});

  /// Doğrudan bu şehir seçili açılır (ör. rota durağından gelindiğinde).
  final String? initialCity;

  @override
  State<RecommendationsScreen> createState() => _RecommendationsScreenState();
}

class _RecommendationsScreenState extends State<RecommendationsScreen> {
  final _discovery = DiscoveryService(useMock: kUseMock);
  final _location = LocationService(useMock: kUseMock);

  bool _nearMe = false;
  List<String> _cities = [];
  String? _city;
  late Future<List<_RankedSite>> _result;

  @override
  void initState() {
    super.initState();
    _result = Future.value(const []);
    _loadCities();
  }

  Future<void> _loadCities() async {
    final cities = await _discovery.cities();
    if (!mounted) return;
    final wanted = widget.initialCity;
    setState(() {
      _cities = cities;
      _city = (wanted != null && cities.contains(wanted))
          ? wanted
          : (cities.isNotEmpty ? cities.first : null);
    });
    _refresh();
  }

  void _refresh() {
    setState(() {
      _result = _nearMe ? _loadNearMe() : _loadByCity();
    });
  }

  Future<List<_RankedSite>> _loadByCity() async {
    final city = _city;
    if (city == null) return const [];
    final sites = await _discovery.sitesForCity(city);
    return sites.map((s) => _RankedSite(s)).toList();
  }

  Future<List<_RankedSite>> _loadNearMe() async {
    final me = await _location.current();
    final sites = await _discovery.allSites();
    return rankSitesByDistance(sites, me, _location)
        .map((r) => _RankedSite(r.site, r.distanceMeters))
        .toList();
  }

  /// Mekanı cihazın harita uygulamasında açar (konum sorgusuyla).
  Future<void> _openMap(TouristSite s) async {
    final uri = Uri.parse(
        'https://www.google.com/maps/search/?api=1&query=${s.lat},${s.lng}');
    final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!ok && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.stringsRead.mapOpenFailed)));
    }
  }

  void _setNearMe(Set<bool> selection) {
    final nearMe = selection.first;
    if (nearMe == _nearMe) return;
    setState(() => _nearMe = nearMe);
    _refresh();
  }

  @override
  Widget build(BuildContext context) {
    final s = context.strings;
    return Scaffold(
      appBar: AppBar(title: Text(s.recommendationsTitle)),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: SegmentedButton<bool>(
              segments: [
                ButtonSegment(
                    value: false,
                    label: Text(s.byCity),
                    icon: const Icon(Icons.location_city)),
                ButtonSegment(
                    value: true,
                    label: Text(s.nearby),
                    icon: const Icon(Icons.my_location)),
              ],
              selected: {_nearMe},
              onSelectionChanged: _setNearMe,
            ),
          ),
          if (!_nearMe)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: DropdownButtonFormField<String>(
                value: _city,
                decoration: InputDecoration(
                  labelText: s.cityLabel,
                  border: const OutlineInputBorder(),
                ),
                items: _cities
                    .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                    .toList(),
                onChanged: (c) {
                  if (c == null) return;
                  setState(() => _city = c);
                  _refresh();
                },
              ),
            ),
          Expanded(
            child: FutureBuilder<List<_RankedSite>>(
              future: _result,
              builder: (context, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snap.hasError) {
                  return ErrorRetry(
                    message: _nearMe ? s.nearbyError : s.recommendationsError,
                    onRetry: _refresh,
                  );
                }
                final items = snap.data ?? const [];
                if (items.isEmpty) {
                  return EmptyState(
                      message: s.recommendationsEmpty, icon: Icons.place);
                }
                return ListView.separated(
                  itemCount: items.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, i) {
                    final r = items[i];
                    return ListTile(
                      leading: Icon(_categoryIcon(r.site.category)),
                      title: Text(r.site.name),
                      subtitle: Text(s.category(r.site.category)),
                      trailing: r.distanceMeters == null
                          ? const Icon(Icons.map_outlined)
                          : Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(_formatDistance(r.distanceMeters!)),
                                const SizedBox(width: 8),
                                const Icon(Icons.map_outlined),
                              ],
                            ),
                      onTap: () => _openMap(r.site),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

String _formatDistance(double meters) {
  if (meters < 1000) return '${meters.round()} m';
  return '${(meters / 1000).toStringAsFixed(1)} km';
}

IconData _categoryIcon(String? category) {
  switch (category) {
    case 'mosque':
      return Icons.mosque;
    case 'mausoleum':
      return Icons.account_balance;
    case 'bazaar':
      return Icons.storefront;
    case 'madrasah':
      return Icons.school;
    case 'square':
      return Icons.location_city;
    default:
      return Icons.place;
  }
}

