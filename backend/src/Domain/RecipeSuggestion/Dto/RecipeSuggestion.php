<?php

namespace App\Domain\RecipeSuggestion\Dto;

use ApiPlatform\Metadata\ApiResource;
use ApiPlatform\Metadata\GetCollection;
use ApiPlatform\Metadata\Link;
use App\Domain\Group\Entity\Group;
use App\Domain\RecipeSuggestion\State\RecipeSuggestionsProvider;
use Symfony\Component\Serializer\Annotation\Groups;

/**
 * Pas une entité Doctrine : calculée à la volée par RecipeSuggestionsProvider
 * à partir du pool de recettes + du frigo/placard du groupe, jamais stockée
 * (une suggestion n'a de sens qu'à l'instant où elle est demandée).
 *
 * Portée du volet calorique actée avec Carl le 2026-10-02 : le calorieGoal
 * des profils du groupe sert de SIGNAL de tri (recettes dont les calories
 * par portion se rapprochent du besoin journalier moyen du groupe passent
 * devant), jamais de filtre strict ni de redécoupage de grammes par profil
 * — ce dernier point (CLAUDE.md, section 5 "Multi-profils et répartition
 * par assiette") reste explicitement gelé, pas de suivi de consommation
 * journalière pour s'appuyer dessus.
 */
#[ApiResource(
    operations: [
        new GetCollection(
            uriTemplate: '/groups/{groupId}/recipe_suggestions',
            uriVariables: ['groupId' => new Link(fromClass: Group::class, toProperty: 'group')],
            provider: RecipeSuggestionsProvider::class,
        ),
    ],
    normalizationContext: ['groups' => ['recipe_suggestion:read']],
)]
final class RecipeSuggestion
{
    /** Uniquement pour que l'uriVariable {groupId} se résolve (voir Link ci-dessus) — jamais lu ni sérialisé. */
    public ?Group $group = null;

    /**
     * @param string[] $missingIngredientNames
     */
    public function __construct(
        #[Groups(['recipe_suggestion:read'])]
        private readonly int $id,
        #[Groups(['recipe_suggestion:read'])]
        private readonly string $name,
        #[Groups(['recipe_suggestion:read'])]
        private readonly int $referenceServings,
        #[Groups(['recipe_suggestion:read'])]
        private readonly float $caloriesPerServing,
        #[Groups(['recipe_suggestion:read'])]
        private readonly int $matchedIngredientsCount,
        #[Groups(['recipe_suggestion:read'])]
        private readonly int $totalIngredientsCount,
        #[Groups(['recipe_suggestion:read'])]
        private readonly array $missingIngredientNames,
        #[Groups(['recipe_suggestion:read'])]
        private readonly ?\DateTimeImmutable $soonestExpirationDate,
    ) {
    }

    public function getId(): int
    {
        return $this->id;
    }

    public function getName(): string
    {
        return $this->name;
    }

    public function getReferenceServings(): int
    {
        return $this->referenceServings;
    }

    public function getCaloriesPerServing(): float
    {
        return $this->caloriesPerServing;
    }

    public function getMatchedIngredientsCount(): int
    {
        return $this->matchedIngredientsCount;
    }

    public function getTotalIngredientsCount(): int
    {
        return $this->totalIngredientsCount;
    }

    /** @return string[] */
    public function getMissingIngredientNames(): array
    {
        return $this->missingIngredientNames;
    }

    public function getSoonestExpirationDate(): ?\DateTimeImmutable
    {
        return $this->soonestExpirationDate;
    }
}
