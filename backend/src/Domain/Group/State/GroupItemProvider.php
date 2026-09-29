<?php

namespace App\Domain\Group\State;

use ApiPlatform\Metadata\Operation;
use ApiPlatform\State\ProviderInterface;
use App\Domain\Group\Entity\Group;
use App\Domain\Group\Repository\GroupMembershipRepository;
use App\Domain\Group\Repository\GroupRepository;
use App\Shared\Entity\User;
use Symfony\Bundle\SecurityBundle\Security;
use Symfony\Component\Security\Core\Exception\AccessDeniedException;

/**
 * Un groupe n'est consultable que par ses membres (pas de fuite d'info sur
 * un groupe auquel on n'appartient pas, même son simple nom).
 */
final class GroupItemProvider implements ProviderInterface
{
    public function __construct(
        private readonly GroupRepository $groups,
        private readonly GroupMembershipRepository $memberships,
        private readonly Security $security,
    ) {
    }

    public function provide(Operation $operation, array $uriVariables = [], array $context = []): ?Group
    {
        $group = $this->groups->find($uriVariables['id']);
        if (null === $group) {
            return null;
        }

        $user = $this->security->getUser();
        if (!$user instanceof User || !$this->memberships->isMember($user, $group)) {
            throw new AccessDeniedException();
        }

        return $group;
    }
}
