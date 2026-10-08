<?php

namespace App\Domain\MealPlan\State;

use ApiPlatform\Metadata\Operation;
use ApiPlatform\State\ProviderInterface;
use App\Domain\Group\Repository\GroupMembershipRepository;
use App\Domain\Group\Repository\GroupRepository;
use App\Domain\MealPlan\Repository\MealPlanEntryRepository;
use App\Shared\Entity\User;
use Symfony\Bundle\SecurityBundle\Security;
use Symfony\Component\HttpKernel\Exception\NotFoundHttpException;
use Symfony\Component\Security\Core\Exception\AccessDeniedException;

/**
 * `from`/`to` (query string, format YYYY-MM-DD) bornent la période — sans
 * eux, retombe sur "aujourd'hui + 6 jours" (une semaine glissante), pour que
 * l'écran Flutter ait toujours quelque chose de raisonnable à afficher par
 * défaut.
 */
final class MealPlanEntriesProvider implements ProviderInterface
{
    public function __construct(
        private readonly GroupRepository $groups,
        private readonly GroupMembershipRepository $memberships,
        private readonly MealPlanEntryRepository $mealPlanEntries,
        private readonly Security $security,
    ) {
    }

    public function provide(Operation $operation, array $uriVariables = [], array $context = []): array
    {
        $group = $this->groups->find($uriVariables['groupId']);
        if (null === $group) {
            throw new NotFoundHttpException();
        }

        $user = $this->security->getUser();
        if (!$user instanceof User || !$this->memberships->isMember($user, $group)) {
            throw new AccessDeniedException();
        }

        $filters = $context['filters'] ?? [];
        $from = isset($filters['from'])
            ? \DateTimeImmutable::createFromFormat('!Y-m-d', $filters['from'])
            : new \DateTimeImmutable('today');
        $to = isset($filters['to'])
            ? \DateTimeImmutable::createFromFormat('!Y-m-d', $filters['to'])
            : $from->modify('+6 days');

        return $this->mealPlanEntries->findForGroupInRange($group, $from, $to);
    }
}
