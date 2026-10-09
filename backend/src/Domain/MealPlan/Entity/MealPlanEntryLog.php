<?php

namespace App\Domain\MealPlan\Entity;

use ApiPlatform\Metadata\ApiResource;
use ApiPlatform\Metadata\GetCollection;
use ApiPlatform\Metadata\Post;
use App\Domain\MealPlan\Repository\MealPlanEntryLogRepository;
use App\Domain\MealPlan\State\CreateOrUpdateMealPlanEntryLogProcessor;
use App\Domain\MealPlan\State\MealPlanEntryLogsProvider;
use App\Shared\Entity\User;
use Doctrine\ORM\Mapping as ORM;
use Symfony\Component\Serializer\Annotation\Groups;
use Symfony\Component\Validator\Constraints as Assert;

/**
 * Réponse personnelle d'un membre au pop-up "as-tu pris ce repas ?" — jamais
 * une mutation du MealPlanEntry lui-même (partagé par tout le groupe) : deux
 * personnes du même groupe peuvent répondre différemment au même créneau
 * (l'une a mangé, l'autre non), d'où l'unicité sur (entry, user) et pas sur
 * entry seul.
 *
 * `appliedX` capture ce qui a *réellement* été ajouté au DailyNutritionLog du
 * jour au moment de la réponse (1 portion de la recette pour `Eaten`, les
 * valeurs fournies pour `Replaced`, zéro pour `Skipped`). Répondre à nouveau
 * au même créneau (changer d'avis) passe par la soustraction de ces valeurs
 * stockées avant d'appliquer la nouvelle réponse — voir
 * CreateOrUpdateMealPlanEntryLogProcessor — plutôt que de recalculer depuis
 * la recette, qui pourrait avoir changé entre-temps.
 */
#[ORM\Entity(repositoryClass: MealPlanEntryLogRepository::class)]
#[ORM\UniqueConstraint(name: 'uniq_meal_plan_entry_log_entry_user', columns: ['meal_plan_entry_id', 'user_id'])]
#[ApiResource(
    operations: [
        new GetCollection(provider: MealPlanEntryLogsProvider::class),
        new Post(processor: CreateOrUpdateMealPlanEntryLogProcessor::class, validationContext: ['groups' => ['meal_plan_entry_log:write']]),
    ],
    normalizationContext: ['groups' => ['meal_plan_entry_log:read']],
    denormalizationContext: ['groups' => ['meal_plan_entry_log:write']],
)]
class MealPlanEntryLog
{
    #[ORM\Id]
    #[ORM\GeneratedValue]
    #[ORM\Column]
    #[Groups(['meal_plan_entry_log:read'])]
    private ?int $id = null;

    #[ORM\ManyToOne(targetEntity: MealPlanEntry::class)]
    #[ORM\JoinColumn(nullable: false)]
    #[Groups(['meal_plan_entry_log:read', 'meal_plan_entry_log:write'])]
    #[Assert\NotNull(groups: ['meal_plan_entry_log:write'])]
    private ?MealPlanEntry $mealPlanEntry = null;

    #[ORM\ManyToOne(targetEntity: User::class)]
    #[ORM\JoinColumn(nullable: false)]
    private ?User $user = null;

    #[ORM\Column(length: 10, enumType: MealPlanEntryStatus::class)]
    #[Groups(['meal_plan_entry_log:read', 'meal_plan_entry_log:write'])]
    #[Assert\NotNull(groups: ['meal_plan_entry_log:write'])]
    private ?MealPlanEntryStatus $status = null;

    /** Renseigné uniquement pour `Replaced` ("autre chose" : description libre + macros, saisies ou préremplies depuis le catalogue aliments du Frigo). */
    #[ORM\Column(length: 255, nullable: true)]
    #[Groups(['meal_plan_entry_log:read', 'meal_plan_entry_log:write'])]
    private ?string $replacementDescription = null;

    #[ORM\Column(type: 'float', nullable: true)]
    #[Groups(['meal_plan_entry_log:read', 'meal_plan_entry_log:write'])]
    private ?float $replacementCalories = null;

    #[ORM\Column(type: 'float', nullable: true)]
    #[Groups(['meal_plan_entry_log:read', 'meal_plan_entry_log:write'])]
    private ?float $replacementProteinG = null;

