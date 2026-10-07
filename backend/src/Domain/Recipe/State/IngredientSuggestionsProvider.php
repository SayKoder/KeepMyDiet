<?php

namespace App\Domain\Recipe\State;

use ApiPlatform\Metadata\Operation;
use ApiPlatform\State\ProviderInterface;
use App\Domain\Recipe\Entity\RecipeIngredient;
use App\Domain\Recipe\Repository\RecipeIngredientRepository;

/**
 * Pas de membership/groupe à vérifier ici : les recettes (et donc leurs
 * ingrédients) forment un pool global, comme `Recipe` lui-même.
 */
final class IngredientSuggestionsProvider implements ProviderInterface
{
    public function __construct(
        private readonly RecipeIngredientRepository $ingredients,
    ) {
    }

    /**
     * @return RecipeIngredient[]
     */
    public function provide(Operation $operation, array $uriVariables = [], array $context = []): array
    {
        $query = trim((string) ($context['filters']['query'] ?? ''));
        if (mb_strlen($query) < 2) {
            return [];
        }

        return $this->ingredients->searchByName($query);
    }
}
