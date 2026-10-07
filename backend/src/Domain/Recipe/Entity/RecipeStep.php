<?php

namespace App\Domain\Recipe\Entity;

use Doctrine\ORM\Mapping as ORM;
use Symfony\Component\Serializer\Annotation\Groups;
use Symfony\Component\Validator\Constraints as Assert;

/**
 * Pas une ApiResource à part entière, même logique que RecipeIngredient :
 * toujours créé/lu/modifié à travers Recipe. Entièrement facultatif (une
 * recette peut n'avoir aucune étape) — l'ordre vient de l'ordre de création
 * (voir `#[ORM\OrderBy]` sur Recipe::$steps), pas de colonne d'ordre dédiée
 * tant qu'il n'y a pas de besoin de réordonner après coup.
 */
#[ORM\Entity]
class RecipeStep
{
    #[ORM\Id]
    #[ORM\GeneratedValue]
    #[ORM\Column]
    #[Groups(['recipe:read'])]
    private ?int $id = null;

    #[ORM\ManyToOne(targetEntity: Recipe::class, inversedBy: 'steps')]
    #[ORM\JoinColumn(nullable: false)]
    private ?Recipe $recipe = null;

    #[ORM\Column(type: 'text')]
    #[Groups(['recipe:read', 'recipe:write'])]
    #[Assert\NotBlank(groups: ['recipe:write'])]
    private string $instruction = '';

    #[ORM\Column(nullable: true)]
    #[Groups(['recipe:read', 'recipe:write'])]
    #[Assert\Positive(groups: ['recipe:write'])]
    private ?int $durationMinutes = null;

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

    public function getInstruction(): string
    {
        return $this->instruction;
    }

    public function setInstruction(string $instruction): static
    {
        $this->instruction = $instruction;

        return $this;
    }

    public function getDurationMinutes(): ?int
    {
        return $this->durationMinutes;
    }

    public function setDurationMinutes(?int $durationMinutes): static
    {
        $this->durationMinutes = $durationMinutes;

        return $this;
    }
}
