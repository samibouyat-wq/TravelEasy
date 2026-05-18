import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_client.dart';

final tripDetailProvider = FutureProvider.family<Map<String, dynamic>, String>((ref, tripId) async {
  final dio = ref.read(dioProvider);
  final response = await dio.get('/trips/$tripId');
  return Map<String, dynamic>.from(response.data as Map);
});
