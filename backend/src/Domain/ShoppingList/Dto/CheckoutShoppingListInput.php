<?php

namespace App\Domain\ShoppingList\Dto;

final class CheckoutShoppingListInput
{
    /** @var CheckoutItemInput[] */
    public array $items = [];
}
