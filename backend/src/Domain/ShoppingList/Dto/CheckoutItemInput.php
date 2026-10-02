<?php

namespace App\Domain\ShoppingList\Dto;

/**
 * Une ligne achetée à convertir en FoodReference + FridgeItem. `itemId`
 * référence `ShoppingListItem.id` directement (pas une IRI : ShoppingListItem
 * n'est pas une ApiResource, même principe que RecipeIngredient).
 */
final class CheckoutItemInput
{
    public ?int $itemId = null;

    /** 'fridge' ou 'pantry' (voir StorageLocation). */
    public ?string $storageLocation = null;

    /** Format YYYY-MM-DD. */
    public ?string $expirationDate = null;
}
