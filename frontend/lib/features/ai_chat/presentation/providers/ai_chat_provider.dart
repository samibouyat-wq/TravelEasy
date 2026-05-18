import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_client.dart';

class AiChatNotifier extends StateNotifier<List<Map<String, String>>> {
  final Ref _ref;
  AiChatNotifier(this._ref) : super([]);

  Future<void> sendMessage(String text) async {
    state = [...state, {'role': 'user', 'content': text}];
    try {
      final dio = _ref.read(dioProvider);
      final response = await dio.post('/ai/chat', data: {
        'messages': state.map((m) => {'role': m['role'], 'content': m['content']}).toList(),
      });
      final reply = response.data['reply'] as String;
      state = [...state, {'role': 'assistant', 'content': reply}];
    } catch (e) {
      state = [...state, {'role': 'assistant', 'content': 'Désolé, une erreur est survenue. Réessayez.'}];
    }
  }
}

final aiChatNotifierProvider =
    StateNotifierProvider<AiChatNotifier, List<Map<String, String>>>(
  (ref) => AiChatNotifier(ref),
);
