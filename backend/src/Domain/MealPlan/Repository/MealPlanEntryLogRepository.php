<?php

namespace App\Domain\MealPlan\Repository;

use App\Domain\MealPlan\Entity\MealPlanEntry;
use App\Domain\MealPlan\Entity\MealPlanEntryLog;
use App\Shared\Entity\User;
use Doctrine\Bundle\DoctrineBundle\Repository\ServiceEntityRepository;
use Doctrine\Persistence\ManagerRegistry;

/**
 * @extends ServiceEntityRepository<MealPlanEntryLog>
 */
class MealPlanEntryLogRepository extends ServiceEntityRepository
{
    public function __construct(ManagerRegistry $registry)
    {
        parent::__construct($registry, MealPlanEntryLog::class);
    }

    public function findForEntryAndUser(MealPlanEntry $entry, User $user): ?MealPlanEntryLog
    {
        return $this->findOneBy(['mealPlanEntry' => $entry, 'user' => $user]);
    }

    /** @return MealPlanEntryLog[] */
    public function findForUserAndDate(User $user, \DateTimeImmutable $date): array
    {
        return $this->createQueryBuilder('l')
            ->join('l.mealPlanEntry', 'e')
            ->andWhere('l.user = :user')
            ->andWhere('e.date = :date')
            ->setParameter('user', $user)
            ->setParameter('date', $date)
            ->getQuery()
            ->getResult();
    }
}
