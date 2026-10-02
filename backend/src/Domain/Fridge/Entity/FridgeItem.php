<?php

namespace App\Domain\Fridge\Entity;

use ApiPlatform\Metadata\ApiProperty;
use ApiPlatform\Metadata\ApiResource;
use ApiPlatform\Metadata\Delete;
use ApiPlatform\Metadata\GetCollection;
use ApiPlatform\Metadata\Link;
use ApiPlatform\Metadata\Post;
use App\Domain\Fridge\Repository\FridgeItemRepository;
use App\Domain\Fridge\State\CreateFridgeItemProcessor;
use App\Domain\Fridge\State\DeleteFridgeItemProcessor;
use App\Domain\Fridge\State\FridgeItemsProvider;
use App\Domain\Group\Entity\Group;
use App\Shared\Entity\User;
use Doctrine\ORM\Mapping as ORM;
use Symfony\Component\Serializer\Annotation\Groups;
use Symfony\Component\Validator\Constraints as Assert;

/**
 * Un aliment en stock dans le frigo ou le placard d'un groupe. Référence
 * toujours un `FoodReference` (jamais de macros dupliquées ici) : la
 * quantité réelle consommée se calcule côté moteur de recettes à partir des
 * valeurs pour 100g du `FoodReference` et de `quantity`.
 */
#[ORM\Entity(repositoryClass: FridgeItemRepository::class)]
#[ApiResource(
    operations: [
        new GetCollection(
            uriTemplate: '/groups/{groupId}/fridge_items',
            uriVariables: ['groupId' => new Link(fromClass: Group::class, toProperty: 'group')],
            provider: FridgeItemsProvider::class,
        ),
        new Post(processor: CreateFridgeItemProcessor::class, validationContext: ['groups' => ['fridge_item:write']]),
        new Delete(processor: DeleteFridgeItemProcessor::class),
    ],
    normalizationContext: ['groups' => ['fridge_item:read']],
    denormalizationContext: ['groups' => ['fridge_item:write']],
)]
class FridgeItem
{
    #[ORM\Id]
    #[ORM\GeneratedValue]
    #[ORM\Column]
    #[Groups(['fridge_item:read'])]
    private ?int $id = null;

    #[ORM\ManyToOne(targetEntity: Group::class)]
    #[ORM\JoinColumn(nullable: false)]
    #[Groups(['fridge_item:read', 'fridge_item:write'])]
    #[Assert\NotNull(groups: ['fridge_item:write'])]
    private ?Group $group = null;

    #[ORM\ManyToOne(targetEntity: FoodReference::class)]
    #[ORM\JoinColumn(nullable: false)]
    #[Groups(['fridge_item:read', 'fridge_item:write'])]
    #[Assert\NotNull(groups: ['fridge_item:write'])]
    #[ApiProperty(readableLink: true)]
    private ?FoodReference $foodReference = null;

    #[ORM\Column(length: 10, enumType: StorageLocation::class)]
    #[Groups(['fridge_item:read', 'fridge_item:write'])]
    #[Assert\NotNull(groups: ['fridge_item:write'])]
    private ?StorageLocation $storageLocation = null;

    #[ORM\Column(type: 'float')]
    #[Groups(['fridge_item:read', 'fridge_item:write'])]
    #[Assert\Positive(groups: ['fridge_item:write'])]
    private float $quantity = 0;

    #[ORM\Column(length: 20)]
    #[Groups(['fridge_item:read', 'fridge_item:write'])]
    #[Assert\NotBlank(groups: ['fridge_item:write'])]
    private string $unit = 'g';

    /** DLC — le tri par urgence (CLAUDE.md, "Frigo et placard") se fait sur ce champ. */
    #[ORM\Column(type: 'date_immutable')]
    #[Groups(['fridge_item:read', 'fridge_item:write'])]
    #[Assert\NotNull(groups: ['fridge_item:write'])]
    private ?\DateTimeImmutable $expirationDate = null;

    #[ORM\ManyToOne(targetEntity: User::class)]
    #[ORM\JoinColumn(nullable: false)]
    private ?User $addedBy = null;

    #[ORM\Column(type: 'datetime_immutable')]
    #[Groups(['fridge_item:read'])]
    private \DateTimeImmutable $addedAt;

    public function __construct()
    {
        $this->addedAt = new \DateTimeImmutable();
    }

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

    public function getFoodReference(): ?FoodReference
    {
        return $this->foodReference;
    }

    public function setFoodReference(?FoodReference $foodReference): static
    {
        $this->foodReference = $foodReference;

        return $this;
    }

    public function getStorageLocation(): ?StorageLocation
    {
        return $this->storageLocation;
    }

    public function setStorageLocation(StorageLocation $storageLocation): static
    {
        $this->storageLocation = $storageLocation;

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

    public function getExpirationDate(): ?\DateTimeImmutable
    {
        return $this->expirationDate;
    }

    public function setExpirationDate(\DateTimeImmutable $expirationDate): static
    {
        $this->expirationDate = $expirationDate;

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

    public function getAddedAt(): \DateTimeImmutable
    {
        return $this->addedAt;
    }
}
