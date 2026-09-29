<?php

namespace App\Domain\Group\Entity;

use ApiPlatform\Metadata\ApiResource;
use ApiPlatform\Metadata\Get;
use ApiPlatform\Metadata\GetCollection;
use ApiPlatform\Metadata\Post;
use App\Domain\Group\Repository\GroupRepository;
use App\Domain\Group\State\CreateGroupProcessor;
use App\Domain\Group\State\GroupItemProvider;
use App\Domain\Group\State\MyGroupsProvider;
use Doctrine\Common\Collections\ArrayCollection;
use Doctrine\Common\Collections\Collection;
use Doctrine\ORM\Mapping as ORM;
use Symfony\Component\Serializer\Annotation\Groups;
use Symfony\Component\Validator\Constraints as Assert;

#[ORM\Entity(repositoryClass: GroupRepository::class)]
#[ORM\Table(name: 'app_group')]
#[ApiResource(
    operations: [
        new GetCollection(provider: MyGroupsProvider::class),
        new Get(provider: GroupItemProvider::class),
        new Post(processor: CreateGroupProcessor::class, validationContext: ['groups' => ['group:write']]),
    ],
    normalizationContext: ['groups' => ['group:read']],
    denormalizationContext: ['groups' => ['group:write']],
)]
class Group
{
    #[ORM\Id]
    #[ORM\GeneratedValue]
    #[ORM\Column]
    #[Groups(['group:read'])]
    private ?int $id = null;

    #[ORM\Column(length: 120)]
    #[Groups(['group:read', 'group:write'])]
    #[Assert\NotBlank(groups: ['group:write'])]
    #[Assert\Length(max: 120, groups: ['group:write'])]
    private string $name = '';

    #[ORM\Column(type: 'datetime_immutable')]
    #[Groups(['group:read'])]
    private \DateTimeImmutable $createdAt;

    /** @var Collection<int, GroupMembership> */
    #[ORM\OneToMany(targetEntity: GroupMembership::class, mappedBy: 'group', orphanRemoval: true)]
    private Collection $memberships;

    public function __construct()
    {
        $this->createdAt = new \DateTimeImmutable();
        $this->memberships = new ArrayCollection();
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

    public function getCreatedAt(): \DateTimeImmutable
    {
        return $this->createdAt;
    }

    /** @return Collection<int, GroupMembership> */
    public function getMemberships(): Collection
    {
        return $this->memberships;
    }
}
