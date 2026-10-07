<?php

namespace App\Domain\Nutrition\Entity;

use ApiPlatform\Metadata\ApiResource;
use ApiPlatform\Metadata\GetCollection;
use ApiPlatform\Metadata\Post;
use App\Domain\Nutrition\Dto\AddWaterIntakeInput;
use App\Domain\Nutrition\Repository\WaterIntakeRepository;
use App\Domain\Nutrition\State\AddWaterIntakeProcessor;
use App\Domain\Nutrition\State\TodayWaterIntakeProvider;
use App\Shared\Entity\User;
use Doctrine\ORM\Mapping as ORM;
use Symfony\Component\Serializer\Annotation\Groups;

/**
 * Suivi d'eau volontairement simple : un total en mL par jour par
 * utilisateur (pas un journal d'évènements horodatés — pas besoin de plus
 * pour "combien j'ai bu aujourd'hui"). Une ligne par (user, date), créée à la
 * volée au premier ajout de la journée. `add` (voir AddWaterIntakeProcessor)
 * incrémente le total existant plutôt que de le remplacer : le client envoie
 * toujours un delta ("+250"), jamais le total absolu, pour éviter tout souci
 * de synchronisation s'il relit l'état avant d'écrire.
 */
#[ORM\Entity(repositoryClass: WaterIntakeRepository::class)]
#[ORM\Table(name: 'water_intake')]
#[ORM\UniqueConstraint(name: 'uniq_water_intake_user_date', columns: ['user_id', 'date'])]
#[ApiResource(
    operations: [
        new GetCollection(provider: TodayWaterIntakeProvider::class),
        new Post(
            uriTemplate: '/water_intakes/add',
            input: AddWaterIntakeInput::class,
            processor: AddWaterIntakeProcessor::class,
        ),
    ],
    normalizationContext: ['groups' => ['water_intake:read']],
)]
class WaterIntake
{
    #[ORM\Id]
    #[ORM\GeneratedValue]
    #[ORM\Column]
    #[Groups(['water_intake:read'])]
    private ?int $id = null;

    #[ORM\ManyToOne(targetEntity: User::class)]
    #[ORM\JoinColumn(nullable: false)]
    private ?User $user = null;

    #[ORM\Column(type: 'date_immutable')]
    #[Groups(['water_intake:read'])]
    private ?\DateTimeImmutable $date = null;

    #[ORM\Column(type: 'integer')]
    #[Groups(['water_intake:read'])]
    private int $amountMl = 0;

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

    public function getAmountMl(): int
    {
        return $this->amountMl;
    }

    /** Jamais négatif : un delta négatif (annulation) qui dépasserait le total est clampé à 0, pas une erreur. */
    public function setAmountMl(int $amountMl): static
    {
        $this->amountMl = max(0, $amountMl);

        return $this;
    }
}
