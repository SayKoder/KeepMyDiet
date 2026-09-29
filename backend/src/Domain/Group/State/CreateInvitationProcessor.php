<?php

namespace App\Domain\Group\State;

use ApiPlatform\Metadata\Operation;
use ApiPlatform\State\ProcessorInterface;
use App\Domain\Group\Entity\Invitation;
use App\Domain\Group\Repository\GroupMembershipRepository;
use App\Shared\Entity\User;
use Doctrine\ORM\EntityManagerInterface;
use Symfony\Bundle\SecurityBundle\Security;
use Symfony\Component\Security\Core\Exception\AccessDeniedException;

/**
 * Seul un admin du groupe peut générer un lien d'invitation.
 */
final class CreateInvitationProcessor implements ProcessorInterface
{
    public function __construct(
        private readonly EntityManagerInterface $em,
        private readonly GroupMembershipRepository $memberships,
        private readonly Security $security,
    ) {
    }

    public function process(mixed $data, Operation $operation, array $uriVariables = [], array $context = []): mixed
    {
        /** @var Invitation $data */
        $user = $this->security->getUser();
        if (!$user instanceof User) {
            throw new AccessDeniedException();
        }

        $group = $data->getGroup();
        if (null === $group || !$this->memberships->isAdmin($user, $group)) {
            throw new AccessDeniedException('Seul un admin du groupe peut créer une invitation.');
        }

        // Token persistant et réutilisable, jamais régénéré ni invalidé après usage.
        $data->setToken(bin2hex(random_bytes(24)));
        $data->setCreatedBy($user);

        $this->em->persist($data);
        $this->em->flush();

        return $data;
    }
}
