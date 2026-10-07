<?php

namespace App\Domain\Nutrition\State;

use ApiPlatform\Metadata\Operation;
use ApiPlatform\State\ProviderInterface;
use App\Domain\Nutrition\Repository\WaterIntakeRepository;
use App\Shared\Entity\User;
use Symfony\Bundle\SecurityBundle\Security;
use Symfony\Component\Security\Core\Exception\AccessDeniedException;

/**
 * Pas une vraie "collection" : renvoie 0 ou 1 élément (le suivi d'eau du
 * jour pour l'utilisateur courant) — même logique que MyProfileProvider.
 * Absence de ligne = 0 mL bu aujourd'hui, un état normal côté client, pas une
 * erreur à gérer.
 */
final class TodayWaterIntakeProvider implements ProviderInterface
{
    public function __construct(
        private readonly WaterIntakeRepository $waterIntakes,
        private readonly Security $security,
    ) {
    }

    public function provide(Operation $operation, array $uriVariables = [], array $context = []): array
    {
        $user = $this->security->getUser();
        if (!$user instanceof User) {
            throw new AccessDeniedException();
        }

        $intake = $this->waterIntakes->findForUserAndDate($user, new \DateTimeImmutable('today'));

        return null === $intake ? [] : [$intake];
    }
}
