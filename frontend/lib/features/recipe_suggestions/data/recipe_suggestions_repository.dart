import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:keepmydiet/features/recipe_suggestions/data/recipe_suggestions_api_client.dart';
import 'package:keepmydiet/features/recipe_suggestions/domain/recipe_suggestion.dart';

final recipeSuggestionsRepositoryProvider =
    Provider<RecipeSuggestionsRepository>((ref) {
      return RecipeSuggestionsRepository(
        ref.watch(recipeSuggestionsApiClientProvider),
      );
    });

class RecipeSuggestionsRepository {
  RecipeSuggestionsRepository(this._api);

  final RecipeSuggestionsApiClient _api;

  Future<List<RecipeSuggestion>> fetchForGroup(int groupId) =>
      _api.fetchForGroup(groupId);
}
