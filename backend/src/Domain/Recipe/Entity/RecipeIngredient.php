<?php

namespace App\Domain\Recipe\Entity;

use ApiPlatform\Metadata\ApiResource;
use ApiPlatform\Metadata\GetCollection;
use App\Domain\Recipe\Repository\RecipeIngredientRepository;
use App\Domain\Recipe\State\IngredientSuggestionsProvider;
use Doctrine\ORM\Mapping as ORM;
use Symfony\Component\Serializer\Annotation\Groups;
use Symfony\Component\Validator\Constraints as Assert;

/**
 * Pas une ApiResource à part entière pour la création/lecture habituelle :
 * toujours créé/lu/modifié à travers Recipe (cascade persist/remove). Porte
 * ses propres macros directement (déjà calculées pour SA quantité dans la
 * recette), plutôt que de référencer un aliment externe — il n'existe pas
 * encore d'entité "aliment" partagée (le futur FoodItem du Frigo + import
 * Ciqual/Open Food Facts, phase 2). À relier plus tard, décision actée avec
 * Carl le 2026-09-29.
 *
 * Exception : une seule route en lecture seule, `/ingredient_suggestions`,
 * pour l'autocomplete à la création d'une recette (réutilise l'entité telle
 * quelle plutôt qu'un DTO parallèle qui dupliquerait les 7 mêmes champs —
 * décision actée avec Carl le 2026-10-07).
 */
#[ORM\Entity(repositoryClass: RecipeIngredientRepository::class)]
#[ApiResource(
    operations: [
        new GetCollection(uriTemplate: '/ingredient_suggestions', provider: IngredientSuggestionsProvider::class),
    ],
    normalizationContext: ['groups' => ['ingredient_suggestion:read']],
)]
class RecipeIngredient
{
    #[ORM\Id]
    #[ORM\GeneratedValue]
    #[ORM\Column]
    #[Groups(['recipe:read'])]
    private ?int $id = null;

    #[ORM\ManyToOne(targetEntity: Recipe::class, inversedBy: 'ingredients')]
    #[ORM\JoinColumn(nullable: false)]
    private ?Recipe $recipe = null;

    #[ORM\Column(length: 120)]
    #[Groups(['recipe:read', 'recipe:write', 'ingredient_suggestion:read', 'meal_plan_entry:read'])]
    #[Assert\NotBlank(groups: ['recipe:write'])]
    private string $name = '';

    #[ORM\Column(type: 'float')]
    #[Groups(['recipe:read', 'recipe:write', 'ingredient_suggestion:read', 'meal_plan_entry:read'])]
    #[Assert\Positive(groups: ['recipe:write'])]
    private float $quantity = 0;

    /** Libre pour l'instant (g, ml, unité, pincée...) — pas de table de conversion tant qu'il n'y a pas de vraie base aliments. */
    #[ORM\Column(length: 20)]
    #[Groups(['recipe:read', 'recipe:write', 'ingredient_suggestion:read', 'meal_plan_entry:read'])]
    #[Assert\NotBlank(groups: ['recipe:write'])]
    private string $unit = 'g';

    #[ORM\Column(type: 'float')]
    #[Groups(['recipe:read', 'recipe:write', 'ingredient_suggestion:read', 'meal_plan_entry:read'])]
    #[Assert\PositiveOrZero(groups: ['recipe:write'])]
    private float $calories = 0;

    #[ORM\Column(type: 'float')]
    #[Groups(['recipe:read', 'recipe:write', 'ingredient_suggestion:read', 'meal_plan_entry:read'])]
    #[Assert\PositiveOrZero(groups: ['recipe:write'])]
    private float $proteins = 0;

    #[ORM\Column(type: 'float')]
    #[Groups(['recipe:read', 'recipe:write', 'ingredient_suggestion:read', 'meal_plan_entry:read'])]
    #[Assert\PositiveOrZero(groups: ['recipe:write'])]
    private float $carbs = 0;

    #[ORM\Column(type: 'float')]
    #[Groups(['recipe:read', 'recipe:write', 'ingredient_suggestion:read', 'meal_plan_entry:read'])]
    #[Assert\PositiveOrZero(groups: ['recipe:write'])]
    private float $fats = 0;

    public function getId(): ?int
    {
        return $this->id;
    }

    public function getRecipe(): ?Recipe
    {
        return $this->recipe;
    }

    public function setRecipe(?Recipe $recipe): static
    {
        $this->recipe = $recipe;

        return $this;
    }

    public function getName(): string
    {
        return $this->name;
    }

    public function setName(string $name): static
    {
        $this->name = $name;

        return $this;
    }

    public function getQuantity(): float
    {
        return $this->quantity;
    }

    public function setQuantity(float $quantity): static
    {
        $this->quantity = $quantity;

        return $this;
    }

    public function getUnit(): string
    {
        return $this->unit;
    }

    public function setUnit(string $unit): static
    {
        $this->unit = $unit;

        return $this;
    }

    public function getCalories(): float
    {
        return $this->calories;
    }

    public function setCalories(float $calories): static
    {
        $this->calories = $calories;

        return $this;
    }

    public function getProteins(): float
    {
        return $this->proteins;
    }

    public function setProteins(float $proteins): static
    {
        $this->proteins = $proteins;

        return $this;
    }

    public function getCarbs(): float
    {
        return $this->carbs;
    }

    public function setCarbs(float $carbs): static
    {
        $this->carbs = $carbs;

        return $this;
    }

    public function getFats(): float
    {
        return $this->fats;
    }

    public function setFats(float $fats): static
    {
        $this->fats = $fats;

        return $this;
    }
}
