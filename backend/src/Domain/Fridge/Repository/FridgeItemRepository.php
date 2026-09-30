<?php

namespace App\Domain\Fridge\Repository;

use App\Domain\Fridge\Entity\FridgeItem;
use App\Domain\Group\Entity\Group;
use Doctrine\Bundle\DoctrineBundle\Repository\ServiceEntityRepository;
use Doctrine\Persistence\ManagerRegistry;

/**
 * @extends ServiceEntityRepository<FridgeItem>
 */
class FridgeItemRepository extends ServiceEntityRepository
{
    public function __construct(ManagerRegistry $registry)
    {
        parent::__construct($registry, FridgeItem::class);
    }

    /**
     * Triées par DLC croissante (plus urgent en premier) — voir CLAUDE.md,
     * section "Frigo et placard".
     *
     * @return FridgeItem[]
     */
    public function findForGroup(Group $group): array
    {
        return $this->createQueryBuilder('f')
            ->where('f.group = :group')
            ->setParameter('group', $group)
            ->orderBy('f.expirationDate', 'ASC')
            ->getQuery()
            ->getResult();
    }
}
