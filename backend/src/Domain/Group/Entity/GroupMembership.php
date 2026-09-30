<?php

namespace App\Domain\Group\Entity;

use ApiPlatform\Metadata\ApiProperty;
use ApiPlatform\Metadata\ApiResource;
use ApiPlatform\Metadata\GetCollection;
use App\Domain\Group\Repository\GroupMembershipRepository;
use App\Domain\Group\State\GroupMembershipsProvider;
use App\Shared\Entity\User;
use Doctrine\ORM\Mapping as ORM;
use Symfony\Component\Serializer\Annotation\Groups;

#[ORM\Entity(repositoryClass: GroupMembershipRepository::class)]
#[ORM\UniqueConstraint(name: 'UNIQ_MEMBERSHIP_USER_GROUP', fields: ['user', 'group'])]
#[ApiResource(
    operations: [
        new GetCollection(
            uriTemplate: '/groups/{groupId}/memberships',
            uriVariables: ['groupId' => new \ApiPlatform\Metadata\Link(fromClass: Group::class, toProperty: 'group')],
            provider: GroupMembershipsProvider::class,
        ),
    ],
    normalizationContext: ['groups' => ['membership:read']],
)]
class GroupMembership
{
    #[ORM\Id]
    #[ORM\GeneratedValue]
    #[ORM\Column]
    #[Groups(['membership:read'])]
    private ?int $id = null;

    #[ORM\ManyToOne(targetEntity: Group::class, inversedBy: 'memberships')]
    #[ORM\JoinColumn(nullable: false)]
    private ?Group $group = null;

    #[ORM\ManyToOne(targetEntity: User::class)]
    #[ORM\JoinColumn(nullable: false)]
    #[Groups(['membership:read'])]
    #[ApiProperty(readableLink: true)]
    private ?User $user = null;

    #[ORM\Column(length: 20, enumType: GroupRole::class)]
    #[Groups(['membership:read'])]
    private GroupRole $role;

    #[ORM\Column(type: 'datetime_immutable')]
    #[Groups(['membership:read'])]
    private \DateTimeImmutable $joinedAt;

    public function __construct(Group $group, User $user, GroupRole $role)
    {
        $this->group = $group;
        $this->user = $user;
        $this->role = $role;
        $this->joinedAt = new \DateTimeImmutable();
    }

    public function getId(): ?int
    {
        return $this->id;
    }

    public function getGroup(): ?Group
    {
        return $this->group;
    }

    public function getUser(): ?User
    {
        return $this->user;
    }

    public function getRole(): GroupRole
    {
        return $this->role;
    }

    public function getJoinedAt(): \DateTimeImmutable
    {
        return $this->joinedAt;
    }
}
