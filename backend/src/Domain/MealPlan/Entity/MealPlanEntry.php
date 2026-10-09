<?php

namespace App\Domain\MealPlan\Entity;

use ApiPlatform\Metadata\ApiResource;
use ApiPlatform\Metadata\Delete;
use ApiPlatform\Metadata\GetCollection;
use ApiPlatform\Metadata\Link;
use ApiPlatform\Metadata\Patch;
use ApiPlatform\Metadata\Post;
use App\Domain\Group\Entity\Group;
use App\Domain\MealPlan\Repository\MealPlanEntryRepository;
use App\Domain\MealPlan\State\CreateMealPlanEntryProcessor;
use App\Domain\MealPlan\State\DeleteMealPlanEntryProcessor;
use App\Domain\MealPlan\State\MealPlanEntriesProvider;
use App\Domain\MealPlan\State\UpdateMealPlanEntryProcessor;
use App\Domain\Recipe\Entity\Recipe;
use App\Shared\Entity\User;
use Doctrine\ORM\Mapping as ORM;
use Symfony\Component\Serializer\Annotation\Groups;
use Symfony\Component\Validator\Constraints as Assert;

/**
 * Un créneau de repas prévu (groupe, jour, type de repas) référençant
 * toujours une `Recipe` — y compris pour un "ajout rapide d'aliments"
 * (banane + jus de pomme...), qui crée en coulisses une recette sans étapes
 * via l'endpoint `POST /recipes` existant plutôt que d'inventer un second
 * modèle de données (décision actée avec Carl le 2026-10-07). `servings` est
 * le nombre de portions *prévues* pour ce créneau, indépendant du nombre de
 * membres du groupe (contrairement à la mise à l'échelle de
 * `GenerateShoppingListProcessor`) : on peut prévoir 2 portions de lasagnes
 * même dans un groupe de 3.
 */
#[ORM\Entity(repositoryClass: MealPlanEntryRepository::class)]
#[ApiResource(
    operations: [
        new GetCollection(
            uriTemplate: '/groups/{groupId}/meal_plan_entries',
            uriVariables: ['groupId' => new Link(fromClass: Group::class, toProperty: 'group')],
            provider: MealPlanEntriesProvider::class,
        ),
        new Post(processor: CreateMealPlanEntryProcessor::class, validationContext: ['groups' => ['meal_plan_entry:write']]),
        // Remplacer la recette d'un créneau déjà prévu (choix "Remplacer ?"
        // sur l'Accueil) plutôt que recréer + supprimer : évite de devoir
        // réconcilier un MealPlanEntryLog déjà posé sur l'ancien id (voir
        // UpdateMealPlanEntryProcessor et JOURNAL.md).
        new Patch(processor: UpdateMealPlanEntryProcessor::class, validationContext: ['groups' => ['meal_plan_entry:write']]),
        new Delete(processor: DeleteMealPlanEntryProcessor::class),
    ],
    normalizationContext: ['groups' => ['meal_plan_entry:read']],
    denormalizationContext: ['groups' => ['meal_plan_entry:write']],
)]
class MealPlanEntry
{
    #[ORM\Id]
    #[ORM\GeneratedValue]
    #[ORM\Column]
    #[Groups(['meal_plan_entry:read'])]
    private ?int $id = null;

    #[ORM\ManyToOne(targetEntity: Group::class)]
    #[ORM\JoinColumn(nullable: false)]
    #[Groups(['meal_plan_entry:read', 'meal_plan_entry:write'])]
    #[Assert\NotNull(groups: ['meal_plan_entry:write'])]
    private ?Group $group = null;

    #[ORM\Column(type: 'date_immutable')]
    #[Groups(['meal_plan_entry:read', 'meal_plan_entry:write'])]
    #[Assert\NotNull(groups: ['meal_plan_entry:write'])]
    private ?\DateTimeImmutable $date = null;

    #[ORM\Column(length: 10, enumType: MealType::class)]
    #[Groups(['meal_plan_entry:read', 'meal_plan_entry:write'])]
    #[Assert\NotNull(groups: ['meal_plan_entry:write'])]
    private ?MealType $mealType = null;

    #[ORM\ManyToOne(targetEntity: Recipe::class)]
    #[ORM\JoinColumn(nullable: false)]
    #[Groups(['meal_plan_entry:read', 'meal_plan_entry:write'])]
    #[Assert\NotNull(groups: ['meal_plan_entry:write'])]
    private ?Recipe $recipe = null;

    #[ORM\Column]
    #[Groups(['meal_plan_entry:read', 'meal_plan_entry:write'])]
    #[Assert\Positive(groups: ['meal_plan_entry:write'])]
    private int $servings = 1;

    #[ORM\ManyToOne(targetEntity: User::class)]
    #[ORM\JoinColumn(nullable: false)]
    private ?User $addedBy = null;

    public function getId(): ?int
    {
        return $this->id;
    }

    public function getGroup(): ?Group
    {
        return $this->group;
    }

    public function setGroup(?Group $group): static
    {
        $this->group = $group;

        return $this;
    }

    public function getDate(): ?\DateTimeImmutable
    {
        return $this->date;
    }

    public function setDate(\DateTimeImmutable $date): static
    {
        $this->date = $date;

        return $this;
    }

    public function getMealType(): ?MealType
    {
        return $this->mealType;
    }

    public function setMealType(MealType $mealType): static
    {
        $this->mealType = $mealType;

        return $this;
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

    public function getServings(): int
    {
        return $this->servings;
    }

    public function setServings(int $servings): static
    {
        $this->servings = $servings;

        return $this;
    }

    public function getAddedBy(): ?User
    {
        return $this->addedBy;
    }

    public function setAddedBy(User $addedBy): static
    {
        $this->addedBy = $addedBy;

        return $this;
    }
}
