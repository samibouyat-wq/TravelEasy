import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/booking_provider.dart';

class BookingScreen extends ConsumerWidget {
  final String tripId;
  const BookingScreen({super.key, required this.tripId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tripAsync = ref.watch(tripDetailProvider(tripId));
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF8FAFC),
        title: const Text('Propositions IA'),
      ),
      body: tripAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: 12),
              Text('Erreur: $e', textAlign: TextAlign.center),
            ],
          ),
        ),
        data: (trip) {
          final proposals = _extractProposals(trip['ai_proposals']);
          return CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: _TripHeader(trip: trip),
              ),
              if (proposals == null)
                const SliverFillRemaining(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 16),
                        Text('L\'IA génère vos propositions...',
                            style: TextStyle(color: Color(0xFF6B7280))),
                        SizedBox(height: 8),
                        Text('Cela prend 5 à 10 secondes.',
                            style: TextStyle(
                                color: Color(0xFF9CA3AF), fontSize: 12)),
                      ],
                    ),
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, i) => _ProposalCard(
                        proposal: proposals[i] as Map<String, dynamic>,
                        index: i,
                        onBook: () => _confirmBooking(context, proposals[i]),
                      ),
                      childCount: proposals.length,
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  List? _extractProposals(dynamic aiProposals) {
    if (aiProposals == null) return null;
    if (aiProposals is List) return aiProposals;
    if (aiProposals is Map) {
      if (aiProposals['voyages'] is List) return aiProposals['voyages'] as List;
      if (aiProposals['proposals'] is List) return aiProposals['proposals'] as List;
      for (final v in aiProposals.values) {
        if (v is List) return v;
      }
    }
    return null;
  }

  void _confirmBooking(BuildContext context, dynamic proposal) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => _BookingConfirmSheet(proposal: proposal),
    );
  }
}

class _TripHeader extends StatelessWidget {
  final Map<String, dynamic> trip;
  const _TripHeader({required this.trip});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1E40AF), Color(0xFF059669)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            trip['title'] ?? '',
            style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.trip_origin, color: Colors.white70, size: 16),
              const SizedBox(width: 6),
              Text(trip['origin_city'] ?? '',
                  style: const TextStyle(color: Colors.white70)),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 8),
                child: Icon(Icons.arrow_forward, color: Colors.white54, size: 16),
              ),
              const Icon(Icons.place, color: Colors.white70, size: 16),
              const SizedBox(width: 6),
              Text(trip['destination_city'] ?? '',
                  style: const TextStyle(color: Colors.white70)),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _InfoChip(Icons.calendar_today, trip['departure_date'] ?? ''),
              const SizedBox(width: 8),
              _InfoChip(Icons.people, '${trip['num_travelers'] ?? 1} voyageur(s)'),
            ],
          ),
        ],
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  const _InfoChip(this.icon, this.label);
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white24,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Icon(icon, size: 12, color: Colors.white),
          const SizedBox(width: 4),
          Text(label,
              style: const TextStyle(color: Colors.white, fontSize: 12)),
        ],
      ),
    );
  }
}

class _ProposalCard extends StatelessWidget {
  final Map<String, dynamic> proposal;
  final int index;
  final VoidCallback onBook;
  const _ProposalCard(
      {required this.proposal, required this.index, required this.onBook});

  @override
  Widget build(BuildContext context) {
    final hotel = proposal['hotel'] as Map<String, dynamic>?;
    final transport = proposal['transport'] as Map<String, dynamic>?;
    final highlights = proposal['highlights'] as List? ?? [];
    final totalPrice = proposal['total_price'];
    final colors = [
      const Color(0xFF1E40AF),
      const Color(0xFF059669),
      const Color(0xFFF97316),
    ];
    final cardColor = colors[index % colors.length];

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: [
          BoxShadow(
              color: cardColor.withOpacity(0.08),
              blurRadius: 16,
              offset: const Offset(0, 4))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                      color: Colors.white24,
                      borderRadius: BorderRadius.circular(8)),
                  child: Center(
                    child: Text('${index + 1}',
                        style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    proposal['title'] ?? 'Option ${index + 1}',
                    style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 15),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (transport != null) _TransportRow(transport: transport),
                if (hotel != null) ...[const SizedBox(height: 12), _HotelRow(hotel: hotel)],
                if (highlights.isNotEmpty) ...[const SizedBox(height: 12), _HighlightsList(highlights: highlights)],
                const SizedBox(height: 16),
                const Divider(height: 1),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Prix total',
                            style: TextStyle(
                                fontSize: 12, color: Color(0xFF6B7280))),
                        Text(
                          '${totalPrice ?? '?'}€',
                          style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: cardColor),
                        ),
                      ],
                    ),
                    ElevatedButton(
                      onPressed: onBook,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: cardColor,
                        minimumSize: const Size(140, 44),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                      ),
                      child: const Text('Réserver',
                          style: TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 14)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TransportRow extends StatelessWidget {
  final Map<String, dynamic> transport;
  const _TransportRow({required this.transport});
  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
              color: const Color(0xFF1E40AF).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8)),
          child: const Icon(Icons.train, color: Color(0xFF1E40AF), size: 18),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(transport['type'] ?? 'Transport',
                  style: const TextStyle(fontWeight: FontWeight.w600)),
              if (transport['details'] != null)
                Text(transport['details'],
                    style: const TextStyle(
                        color: Color(0xFF6B7280), fontSize: 12)),
            ],
          ),
        ),
      ],
    );
  }
}

class _HotelRow extends StatelessWidget {
  final Map<String, dynamic> hotel;
  const _HotelRow({required this.hotel});
  @override
  Widget build(BuildContext context) {
    final stars = (hotel['stars'] as num?)?.toInt() ?? 0;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
              color: const Color(0xFFF97316).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8)),
          child: const Icon(Icons.hotel, color: Color(0xFFF97316), size: 18),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(hotel['name'] ?? 'Hôtel',
                  style: const TextStyle(fontWeight: FontWeight.w600)),
              Row(
                children: [
                  Row(
                    children: List.generate(
                        stars,
                        (_) => const Icon(Icons.star,
                            color: Color(0xFFF59E0B), size: 12)),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '${hotel['nights'] ?? '?'} nuits · ${hotel['price_per_night'] ?? '?'}€/nuit',
                    style: const TextStyle(
                        color: Color(0xFF6B7280), fontSize: 12),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _HighlightsList extends StatelessWidget {
  final List highlights;
  const _HighlightsList({required this.highlights});
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Points forts',
            style: TextStyle(
                fontWeight: FontWeight.w600, color: Color(0xFF374151))),
        const SizedBox(height: 8),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: highlights
              .map((h) => Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF3F4F6),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text('✓  $h',
                        style: const TextStyle(
                            fontSize: 11, color: Color(0xFF374151))),
                  ))
              .toList(),
        ),
      ],
    );
  }
}

class _BookingConfirmSheet extends StatelessWidget {
  final dynamic proposal;
  const _BookingConfirmSheet({required this.proposal});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2)),
          ),
          const SizedBox(height: 20),
          const Icon(Icons.credit_card, size: 48, color: Color(0xFF1E40AF)),
          const SizedBox(height: 12),
          const Text('Confirmer la réservation',
              style:
                  TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text(
            'Total : ${proposal['total_price'] ?? '?'}€',
            style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1E40AF)),
          ),
          const SizedBox(height: 8),
          const Text(
            'Le paiement Stripe sera disponible prochainement.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Color(0xFF6B7280), fontSize: 13),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fermer'),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}
