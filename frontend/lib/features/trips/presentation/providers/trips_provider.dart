import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_client.dart';

Future<List<Map<String, dynamic>>> _fetchTrips(Ref ref) async {
  final dio = ref.read(dioProvider);
  final response = await dio.get('/trips/');
  return List<Map<String, dynamic>>.from(response.data as List);
}

final tripsProvider = FutureProvider<List<Map<String, dynamic>>>((ref) {
  return _fetchTrips(ref);
});

final tripsProviderFamily =
    FutureProvider<List<Map<String, dynamic>>>((ref) {
  return _fetchTrips(ref);
});
