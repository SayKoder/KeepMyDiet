<?php

namespace App\Domain\Nutrition\Repository;

use App\Domain\Nutrition\Entity\WaterIntake;
use App\Shared\Entity\User;
use Doctrine\Bundle\DoctrineBundle\Repository\ServiceEntityRepository;
use Doctrine\Persistence\ManagerRegistry;

/**
 * @extends ServiceEntityRepository<WaterIntake>
 */
class WaterIntakeRepository extends ServiceEntityRepository
{
    public function __construct(ManagerRegistry $registry)
    {
        parent::__construct($registry, WaterIntake::class);
    }

    public function findForUserAndDate(User $user, \DateTimeImmutable $date): ?WaterIntake
    {
        return $this->findOneBy(['user' => $user, 'date' => $date]);
    }
}
