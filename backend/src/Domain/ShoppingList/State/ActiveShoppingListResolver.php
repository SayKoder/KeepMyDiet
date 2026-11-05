<?php

namespace App\Domain\ShoppingList\State;

use App\Domain\Group\Repository\GroupMembershipRepository;
use App\Domain\Group\Repository\GroupRepository;
use App\Domain\ShoppingList\Entity\ShoppingList;
use App\Domain\ShoppingList\Repository\ShoppingListRepository;
use App\Shared\Entity\User;
use Symfony\Bundle\SecurityBundle\Security;
use Symfony\Component\HttpKernel\Exception\NotFoundHttpException;
use Symfony\Component\Security\Core\Exception\AccessDeniedException;

/**
 * Liste active du groupe pour un membre authentifié, non persistée si elle
 * vient d'être créée : l'appelant fait le persist/flush.
 */
final class ActiveShoppingListResolver
{
    public function __construct(
        private readonly GroupRepository $groups,
        private readonly GroupMembershipRepository $memberships,
        private readonly ShoppingListRepository $shoppingLists,
        private readonly Security $security,
    ) {
    }

    public function resolve(int|string $groupId): ShoppingList
    {
        $group = $this->groups->find($groupId);
        if (null === $group) {
            throw new NotFoundHttpException();
        }

        $user = $this->security->getUser();
        if (!$user instanceof User || !$this->memberships->isMember($user, $group)) {
            throw new AccessDeniedException();
        }

        $list = $this->shoppingLists->findActiveForGroup($group);
        if (null === $list) {
            $list = new ShoppingList();
            $list->setGroup($group);
        }

        return $list;
    }
}
