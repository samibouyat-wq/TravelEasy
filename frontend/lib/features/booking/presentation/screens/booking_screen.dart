import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/network/api_client.dart';
import '../providers/booking_provider.dart';

class BookingScreen extends ConsumerStatefulWidget {
  final String tripId;
  const BookingScreen({super.key, required this.tripId});

  @override
  ConsumerState<BookingScreen> createState() => _BookingScreenState();
}

class _BookingScreenState extends ConsumerState<BookingScreen> {
  Timer? _timer;
  int _attempts = 0;

  @override
  void initState() {
    super.initState();
    _startPolling();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startPolling() {
    _timer = Timer.periodic(const Duration(seconds: 3), (_) {
      final trip = ref.read(tripDetailProvider(widget.tripId)).valueOrNull;
      if (_extractProposals(trip?['ai_proposals']) != null) {
        _timer?.cancel();
        return;
      }
      _attempts++;
      if (_attempts > 20) {
        _timer?.cancel();
        return;
      }
      ref.invalidate(tripDetailProvider(widget.tripId));
    });
  }

  List? _extractProposals(dynamic ai) {
    if (ai == null) return null;
    if (ai is List) return ai;
    if (ai is Map) {
      if (ai['voyages'] is List) return ai['voyages'] as List;
      if (ai['proposals'] is List) return ai['proposals'] as List;
      for (final v in ai.values) {
        if (v is List) return v;
      }
    }
    return null;
  }

  Future<void> _pay(
      BuildContext context, Map<String, dynamic> trip, dynamic proposal) async {
    final amount = (proposal['total_price'] as num?)?.toDouble() ?? 0;
    final title = proposal['title'] ?? trip['title'] ?? 'Voyage TravelEasy';

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final dio = ref.read(dioProvider);
      final response =
          await dio.post('/payments/create-checkout-session', data: {
        'trip_id': widget.tripId,
        'trip_title': title,
        'amount': amount,
        'currency': 'eur',
      });
      final url = response.data['checkout_url'] as String;
      if (context.mounted) Navigator.pop(context);
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    } catch (e) {
      if (context.mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Erreur paiement: $e'),
              backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final tripAsync = ref.watch(tripDetailProvider(widget.tripId));
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
              SliverToBoxAdapter(child: _TripHeader(trip: trip)),
              if (proposals == null)
                const SliverFillRemaining(
                  child: _LoadingProposals(),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, i) => _ProposalCard(
                        proposal: proposals[i] as Map<String, dynamic>,
                        index: i,
                        onBook: () => _pay(
                            context, trip, proposals[i]),
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
}

class _LoadingProposals extends StatelessWidget {
  const _LoadingProposals();
  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 56,
            height: 56,
            child: CircularProgressIndicator(strokeWidth: 3),
          ),
          SizedBox(height: 20),
          Text(
            'L\'IA génère vos propositions...',
            style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: Color(0xFF374151)),
          ),
          SizedBox(height: 8),
          Text(
            'Cela prend 5 à 10 secondes.',
            style: TextStyle(color: Color(0xFF9CA3AF), fontSize: 12),
          ),
        ],
      ),
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
                fontSize: 18,
                fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.trip_origin, color: Colors.white70, size: 14),
              const SizedBox(width: 6),
              Text(trip['origin_city'] ?? '',
                  style: const TextStyle(
                      color: Colors.white70, fontSize: 13)),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 8),
                child: Icon(Icons.arrow_forward,
                    color: Colors.white54, size: 14),
              ),
              const Icon(Icons.place, color: Colors.white70, size: 14),
              const SizedBox(width: 6),
              Text(trip['destination_city'] ?? '',
                  style: const TextStyle(
                      color: Colors.white70, fontSize: 13)),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            children: [
              _InfoChip(
                  Icons.calendar_today, trip['departure_date'] ?? ''),
              _InfoChip(Icons.people,
                  '${trip['num_travelers'] ?? 1} voyageur(s)'),
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
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: Colors.white),
          const SizedBox(width: 4),
          Text(label,
              style:
                  const TextStyle(color: Colors.white, fontSize: 11)),
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

  static const _colors = [
    Color(0xFF1E40AF),
    Color(0xFF059669),
    Color(0xFFF97316),
  ];

  @override
  Widget build(BuildContext context) {
    final hotel = proposal['hotel'] as Map<String, dynamic>?;
    final transport = proposal['transport'] as Map<String, dynamic>?;
    final highlights = proposal['highlights'] as List? ?? [];
    final totalPrice = proposal['total_price'];
    final cardColor = _colors[index % _colors.length];

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
              color: cardColor.withOpacity(0.1),
              blurRadius: 16,
              offset: const Offset(0, 4))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // En-tête colorée
          Container(
            padding: const EdgeInsets.symmetric(
                horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(20)),
            ),
            child: Row(
              children: [
                Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                      color: Colors.white24,
                      borderRadius: BorderRadius.circular(8)),
                  child: Center(
                      child: Text('${index + 1}',
                          style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold))),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    proposal['title'] ?? 'Option ${index + 1}',
                    style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14),
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
                if (transport != null)
                  _DetailRow(
                    icon: Icons.train,
                    color: const Color(0xFF1E40AF),
                    title: transport['type'] ?? 'Transport',
                    subtitle: transport['details'],
                  ),
                if (hotel != null) ...[const SizedBox(height: 10), _HotelRow(hotel: hotel)],
                if (highlights.isNotEmpty) ...[const SizedBox(height: 12), _HighlightsList(highlights: highlights)],
                const SizedBox(height: 16),
                const Divider(height: 1),
                const SizedBox(height: 14),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Prix total',
                            style: TextStyle(
                                fontSize: 11,
                                color: Color(0xFF9CA3AF))),
                        Text('${totalPrice ?? '?'}€',
                            style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: cardColor)),
                      ],
                    ),
                    ElevatedButton.icon(
                      onPressed: onBook,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: cardColor,
                        minimumSize: const Size(130, 44),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                      ),
                      icon: const Icon(Icons.credit_card,
                          size: 16, color: Colors.white),
                      label: const Text('Payer',
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              color: Colors.white)),
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

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String? subtitle;
  const _DetailRow(
      {required this.icon,
      required this.color,
      required this.title,
      this.subtitle});
  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(7),
          decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8)),
          child: Icon(icon, color: color, size: 16),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  style: const TextStyle(
                      fontWeight: FontWeight.w600, fontSize: 13)),
              if (subtitle != null)
                Text(subtitle!,
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
          padding: const EdgeInsets.all(7),
          decoration: BoxDecoration(
              color: const Color(0xFFF97316).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8)),
          child: const Icon(Icons.hotel,
              color: Color(0xFFF97316), size: 16),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(hotel['name'] ?? 'Hôtel',
                  style: const TextStyle(
                      fontWeight: FontWeight.w600, fontSize: 13)),
              Row(
                children: [
                  ...List.generate(
                      stars,
                      (_) => const Icon(Icons.star,
                          color: Color(0xFFF59E0B), size: 11)),
                  const SizedBox(width: 4),
                  Text(
                      '${hotel['nights'] ?? '?'} nuits · ${hotel['price_per_night'] ?? '?'}€/nuit',
                      style: const TextStyle(
                          color: Color(0xFF6B7280), fontSize: 11)),
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
                fontWeight: FontWeight.w600,
                fontSize: 12,
                color: Color(0xFF374151))),
        const SizedBox(height: 6),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: highlights
              .map((h) => Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF3F4F6),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text('✓ $h',
                        style: const TextStyle(
                            fontSize: 11,
                            color: Color(0xFF374151))),
                  ))
              .toList(),
        ),
      ],
    );
  }
}
