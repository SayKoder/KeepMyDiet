<?php

namespace App\Domain\Group\State;

use ApiPlatform\Metadata\Operation;
use ApiPlatform\State\ProviderInterface;
use App\Domain\Group\Repository\GroupMembershipRepository;
use App\Shared\Entity\User;
use Symfony\Bundle\SecurityBundle\Security;
use Symfony\Component\Security\Core\Exception\AccessDeniedException;

/**
 * Les groupes sont privés : la collection ne renvoie jamais que les groupes
 * dont l'utilisateur courant est membre, jamais tous les groupes de l'app.
 */
final class MyGroupsProvider implements ProviderInterface
{
    public function __construct(
        private readonly GroupMembershipRepository $memberships,
        private readonly Security $security,
    ) {
    }

    public function provide(Operation $operation, array $uriVariables = [], array $context = []): iterable
    {
        $user = $this->security->getUser();
        if (!$user instanceof User) {
            throw new AccessDeniedException();
        }

        return $this->memberships->findGroupsForUser($user);
    }
}
