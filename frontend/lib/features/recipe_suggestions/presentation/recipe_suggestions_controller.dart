import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/recipe_suggestions_api_client.dart';
import '../domain/recipe_suggestion.dart';

/// `.family` par `groupId` : les suggestions dépendent du frigo/placard de
/// CE groupe (et des profils de ses membres), pas de l'utilisateur seul.
final recipeSuggestionsProvider =
    FutureProvider.family<List<RecipeSuggestion>, int>((ref, groupId) {
      return ref
          .watch(recipeSuggestionsApiClientProvider)
          .fetchForGroup(groupId);
    });
