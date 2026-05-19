import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../providers/search_provider.dart';
import '../../../trips/presentation/providers/trips_provider.dart';

class SearchScreen extends ConsumerStatefulWidget {
  final String? initialDestination;
  const SearchScreen({super.key, this.initialDestination});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final _formKey = GlobalKey<FormState>();
  final _originCtrl = TextEditingController();
  late final TextEditingController _destCtrl;
  DateTime? _departureDate;
  DateTime? _returnDate;
  double _budgetMin = 0;
  double _budgetMax = 1000;
  int _travelers = 1;
  String _transport = 'train';
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _destCtrl = TextEditingController(text: widget.initialDestination ?? '');
  }

  @override
  void dispose() {
    _originCtrl.dispose();
    _destCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate({required bool isDeparture}) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 7)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() =>
          isDeparture ? _departureDate = picked : _returnDate = picked);
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
    setState(() => _loading = true);
    try {
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
      if (mounted) {
        ref.invalidate(tripsProvider);
        context.go('/trips');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Erreur: ${e.toString()}'),
              backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final fmt = DateFormat('dd/MM/yyyy', 'fr');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Nouveau voyage'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Où souhaitez-vous aller ?',
                  style: theme.textTheme.titleLarge
                      ?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 20),
              TextFormField(
                controller: _originCtrl,
                decoration: InputDecoration(
                  labelText: 'Ville de départ',
                  prefixIcon: const Icon(Icons.flight_takeoff),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                validator: (v) =>
                    v == null || v.isEmpty ? 'Requis' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _destCtrl,
                decoration: InputDecoration(
                  labelText: 'Destination',
                  prefixIcon: const Icon(Icons.flight_land),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                validator: (v) =>
                    v == null || v.isEmpty ? 'Requis' : null,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _pickDate(isDeparture: true),
                      style: OutlinedButton.styleFrom(
                          padding:
                              const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12))),
                      icon: const Icon(Icons.calendar_today, size: 16),
                      label: Text(_departureDate != null
                          ? fmt.format(_departureDate!)
                          : 'Aller'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _pickDate(isDeparture: false),
                      style: OutlinedButton.styleFrom(
                          padding:
                              const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12))),
                      icon: const Icon(Icons.calendar_today, size: 16),
                      label: Text(_returnDate != null
                          ? fmt.format(_returnDate!)
                          : 'Retour'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Budget',
                      style: theme.textTheme.titleMedium
                          ?.copyWith(fontWeight: FontWeight.w600)),
                  Text(
                    '${_budgetMin.toInt()}€ – ${_budgetMax.toInt()}€',
                    style: TextStyle(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              RangeSlider(
                values: RangeValues(_budgetMin, _budgetMax),
                min: 0,
                max: 3000,
                divisions: 60,
                labels: RangeLabels(
                    '${_budgetMin.toInt()}€', '${_budgetMax.toInt()}€'),
                onChanged: (v) => setState(() {
                  _budgetMin = v.start;
                  _budgetMax = v.end;
                }),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                      child: Text('Voyageurs',
                          style: theme.textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.w600))),
                  IconButton(
                      icon: const Icon(Icons.remove_circle_outline),
                      onPressed: () => setState(() {
                            if (_travelers > 1) _travelers--;
                          })),
                  Container(
                    width: 36,
                    height: 36,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text('$_travelers',
                        style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.primary)),
                  ),
                  IconButton(
                      icon: const Icon(Icons.add_circle_outline),
                      onPressed: () =>
                          setState(() => _travelers++)),
                ],
              ),
              const SizedBox(height: 16),
              Text('Transport',
                  style: theme.textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              SegmentedButton<String>(
                segments: const [
                  ButtonSegment(
                      value: 'train',
                      label: Text('Train'),
                      icon: Icon(Icons.train)),
                  ButtonSegment(
                      value: 'flight',
                      label: Text('Vol'),
                      icon: Icon(Icons.flight)),
                  ButtonSegment(
                      value: 'car',
                      label: Text('Voiture'),
                      icon: Icon(Icons.directions_car)),
                ],
                selected: {_transport},
                onSelectionChanged: (s) =>
                    setState(() => _transport = s.first),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _loading ? null : _search,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  icon: _loading
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white))
                      : const Icon(Icons.auto_awesome),
                  label: Text(
                      _loading ? 'Lancement...' : 'Lancer la recherche IA',
                      style: const TextStyle(fontSize: 16)),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}
