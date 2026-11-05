import 'package:flutter/material.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:keepmydiet/features/fridge/data/fridge_repository.dart';
import 'package:keepmydiet/features/fridge/domain/food_draft.dart';
import 'package:keepmydiet/features/fridge/domain/food_reference.dart';
import 'package:keepmydiet/features/groups/data/groups_repository.dart';
import 'package:keepmydiet/features/groups/domain/group.dart';
import 'package:keepmydiet/features/groups/domain/group_member.dart';
import 'package:keepmydiet/features/groups/presentation/group_detail_screen.dart';
import 'package:keepmydiet/features/groups/presentation/groups_controller.dart';
import 'package:keepmydiet/features/recipes/data/recipes_repository.dart';
import 'package:keepmydiet/features/recipes/domain/recipe.dart';
import 'package:keepmydiet/features/recipes/domain/recipe_draft.dart';
import 'package:keepmydiet/features/recipes/domain/recipe_ingredient.dart';
import 'package:keepmydiet/features/recipes/domain/recipe_step.dart';
import 'package:keepmydiet/features/recipes/presentation/recipe_detail_screen.dart';
import 'package:keepmydiet/features/recipes/presentation/recipe_form_screen.dart';
import 'package:keepmydiet/features/shopping_list/presentation/add_shopping_item_screen.dart';

import 'support/harness.dart';

final _edit = find.byIcon(Icons.edit_outlined);

Group _group({bool canEdit = true, String name = 'Famille'}) =>
    Group(id: 1, name: name, createdAt: DateTime(2026), canEdit: canEdit);

class _TestGroupsController extends GroupsController {
  _TestGroupsController(this.initial);

  final List<Group> initial;

  @override
  Future<List<Group>> build() async => initial;
}

class _FakeGroupsRepository extends Fake implements GroupsRepository {
  final renames = <String>[];

  @override
  Future<List<GroupMember>> fetchMembers(int groupId) async => const [];

  @override
  Future<Group> updateGroup(int groupId, {required String name}) async {
    renames.add(name);
    return _group(name: name);
  }
}

Recipe _recipe({bool canEdit = true}) => Recipe(
  id: 7,
  name: 'Gratin',
  referenceServings: 2,
  ingredients: const [
    RecipeIngredient(
      name: 'Pomme de terre',
      quantity: 500,
      unit: 'g',
      calories: 385,
      proteins: 10,
      carbs: 85,
      fats: 1,
    ),
    RecipeIngredient(
      name: 'Creme',
      quantity: 20,
      unit: 'cL',
      calories: 600,
      proteins: 4,
      carbs: 5,
      fats: 60,
    ),
  ],
  steps: const [RecipeStep(instruction: 'Eplucher', durationMinutes: 10)],
  totalCalories: 985,
  totalProteins: 14,
  totalCarbs: 90,
  totalFats: 61,
  canEdit: canEdit,
);

class _FakeRecipesRepository extends Fake implements RecipesRepository {
  _FakeRecipesRepository(this.recipe);

  final Recipe recipe;
  RecipeDraft? sent;

  @override
  Future<List<Recipe>> fetchAll() async => [recipe];

  @override
  Future<Recipe> update(int id, RecipeDraft draft) async {
    sent = draft;
    return _recipe();
  }
}

class _FakeFridgeRepository extends Fake implements FridgeRepository {
  var catalog = const [
    FoodReference(
      id: 1,
      name: 'Granola',
      caloriesPer100g: 450,
      proteinsPer100g: 9,
      carbsPer100g: 60,
      fatsPer100g: 18,
      canEdit: true,
    ),
    FoodReference(
      id: 2,
      name: 'Pomme',
      caloriesPer100g: 52,
      proteinsPer100g: 0,
      carbsPer100g: 14,
      fatsPer100g: 0,
    ),
  ];
  (int, FoodDraft)? sent;

  @override
  Future<List<FoodReference>> fetchCatalog(int groupId) async => catalog;

  @override
  Future<FoodReference> updateCustomFood(int foodId, FoodDraft draft) async {
    sent = (foodId, draft);
    final updated = FoodReference(
      id: foodId,
      name: draft.name,
      caloriesPer100g: draft.caloriesPer100g,
      proteinsPer100g: draft.proteinsPer100g,
      carbsPer100g: draft.carbsPer100g,
      fatsPer100g: draft.fatsPer100g,
      canEdit: true,
    );
    catalog = [for (final f in catalog) f.id == foodId ? updated : f];
    return updated;
  }
}

