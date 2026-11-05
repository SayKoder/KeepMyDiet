import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:keepmydiet/features/recipe_suggestions/data/recipe_suggestions_api_client.dart';
import 'package:keepmydiet/features/recipe_suggestions/domain/recipe_suggestion.dart';
import 'package:keepmydiet/shared/local_database.dart';
import 'package:keepmydiet/shared/network_first.dart';

final recipeSuggestionsRepositoryProvider =
    Provider<RecipeSuggestionsRepository>((ref) {
      return RecipeSuggestionsRepository(
        ref.watch(recipeSuggestionsApiClientProvider),
        ref.watch(localDatabaseProvider),
      );
    });

class RecipeSuggestionsRepository {
  RecipeSuggestionsRepository(this._api, this._database);

  final RecipeSuggestionsApiClient _api;
  final LocalDatabase _database;

  Future<List<RecipeSuggestion>> fetchForGroup(int groupId) => networkFirst(
    _database,
    key: 'recipe_suggestions_$groupId',
    fetch: () => _api.fetchForGroup(groupId),
    toJson: (suggestions) => [
      for (final suggestion in suggestions) suggestion.toJson(),
    ],
    fromJson: (json) => [
      for (final suggestion in json as List)
        RecipeSuggestion.fromJson(suggestion as Map<String, dynamic>),
    ],
  );
}
