import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers/trips_provider.dart';

class TripsScreen extends ConsumerWidget {
  const TripsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tripsAsync = ref.watch(tripsProvider);
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: CustomScrollView(
        slivers: [
          const SliverAppBar(
            title: Text('Mes voyages'),
            floating: true,
            backgroundColor: Color(0xFFF8FAFC),
            scrolledUnderElevation: 0,
          ),
          tripsAsync.when(
            loading: () => const SliverFillRemaining(
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (e, _) => SliverFillRemaining(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.wifi_off,
                        size: 48, color: Colors.grey),
                    const SizedBox(height: 12),
                    Text('Erreur: $e',
                        textAlign: TextAlign.center,
                        style:
                            const TextStyle(color: Colors.grey)),
                    const SizedBox(height: 16),
                    TextButton.icon(
                      onPressed: () => ref.invalidate(tripsProvider),
                      icon: const Icon(Icons.refresh),
                      label: const Text('Réessayer'),
                    ),
                  ],
                ),
              ),
            ),
            data: (trips) => trips.isEmpty
                ? SliverFillRemaining(
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              color: const Color(0xFF1E40AF)
                                  .withOpacity(0.08),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.luggage,
                                size: 48,
                                color: Color(0xFF1E40AF)),
                          ),
                          const SizedBox(height: 20),
                          const Text('Aucun voyage pour le moment',
                              style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF374151))),
                          const SizedBox(height: 8),
                          const Text(
                              'Planifiez votre premier voyage avec l\'IA !',
                              style: TextStyle(
                                  color: Color(0xFF6B7280),
                                  fontSize: 13)),
                          const SizedBox(height: 24),
                          ElevatedButton.icon(
                            onPressed: () => context.push('/search'),
                            icon: const Icon(Icons.auto_awesome),
                            label: const Text('Nouveau voyage'),
                            style: ElevatedButton.styleFrom(
                                minimumSize: const Size(200, 48)),
                          ),
                        ],
                      ),
                    ),
                  )
                : SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) =>
                            _TripCard(trip: trips[index]),
                        childCount: trips.length,
                      ),
                    ),
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/search'),
        backgroundColor: const Color(0xFF1E40AF),
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Nouveau',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
      ),
    );
  }
}

class _TripCard extends StatelessWidget {
  final Map<String, dynamic> trip;
  const _TripCard({required this.trip});

  static const _emojis = {
    'Paris': '🗼', 'Lyon': '🍷', 'Marseille': '⛵', 'Nice': '🌊',
    'Bordeaux': '🍇', 'Toulouse': '🏛', 'Strasbourg': '🥨',
    'Nantes': '🏰', 'Montpellier': '☀️', 'Lille': '🍺',
  };

  @override
  Widget build(BuildContext context) {
    final dest = trip['destination_city'] ?? '';
    final emoji = _emojis[dest] ?? '✈️';
    final status = trip['status'] ?? 'draft';
    final (label, color) = _statusInfo(status);
    final hasProposals = trip['ai_proposals'] != null;

    return GestureDetector(
      onTap: () => context.push('/booking/${trip['id']}'),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFE5E7EB)),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 8,
                offset: const Offset(0, 2))
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 80,
              height: 100,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    _colorForStatus(status),
                    _colorForStatus(status).withOpacity(0.7)
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: const BorderRadius.horizontal(
                    left: Radius.circular(20)),
              ),
              child: Center(
                  child: Text(emoji,
                      style: const TextStyle(fontSize: 32))),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      trip['title'] ?? '${ trip['origin_city']} → $dest',
                      style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          color: Color(0xFF111827)),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.trip_origin,
                            size: 12, color: Color(0xFF9CA3AF)),
                        const SizedBox(width: 4),
                        Text(
                          '${trip['origin_city'] ?? ''} → $dest',
                          style: const TextStyle(
                              color: Color(0xFF6B7280), fontSize: 12),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.calendar_today,
                            size: 12, color: Color(0xFF9CA3AF)),
                        const SizedBox(width: 4),
                        Text(
                          trip['departure_date'] ?? '',
                          style: const TextStyle(
                              color: Color(0xFF6B7280), fontSize: 12),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _StatusBadge(label: label, color: color),
                        if (hasProposals)
                          const Text('Voir les offres →',
                              style: TextStyle(
                                  fontSize: 11,
                                  color: Color(0xFF1E40AF),
                                  fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  (String, Color) _statusInfo(String status) => switch (status) {
        'confirmed' => ('Confirmé', const Color(0xFF059669)),
        'proposed' => ('Proposé', const Color(0xFF1E40AF)),
        'searching' => ('Recherche...', const Color(0xFFF97316)),
        'completed' => ('Terminé', const Color(0xFF6B7280)),
        'cancelled' => ('Annulé', const Color(0xFFDC2626)),
        _ => ('Brouillon', const Color(0xFF9CA3AF)),
      };

  Color _colorForStatus(String status) => switch (status) {
        'confirmed' => const Color(0xFF059669),
        'proposed' => const Color(0xFF1E40AF),
        'searching' => const Color(0xFFF97316),
        'completed' => const Color(0xFF6B7280),
        'cancelled' => const Color(0xFFDC2626),
        _ => const Color(0xFF9CA3AF),
      };
}

class _StatusBadge extends StatelessWidget {
  final String label;
  final Color color;
  const _StatusBadge({required this.label, required this.color});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(label,
          style: TextStyle(
              color: color, fontSize: 11, fontWeight: FontWeight.w600)),
    );
  }
}
