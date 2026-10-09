<?php

namespace App\Domain\Nutrition\State;

use ApiPlatform\Metadata\Operation;
use ApiPlatform\State\ProviderInterface;
use App\Domain\Nutrition\Repository\DailyNutritionLogRepository;
use App\Shared\Entity\User;
use Symfony\Bundle\SecurityBundle\Security;
use Symfony\Component\Security\Core\Exception\AccessDeniedException;

/**
 * Pas une vraie "collection" : renvoie 0 ou 1 élément (le journal du jour
 * demandé pour l'utilisateur courant) — même logique que TodayWaterIntakeProvider.
 * `?date=YYYY-MM-DD` optionnel (défaut aujourd'hui) pour la navigation jour
 * par jour. Absence de ligne = rien consommé ce jour-là, un état normal côté
 * client, pas une erreur à gérer.
 */
final class DailyNutritionLogProvider implements ProviderInterface
{
    public function __construct(
        private readonly DailyNutritionLogRepository $dailyNutritionLogs,
        private readonly Security $security,
    ) {
    }

    public function provide(Operation $operation, array $uriVariables = [], array $context = []): array
    {
        $user = $this->security->getUser();
        if (!$user instanceof User) {
            throw new AccessDeniedException();
        }

        $filters = $context['filters'] ?? [];
        $date = isset($filters['date'])
            ? \DateTimeImmutable::createFromFormat('!Y-m-d', $filters['date'])
            : new \DateTimeImmutable('today');

        $log = $this->dailyNutritionLogs->findForUserAndDate($user, $date);

        return null === $log ? [] : [$log];
    }
}
