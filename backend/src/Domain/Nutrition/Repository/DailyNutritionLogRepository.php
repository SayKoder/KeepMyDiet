<?php

namespace App\Domain\Nutrition\Repository;

use App\Domain\Nutrition\Entity\DailyNutritionLog;
use App\Shared\Entity\User;
use Doctrine\Bundle\DoctrineBundle\Repository\ServiceEntityRepository;
use Doctrine\Persistence\ManagerRegistry;

/**
 * @extends ServiceEntityRepository<DailyNutritionLog>
 */
class DailyNutritionLogRepository extends ServiceEntityRepository
{
    public function __construct(ManagerRegistry $registry)
    {
        parent::__construct($registry, DailyNutritionLog::class);
    }

    public function findForUserAndDate(User $user, \DateTimeImmutable $date): ?DailyNutritionLog
    {
        return $this->findOneBy(['user' => $user, 'date' => $date]);
    }

    /**
     * Find-or-create la ligne du jour, applique les deltas (potentiellement
     * négatifs) et persiste. Centralisé ici plutôt que dupliqué dans chaque
     * processor qui a besoin d'écrire au journal (ajout manuel ET réponse à
     * un créneau de repas planifié, voir CreateOrUpdateMealPlanEntryLogProcessor).
     */
    public function applyDelta(
        User $user,
        \DateTimeImmutable $date,
        int $deltaKcal,
        float $deltaProteinG,
        float $deltaCarbG,
        float $deltaFatG,
    ): DailyNutritionLog {
        $log = $this->findForUserAndDate($user, $date);
        if (null === $log) {
            $log = new DailyNutritionLog();
            $log->setUser($user);
            $log->setDate($date);
        }

        $log->setCaloriesConsumed($log->getCaloriesConsumed() + $deltaKcal);
        $log->setProteinConsumedG($log->getProteinConsumedG() + $deltaProteinG);
        $log->setCarbConsumedG($log->getCarbConsumedG() + $deltaCarbG);
        $log->setFatConsumedG($log->getFatConsumedG() + $deltaFatG);

        $em = $this->getEntityManager();
        $em->persist($log);
        $em->flush();

        return $log;
    }
}
