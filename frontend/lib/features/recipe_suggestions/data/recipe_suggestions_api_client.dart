import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/api_client.dart';
import '../domain/recipe_suggestion.dart';

final recipeSuggestionsApiClientProvider = Provider<RecipeSuggestionsApiClient>(
  (ref) {
    return RecipeSuggestionsApiClient(ref.watch(dioProvider));
  },
);

class RecipeSuggestionsApiClient {
  RecipeSuggestionsApiClient(this._dio);

  final Dio _dio;

  /// Déjà triées par le backend (couverture, puis urgence DLC, puis
  /// proximité calorique) — pas de tri supplémentaire côté client.
  Future<List<RecipeSuggestion>> fetchForGroup(int groupId) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/groups/$groupId/recipe_suggestions',
    );
    final members = response.data!['member'] as List<dynamic>;

    return members
        .map((e) => RecipeSuggestion.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
