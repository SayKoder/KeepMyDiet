<?php

namespace App\Domain\Recipe\Entity;

use ApiPlatform\Metadata\ApiResource;
use ApiPlatform\Metadata\Delete;
use ApiPlatform\Metadata\Get;
use ApiPlatform\Metadata\GetCollection;
use ApiPlatform\Metadata\Post;
use App\Domain\Recipe\Repository\RecipeRepository;
use App\Domain\Recipe\State\CreateRecipeProcessor;
use App\Shared\Entity\User;
use Doctrine\Common\Collections\ArrayCollection;
use Doctrine\Common\Collections\Collection;
use Doctrine\ORM\Mapping as ORM;
use Symfony\Component\Serializer\Annotation\Groups;
use Symfony\Component\Validator\Constraints as Assert;

/**
 * Toutes les recettes (seed + ajoutées par les utilisateurs) partagent le même
 * pool global — pas de scope par groupe (voir CLAUDE.md, section "Moteur de
 * recettes").
 */
#[ORM\Entity(repositoryClass: RecipeRepository::class)]
#[ApiResource(
    operations: [
        new GetCollection(),
        new Get(),
        new Post(processor: CreateRecipeProcessor::class, validationContext: ['groups' => ['recipe:write']]),
        new Delete(security: 'object.getCreatedBy() == user'),
    ],
    normalizationContext: ['groups' => ['recipe:read']],
    denormalizationContext: ['groups' => ['recipe:write']],
)]
class Recipe
{
    #[ORM\Id]
    #[ORM\GeneratedValue]
    #[ORM\Column]
    #[Groups(['recipe:read'])]
    private ?int $id = null;

    #[ORM\Column(length: 120)]
    #[Groups(['recipe:read', 'recipe:write'])]
    #[Assert\NotBlank(groups: ['recipe:write'])]
    #[Assert\Length(max: 120, groups: ['recipe:write'])]
    private string $name = '';

    /** Nombre de personnes pour lequel les quantités des ingrédients sont prévues. */
    #[ORM\Column]
    #[Groups(['recipe:read', 'recipe:write'])]
    #[Assert\Positive(groups: ['recipe:write'])]
    private int $referenceServings = 1;

    #[ORM\ManyToOne(targetEntity: User::class)]
    #[ORM\JoinColumn(nullable: true)]
    private ?User $createdBy = null;

    #[ORM\Column(type: 'datetime_immutable')]
    #[Groups(['recipe:read'])]
    private \DateTimeImmutable $createdAt;

    /** @var Collection<int, RecipeIngredient> */
    #[ORM\OneToMany(targetEntity: RecipeIngredient::class, mappedBy: 'recipe', cascade: ['persist'], orphanRemoval: true)]
    #[Groups(['recipe:read', 'recipe:write'])]
    #[Assert\Count(min: 1, groups: ['recipe:write'], minMessage: 'Une recette doit avoir au moins un ingrédient.')]
    #[Assert\Valid]
    private Collection $ingredients;

    public function __construct()
    {
        $this->createdAt = new \DateTimeImmutable();
        $this->ingredients = new ArrayCollection();
    }

    public function getId(): ?int
    {
        return $this->id;
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

    public function getReferenceServings(): int
    {
        return $this->referenceServings;
    }

    public function setReferenceServings(int $referenceServings): static
    {
        $this->referenceServings = $referenceServings;

        return $this;
    }

    public function getCreatedBy(): ?User
    {
        return $this->createdBy;
    }

    public function setCreatedBy(?User $createdBy): static
    {
        $this->createdBy = $createdBy;

        return $this;
    }

    public function getCreatedAt(): \DateTimeImmutable
    {
        return $this->createdAt;
    }

    /** @return Collection<int, RecipeIngredient> */
    public function getIngredients(): Collection
    {
        return $this->ingredients;
    }

    public function addIngredient(RecipeIngredient $ingredient): static
    {
        if (!$this->ingredients->contains($ingredient)) {
            $this->ingredients->add($ingredient);
            $ingredient->setRecipe($this);
        }

        return $this;
    }

    public function removeIngredient(RecipeIngredient $ingredient): static
    {
        $this->ingredients->removeElement($ingredient);

        return $this;
    }

    #[Groups(['recipe:read'])]
    public function getTotalCalories(): float
    {
        return array_sum(array_map(static fn (RecipeIngredient $i) => $i->getCalories(), $this->ingredients->toArray()));
    }

    #[Groups(['recipe:read'])]
    public function getTotalProteins(): float
    {
        return array_sum(array_map(static fn (RecipeIngredient $i) => $i->getProteins(), $this->ingredients->toArray()));
    }

    #[Groups(['recipe:read'])]
    public function getTotalCarbs(): float
    {
        return array_sum(array_map(static fn (RecipeIngredient $i) => $i->getCarbs(), $this->ingredients->toArray()));
    }

    #[Groups(['recipe:read'])]
    public function getTotalFats(): float
    {
        return array_sum(array_map(static fn (RecipeIngredient $i) => $i->getFats(), $this->ingredients->toArray()));
    }
}
