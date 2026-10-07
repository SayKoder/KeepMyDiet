<?php

namespace App\Domain\Nutrition\Entity;

use ApiPlatform\Metadata\ApiResource;
use ApiPlatform\Metadata\GetCollection;
use ApiPlatform\Metadata\Post;
use App\Domain\Nutrition\Dto\ResetWaterGoalInput;
use App\Domain\Nutrition\Dto\SetWaterGoalInput;
use App\Domain\Nutrition\Repository\WaterGoalRepository;
use App\Domain\Nutrition\State\MyWaterGoalProvider;
use App\Domain\Nutrition\State\ResetWaterGoalProcessor;
use App\Domain\Nutrition\State\SetWaterGoalProcessor;
use App\Shared\Entity\User;
use Doctrine\ORM\Mapping as ORM;
use Symfony\Component\Serializer\Annotation\Groups;

/**
 * Objectif d'hydratation personnalisé, optionnel (0 ou 1 ligne par
 * utilisateur) : son absence = pas de surcharge, le client retombe sur son
 * calcul par défaut (35 mL/kg, voir `_WaterCard` côté Flutter — pas dupliqué
 * côté backend, pas besoin de coupler cette entité à `Profile` pour une
 * formule à une ligne). `set`/`reset` plutôt qu'un `Patch` classique : un
 * `goalMl` nul dans `set` ne peut pas être renvoyé normalement (API Platform
 * ne peut pas générer d'IRI pour une entité jamais persistée), d'où une
 * action dédiée `reset` avec `output: false` (pas de corps à sérialiser).
 */
#[ORM\Entity(repositoryClass: WaterGoalRepository::class)]
#[ORM\Table(name: 'water_goal')]
#[ORM\UniqueConstraint(name: 'uniq_water_goal_user', columns: ['user_id'])]
#[ApiResource(
    operations: [
        new GetCollection(provider: MyWaterGoalProvider::class),
        new Post(
            uriTemplate: '/water_goals/set',
            input: SetWaterGoalInput::class,
            processor: SetWaterGoalProcessor::class,
        ),
        new Post(
            uriTemplate: '/water_goals/reset',
            input: ResetWaterGoalInput::class,
            output: false,
            processor: ResetWaterGoalProcessor::class,
        ),
    ],
    normalizationContext: ['groups' => ['water_goal:read']],
)]
class WaterGoal
{
    #[ORM\Id]
    #[ORM\GeneratedValue]
    #[ORM\Column]
    #[Groups(['water_goal:read'])]
    private ?int $id = null;

    #[ORM\ManyToOne(targetEntity: User::class)]
    #[ORM\JoinColumn(nullable: false)]
    private ?User $user = null;

    #[ORM\Column(type: 'integer')]
    #[Groups(['water_goal:read'])]
    private ?int $goalMl = null;

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

    public function getGoalMl(): ?int
    {
        return $this->goalMl;
    }

    public function setGoalMl(?int $goalMl): static
    {
        $this->goalMl = $goalMl;

        return $this;
    }
}
