import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_client.dart';

class SearchState {
  final bool isLoading;
  final String? error;
  const SearchState({this.isLoading = false, this.error});
}

class SearchNotifier extends StateNotifier<SearchState> {
  final Ref _ref;
  SearchNotifier(this._ref) : super(const SearchState());

  Future<void> searchTrip({
    required String origin,
    required String destination,
    required DateTime departureDate,
    DateTime? returnDate,
    required double budgetMin,
    required double budgetMax,
    required int numTravelers,
    required String transportType,
  }) async {
    state = const SearchState(isLoading: true);
    try {
      final dio = _ref.read(dioProvider);
      await dio.post('/trips/', data: {
        'title': '$origin → $destination',
        'origin_city': origin,
        'destination_city': destination,
        'departure_date': departureDate.toIso8601String().split('T').first,
        'return_date': returnDate?.toIso8601String().split('T').first,
        'num_travelers': numTravelers,
        'budget_min': budgetMin,
        'budget_max': budgetMax,
        'transport_type': transportType,
      });
      state = const SearchState();
    } catch (e) {
      state = SearchState(error: e.toString());
      rethrow;
    }
  }
}

final searchNotifierProvider = StateNotifierProvider<SearchNotifier, SearchState>(
  (ref) => SearchNotifier(ref),
);
