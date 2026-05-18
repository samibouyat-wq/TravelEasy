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
      appBar: AppBar(title: const Text('Détails du voyage')),
      body: tripAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Erreur: $e')),
        data: (trip) => SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(trip['title'] ?? '', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text('${trip['origin_city']} → ${trip['destination_city']}'),
              const SizedBox(height: 24),
              if (trip['ai_proposals'] != null) ..._buildProposals(context, trip['ai_proposals'], ref, tripId)
              else const Center(child: Column(
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 12),
                  Text('Le moteur IA analyse les offres...'),
                ],
              )),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _buildProposals(BuildContext context, dynamic proposals, WidgetRef ref, String tripId) {
    final list = proposals is List ? proposals : (proposals['proposals'] as List? ?? []);
    return [
      Text('Propositions IA', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
      const SizedBox(height: 16),
      ...list.map((p) => Card(
        margin: const EdgeInsets.only(bottom: 12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(p['title'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 8),
              Text('Transport : ${p['transport'] ?? 'N/A'}'),
              Text('Hôtel : ${p['hotel'] ?? 'N/A'}'),
              Text('Prix total : ${p['total_price'] ?? '?'}€', style: const TextStyle(color: Color(0xFF2563EB), fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: () => _confirmBooking(context, ref, tripId, p),
                child: const Text('Réserver cette option'),
              ),
            ],
          ),
        ),
      )).toList(),
    ];
  }

  Future<void> _confirmBooking(BuildContext context, WidgetRef ref, String tripId, dynamic proposal) async {
    // TODO: implémenter le paiement Stripe
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Réservation en cours...')),
    );
  }
}
