<?php

namespace App\Domain\MealPlan\State;

use ApiPlatform\Metadata\Operation;
use ApiPlatform\State\ProviderInterface;
use App\Domain\MealPlan\Repository\MealPlanEntryLogRepository;
use App\Shared\Entity\User;
use Symfony\Bundle\SecurityBundle\Security;
use Symfony\Component\Security\Core\Exception\AccessDeniedException;

/**
 * Les réponses de l'utilisateur courant pour une date donnée, tous groupes
 * confondus (`?date=YYYY-MM-DD`, défaut aujourd'hui) — permet à l'écran de
 * savoir quels créneaux planifiés ont déjà une réponse, sans requête
 * supplémentaire par groupe.
 */
final class MealPlanEntryLogsProvider implements ProviderInterface
{
    public function __construct(
        private readonly MealPlanEntryLogRepository $mealPlanEntryLogs,
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

        return $this->mealPlanEntryLogs->findForUserAndDate($user, $date);
    }
}
