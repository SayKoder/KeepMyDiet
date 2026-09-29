<?php

namespace App\Domain\Group\Entity;

use ApiPlatform\Metadata\ApiResource;
use ApiPlatform\Metadata\Post;
use App\Domain\Group\Repository\InvitationRepository;
use App\Domain\Group\State\AcceptInvitationProcessor;
use App\Domain\Group\State\CreateInvitationProcessor;
use App\Shared\Entity\User;
use Doctrine\ORM\Mapping as ORM;
use Symfony\Component\Serializer\Annotation\Groups;
use Symfony\Component\Validator\Constraints as Assert;

#[ORM\Entity(repositoryClass: InvitationRepository::class)]
#[ApiResource(
    shortName: 'GroupInvitation',
    operations: [
        new Post(
            uriTemplate: '/group_invitations',
            processor: CreateInvitationProcessor::class,
            normalizationContext: ['groups' => ['invitation:read']],
            denormalizationContext: ['groups' => ['invitation:write']],
            validationContext: ['groups' => ['invitation:write']],
        ),
        new Post(
            uriTemplate: '/group_invitations/join',
            name: 'join',
            processor: AcceptInvitationProcessor::class,
            normalizationContext: ['groups' => ['invitation:read']],
            denormalizationContext: ['groups' => ['invitation:join']],
            validationContext: ['groups' => ['invitation:join']],
        ),
    ],
)]
class Invitation
{
    #[ORM\Id]
    #[ORM\GeneratedValue]
    #[ORM\Column]
    #[Groups(['invitation:read'])]
    private ?int $id = null;

    #[ORM\ManyToOne(targetEntity: Group::class)]
    #[ORM\JoinColumn(nullable: false)]
    #[Groups(['invitation:read', 'invitation:write'])]
    #[Assert\NotNull(groups: ['invitation:write'])]
    private ?Group $group = null;

    /**
     * Lien persistant et réutilisable : rejoindre via ce token crée une nouvelle
     * adhésion sans jamais retirer l'utilisateur de ses groupes existants
     * (voir CLAUDE.md, section "Groupes et invitations").
     */
    #[ORM\Column(length: 64, unique: true)]
    #[Groups(['invitation:read', 'invitation:join'])]
    #[Assert\NotBlank(groups: ['invitation:join'])]
    private string $token = '';

    #[ORM\ManyToOne(targetEntity: User::class)]
    #[ORM\JoinColumn(nullable: false)]
    private ?User $createdBy = null;

    #[ORM\Column(type: 'datetime_immutable')]
    #[Groups(['invitation:read'])]
    private \DateTimeImmutable $createdAt;

    public function __construct()
    {
        $this->createdAt = new \DateTimeImmutable();
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

    public function getToken(): string
    {
        return $this->token;
    }

    public function setToken(string $token): static
    {
        $this->token = $token;

        return $this;
    }

    public function getCreatedBy(): ?User
    {
        return $this->createdBy;
    }

    public function setCreatedBy(User $createdBy): static
    {
        $this->createdBy = $createdBy;

        return $this;
    }

    public function getCreatedAt(): \DateTimeImmutable
    {
        return $this->createdAt;
    }
}
