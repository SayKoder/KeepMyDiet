<?php

namespace App\Domain\Nutrition\Entity;

use ApiPlatform\Metadata\ApiResource;
use ApiPlatform\Metadata\Get;
use ApiPlatform\Metadata\GetCollection;
use ApiPlatform\Metadata\Patch;
use ApiPlatform\Metadata\Post;
use App\Domain\Nutrition\Repository\ProfileRepository;
use App\Domain\Nutrition\State\CreateProfileProcessor;
use App\Domain\Nutrition\State\MyProfileProvider;
use App\Shared\Entity\User;
use Doctrine\ORM\Mapping as ORM;
use Symfony\Component\Serializer\Annotation\Groups;
use Symfony\Component\Validator\Constraints as Assert;

/**
 * Un profil par utilisateur (pas par groupe) : les besoins caloriques sont
 * propres à la personne, indépendamment des groupes qu'elle rejoint (voir
 * CLAUDE.md, section "Multi-profils").
 *
 * Déficit fixé à 20% du TDEE (décision actée avec Carl le 2026-09-30, voir
 * "Décisions ouvertes" du CLAUDE.md) : pas de recalcul automatique dans le
 * temps pour l'instant, juste une valeur de départ recalculée à chaque
 * lecture à partir du poids/activité courants (donc jamais désynchronisée).
 */
#[ORM\Entity(repositoryClass: ProfileRepository::class)]
#[ORM\Table(name: 'nutrition_profile')]
#[ApiResource(
    operations: [
        new GetCollection(provider: MyProfileProvider::class),
        new Post(processor: CreateProfileProcessor::class, validationContext: ['groups' => ['profile:write']]),
        new Get(security: 'object.getUser() == user'),
        new Patch(security: 'object.getUser() == user', validationContext: ['groups' => ['profile:write']]),
    ],
    normalizationContext: ['groups' => ['profile:read']],
    denormalizationContext: ['groups' => ['profile:write']],
)]
class Profile
{
    #[ORM\Id]
    #[ORM\GeneratedValue]
    #[ORM\Column]
    #[Groups(['profile:read'])]
    private ?int $id = null;

    #[ORM\OneToOne(targetEntity: User::class)]
    #[ORM\JoinColumn(nullable: false, unique: true)]
    private ?User $user = null;

    #[ORM\Column(length: 10, enumType: Sex::class)]
    #[Groups(['profile:read', 'profile:write'])]
    #[Assert\NotNull(groups: ['profile:write'])]
    private ?Sex $sex = null;

    #[ORM\Column(type: 'date_immutable')]
    #[Groups(['profile:read', 'profile:write'])]
    #[Assert\NotNull(groups: ['profile:write'])]
    private ?\DateTimeImmutable $birthDate = null;

    #[ORM\Column(type: 'float')]
    #[Groups(['profile:read', 'profile:write'])]
    #[Assert\Positive(groups: ['profile:write'])]
    private float $heightCm = 0;

    #[ORM\Column(type: 'float')]
    #[Groups(['profile:read', 'profile:write'])]
    #[Assert\Positive(groups: ['profile:write'])]
    private float $weightKg = 0;

    #[ORM\Column(length: 20, enumType: ActivityLevel::class)]
    #[Groups(['profile:read', 'profile:write'])]
    #[Assert\NotNull(groups: ['profile:write'])]
    private ?ActivityLevel $activityLevel = null;

    /** Poids visé, optionnel — purement informatif (estimation du délai), ne modifie pas le calcul du déficit. */
    #[ORM\Column(type: 'float', nullable: true)]
    #[Groups(['profile:read', 'profile:write'])]
    #[Assert\Positive(groups: ['profile:write'])]
    private ?float $targetWeightKg = null;

    /**
     * Rythme de perte visé, optionnel (kg/semaine). Si renseigné, remplace le
     * déficit fixe de 20% par un déficit calculé à partir de ce rythme (voir
     * getCalorieGoal) — décision actée avec Carl le 2026-10-03.
     */
    #[ORM\Column(type: 'float', nullable: true)]
    #[Groups(['profile:read', 'profile:write'])]
    #[Assert\Range(min: 0.25, max: 1, groups: ['profile:write'])]
    private ?float $weeklyWeightLossGoalKg = null;

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

    public function getSex(): ?Sex
    {
        return $this->sex;
    }

