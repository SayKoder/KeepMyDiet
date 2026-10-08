<?php

namespace App\Domain\MealPlan\Repository;

use App\Domain\Group\Entity\Group;
use App\Domain\MealPlan\Entity\MealPlanEntry;
use Doctrine\Bundle\DoctrineBundle\Repository\ServiceEntityRepository;
use Doctrine\Persistence\ManagerRegistry;

/**
 * @extends ServiceEntityRepository<MealPlanEntry>
 */
class MealPlanEntryRepository extends ServiceEntityRepository
{
    public function __construct(ManagerRegistry $registry)
    {
        parent::__construct($registry, MealPlanEntry::class);
    }

    /** @return MealPlanEntry[] */
    public function findForGroupInRange(Group $group, \DateTimeImmutable $from, \DateTimeImmutable $to): array
    {
        return $this->createQueryBuilder('e')
            ->andWhere('e.group = :group')
            ->andWhere('e.date >= :from')
            ->andWhere('e.date <= :to')
            ->setParameter('group', $group)
            ->setParameter('from', $from)
            ->setParameter('to', $to)
            ->orderBy('e.date', 'ASC')
            ->getQuery()
            ->getResult();
    }
}
