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
      await ref.read(searchNotifierProvider.notifier).searchTrip(
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

  String _formatDate(DateTime? d) {
    if (d == null) return '';
    return DateFormat('dd MMM yyyy', 'fr').format(d);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF8FAFC),
        title: const Text('Nouveau voyage'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _SectionLabel('Itinéraire'),
              const SizedBox(height: 8),
              TextFormField(
                controller: _originCtrl,
                decoration: const InputDecoration(
                  labelText: 'Ville de départ',
                  prefixIcon: Icon(Icons.trip_origin, color: Color(0xFF1E40AF)),
                ),
                validator: (v) => v == null || v.isEmpty ? 'Requis' : null,
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _destCtrl,
                decoration: const InputDecoration(
                  labelText: 'Destination',
                  prefixIcon: Icon(Icons.place, color: Color(0xFF059669)),
                ),
                validator: (v) => v == null || v.isEmpty ? 'Requis' : null,
              ),
              const SizedBox(height: 20),
              _SectionLabel('Dates'),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: _DateButton(
                      label: _departureDate != null
                          ? _formatDate(_departureDate)
                          : 'Départ',
                      icon: Icons.flight_takeoff,
                      hasValue: _departureDate != null,
                      onTap: () => _pickDate(isDeparture: true),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _DateButton(
                      label: _returnDate != null
                          ? _formatDate(_returnDate)
                          : 'Retour',
                      icon: Icons.flight_land,
                      hasValue: _returnDate != null,
                      onTap: () => _pickDate(isDeparture: false),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _SectionLabel('Budget'),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E40AF).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${_budgetMin.toInt()}€ – ${_budgetMax.toInt()}€',
                      style: const TextStyle(
                          color: Color(0xFF1E40AF),
                          fontWeight: FontWeight.bold,
                          fontSize: 13),
                    ),
                  ),
                ],
              ),
              RangeSlider(
                values: RangeValues(_budgetMin, _budgetMax),
                min: 0,
                max: 3000,
                divisions: 60,
                activeColor: const Color(0xFF1E40AF),
                labels: RangeLabels(
                    '${_budgetMin.toInt()}€', '${_budgetMax.toInt()}€'),
                onChanged: (v) => setState(() {
                  _budgetMin = v.start;
                  _budgetMax = v.end;
                }),
              ),
              const SizedBox(height: 12),
              _SectionLabel('Voyageurs'),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE5E7EB)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.people_outline,
                        color: Color(0xFF6B7280)),
                    const SizedBox(width: 12),
                    const Expanded(
                        child: Text('Nombre de voyageurs')),
                    IconButton(
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        icon: const Icon(Icons.remove_circle_outline,
                            color: Color(0xFF1E40AF)),
                        onPressed: () => setState(() {
                              if (_travelers > 1) _travelers--;
                            })),
                    Padding(
                      padding:
                          const EdgeInsets.symmetric(horizontal: 12),
                      child: Text('$_travelers',
                          style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold)),
                    ),
                    IconButton(
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        icon: const Icon(Icons.add_circle_outline,
                            color: Color(0xFF1E40AF)),
                        onPressed: () =>
                            setState(() => _travelers++)),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              _SectionLabel('Transport'),
              const SizedBox(height: 8),
              Row(
                children: [
                  _TransportChip(
                    value: 'train',
                    label: 'Train',
                    icon: Icons.train,
                    selected: _transport == 'train',
                    onTap: () => setState(() => _transport = 'train'),
                  ),
                  const SizedBox(width: 8),
                  _TransportChip(
                    value: 'flight',
                    label: 'Avion',
                    icon: Icons.flight,
                    selected: _transport == 'flight',
                    onTap: () => setState(() => _transport = 'flight'),
                  ),
                  const SizedBox(width: 8),
                  _TransportChip(
                    value: 'car',
                    label: 'Voiture',
                    icon: Icons.directions_car,
                    selected: _transport == 'car',
                    onTap: () => setState(() => _transport = 'car'),
                  ),
                ],
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: _loading ? null : _search,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1E40AF),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: _loading
                    ? const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white)),
                          SizedBox(width: 12),
                          Text('Génération en cours...',
                              style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600)),
                        ],
                      )
                    : const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.auto_awesome, size: 20),
                          SizedBox(width: 8),
                          Text('Générer avec l\'IA',
                              style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600)),
                        ],
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);
  @override
  Widget build(BuildContext context) => Text(text,
      style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: Color(0xFF6B7280),
          letterSpacing: 0.5));
}

class _DateButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool hasValue;
  final VoidCallback onTap;
  const _DateButton(
      {required this.label,
      required this.icon,
      required this.hasValue,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        decoration: BoxDecoration(
          color: hasValue
              ? const Color(0xFF1E40AF).withOpacity(0.06)
              : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
              color: hasValue
                  ? const Color(0xFF1E40AF)
                  : const Color(0xFFE5E7EB)),
        ),
        child: Row(
          children: [
            Icon(icon,
                size: 16,
                color: hasValue
                    ? const Color(0xFF1E40AF)
                    : const Color(0xFF9CA3AF)),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                    fontSize: 13,
                    color: hasValue
                        ? const Color(0xFF1E40AF)
                        : const Color(0xFF9CA3AF),
                    fontWeight: hasValue
                        ? FontWeight.w600
                        : FontWeight.normal),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TransportChip extends StatelessWidget {
  final String value;
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;
  const _TransportChip(
      {required this.value,
      required this.label,
      required this.icon,
      required this.selected,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: selected
                ? const Color(0xFF1E40AF)
                : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
                color: selected
                    ? const Color(0xFF1E40AF)
                    : const Color(0xFFE5E7EB)),
          ),
          child: Column(
            children: [
              Icon(icon,
                  color: selected ? Colors.white : const Color(0xFF6B7280),
                  size: 20),
              const SizedBox(height: 4),
              Text(label,
                  style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: selected
                          ? Colors.white
                          : const Color(0xFF6B7280))),
            ],
          ),
        ),
      ),
    );
  }
}