    public function setSex(Sex $sex): static
    {
        $this->sex = $sex;

        return $this;
    }

    public function getBirthDate(): ?\DateTimeImmutable
    {
        return $this->birthDate;
    }

    public function setBirthDate(\DateTimeImmutable $birthDate): static
    {
        $this->birthDate = $birthDate;

        return $this;
    }

    public function getHeightCm(): float
    {
        return $this->heightCm;
    }

    public function setHeightCm(float $heightCm): static
    {
        $this->heightCm = $heightCm;

        return $this;
    }

    public function getWeightKg(): float
    {
        return $this->weightKg;
    }

    public function setWeightKg(float $weightKg): static
    {
        $this->weightKg = $weightKg;

        return $this;
    }

    public function getActivityLevel(): ?ActivityLevel
    {
        return $this->activityLevel;
    }

    public function setActivityLevel(ActivityLevel $activityLevel): static
    {
        $this->activityLevel = $activityLevel;

        return $this;
    }

    public function getTargetWeightKg(): ?float
    {
        return $this->targetWeightKg;
    }

    public function setTargetWeightKg(?float $targetWeightKg): static
    {
        $this->targetWeightKg = $targetWeightKg;

        return $this;
    }

    public function getWeeklyWeightLossGoalKg(): ?float
    {
        return $this->weeklyWeightLossGoalKg;
    }

    public function setWeeklyWeightLossGoalKg(?float $weeklyWeightLossGoalKg): static
    {
        $this->weeklyWeightLossGoalKg = $weeklyWeightLossGoalKg;

        return $this;
    }

    #[Groups(['profile:read'])]
    public function getAge(): int
    {
        return $this->birthDate?->diff(new \DateTimeImmutable())->y ?? 0;
    }

    /** Métabolisme de base (Mifflin-St Jeor), en kcal/jour. */
    #[Groups(['profile:read'])]
    public function getBmr(): float
    {
        $base = 10 * $this->weightKg + 6.25 * $this->heightCm - 5 * $this->getAge();

        return Sex::Male === $this->sex ? $base + 5 : $base - 161;
    }

    /** Dépense calorique totale journalière (BMR × niveau d'activité), en kcal/jour. */
    #[Groups(['profile:read'])]
    public function getTdee(): float
    {
        return null === $this->activityLevel ? 0.0 : $this->getBmr() * $this->activityLevel->multiplier();
    }

    /**
     * Objectif calorique perte de poids.
     *
     * Si `weeklyWeightLossGoalKg` est renseigné : déficit calculé à partir de
     * ce rythme (1 kg de masse grasse ≈ 7700 kcal — constante scientifique
     * standard), jamais sous le plancher de sécurité (`getCalorieFloor`,
     * décision actée avec Carl le 2026-10-03).
     * Sinon : comportement par défaut inchangé, déficit fixe de 20% du TDEE.
     */
    #[Groups(['profile:read'])]
    public function getCalorieGoal(): float
    {
        if (null === $this->weeklyWeightLossGoalKg) {
            return $this->getTdee() * 0.8;
        }

        $dailyDeficit = $this->weeklyWeightLossGoalKg * 7700 / 7;

        return max($this->getCalorieFloor(), $this->getTdee() - $dailyDeficit);
    }

    /** Plancher de sécurité : jamais descendre sous son métabolisme de base. */
    #[Groups(['profile:read'])]
    public function getCalorieFloor(): float
    {
        return $this->getBmr();
    }

    /**
     * Estimation du nombre de semaines pour atteindre le poids visé, au
     * rythme hebdomadaire choisi — purement informatif, n'influence pas
     * `getCalorieGoal`. Null si l'un des deux n'est pas renseigné, ou si le
     * poids visé n'est pas inférieur au poids actuel (objectif de perte
     * uniquement, cohérent avec le reste de l'app).
     */
    #[Groups(['profile:read'])]
    public function getEstimatedWeeksToTarget(): ?int
    {
        if (null === $this->targetWeightKg || null === $this->weeklyWeightLossGoalKg) {
            return null;
        }

        $remainingKg = $this->weightKg - $this->targetWeightKg;
        if ($remainingKg <= 0) {
            return null;
        }

        return (int) ceil($remainingKg / $this->weeklyWeightLossGoalKg);
    }
}
