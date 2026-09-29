<?php

namespace App\Domain\Group\State;

use ApiPlatform\Metadata\Operation;
use ApiPlatform\State\ProviderInterface;
use App\Domain\Group\Repository\GroupMembershipRepository;
use App\Domain\Group\Repository\GroupRepository;
use App\Shared\Entity\User;
use Symfony\Bundle\SecurityBundle\Security;
use Symfony\Component\HttpKernel\Exception\NotFoundHttpException;
use Symfony\Component\Security\Core\Exception\AccessDeniedException;

final class GroupMembershipsProvider implements ProviderInterface
{
    public function __construct(
        private readonly GroupRepository $groups,
        private readonly GroupMembershipRepository $memberships,
        private readonly Security $security,
    ) {
    }

    public function provide(Operation $operation, array $uriVariables = [], array $context = []): iterable
    {
        $group = $this->groups->find($uriVariables['groupId']);
        if (null === $group) {
            throw new NotFoundHttpException();
        }

        $user = $this->security->getUser();
        if (!$user instanceof User || !$this->memberships->isMember($user, $group)) {
            throw new AccessDeniedException();
        }

        return $group->getMemberships()->toArray();
    }
}
