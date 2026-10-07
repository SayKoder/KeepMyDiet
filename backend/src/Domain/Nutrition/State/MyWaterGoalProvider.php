<?php

namespace App\Domain\Nutrition\State;

use ApiPlatform\Metadata\Operation;
use ApiPlatform\State\ProviderInterface;
use App\Domain\Nutrition\Repository\WaterGoalRepository;
use App\Shared\Entity\User;
use Symfony\Bundle\SecurityBundle\Security;
use Symfony\Component\Security\Core\Exception\AccessDeniedException;

/**
 * Pas une vraie "collection" : renvoie 0 ou 1 élément (l'objectif
 * d'hydratation personnalisé de l'utilisateur courant, s'il en a défini un)
 * — même logique que MyProfileProvider/TodayWaterIntakeProvider. Absence de
 * ligne = pas de surcharge, le client utilise son calcul par défaut.
 */
final class MyWaterGoalProvider implements ProviderInterface
{
    public function __construct(
        private readonly WaterGoalRepository $waterGoals,
        private readonly Security $security,
    ) {
    }

    public function provide(Operation $operation, array $uriVariables = [], array $context = []): array
    {
        $user = $this->security->getUser();
        if (!$user instanceof User) {
            throw new AccessDeniedException();
        }

        $goal = $this->waterGoals->findForUser($user);

        return null === $goal ? [] : [$goal];
    }
}