    #[ORM\Column(type: 'float', nullable: true)]
    #[Groups(['meal_plan_entry_log:read', 'meal_plan_entry_log:write'])]
    private ?float $replacementCarbG = null;

    #[ORM\Column(type: 'float', nullable: true)]
    #[Groups(['meal_plan_entry_log:read', 'meal_plan_entry_log:write'])]
    private ?float $replacementFatG = null;

    #[ORM\Column(type: 'integer')]
    #[Groups(['meal_plan_entry_log:read'])]
    private int $appliedCalories = 0;

    #[ORM\Column(type: 'float')]
    #[Groups(['meal_plan_entry_log:read'])]
    private float $appliedProteinG = 0;

    #[ORM\Column(type: 'float')]
    #[Groups(['meal_plan_entry_log:read'])]
    private float $appliedCarbG = 0;

    #[ORM\Column(type: 'float')]
    #[Groups(['meal_plan_entry_log:read'])]
    private float $appliedFatG = 0;

    #[ORM\Column(type: 'datetime_immutable')]
    #[Groups(['meal_plan_entry_log:read'])]
    private \DateTimeImmutable $createdAt;

    public function __construct()
    {
        $this->createdAt = new \DateTimeImmutable();
    }

    public function getId(): ?int
    {
        return $this->id;
    }

    public function getMealPlanEntry(): ?MealPlanEntry
    {
        return $this->mealPlanEntry;
    }

    public function setMealPlanEntry(?MealPlanEntry $mealPlanEntry): static
    {
        $this->mealPlanEntry = $mealPlanEntry;

        return $this;
    }

    public function getUser(): ?User
    {
        return $this->user;
    }

    public function setUser(User $user): static
    {
        $this->user = $user;

        return $this;
    }

    public function getStatus(): ?MealPlanEntryStatus
    {
        return $this->status;
    }

    public function setStatus(MealPlanEntryStatus $status): static
    {
        $this->status = $status;

        return $this;
    }

    public function getReplacementDescription(): ?string
    {
        return $this->replacementDescription;
    }

    public function setReplacementDescription(?string $replacementDescription): static
    {
        $this->replacementDescription = $replacementDescription;

        return $this;
    }

    public function getReplacementCalories(): ?float
    {
        return $this->replacementCalories;
    }

    public function setReplacementCalories(?float $replacementCalories): static
    {
        $this->replacementCalories = $replacementCalories;

        return $this;
    }

    public function getReplacementProteinG(): ?float
    {
        return $this->replacementProteinG;
    }

    public function setReplacementProteinG(?float $replacementProteinG): static
    {
        $this->replacementProteinG = $replacementProteinG;

        return $this;
    }

    public function getReplacementCarbG(): ?float
    {
        return $this->replacementCarbG;
    }

    public function setReplacementCarbG(?float $replacementCarbG): static
    {
        $this->replacementCarbG = $replacementCarbG;

        return $this;
    }

    public function getReplacementFatG(): ?float
    {
        return $this->replacementFatG;
    }

    public function setReplacementFatG(?float $replacementFatG): static
    {
        $this->replacementFatG = $replacementFatG;

        return $this;
    }

    public function getAppliedCalories(): int
    {
        return $this->appliedCalories;
    }

    public function setAppliedCalories(int $appliedCalories): static
    {
        $this->appliedCalories = $appliedCalories;

        return $this;
    }

    public function getAppliedProteinG(): float
    {
        return $this->appliedProteinG;
    }

    public function setAppliedProteinG(float $appliedProteinG): static
    {
        $this->appliedProteinG = $appliedProteinG;

        return $this;
    }

    public function getAppliedCarbG(): float
    {
        return $this->appliedCarbG;
    }

    public function setAppliedCarbG(float $appliedCarbG): static
    {
        $this->appliedCarbG = $appliedCarbG;

        return $this;
    }

    public function getAppliedFatG(): float
    {
        return $this->appliedFatG;
    }

    public function setAppliedFatG(float $appliedFatG): static
    {
        $this->appliedFatG = $appliedFatG;

        return $this;
    }

    public function getCreatedAt(): \DateTimeImmutable
    {
        return $this->createdAt;
    }
}
