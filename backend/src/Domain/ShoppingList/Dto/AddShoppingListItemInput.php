<?php

namespace App\Domain\ShoppingList\Dto;

/**
 * Entrée de `POST /groups/{groupId}/shopping_lists/items`. Macros pour 100g
 * (même convention que `ShoppingListItem`), à 0 si l'aliment n'en fournit pas.
 */
final class AddShoppingListItemInput
{
    public string $name = '';

    public float $quantity = 0;

    public string $unit = '';

    public float $caloriesPer100g = 0;

    public float $proteinsPer100g = 0;

    public float $carbsPer100g = 0;

    public float $fatsPer100g = 0;
}
