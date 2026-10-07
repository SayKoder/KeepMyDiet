<?php

namespace App\Domain\Nutrition\Repository;

use App\Domain\Nutrition\Entity\WaterGoal;
use App\Shared\Entity\User;
use Doctrine\Bundle\DoctrineBundle\Repository\ServiceEntityRepository;
use Doctrine\Persistence\ManagerRegistry;

/**
 * @extends ServiceEntityRepository<WaterGoal>
 */
class WaterGoalRepository extends ServiceEntityRepository
{
    public function __construct(ManagerRegistry $registry)
    {
        parent::__construct($registry, WaterGoal::class);
    }

    public function findForUser(User $user): ?WaterGoal
    {
        return $this->findOneBy(['user' => $user]);
    }
}
