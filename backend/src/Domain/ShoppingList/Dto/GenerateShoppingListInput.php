<?php

namespace App\Domain\ShoppingList\Dto;

/**
 * Entrée de `POST /groups/{groupId}/shopping_lists/generate`. `recipes` est
 * une liste d'IRIs (`/api/recipes/3`), résolues manuellement dans le
 * processor via `IriConverterInterface` plutôt que de typer la propriété en
 * `Recipe[]` et compter sur le dénormalizer d'API Platform pour le faire
 * tout seul — plus explicite à déboguer, voir JOURNAL.md.
 */
final class GenerateShoppingListInput
{
    /** @var string[] */
    public array $recipes = [];
}
