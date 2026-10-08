<?php

namespace App\Domain\ShoppingList\Dto;

/** Entrée de `POST /groups/{groupId}/shopping_lists/generate_from_plan`. Format YYYY-MM-DD. */
final class GenerateFromMealPlanInput
{
    public ?string $from = null;
    public ?string $to = null;
}
