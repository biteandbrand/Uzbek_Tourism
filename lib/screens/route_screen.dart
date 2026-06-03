import 'package:flutter/material.dart';
import '../app_config.dart';
import '../models/route_plan.dart';
import '../l10n/app_strings.dart';
import '../services/discovery_service.dart';
import '../widgets/empty_state.dart';
import '../widgets/error_retry.dart';
import 'recommendations_screen.dart';

/// Rota akışı: hazır gezi planlarını ve duraklarını listeler.
class RouteScreen extends StatefulWidget {
  const RouteScreen({super.key});

  @override
  State<RouteScreen> createState() => _RouteScreenState();
}

class _RouteScreenState extends State<RouteScreen> {
  final _service = DiscoveryService(useMock: kUseMock);
  late Future<List<RoutePlan>> _routes;

  @override
  void initState() {
    super.initState();
    _routes = _service.routes();
  }

  void _reload() => setState(() => _routes = _service.routes());

  @override
  Widget build(BuildContext context) {
    final s = context.strings;
    return Scaffold(
      appBar: AppBar(title: Text(s.routesTitle)),
      body: FutureBuilder<List<RoutePlan>>(
        future: _routes,
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) {
            return ErrorRetry(message: s.routesError, onRetry: _reload);
          }
          final routes = snap.data ?? const [];
          if (routes.isEmpty) {
            return EmptyState(message: s.routesEmpty, icon: Icons.route);
          }
          return ListView(
            padding: const EdgeInsets.all(12),
            children: routes.map((r) => _RouteCard(plan: r)).toList(),
          );
        },
      ),
    );
  }
}

class _RouteCard extends StatelessWidget {
  const _RouteCard({required this.plan});

  final RoutePlan plan;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: ExpansionTile(
        title: Text(plan.name, style: text.titleMedium),
        subtitle: Text(plan.summary),
        childrenPadding: const EdgeInsets.only(bottom: 8),
        children: [
          for (var i = 0; i < plan.stops.length; i++)
            _StopTile(stop: plan.stops[i], index: i + 1),
        ],
      ),
    );
  }
}

class _StopTile extends StatelessWidget {
  const _StopTile({required this.stop, required this.index});

  final RouteStop stop;
  final int index;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: CircleAvatar(child: Text('$index')),
      title: Text(stop.title),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('${stop.city}'
              '${stop.durationLabel != null ? ' · ${stop.durationLabel}' : ''}'),
          const SizedBox(height: 2),
          Text(stop.description),
          const SizedBox(height: 4),
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: TextButton.icon(
              style: TextButton.styleFrom(
                padding: EdgeInsets.zero,
                minimumSize: const Size(0, 32),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              icon: const Icon(Icons.recommend, size: 18),
              label: Text(context.strings.cityRecommendations(stop.city)),
              onPressed: () => Navigator.of(context).push(MaterialPageRoute(
                builder: (_) =>
                    RecommendationsScreen(initialCity: stop.city),
              )),
            ),
          ),
        ],
      ),
      isThreeLine: true,
    );
  }
}
