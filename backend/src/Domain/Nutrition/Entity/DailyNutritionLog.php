<?php

namespace App\Domain\Nutrition\Entity;

use ApiPlatform\Metadata\ApiResource;
use ApiPlatform\Metadata\GetCollection;
use ApiPlatform\Metadata\Post;
use App\Domain\Nutrition\Dto\AddDailyNutritionLogInput;
use App\Domain\Nutrition\Repository\DailyNutritionLogRepository;
use App\Domain\Nutrition\State\AddDailyNutritionLogProcessor;
use App\Domain\Nutrition\State\DailyNutritionLogProvider;
use App\Shared\Entity\User;
use Doctrine\ORM\Mapping as ORM;
use Symfony\Component\Serializer\Annotation\Groups;

/**
 * Pendant de WaterIntake pour les calories/macros réellement consommées :
 * une ligne par (user, date), créée à la volée au premier ajout du jour.
 * `add` (voir AddDailyNutritionLogProcessor) incrémente les totaux existants
 * plutôt que de les remplacer — toujours un delta (potentiellement négatif
 * pour corriger une saisie), jamais une valeur absolue, même logique que
 * WaterIntake::setAmountMl.
 */
#[ORM\Entity(repositoryClass: DailyNutritionLogRepository::class)]
#[ORM\Table(name: 'daily_nutrition_log')]
#[ORM\UniqueConstraint(name: 'uniq_daily_nutrition_log_user_date', columns: ['user_id', 'date'])]
#[ApiResource(
    operations: [
        new GetCollection(provider: DailyNutritionLogProvider::class),
        new Post(
            uriTemplate: '/daily_nutrition_logs/add',
            input: AddDailyNutritionLogInput::class,
            processor: AddDailyNutritionLogProcessor::class,
        ),
    ],
    normalizationContext: ['groups' => ['daily_nutrition_log:read']],
)]
class DailyNutritionLog
{
    #[ORM\Id]
    #[ORM\GeneratedValue]
    #[ORM\Column]
    #[Groups(['daily_nutrition_log:read'])]
    private ?int $id = null;

    #[ORM\ManyToOne(targetEntity: User::class)]
    #[ORM\JoinColumn(nullable: false)]
    private ?User $user = null;

    #[ORM\Column(type: 'date_immutable')]
    #[Groups(['daily_nutrition_log:read'])]
    private ?\DateTimeImmutable $date = null;

    #[ORM\Column(type: 'integer')]
    #[Groups(['daily_nutrition_log:read'])]
    private int $caloriesConsumed = 0;

    #[ORM\Column(type: 'float')]
    #[Groups(['daily_nutrition_log:read'])]
    private float $proteinConsumedG = 0;

    #[ORM\Column(type: 'float')]
    #[Groups(['daily_nutrition_log:read'])]
    private float $carbConsumedG = 0;

    #[ORM\Column(type: 'float')]
    #[Groups(['daily_nutrition_log:read'])]
    private float $fatConsumedG = 0;

    public function getId(): ?int
    {
        return $this->id;
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

    public function getDate(): ?\DateTimeImmutable
    {
        return $this->date;
    }

    public function setDate(\DateTimeImmutable $date): static
    {
        $this->date = $date;

        return $this;
    }

    public function getCaloriesConsumed(): int
    {
        return $this->caloriesConsumed;
    }

    /** Jamais négatif : un delta qui ferait passer le total sous 0 est clampé à 0, pas une erreur. */
    public function setCaloriesConsumed(int $caloriesConsumed): static
    {
        $this->caloriesConsumed = max(0, $caloriesConsumed);

        return $this;
    }

    public function getProteinConsumedG(): float
    {
        return $this->proteinConsumedG;
    }

    public function setProteinConsumedG(float $proteinConsumedG): static
    {
        $this->proteinConsumedG = max(0.0, $proteinConsumedG);

        return $this;
    }

    public function getCarbConsumedG(): float
    {
        return $this->carbConsumedG;
    }

    public function setCarbConsumedG(float $carbConsumedG): static
    {
        $this->carbConsumedG = max(0.0, $carbConsumedG);

        return $this;
    }

    public function getFatConsumedG(): float
    {
        return $this->fatConsumedG;
    }

    public function setFatConsumedG(float $fatConsumedG): static
    {
        $this->fatConsumedG = max(0.0, $fatConsumedG);

        return $this;
    }
}
