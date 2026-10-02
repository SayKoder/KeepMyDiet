<?php

namespace App\Domain\ShoppingList\Repository;

use App\Domain\Group\Entity\Group;
use App\Domain\ShoppingList\Entity\ShoppingList;
use Doctrine\Bundle\DoctrineBundle\Repository\ServiceEntityRepository;
use Doctrine\Persistence\ManagerRegistry;

/**
 * @extends ServiceEntityRepository<ShoppingList>
 */
class ShoppingListRepository extends ServiceEntityRepository
{
    public function __construct(ManagerRegistry $registry)
    {
        parent::__construct($registry, ShoppingList::class);
    }

    public function findActiveForGroup(Group $group): ?ShoppingList
    {
        return $this->findOneBy(['group' => $group]);
    }
}
