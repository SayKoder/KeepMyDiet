<?php

namespace App\Domain\Group\Repository;

use App\Domain\Group\Entity\Group;
use App\Domain\Group\Entity\GroupMembership;
use App\Domain\Group\Entity\GroupRole;
use App\Shared\Entity\User;
use Doctrine\Bundle\DoctrineBundle\Repository\ServiceEntityRepository;
use Doctrine\Persistence\ManagerRegistry;

/**
 * @extends ServiceEntityRepository<GroupMembership>
 */
class GroupMembershipRepository extends ServiceEntityRepository
{
    public function __construct(ManagerRegistry $registry)
    {
        parent::__construct($registry, GroupMembership::class);
    }

    public function findMembership(User $user, Group $group): ?GroupMembership
    {
        return $this->findOneBy(['user' => $user, 'group' => $group]);
    }

    public function isMember(User $user, Group $group): bool
    {
        return null !== $this->findMembership($user, $group);
    }

    public function isAdmin(User $user, Group $group): bool
    {
        return GroupRole::Admin === $this->findMembership($user, $group)?->getRole();
    }

    /**
     * @return Group[]
     */
    public function findGroupsForUser(User $user): array
    {
        $memberships = $this->findBy(['user' => $user]);

        return array_map(static fn (GroupMembership $membership) => $membership->getGroup(), $memberships);
    }
}
