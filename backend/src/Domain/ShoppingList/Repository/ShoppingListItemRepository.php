<?php

namespace App\Domain\ShoppingList\Repository;

use App\Domain\ShoppingList\Entity\ShoppingListItem;
use Doctrine\Bundle\DoctrineBundle\Repository\ServiceEntityRepository;
use Doctrine\Persistence\ManagerRegistry;

/**
 * @extends ServiceEntityRepository<ShoppingListItem>
 */
class ShoppingListItemRepository extends ServiceEntityRepository
{
    public function __construct(ManagerRegistry $registry)
    {
        parent::__construct($registry, ShoppingListItem::class);
    }
}