void main() {
  group('canEdit dans les modèles', () {
    test('absent du JSON : faux ; présent : lu et conservé dans le cache', () {
      final group = {
        'id': 1,
        'name': 'G',
        'createdAt': '2026-01-01T00:00:00+00:00',
      };
      expect(Group.fromJson(group).canEdit, isFalse);
      expect(Group.fromJson({...group, 'canEdit': true}).canEdit, isTrue);
      expect(
        Group.fromJson(Group.fromJson({...group, 'canEdit': true}).toJson())
            .canEdit,
        isTrue,
      );

      final food = {
        'id': 1,
        'name': 'F',
        'caloriesPer100g': 1,
        'proteinsPer100g': 1,
        'carbsPer100g': 1,
        'fatsPer100g': 1,
      };
      expect(FoodReference.fromJson(food).canEdit, isFalse);
      expect(
        FoodReference.fromJson({...food, 'canEdit': true}).canEdit,
        isTrue,
      );
    });
  });

  group('Renommer un groupe', () {
    List<Override> overrides(
      _FakeGroupsRepository repo, {
      bool canEdit = true,
    }) => [
      groupsControllerProvider.overrideWith(
        () => _TestGroupsController([_group(canEdit: canEdit)]),
      ),
      groupsRepositoryProvider.overrideWithValue(repo),
    ];

    testWidgets('pas de bouton Modifier pour un simple membre', (tester) async {
      await pumpScreen(
        tester,
        GroupDetailScreen(group: _group(canEdit: false)),
        overrides: overrides(_FakeGroupsRepository(), canEdit: false),
      );

      expect(_edit, findsNothing);
      await disposeScreen(tester);
    });

    testWidgets('l\'admin renomme : formulaire pré-rempli, titre mis à jour', (
      tester,
    ) async {
      final repo = _FakeGroupsRepository();
      await pumpScreen(
        tester,
        GroupDetailScreen(group: _group()),
        overrides: overrides(repo),
      );

      await tester.tap(_edit);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.widgetWithText(TextField, 'Famille'), findsOneWidget);

      await tester.enterText(find.byType(TextField), 'Les Dupont');
      await tester.tap(find.text('Enregistrer'));
      await tester.pumpAndSettle();

      expect(repo.renames, ['Les Dupont']);
      expect(find.text('Les Dupont'), findsOneWidget);
      expect(find.text('Famille'), findsNothing);
      await disposeScreen(tester);
    });
  });

  group('Modifier une recette', () {
    testWidgets('détail : Modifier et Supprimer réservés au créateur', (
      tester,
    ) async {
      for (final canEdit in [false, true]) {
        await pumpScreen(
          tester,
          RecipeDetailScreen(recipe: _recipe(canEdit: canEdit)),
          overrides: [
            recipesRepositoryProvider.overrideWithValue(
              _FakeRecipesRepository(_recipe(canEdit: canEdit)),
            ),
          ],
        );

        expect(_edit, canEdit ? findsOneWidget : findsNothing);
        expect(
          find.byIcon(Icons.delete_outline),
          canEdit ? findsOneWidget : findsNothing,
        );
        await disposeScreen(tester);
      }
    });

    testWidgets('formulaire pré-rempli, envoie tout et remplace', (
      tester,
    ) async {
      final repo = _FakeRecipesRepository(_recipe());
      await pumpScreen(
        tester,
        RecipeFormScreen(recipe: _recipe()),
        overrides: [recipesRepositoryProvider.overrideWithValue(repo)],
      );

      expect(find.text('Modifier la recette'), findsOneWidget);
      expect(find.text('Pomme de terre'), findsOneWidget);
      expect(find.text('Creme'), findsOneWidget);

      await tester.enterText(
        find.widgetWithText(TextField, 'Gratin'),
        'Gratin light',
      );
      final save = find.widgetWithText(FilledButton, 'Enregistrer');
      await tester.dragUntilVisible(
        save,
        find.byType(ListView),
        const Offset(0, -200),
      );
      await tester.pumpAndSettle();
      await tester.tap(save);
      await tester.pumpAndSettle();

      final sent = repo.sent!;
      expect(sent.name, 'Gratin light');
      expect(sent.referenceServings, 2);
      expect(sent.ingredients.map((i) => i.name), ['Pomme de terre', 'Creme']);
      expect(sent.steps.single.instruction, 'Eplucher');
      expect(sent.steps.single.durationMinutes, 10);
      await disposeScreen(tester);
    });

    testWidgets('création : formulaire vide, comme avant', (tester) async {
      await pumpScreen(
        tester,
        const RecipeFormScreen(),
        overrides: [
          recipesRepositoryProvider.overrideWithValue(
            _FakeRecipesRepository(_recipe()),
          ),
        ],
      );

      expect(find.text('Nouvelle recette'), findsOneWidget);
      expect(find.text('Créer la recette'), findsOneWidget);
      expect(find.text('Gratin'), findsNothing);
      await disposeScreen(tester);
    });
  });

  group('Modifier un aliment', () {
    testWidgets(
      'crayon seulement sur ses aliments, et la liste se met à jour',
      (tester) async {
        final repo = _FakeFridgeRepository();
        await pumpScreen(
          tester,
          const AddShoppingItemScreen(groupId: 1),
          overrides: [fridgeRepositoryProvider.overrideWithValue(repo)],
        );

        expect(_edit, findsOneWidget);

        await tester.tap(_edit);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 400));
        expect(find.text('Modifier le produit'), findsOneWidget);
        expect(find.widgetWithText(TextField, 'Granola'), findsOneWidget);

        await tester.enterText(
          find.widgetWithText(TextField, 'Granola'),
          'Granola miel',
        );
        await tester.tap(find.text('Enregistrer'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 400));

        final (id, draft) = repo.sent!;
        expect(id, 1);
        expect(draft.name, 'Granola miel');
        expect(draft.caloriesPer100g, 450);
        expect(draft.barcode, isNull);
        expect(find.text('Granola miel'), findsOneWidget);
        await disposeScreen(tester);
      },
    );
  });
}
