import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../providers/search_provider.dart';

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final _formKey = GlobalKey<FormState>();
  final _originCtrl = TextEditingController();
  final _destCtrl = TextEditingController();
  DateTime? _departureDate;
  DateTime? _returnDate;
  double _budgetMin = 0;
  double _budgetMax = 500;
  int _travelers = 1;
  String _transport = 'train';

  Future<void> _pickDate({required bool isDeparture}) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 7)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() => isDeparture ? _departureDate = picked : _returnDate = picked);
    }
  }

  Future<void> _search() async {
    if (!_formKey.currentState!.validate()) return;
    if (_departureDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Choisissez une date de départ')),
      );
      return;
    }

    final notifier = ref.read(searchNotifierProvider.notifier);
    await notifier.searchTrip(
      origin: _originCtrl.text.trim(),
      destination: _destCtrl.text.trim(),
      departureDate: _departureDate!,
      returnDate: _returnDate,
      budgetMin: _budgetMin,
      budgetMax: _budgetMax,
      numTravelers: _travelers,
      transportType: _transport,
    );

    if (mounted) context.push('/trips');
  }

  @override
  Widget build(BuildContext context) {
    final fmt = DateFormat('dd/MM/yyyy', 'fr');
    return Scaffold(
      appBar: AppBar(title: const Text('Rechercher un voyage')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller: _originCtrl,
                decoration: const InputDecoration(labelText: 'Ville de départ', prefixIcon: Icon(Icons.flight_takeoff)),
                validator: (v) => v == null || v.isEmpty ? 'Requis' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _destCtrl,
                decoration: const InputDecoration(labelText: 'Destination', prefixIcon: Icon(Icons.flight_land)),
                validator: (v) => v == null || v.isEmpty ? 'Requis' : null,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _pickDate(isDeparture: true),
                      icon: const Icon(Icons.calendar_today, size: 16),
                      label: Text(_departureDate != null ? fmt.format(_departureDate!) : 'Départ'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _pickDate(isDeparture: false),
                      icon: const Icon(Icons.calendar_today, size: 16),
                      label: Text(_returnDate != null ? fmt.format(_returnDate!) : 'Retour'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Text('Budget : ${_budgetMin.toInt()}€ – ${_budgetMax.toInt()}€',
                  style: Theme.of(context).textTheme.titleMedium),
              RangeSlider(
                values: RangeValues(_budgetMin, _budgetMax),
                min: 0,
                max: 2000,
                divisions: 40,
                labels: RangeLabels('${_budgetMin.toInt()}€', '${_budgetMax.toInt()}€'),
                onChanged: (v) => setState(() { _budgetMin = v.start; _budgetMax = v.end; }),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(child: Text('Voyageurs', style: Theme.of(context).textTheme.titleMedium)),
                  IconButton(icon: const Icon(Icons.remove_circle_outline), onPressed: () => setState(() { if (_travelers > 1) _travelers--; })),
                  Text('$_travelers', style: Theme.of(context).textTheme.titleLarge),
                  IconButton(icon: const Icon(Icons.add_circle_outline), onPressed: () => setState(() => _travelers++)),
                ],
              ),
              const SizedBox(height: 16),
              SegmentedButton<String>(
                segments: const [
                  ButtonSegment(value: 'train', label: Text('Train'), icon: Icon(Icons.train)),
                  ButtonSegment(value: 'flight', label: Text('Vol'), icon: Icon(Icons.flight)),
                  ButtonSegment(value: 'car', label: Text('Voiture'), icon: Icon(Icons.directions_car)),
                ],
                selected: {_transport},
                onSelectionChanged: (s) => setState(() => _transport = s.first),
              ),
              const SizedBox(height: 32),
              ElevatedButton.icon(
                onPressed: _search,
                icon: const Icon(Icons.auto_awesome),
                label: const Text('Lancer la recherche IA'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
